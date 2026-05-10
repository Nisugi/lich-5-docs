# frozen_string_literal: true

require 'time'

module Lich
  module InternalAPI
    module ActiveSessions
      # Manages active sessions for the Lich application.
      #
      # This class provides methods to upsert, remove, and retrieve session data.
      #
      # @see Lich::InternalAPI::ActiveSessions
      class Registry
        # Initializes a new session registry.
        #
        # @param time_source [Proc] a callable that returns the current time in seconds.
        # @param process_checker [Proc] a callable that checks if a process is alive.
        # @return [void]
        def initialize(time_source: -> { Time.now.to_i }, process_checker: self.class.method(:process_alive?))
          @time_source = time_source
          @process_checker = process_checker
          @sessions = {}
          @mutex = Mutex.new
        end

        # Upserts a session with the given payload.
        #
        # This method updates an existing session or creates a new one if it doesn't exist.
        #
        # @param payload [Hash] the session data to upsert, including :pid and :started_at.
        # @return [Hash] the session data after upserting.
        def upsert(payload)
          data = symbolize_keys(payload)
          pid = Integer(data.fetch(:pid))
          now = @time_source.call

          @mutex.synchronize do
            current = @sessions[pid] || {}
            started_at = data[:started_at] || current[:started_at] || now
            merged = current.merge(mergeable_data(data))
            merged[:pid] = pid
            merged[:started_at] = started_at
            merged[:last_seen_at] = now
            merged[:connected] = !!merged[:connected]
            merged[:hidden] = !!merged[:hidden]
            @sessions[pid] = merged
          end

          session(pid)
        end

        # Removes a session by its process ID.
        #
        # @param pid [Integer] the process ID of the session to remove.
        # @return [Boolean] true if the session was removed, false otherwise.
        def remove(pid)
          @mutex.synchronize { !@sessions.delete(pid.to_i).nil? }
        end

        # Retrieves a session by its process ID.
        #
        # @param pid [Integer] the process ID of the session to retrieve.
        # @return [Hash, nil] the session data if found, nil otherwise.
        def session(pid)
          @mutex.synchronize do
            record = @sessions[pid.to_i]
            record ? record.dup : nil
          end
        end

        # Takes a snapshot of all active sessions.
        #
        # This method returns a summary of all sessions, including their uptime and connection status.
        #
        # @return [Hash] a summary of active sessions.
        def snapshot
          sweep_dead_sessions!
          now = @time_source.call
          sessions = @mutex.synchronize { @sessions.values.map(&:dup) }
          normalized = sessions.sort_by { |session| session[:pid] }.map do |session|
            session.merge(
              uptime_seconds: [0, now - session[:started_at].to_i].max,
              listener: listener_hash(session)
            )
          end

          {
            source: 'ActiveSessionsAPI',
            total: normalized.length,
            connected: normalized.count { |session| session[:connected] },
            detachable: normalized.count { |session| session[:listener] },
            sessions: normalized
          }
        end

        # Cleans up sessions that are no longer associated with alive processes.
        #
        # This method checks for dead sessions and removes them from the registry.
        #
        # @return [void]
        # @api private
        def sweep_dead_sessions!
          dead_pids = @mutex.synchronize { @sessions.keys }.reject { |pid| @process_checker.call(pid) }
          return if dead_pids.empty?

          @mutex.synchronize do
            dead_pids.each { |pid| @sessions.delete(pid) }
          end
        end

        # Returns an empty snapshot of sessions with optional error information.
        #
        # @param error [String, nil] an optional error message to include in the snapshot.
        # @return [Hash] an empty session summary.
        def empty_snapshot(error: nil)
          {
            source: 'ActiveSessionsAPI',
            total: 0,
            connected: 0,
            detachable: 0,
            sessions: [],
            error: error
          }.compact
        end

        # Checks if a process is alive based on its process ID.
        #
        # @param pid [Integer] the process ID to check.
        # @return [Boolean] true if the process is alive, false otherwise.
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

        private

        def symbolize_keys(hash)
          hash.each_with_object({}) do |(key, value), normalized|
            normalized[key.to_sym] = value
          end
        end

        def mergeable_data(data)
          data.each_with_object({}) do |(key, value), merged|
            next if value.nil? && !%i[listener_host listener_port].include?(key)

            merged[key] = value
          end
        end
        private :mergeable_data

        def listener_hash(session)
          return nil if session[:listener_port].nil?

          {
            host: session[:listener_host] || '127.0.0.1',
            port: session[:listener_port].to_i
          }
        end
      end
    end
  end
end
