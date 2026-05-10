# frozen_string_literal: true

require 'time'

module Lich
  # Provides common functionality for session lifecycle management.
  #
  # @see Lich::Common
  module Common
    module SessionLifecycle
      REGISTRATION_DELAY_SECONDS = 5

      @heartbeat_thread = nil
      @running = false
      @started = false
      @mutex = Mutex.new

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
      # @param detachable_client_port [Integer, nil] optional port for detachable clients
      # @return [String] the resolved role
      def self.resolve_role(argv:, detachable_client_port:)
        return 'detachable' unless detachable_client_port.nil?
        return 'headless' if argv.include?('--without-frontend')

        'session'
      end

      # Starts the session lifecycle with the given parameters.
      #
      # @param session_name [String] the name of the session
      # @param role [String] the role of the session
      # @param heartbeat_interval [Integer] interval for heartbeat in seconds
      # @param registration_delay [Integer] delay before registration in seconds
      # @return [Boolean] true if the session started successfully, false otherwise
      def self.start(session_name:, role:, heartbeat_interval: SessionsSettings::HEARTBEAT_INTERVAL_SECONDS, registration_delay: REGISTRATION_DELAY_SECONDS)
        return false unless SessionsSettings.enabled?

        @mutex.synchronize do
          return false if @started

          frontend = resolve_frontend
          started_epoch = Time.now.to_i
          started_iso = Time.at(started_epoch).utc.iso8601
          scheduled_register_epoch = started_epoch + registration_delay.to_i
          scheduled_register_iso = Time.at(scheduled_register_epoch).utc.iso8601
          registration_complete = false

          begin
            @running = true
            @started = true
            Lich.log(
              "info: SessionLifecycle start scheduled " \
              "pid=#{Process.pid} session=#{session_name.inspect} role=#{role.inspect} " \
              "started_epoch=#{started_epoch} started_iso=#{started_iso} " \
              "register_at_epoch=#{scheduled_register_epoch} register_at_iso=#{scheduled_register_iso} " \
              "heartbeat_interval=#{heartbeat_interval}s"
            ) if Lich.respond_to?(:log)

            @heartbeat_thread = Thread.new do
              sleep registration_delay
              Thread.exit unless @running

              if game_context_ready?
                registration_complete = attempt_register(
                  session_name: session_name,
                  role: role,
                  frontend: frontend,
                  started_epoch: started_epoch,
                  started_iso: started_iso,
                  registration_delay: registration_delay
                )
              else
                Lich.log(
                  "info: SessionLifecycle deferred register postponed " \
                  "pid=#{Process.pid} session=#{session_name.inspect} role=#{role.inspect} " \
                  "reason=xmldata_game_unavailable attempt_epoch=#{Time.now.to_i}"
                ) if Lich.respond_to?(:log)
              end

              loop do
                sleep heartbeat_interval
                break unless @running

                game_code = resolve_game_code
                if !registration_complete && !game_code.nil?
                  registration_complete = attempt_register(
                    session_name: session_name,
                    role: role,
                    frontend: frontend,
                    started_epoch: started_epoch,
                    started_iso: started_iso,
                    registration_delay: registration_delay
                  )
                end

                Lich.log(
                  "debug: SessionLifecycle heartbeat tick " \
                  "pid=#{Process.pid} session=#{session_name.inspect} role=#{role.inspect} " \
                  "tick_epoch=#{Time.now.to_i}"
                ) if Lich.respond_to?(:log)
                SessionsSettings.heartbeat(
                  pid: Process.pid,
                  state: 'running',
                  session_name: session_name,
                  role: role,
                  frontend: frontend,
                  game_code: game_code
                )
              end
            rescue StandardError => e
              Lich.log("warning: SessionLifecycle heartbeat failed: #{e.class}: #{e.message}") if Lich.respond_to?(:log)
            end
          rescue StandardError
            @running = false
            @started = false
            @heartbeat_thread = nil
            raise
          end
        end
        true
      rescue StandardError => e
        Lich.log("warning: SessionLifecycle start failed: #{e.class}: #{e.message}") if Lich.respond_to?(:log)
        false
      end

      # Stops the session lifecycle, unregistering the session.
      #
      # @return [Boolean] true if the session stopped successfully, false otherwise
      def self.stop
        return false unless SessionsSettings.enabled?

        heartbeat_thread = nil
        @mutex.synchronize do
          return false unless @started

          @running = false
          heartbeat_thread = @heartbeat_thread
          @heartbeat_thread = nil
        end

        # Cooperative shutdown first: allow the heartbeat loop to observe
        # @running=false and exit naturally before using hard-kill fallback.
        heartbeat_thread&.join(0.5)
        heartbeat_thread&.kill if heartbeat_thread&.alive?

        @mutex.synchronize do
          @heartbeat_thread = nil
          SessionsSettings.unregister_session(pid: Process.pid)
          @started = false
        end
        true
      rescue StandardError => e
        Lich.log("warning: SessionLifecycle stop failed: #{e.class}: #{e.message}") if Lich.respond_to?(:log)
        false
      end

      # Resolves the frontend context for the session.
      #
      # @return [String, nil] the frontend identifier or nil if not set
      def self.resolve_frontend
        return $frontend if defined?($frontend) && !$frontend.nil? && !$frontend.to_s.empty?

        nil
      end

      # Resolves the game code from the XML data.
      #
      # @return [String, nil] the game code or nil if not available
      def self.resolve_game_code
        return XMLData.game if defined?(XMLData) && XMLData.respond_to?(:game) && !XMLData.game.to_s.empty?

        nil
      end

      # Checks if the game context is ready for registration.
      #
      # @return [Boolean] true if the game context is ready, false otherwise
      def self.game_context_ready?
        !resolve_game_code.nil?
      end

      # Attempts to register the session with the given parameters.
      #
      # @param session_name [String] the name of the session
      # @param role [String] the role of the session
      # @param frontend [String] the frontend identifier
      # @param started_epoch [Integer] the epoch time when the session started
      # @param started_iso [String] the ISO 8601 formatted start time
      # @param registration_delay [Integer] delay before registration in seconds
      # @return [Boolean] true if registration was successful, false otherwise
      def self.attempt_register(session_name:, role:, frontend:, started_epoch:, started_iso:, registration_delay:)
        begin
          game_code = resolve_game_code
          return false if game_code.nil?

          Lich.log(
            "info: SessionLifecycle deferred register attempt " \
            "pid=#{Process.pid} session=#{session_name.inspect} role=#{role.inspect} " \
            "attempt_epoch=#{Time.now.to_i}"
          ) if Lich.respond_to?(:log)
          SessionsSettings.register_session(
            pid: Process.pid,
            session_name: session_name,
            role: role,
            state: 'running',
            frontend: frontend,
            game_code: game_code
          )
          Lich.log(
            "info: SessionLifecycle deferred register success " \
            "pid=#{Process.pid} session=#{session_name.inspect} role=#{role.inspect} " \
            "success_epoch=#{Time.now.to_i}"
          ) if Lich.respond_to?(:log)
          true
        rescue StandardError => e
          Lich.log(
            "warning: SessionLifecycle deferred register failed: #{e.class}: #{e.message} " \
            "pid=#{Process.pid} session=#{session_name.inspect} role=#{role.inspect} " \
            "started_epoch=#{started_epoch} started_iso=#{started_iso} delay=#{registration_delay}s"
          ) if Lich.respond_to?(:log)
          false
        end
      end
    end
  end
end
