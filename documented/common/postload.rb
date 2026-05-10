# frozen_string_literal: true

require_relative 'watchable'

module Lich
  # Provides common functionality for the Lich project.
  #
  # This module includes methods for managing post-load callbacks and game state.
  module Common
    module PostLoad
      extend Lich::Common::Watchable

      @@complete = false
      @@game_loaded = false
      @callbacks = {}
      @mutex = Mutex.new

      # Registers a callback for post-load processing.
      #
      # @param name [String] the name of the callback
      # @param block [Proc] the callback to be executed
      # @return [void]
      # @raise [ArgumentError] if no block is given
      def self.register(name, &block)
        raise ArgumentError, "PostLoad.register requires a block" unless block_given?

        @mutex.synchronize do
          @callbacks[name.to_s] = block
        end
      end

      # Marks the game as loaded.
      #
      # @return [void]
      def self.game_loaded!
        @@game_loaded = true
      end

      # Checks if the game has been loaded.
      #
      # @return [Boolean] true if the game is loaded, false otherwise
      def self.game_loaded?
        @@game_loaded
      end

      # Checks if all post-load callbacks have been completed.
      #
      # @return [Boolean] true if all callbacks are complete, false otherwise
      def self.complete?
        @@complete
      end

      # Starts a thread to monitor the game loading process and execute callbacks.
      #
      # @return [void]
      def self.watch!
        @thread ||= Thread.new do
          begin
            # Phase 1: Wait for base readiness (same as other watchers)
            sleep 0.1 until GameBase::Game.autostarted? &&
                            XMLData.name && !XMLData.name.empty?

            # Phase 2: Wait for game-specific init to signal completion
            sleep 0.1 until @@game_loaded

            # Phase 3: Run registered callbacks
            run_callbacks
          rescue StandardError => e
            respond "--- Lich: error in PostLoad thread: #{e.message}"
            respond e.backtrace.first(5).join("\n") if e.backtrace
          end
        end
      end

      # Executes all registered post-load callbacks.
      #
      # @return [void]
      # @api private
      def self.run_callbacks
        snapshot = @mutex.synchronize { @callbacks.dup }
        snapshot.each do |name, callback|
          begin
            callback.call
          rescue StandardError => e
            respond "--- Lich: error in PostLoad callback '#{name}': #{e.message}"
            respond e.backtrace.first(5).join("\n") if e.backtrace
          end
        end
        @@complete = true
      end

      private_class_method :run_callbacks
    end
  end
end
