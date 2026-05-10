
# The Lich module
# This module serves as the main namespace for the Lich application.
# @example Using the Lich module
#   Lich::InternalAPI::ActiveSessions.start
module Lich
  # The InternalAPI module
  # This module contains internal APIs for the Lich application.
  # @example Accessing InternalAPI
  #   Lich::InternalAPI::ActiveSessions.stop
  module InternalAPI
    module ActiveSessions
      module Lifecycle
        # The interval in seconds for the heartbeat.
        # This constant defines how often the heartbeat should occur.
        HEARTBEAT_INTERVAL_SECONDS = 5

        @heartbeat_thread = nil
        @running = false
        @started = false
        @listener_host = nil
        @listener_port = nil
        @listener_connected = false
        @session_name = nil
        @role = nil
        @started_at = nil
        @mutex = Mutex.new
        @registration_mutex = Mutex.new
        @lifecycle_generation = 0
        @feature_enabled = false

        # Resolves the session name based on provided arguments.
        # @param argv [Array<String>] The command line arguments.
        # @param account_character [String, nil] The account character name, if provided.
        # @return [String] The resolved session name.
        # @example Resolving a session name
        #   session_name = resolve_session_name(argv: ARGV)
        def self.resolve_session_name(argv:, account_character: nil)
          if (login_idx = argv.index('--login')) && argv[login_idx + 1]
            argv[login_idx + 1].capitalize
          elsif account_character && !account_character.to_s.empty?
            account_character
          elsif defined?(XMLData) && XMLData.respond_to?(:name) && !XMLData.name.to_s.empty?
            XMLData.name
          else
            "pid-#{Process.pid}"
          end
        end

        # Resolves the role based on provided arguments.
        # @param argv [Array<String>] The command line arguments.
        # @param detachable_client_port [Integer, nil] The port for a detachable client, if provided.
        # @return [String] The resolved role.
        # @example Resolving a role
        #   role = resolve_role(argv: ARGV, detachable_client_port: 3000)
        def self.resolve_role(argv:, detachable_client_port:)
          return 'headless' if argv.include?('--without-frontend')
          return 'detachable' unless detachable_client_port.nil?

          'session'
        end

        # Starts the lifecycle with the given session name and role.
        # @param session_name [String] The name of the session to start.
        # @param role [String] The role of the session.
        # @param heartbeat_interval [Integer] The interval for heartbeat in seconds (default is HEARTBEAT_INTERVAL_SECONDS).
        # @return [Boolean] Returns true if the lifecycle started successfully, false otherwise.
        # @raise [StandardError] Raises an error if the lifecycle fails to start.
        # @example Starting the lifecycle
        #   success = start(session_name: "MySession", role: "detachable")
        def self.start(session_name:, role:, heartbeat_interval: HEARTBEAT_INTERVAL_SECONDS)
          feature_enabled = ActiveSessions.enabled?
          return false unless feature_enabled

          # Bootstrap once during lifecycle startup so the admitted-only
          # heartbeat/update path has a running service to talk to.
          ActiveSessions.ensure_service!

          thread = nil
          @mutex.synchronize do
            return false if @started

            @session_name = session_name
            @role = role
            @started_at = Time.now.to_i
            @feature_enabled = feature_enabled
            @running = true
            @started = true
            @lifecycle_generation += 1
          end

          thread = Thread.new do
            loop do
              sleep heartbeat_interval
              break unless running?

              upsert_current_session
            end
          rescue StandardError => e
            Lich.log("warning: ActiveSessions heartbeat failed: #{e.class}: #{e.message}") if Lich.respond_to?(:log)
          end

          @mutex.synchronize { @heartbeat_thread = thread if @started }

          upsert_current_session
          true
        rescue StandardError => e
          @mutex.synchronize do
            @running = false
            @started = false
            @heartbeat_thread = nil
            @session_name = nil
            @role = nil
            @listener_host = nil
            @listener_port = nil
            @listener_connected = false
            @started_at = nil
            @feature_enabled = false
          end
          thread.kill if thread.respond_to?(:alive?) && thread.alive?
          Lich.log("warning: ActiveSessions lifecycle start failed: #{e.class}: #{e.message}") if Lich.respond_to?(:log)
          false
        end

        # Stops the lifecycle if it is currently running.
        # @return [Boolean] Returns true if the lifecycle stopped successfully, false otherwise.
        # @raise [StandardError] Raises an error if the lifecycle fails to stop.
        # @example Stopping the lifecycle
        #   success = stop
        def self.stop
          thread = nil
          lifecycle_active = false
          @mutex.synchronize do
            lifecycle_active = @started || !@heartbeat_thread.nil? || @running
            return false unless lifecycle_active

            @running = false
            @started = false
            @lifecycle_generation += 1
            thread = @heartbeat_thread
            @heartbeat_thread = nil
          end

          thread&.join(0.5)
          thread&.kill if thread&.alive?
          if feature_enabled?
            @registration_mutex.synchronize do
              ActiveSessions.send(:unregister_session_admitted, pid: Process.pid)
              ActiveSessions.cleanup_discovery_if_last_session!
            end
          end

          @mutex.synchronize do
            @session_name = nil
            @role = nil
            @listener_host = nil
            @listener_port = nil
            @listener_connected = false
            @started_at = nil
            @feature_enabled = false
          end
          true
        rescue StandardError => e
          Lich.log("warning: ActiveSessions lifecycle stop failed: #{e.class}: #{e.message}") if Lich.respond_to?(:log)
          false
        end

        # Updates the listener information for the current session.
        # @param host [String] The host of the listener.
        # @param port [Integer] The port of the listener.
        # @param connected [Boolean] Indicates if the listener is connected.
        # @example Updating the listener
        #   update_listener(host: "localhost", port: 8080, connected: true)
        def self.update_listener(host:, port:, connected:)
          return unless started?

          @mutex.synchronize do
            @listener_host = host
            @listener_port = port
            @listener_connected = connected
          end
          upsert_current_session
        end

        # Clears the listener information for the current session.
        # @example Clearing the listener
        #   clear_listener
        def self.clear_listener
          return unless started?

          @mutex.synchronize do
            @listener_host = nil
            @listener_port = nil
            @listener_connected = false
          end
          upsert_current_session
        end

        # Retrieves the current payload for the session.
        # @return [Hash] The current session payload.
        # @example Getting the current payload
        #   payload = current_payload
        def self.current_payload
          @mutex.synchronize { build_current_payload }
        end

        def self.upsert_current_session
          payload = nil
          generation = nil
          @mutex.synchronize do
            return unless @started

            payload = build_current_payload
            generation = @lifecycle_generation
          end

          @registration_mutex.synchronize do
            return unless registration_current?(generation)

            # ActiveSessions keeps the admitted-path helpers private so the
            # feature-gate bypass stays local to lifecycle-owned call sites.
            ActiveSessions.send(:register_session_admitted, payload)
          end
        end
        private_class_method :upsert_current_session

        def self.running?
          @mutex.synchronize { @running }
        end
        private_class_method :running?

        def self.started?
          @mutex.synchronize { @started }
        end
        private_class_method :started?

        def self.feature_enabled?
          @mutex.synchronize { @feature_enabled }
        end
        private_class_method :feature_enabled?

        def self.registration_current?(generation)
          @mutex.synchronize { @started && @lifecycle_generation == generation }
        end
        private_class_method :registration_current?

        def self.build_current_payload
          {
            pid: Process.pid,
            session_name: @session_name,
            role: @role,
            frontend: resolve_frontend,
            game_code: resolve_game_code,
            started_at: @started_at,
            connected: @listener_port.nil? ? true : @listener_connected,
            listener_host: @listener_host,
            listener_port: @listener_port,
            hidden: false
          }
        end
        private_class_method :build_current_payload

        def self.resolve_frontend
          return $frontend if defined?($frontend) && !$frontend.nil? && !$frontend.to_s.empty?

          nil
        end
        private_class_method :resolve_frontend

        def self.resolve_game_code
          return XMLData.game if defined?(XMLData) && XMLData.respond_to?(:game) && !XMLData.game.to_s.empty?

          nil
        end
        private_class_method :resolve_game_code
      end
    end
  end
end
