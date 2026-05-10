# frozen_string_literal: true

require_relative 'watchable'

module Lich
  # Provides common functionality for the Lich project.
  #
  # @see Lich::Common::Watchable for watchable behavior.
  module Common
    module PostLoad
      extend Lich::Common::Watchable

      @@complete = false
      @@game_loaded = false
      @callbacks = {}
      @mutex = Mutex.new

      # Registers a callback with the given name.
      #
      # @param name [String] the name of the callback
      # @yield the callback to be executed when conditions are met
      # @raise [ArgumentError] if no block is given
      def self.register(name, &block)
        raise ArgumentError, "PostLoad.register requires a block" unless block_given?

        @mutex.synchronize do
          @callbacks[name.to_s] = block
        end
      end

      # Marks the game as loaded.
      # @return [void]
      def self.game_loaded!
        @@game_loaded = true
      end

      # Checks if the game has been loaded.
      # @return [Boolean] true if the game is loaded, false otherwise
      def self.game_loaded?
        @@game_loaded
      end

      # Checks if the post-load process is complete.
      # @return [Boolean] true if complete, false otherwise
      def self.complete?
        @@complete
      end

      # Starts watching for game readiness and executes callbacks when ready.
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

      # Executes all registered callbacks.
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
