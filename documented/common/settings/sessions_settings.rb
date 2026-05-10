# frozen_string_literal: true

require_relative 'session_database_adapter'
require 'rbconfig'

module Lich
  # Provides settings and management for session handling.
  #
  # @see Lich::Common::FeatureFlags
  module Common
    module SessionsSettings
      FEATURE_FLAG = :session_summary_store_and_reporting
      HEARTBEAT_INTERVAL_SECONDS = 90
      STALE_THRESHOLD_SECONDS = 360
      IDLE_OVER_30M_SECONDS = 1800
      ADAPTER_MUTEX = Mutex.new

      # Checks if the session summary store and reporting feature is enabled.
      # @return [Boolean] true if the feature is enabled, false otherwise
      def self.enabled?
        return false unless defined?(Lich::Common::FeatureFlags)

        Lich::Common::FeatureFlags.enabled?(FEATURE_FLAG)
      end

      # Retrieves the session database adapter, initializing it if necessary.
      # @return [SessionDatabaseAdapter] the session database adapter instance
      def self.adapter
        return @adapter if @adapter

        ADAPTER_MUTEX.synchronize do
          @adapter ||= SessionDatabaseAdapter.new(db: Lich.db)
        end
      end

      # Registers a new session with the given parameters.
      # @param pid [Integer] the process ID of the session
      # @param session_name [String] the name of the session
      # @param role [String] the role of the session
      # @param state [String] the current state of the session
      # @param frontend [String, nil] optional frontend identifier
      # @param game_code [String, nil] optional game code
      # @param hidden [Boolean] whether the session is hidden
      # @param metadata_json [String, nil] optional metadata in JSON format
      # @return [void]
      def self.register_session(pid:, session_name:, role:, state:, frontend: nil, game_code: nil, hidden: false, metadata_json: nil)
        return unless enabled?

        now = Time.now.to_i
        sweep_dead_sessions!(now: now)
        os_presence_state = os_presence(pid: pid, session_name: session_name, now: now)
        adapter.upsert_session(
          pid: pid,
          session_name: session_name,
          role: role,
          state: state,
          frontend: frontend,
          game_code: game_code,
          hidden: hidden ? 1 : 0,
          started_at: now,
          last_heartbeat_at: now,
          os_seen_at: os_presence_state[:os_seen_at],
          os_seen: os_presence_state[:os_seen],
          os_name: os_presence_state[:os_name],
          metadata_json: metadata_json
        )
      end

      # Updates the heartbeat for an existing session.
      # @param pid [Integer] the process ID of the session
      # @param state [String, nil] the current state of the session
      # @param hidden [Boolean, nil] whether the session is hidden
      # @param session_name [String, nil] the name of the session
      # @param role [String, nil] the role of the session
      # @param frontend [String, nil] optional frontend identifier
      # @param game_code [String, nil] optional game code
      # @param last_utilization_at [Integer, nil] optional timestamp of last utilization
      # @return [void]
      def self.heartbeat(pid:, state: nil, hidden: nil, session_name: nil, role: nil, frontend: nil, game_code: nil, last_utilization_at: nil)
        return unless enabled?

        now = Time.now.to_i
        session_name = session_name || adapter.find_session(pid: pid)&.fetch('session_name', nil)
        os_presence_state = os_presence(pid: pid, session_name: session_name, now: now)
        adapter.upsert_session(
          pid: pid,
          session_name: session_name,
          role: role,
          state: state,
          frontend: frontend,
          game_code: game_code,
          hidden: hidden.nil? ? nil : (hidden ? 1 : 0),
          last_heartbeat_at: now,
          os_seen_at: os_presence_state[:os_seen_at],
          os_seen: os_presence_state[:os_seen],
          os_name: os_presence_state[:os_name],
          last_utilization_at: last_utilization_at
        )
      end

      # Unregisters a session by marking it as exited.
      # @param pid [Integer] the process ID of the session
      # @return [void]
      def self.unregister_session(pid:)
        return unless enabled?

        now = Time.now.to_i
        adapter.upsert_session(
          pid: pid,
          state: 'exited',
          os_seen_at: now,
          os_seen: 0,
          os_name: 0
        )
      end

      # Takes a snapshot of the current active sessions.
      # @return [Hash] a hash containing session statistics and details
      # @example Get the current session snapshot
      #   Lich::Common::SessionsSettings.snapshot
      def self.snapshot
        return disabled_snapshot unless enabled?

        rows = adapter.active_sessions
        now = Time.now.to_i
        sessions = rows.map do |row|
          inactive = row['state'] == 'exited'
          if inactive
            os_seen = row['os_seen']
            os_name = row['os_name']
          else
            # Reporting uses authoritative live OS presence, but does not
            # persist those observations back into storage.
            live_presence = os_presence(pid: row['pid'], session_name: row['session_name'], now: now)
            os_seen = live_presence[:os_seen]
            os_name = live_presence[:os_name]
          end
          heartbeat_is_stale = stale?(row['last_heartbeat_at'], now)
          stale = !inactive && (heartbeat_is_stale || os_seen.to_i == 0)
          marker = inactive ? 'inactive' : (stale ? 'stale' : 'active')
          {
            pid: row['pid'],
            session_name: row['session_name'],
            state: row['state'],
            hidden: row['hidden'].to_i == 1,
            role: row['role'],
            last_heartbeat_at: row['last_heartbeat_at'].to_i,
            heartbeat_age: heartbeat_age(row['last_heartbeat_at'], now),
            stale: stale,
            marker: marker,
            os_seen: os_seen.to_i == 1,
            os_name: os_name.nil? ? nil : (os_name.to_i == 1),
            last_utilization: format_last_utilization(row['last_utilization_at'], now)
          }
        end

        {
          source: 'SessionsSettings',
          total: sessions.length,
          idle_over_30m: sessions.count { |s| !s[:heartbeat_age].nil? && s[:heartbeat_age] > IDLE_OVER_30M_SECONDS },
          stale: sessions.count { |s| s[:stale] },
          running: sessions.count { |s| s[:state] == 'running' },
          sleeping: sessions.count { |s| s[:state] == 'sleeping' },
          hidden: sessions.count { |s| s[:hidden] },
          sessions: sessions
        }
      rescue StandardError => e
        disabled_snapshot(error: e.message)
      end

      # Formats the last utilization timestamp into seconds ago.
      # @param last_utilization_at [Integer, nil] the last utilization timestamp
      # @param now_epoch [Integer] the current epoch time
      # @return [Integer, nil] seconds ago since last utilization, or nil if not applicable
      def self.format_last_utilization(last_utilization_at, now_epoch)
        return nil if last_utilization_at.nil?

        seconds_ago = now_epoch - last_utilization_at.to_i
        seconds_ago.negative? ? 0 : seconds_ago
      end
      private_class_method :format_last_utilization

      # Calculates the age of the last heartbeat.
      # @param last_heartbeat_at [Integer, nil] the last heartbeat timestamp
      # @param now_epoch [Integer] the current epoch time
      # @return [Integer, nil] age of the last heartbeat in seconds, or nil if not applicable
      def self.heartbeat_age(last_heartbeat_at, now_epoch)
        return nil if last_heartbeat_at.nil?

        age = now_epoch - last_heartbeat_at.to_i
        age.negative? ? 0 : age
      end
      private_class_method :heartbeat_age

      # Determines if a session is stale based on the last heartbeat.
      # @param last_heartbeat_at [Integer, nil] the last heartbeat timestamp
      # @param now_epoch [Integer] the current epoch time
      # @return [Boolean] true if the session is stale, false otherwise
      def self.stale?(last_heartbeat_at, now_epoch)
        age = heartbeat_age(last_heartbeat_at, now_epoch)
        !age.nil? && age > STALE_THRESHOLD_SECONDS
      end
      private_class_method :stale?

      # Checks the OS presence of a session based on its PID and session name.
      # @param pid [Integer] the process ID of the session
      # @param session_name [String] the name of the session
      # @param now [Integer] the current epoch time
      # @return [Hash] a hash containing OS presence details
      def self.os_presence(pid:, session_name:, now: Time.now.to_i)
        seen = process_alive?(pid)
        name_match = if seen
                       name_matches_process?(pid, session_name)
                     else
                       0
                     end
        {
          os_seen_at: now,
          os_seen: seen ? 1 : 0,
          os_name: name_match
        }
      end

      # Checks if a process is alive based on its PID.
      # @param pid [Integer] the process ID to check
      # @return [Boolean] true if the process is alive, false otherwise
      # @api private
      def self.process_alive?(pid)
        Process.kill(0, pid.to_i)
        true
      rescue Errno::ESRCH
        false
      rescue Errno::EPERM
        true
      rescue StandardError
        false
      end
      private_class_method :process_alive?

      # Checks if the session name matches the command line of the process.
      # @param pid [Integer] the process ID to check
      # @param session_name [String] the name of the session
      # @return [Integer, nil] 1 if the name matches, 0 if it does not, or nil on error
      # @api private
      def self.name_matches_process?(pid, session_name)
        return nil if session_name.to_s.strip.empty?

        cmdline = process_command_line(pid)
        return nil if cmdline.nil? || cmdline.empty?

        cmdline.downcase.include?(session_name.to_s.downcase) ? 1 : 0
      rescue StandardError
        nil
      end
      private_class_method :name_matches_process?
      private_class_method :os_presence

      # Retrieves the command line of a process based on its PID.
      # @param pid [Integer] the process ID to check
      # @return [String, nil] the command line of the process, or nil on error
      # @api private
      def self.process_command_line(pid)
        case RbConfig::CONFIG['host_os']
        when /linux/, /darwin|mac os/
          `ps -o command= -p #{pid.to_i} 2>/dev/null`.to_s.strip
        when /mswin|mingw|cygwin/
          script = "(Get-CimInstance Win32_Process -Filter \"ProcessId = #{pid.to_i}\").CommandLine"
          output = `powershell.exe -WindowStyle Hidden -NoProfile -Command "#{script}" 2>NUL`.to_s.strip
          output.empty? ? nil : output
        else
          nil
        end
      rescue StandardError
        nil
      end
      private_class_method :process_command_line

      # Sweeps and marks dead sessions as exited based on their PID.
      # @param now [Integer] the current epoch time
      # @return [void]
      # @api private
      def self.sweep_dead_sessions!(now: Time.now.to_i)
        adapter.tracked_live_candidates.each do |row|
          next if process_alive?(row['pid'])

          adapter.upsert_session(
            pid: row['pid'],
            state: 'exited',
            os_seen_at: now,
            os_seen: 0,
            os_name: 0
          )
        end
      end
      private_class_method :sweep_dead_sessions!

      # Returns a snapshot indicating that the session feature is disabled.
      # @param error [String, nil] optional error message
      # @return [Hash] a hash containing default session statistics
      # @api private
      def self.disabled_snapshot(error: nil)
        {
          source: 'SessionsSettings',
          total: 0,
          idle_over_30m: 0,
          stale: 0,
          running: 0,
          sleeping: 0,
          hidden: 0,
          sessions: [],
          error: error
        }.compact
      end
      private_class_method :disabled_snapshot
    end
  end
end
