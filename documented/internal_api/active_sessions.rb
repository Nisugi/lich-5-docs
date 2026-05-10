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
    #
    # @see Lich::InternalAPI
    module ActiveSessions
      FEATURE_FLAG = :active_sessions_api

      DEFAULT_HOST = '127.0.0.1'

      DEFAULT_PORT = 42_857

      DISCOVERY_FILENAME = 'lich-active-sessions.json'

      @registry = nil
      @server = nil
      @service_client = nil
      @service_client_token = nil
      @mutex = Mutex.new
      @service_client_mutex = Mutex.new

      # Checks if the ActiveSessions feature is enabled.
      #
      # @return [Boolean] true if the feature is enabled, false otherwise.
      def self.enabled?
        return false unless defined?(Lich::Common::FeatureFlags)

        Lich::Common::FeatureFlags.enabled?(FEATURE_FLAG)
      rescue StandardError => e
        Lich.log("warning: ActiveSessions feature flag check failed: #{e.class}: #{e.message}") if Lich.respond_to?(:log)
        false
      end

      # Ensures that the ActiveSessions service is running.
      #
      # @return [Boolean] true if the service is available, false otherwise.
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
      #
      # @param payload [Hash] the session data to register.
      # @return [Boolean] true if the session was registered successfully, false otherwise.
      def self.register_session(payload)
        return false unless enabled?
        return false unless ensure_service!

        service_client&.upsert(payload)&.fetch(:ok, false) || false
      end

      def self.register_session_admitted(payload)
        return false unless ensure_service_internal!(allow_bootstrap: true)

        service_client&.upsert(payload)&.fetch(:ok, false) || false
      end
      private_class_method :register_session_admitted

      # Unregisters a session by its process ID.
      #
      # @param pid [Integer] the process ID of the session to unregister.
      # @return [Boolean] true if the session was unregistered successfully, false otherwise.
      def self.unregister_session(pid:)
        return false unless enabled?
        return false unless ensure_service!

        service_client&.remove(pid)&.fetch(:ok, false) || false
      end

      def self.unregister_session_admitted(pid:)
        return false unless ensure_service_internal!(allow_bootstrap: false)

        service_client&.remove(pid)&.fetch(:ok, false) || false
      end
      private_class_method :unregister_session_admitted

      # Retrieves a snapshot of the current active sessions.
      #
      # @return [Hash] a snapshot of active sessions or a fallback snapshot in case of failure.
      def self.snapshot
        return fallback_snapshot unless enabled?
        return fallback_snapshot unless ensure_service!

        response = service_client&.snapshot || fallback_snapshot(error: 'active sessions service unavailable')
        return fallback_snapshot(error: response[:error]) unless response[:ok]

        response[:payload]
      rescue StandardError => e
        fallback_snapshot(error: e.message)
      end

      def self.query_snapshot
        response = service_client&.snapshot
        return fallback_snapshot(error: 'active sessions service unavailable') unless response
        return fallback_snapshot(error: response[:error]) unless response[:ok]

        response[:payload]
      rescue StandardError => e
        fallback_snapshot(error: e.message)
      end

      # Provides information about the ActiveSessions service.
      #
      # @return [Hash] a hash containing service information such as owner PID and availability.
      def self.service_info
        discovery = load_discovery
        {
          source: 'ActiveSessionsAPI',
          owner_pid: discovery[:owner_pid],
          updated_at: discovery[:updated_at],
          service_available: service_available?
        }.compact
      end

      # Stops the ActiveSessions service and cleans up resources.
      #
      # @return [void]
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

      # Provides a fallback snapshot structure in case of service unavailability.
      #
      # @param error [String, nil] optional error message to include in the snapshot.
      # @return [Hash] a fallback snapshot structure.
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

      # Checks if the ActiveSessions service is available.
      #
      # @return [Boolean] true if the service is available, false otherwise.
      def self.service_available?
        service_client&.ping || false
      end
      private_class_method :service_available?

      # Returns the file path for the discovery file.
      #
      # @return [String] the path to the discovery file.
      def self.discovery_path
        base_dir = defined?(TEMP_DIR) ? TEMP_DIR : Dir.tmpdir
        File.join(base_dir, DISCOVERY_FILENAME)
      end
      private_class_method :discovery_path

      # Loads the discovery information from the discovery file.
      #
      # @return [Hash] the discovery data or an empty hash if not found.
      def self.load_discovery
        return {} unless File.exist?(discovery_path)

        JSON.parse(File.read(discovery_path), symbolize_names: true)
      rescue StandardError
        {}
      end
      private_class_method :load_discovery

      # Writes the discovery information to the discovery file.
      #
      # @param owner_pid [Integer] the process ID of the owner.
      # @param auth_token [String] the authentication token for the service.
      # @return [void]
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

      # Deletes the discovery file if this process owns it.
      #
      # @return [void]
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
      #
      # @return [void]
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
