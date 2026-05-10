
module Lich
  module InternalAPI
    module ActiveSessions
      module Lifecycle
        # The interval in seconds for the heartbeat signal.
        #
        # @example
        #   HEARTBEAT_INTERVAL_SECONDS # => 5
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

        # Resolves the session name based on command line arguments or defaults.
        #
        # @param argv [Array<String>] command line arguments
        # @param account_character [String, nil] optional account character name
        # @return [String] the resolved session name
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

        # Determines the role of the session based on command line arguments.
        #
        # @param argv [Array<String>] command line arguments
        # @param detachable_client_port [Integer, nil] port for detachable client
        # @return [String] the resolved role
        def self.resolve_role(argv:, detachable_client_port:)
          return 'headless' if argv.include?('--without-frontend')
          return 'detachable' unless detachable_client_port.nil?

          'session'
        end

        # Starts the session lifecycle with the given parameters.
        #
        # @param session_name [String] the name of the session
        # @param role [String] the role of the session
        # @param heartbeat_interval [Integer] the interval for heartbeat signals (default: HEARTBEAT_INTERVAL_SECONDS)
        # @return [Boolean] true if the session started successfully, false otherwise
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

        # Stops the session lifecycle, cleaning up resources.
        #
        # @return [Boolean] true if the session stopped successfully, false otherwise
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

        # Updates the listener information for the session.
        #
        # @param host [String] the host of the listener
        # @param port [Integer] the port of the listener
        # @param connected [Boolean] whether the listener is connected
        # @return [void]
        def self.update_listener(host:, port:, connected:)
          return unless started?

          @mutex.synchronize do
            @listener_host = host
            @listener_port = port
            @listener_connected = connected
          end
          upsert_current_session
        end

        # Clears the listener information for the session.
        #
        # @return [void]
        def self.clear_listener
          return unless started?

          @mutex.synchronize do
            @listener_host = nil
            @listener_port = nil
            @listener_connected = false
          end
          upsert_current_session
        end

        # Retrieves the current session payload.
        #
        # @return [Hash] the current session payload
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

        # Checks if the session is currently running.
        #
        # @return [Boolean] true if the session is running, false otherwise
        # @api private
        def self.running?
          @mutex.synchronize { @running }
        end
        private_class_method :running?

        # Checks if the session has been started.
        #
        # @return [Boolean] true if the session has started, false otherwise
        # @api private
        def self.started?
          @mutex.synchronize { @started }
        end
        private_class_method :started?

        # Checks if the feature is enabled for the session.
        #
        # @return [Boolean] true if the feature is enabled, false otherwise
        # @api private
        def self.feature_enabled?
          @mutex.synchronize { @feature_enabled }
        end
        private_class_method :feature_enabled?

        # Checks if the registration is current based on the lifecycle generation.
        #
        # @param generation [Integer] the current lifecycle generation
        # @return [Boolean] true if the registration is current, false otherwise
        # @api private
        def self.registration_current?(generation)
          @mutex.synchronize { @started && @lifecycle_generation == generation }
        end
        private_class_method :registration_current?

        # Builds the current session payload with relevant information.
        #
        # @return [Hash] the constructed payload for the current session
        # @api private
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

        # Resolves the frontend information for the session.
        #
        # @return [String, nil] the frontend information if available, nil otherwise
        # @api private
        def self.resolve_frontend
          return $frontend if defined?($frontend) && !$frontend.nil? && !$frontend.to_s.empty?

          nil
        end
        private_class_method :resolve_frontend

        # Resolves the game code for the session.
        #
        # @return [String, nil] the game code if available, nil otherwise
        # @api private
        def self.resolve_game_code
          return XMLData.game if defined?(XMLData) && XMLData.respond_to?(:game) && !XMLData.game.to_s.empty?

          nil
        end
        private_class_method :resolve_game_code
      end
    end
  end
end
