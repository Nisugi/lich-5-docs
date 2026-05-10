# frozen_string_literal: true

require 'time'

module Lich
  module InternalAPI
    module ActiveSessions
      # Manages active sessions for the application.
      # This class provides methods to upsert, remove, and retrieve session data.
      # @example Creating a new session registry
      #   registry = Lich::InternalAPI::ActiveSessions::Registry.new
      class Registry
        # Initializes a new session registry.
        # @param time_source [Proc] A callable that returns the current time in seconds.
        # @param process_checker [Proc] A callable that checks if a process is alive.
        # @return [Registry]
        def initialize(time_source: -> { Time.now.to_i }, process_checker: self.class.method(:process_alive?))
          @time_source = time_source
          @process_checker = process_checker
          @sessions = {}
          @mutex = Mutex.new
        end

        # Upserts a session with the given payload.
        # This method will create a new session or update an existing one based on the provided PID.
        # @param payload [Hash] The session data to upsert, including :pid and :started_at.
        # @return [Hash] The session data after upserting.
        # @example Upserting a session
        #   registry.upsert(pid: 123, started_at: Time.now.to_i)
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

        # Removes a session by its PID.
        # @param pid [Integer] The process ID of the session to remove.
        # @return [Boolean] True if the session was removed, false otherwise.
        # @example Removing a session
        #   registry.remove(123)
        def remove(pid)
          @mutex.synchronize { !@sessions.delete(pid.to_i).nil? }
        end

        # Retrieves a session by its PID.
        # @param pid [Integer] The process ID of the session to retrieve.
        # @return [Hash, nil] The session data if found, nil otherwise.
        # @example Retrieving a session
        #   session_data = registry.session(123)
        def session(pid)
          @mutex.synchronize do
            record = @sessions[pid.to_i]
            record ? record.dup : nil
          end
        end

        # Takes a snapshot of all active sessions.
        # This method returns a summary of all sessions, including their uptime and connection status.
        # @return [Hash] A hash containing the snapshot of active sessions.
        # @example Taking a snapshot of sessions
        #   snapshot = registry.snapshot
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

        def sweep_dead_sessions!
          dead_pids = @mutex.synchronize { @sessions.keys }.reject { |pid| @process_checker.call(pid) }
          return if dead_pids.empty?

          @mutex.synchronize do
            dead_pids.each { |pid| @sessions.delete(pid) }
          end
        end

        # Returns an empty snapshot of sessions with optional error information.
        # @param error [String, nil] An optional error message to include in the snapshot.
        # @return [Hash] A hash representing an empty session snapshot.
        # @example Getting an empty snapshot
        #   empty_snapshot = registry.empty_snapshot(error: "No sessions available")
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
