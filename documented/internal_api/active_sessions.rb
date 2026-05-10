# frozen_string_literal: true

require 'json'
require 'securerandom'
require 'tmpdir'

require_relative 'active_sessions/registry'
require_relative 'active_sessions/server'
require_relative 'active_sessions/client'
require_relative 'active_sessions/lifecycle'

module Lich
  module InternalAPI
    # Cross-process local service that tracks currently active Lich sessions.
    #
    # This module owns the process-local server instance for the active
    # Cross-process local service that tracks currently active Lich sessions.
    #
    # This module owns the process-local server instance for the active
    # sessions.
    # @example Starting the active sessions service
    #   Lich::InternalAPI::ActiveSessions.ensure_service!
    module ActiveSessions
      # Feature flag for the active sessions API.
      FEATURE_FLAG = :active_sessions_api

      # Default host for the active sessions server.
      DEFAULT_HOST = '127.0.0.1'

      # Default port for the active sessions server.
      DEFAULT_PORT = 42_857

      # Filename for the discovery JSON file.
      DISCOVERY_FILENAME = 'lich-active-sessions.json'

      @registry = nil
      @server = nil
      @service_client = nil
      @service_client_token = nil
      @mutex = Mutex.new
      @service_client_mutex = Mutex.new

      # Checks if the active sessions feature is enabled.
      # @return [Boolean] true if enabled, false otherwise.
      # @raise [StandardError] if the feature flag check fails.
      # @example Checking if active sessions are enabled
      #   Lich::InternalAPI::ActiveSessions.enabled?
      def self.enabled?
        return false unless defined?(Lich::Common::FeatureFlags)

        Lich::Common::FeatureFlags.enabled?(FEATURE_FLAG)
      rescue StandardError => e
        Lich.log("warning: ActiveSessions feature flag check failed: #{e.class}: #{e.message}") if Lich.respond_to?(:log)
        false
      end

      # Ensures that the active sessions service is running.
      # @return [Boolean] true if the service is available, false otherwise.
      # @example Ensuring the active sessions service is running
      #   Lich::InternalAPI::ActiveSessions.ensure_service!
      def self.ensure_service!
        return false unless enabled?

        ensure_service_internal!(allow_bootstrap: true)
      end

      def self.ensure_service_internal!(allow_bootstrap:)
        return true if service_available?
        return false unless allow_bootstrap

        # Re-check the live kill switch on the bootstrap path so admitted
        # callers can reuse an existing owner without re-reading the flag,
        # while still preventing creation of a brand-new owner after disable.
        return false unless enabled?

        @mutex.synchronize do
          return true if service_available?

          # If this process previously owned a server whose accept thread
          # died, the TCPServer socket is still bound but unserviceable.
          # Stop it to release the port before attempting a fresh start.
          if @server && !@server.running?
            Lich.log('warning: ActiveSessions server thread died -- releasing zombie socket') if Lich.respond_to?(:log)
            @server.stop
            @server = nil
          end

          @registry ||= Registry.new
          @server ||= Server.new(
            host: DEFAULT_HOST,
            port: DEFAULT_PORT,
            registry: @registry,
            auth_token: SecureRandom.hex(32)
          )
          return false unless @server.start

          write_discovery(owner_pid: Process.pid, auth_token: @server.auth_token)
          true
        end
      rescue StandardError => e
        Lich.log("warning: ActiveSessions service unavailable: #{e.class}: #{e.message}") if Lich.respond_to?(:log)
        false
      end
      private_class_method :ensure_service_internal!

      # Registers a new session with the given payload.
      # @param payload [Hash] The session data to register.
      # @return [Boolean] true if the session was registered successfully, false otherwise.
      # @example Registering a session
      #   Lich::InternalAPI::ActiveSessions.register_session({ user_id: 1 })
      def self.register_session(payload)
        return false unless enabled?
        return false unless ensure_service!

        service_client&.upsert(payload)&.fetch(:ok, false) || false
      end

      # Registers a session that has been admitted.
      # @param payload [Hash] The session data to register.
      # @return [Boolean] true if the session was registered successfully, false otherwise.
      # @example Registering an admitted session
      #   Lich::InternalAPI::ActiveSessions.register_session_admitted({ user_id: 1 })
      def self.register_session_admitted(payload)
        return false unless ensure_service_internal!(allow_bootstrap: true)

        service_client&.upsert(payload)&.fetch(:ok, false) || false
      end
      private_class_method :register_session_admitted

      # Unregisters a session by its process ID.
      # @param pid [Integer] The process ID of the session to unregister.
      # @return [Boolean] true if the session was unregistered successfully, false otherwise.
      # @example Unregistering a session
      #   Lich::InternalAPI::ActiveSessions.unregister_session(pid: 1234)
      def self.unregister_session(pid:)
        return false unless enabled?
        return false unless ensure_service!

        service_client&.remove(pid)&.fetch(:ok, false) || false
      end

      # Unregisters an admitted session by its process ID.
      # @param pid [Integer] The process ID of the session to unregister.
      # @return [Boolean] true if the session was unregistered successfully, false otherwise.
      # @example Unregistering an admitted session
      #   Lich::InternalAPI::ActiveSessions.unregister_session_admitted(pid: 1234)
      def self.unregister_session_admitted(pid:)
        return false unless ensure_service_internal!(allow_bootstrap: false)

        service_client&.remove(pid)&.fetch(:ok, false) || false
      end
      private_class_method :unregister_session_admitted

      # Retrieves a snapshot of the current sessions.
      # @return [Hash] A snapshot of the active sessions.
      # @example Getting a snapshot of active sessions
      #   Lich::InternalAPI::ActiveSessions.snapshot
      def self.snapshot
        return fallback_snapshot unless enabled?
        return fallback_snapshot unless ensure_service!

        response = service_client&.snapshot || fallback_snapshot(error: 'active sessions service unavailable')
        return fallback_snapshot(error: response[:error]) unless response[:ok]

        response[:payload]
      rescue StandardError => e
        fallback_snapshot(error: e.message)
      end

      # Queries the current snapshot of sessions.
      # @return [Hash] A snapshot of the active sessions.
      # @example Querying the snapshot of active sessions
      #   Lich::InternalAPI::ActiveSessions.query_snapshot
      def self.query_snapshot
        response = service_client&.snapshot
        return fallback_snapshot(error: 'active sessions service unavailable') unless response
        return fallback_snapshot(error: response[:error]) unless response[:ok]

        response[:payload]
      rescue StandardError => e
        fallback_snapshot(error: e.message)
      end

      # Retrieves information about the active sessions service.
      # @return [Hash] Information about the service status.
      # @example Getting service information
      #   Lich::InternalAPI::ActiveSessions.service_info
      def self.service_info
        discovery = load_discovery
        {
          source: 'ActiveSessionsAPI',
          owner_pid: discovery[:owner_pid],
          updated_at: discovery[:updated_at],
          service_available: service_available?
        }.compact
      end

      # Stops the active sessions service.
      # @return [void]
      # @example Stopping the active sessions service
      #   Lich::InternalAPI::ActiveSessions.stop_service!
      def self.stop_service!
        @mutex.synchronize do
          @server&.stop
          @server = nil
          @registry = nil
        end
        @service_client_mutex.synchronize do
          @service_client = nil
          @service_client_token = nil
        end
        delete_discovery_if_owned
      end

      # Retrieves the service client for the active sessions.
      # @return [Client, nil] The service client or nil if not available.
      # @example Getting the service client
      #   client = Lich::InternalAPI::ActiveSessions.service_client
      def self.service_client
        discovery = load_discovery
        return nil unless discovery[:auth_token]

        @service_client_mutex.synchronize do
          if @service_client.nil? || @service_client_token != discovery[:auth_token]
            @service_client = Client.new(host: DEFAULT_HOST, port: DEFAULT_PORT, auth_token: discovery[:auth_token])
            @service_client_token = discovery[:auth_token]
          end
          @service_client
        end
      end
      private_class_method :service_client

      # Provides a fallback snapshot in case of errors.
      # @param error [String, nil] An optional error message.
      # @return [Hash] A fallback snapshot structure.
      # @example Getting a fallback snapshot
      #   Lich::InternalAPI::ActiveSessions.fallback_snapshot(error: 'Service unavailable')
      def self.fallback_snapshot(error: nil)
        {
          source: 'ActiveSessionsAPI',
          total: 0,
          connected: 0,
          detachable: 0,
          sessions: [],
          error: error
        }.compact
      end
      private_class_method :fallback_snapshot

      # Checks if the active sessions service is available.
      # @return [Boolean] true if the service is available, false otherwise.
      # @example Checking if the service is available
      #   Lich::InternalAPI::ActiveSessions.service_available?
      def self.service_available?
        service_client&.ping || false
      end
      private_class_method :service_available?

      # Retrieves the path for the discovery file.
      # @return [String] The path to the discovery file.
      # @example Getting the discovery path
      #   path = Lich::InternalAPI::ActiveSessions.discovery_path
      def self.discovery_path
        base_dir = defined?(TEMP_DIR) ? TEMP_DIR : Dir.tmpdir
        File.join(base_dir, DISCOVERY_FILENAME)
      end
      private_class_method :discovery_path

      # Loads the discovery information from the file.
      # @return [Hash] The discovery data or an empty hash if not found.
      # @example Loading discovery data
      #   discovery = Lich::InternalAPI::ActiveSessions.load_discovery
      def self.load_discovery
        return {} unless File.exist?(discovery_path)

        JSON.parse(File.read(discovery_path), symbolize_names: true)
      rescue StandardError
        {}
      end
      private_class_method :load_discovery

      # Writes the discovery information to the file.
      # @param owner_pid [Integer] The process ID of the owner.
      # @param auth_token [String] The authentication token.
      # @return [void]
      # @example Writing discovery data
      #   Lich::InternalAPI::ActiveSessions.write_discovery(owner_pid: Process.pid, auth_token: 'token')
      def self.write_discovery(owner_pid:, auth_token:)
        payload = {
          owner_pid: owner_pid,
          auth_token: auth_token,
          updated_at: Time.now.to_i
        }
        temp_path = "#{discovery_path}.#{Process.pid}.tmp"
        File.open(temp_path, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
          file.write(JSON.dump(payload))
        end
        File.rename(temp_path, discovery_path)
      ensure
        File.delete(temp_path) if defined?(temp_path) && File.exist?(temp_path)
      end
      private_class_method :write_discovery

      # Deletes the discovery file if owned by this process.
      # @return [void]
      # @example Deleting discovery if owned
      #   Lich::InternalAPI::ActiveSessions.delete_discovery_if_owned
      def self.delete_discovery_if_owned
        discovery = load_discovery
        return unless discovery[:owner_pid].to_i == Process.pid
        return unless File.exist?(discovery_path)

        File.delete(discovery_path)
      rescue StandardError
        nil
      end
      private_class_method :delete_discovery_if_owned

      # Cleans up the discovery file if this is the last session.
      # @return [void]
      # @example Cleaning up discovery if last session
      #   Lich::InternalAPI::ActiveSessions.cleanup_discovery_if_last_session!
      def self.cleanup_discovery_if_last_session!
        discovery = load_discovery
        return unless discovery[:owner_pid].to_i == Process.pid

        current_snapshot = query_snapshot
        return if current_snapshot[:error]
        return unless current_snapshot[:source] == 'ActiveSessionsAPI'
        return unless current_snapshot[:total].to_i.zero?

        stop_service!
      rescue StandardError
        nil
      end
    end
  end
end
