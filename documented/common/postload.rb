# frozen_string_literal: true

require_relative 'watchable'

module Lich
  # Provides common functionality for the Lich project.
  # @example Including the module
  #   include Lich::Common
  module Common
    # Handles post-load operations for the game.
    # This module allows for registering callbacks that are executed after the game has loaded.
    # @example Registering a callback
    #   Lich::Common::PostLoad.register("my_callback") { puts "Game loaded!" }
    module PostLoad
      extend Lich::Common::Watchable

      @@complete = false
      @@game_loaded = false
      @callbacks = {}
      @mutex = Mutex.new

      # Registers a callback to be executed after the game has loaded.
      # @param name [String] The name of the callback.
      # @param block [Proc] The callback to be executed.
      # @raise [ArgumentError] If no block is given.
      # @example Registering a callback
      #   Lich::Common::PostLoad.register("my_callback") { puts "Game loaded!" }
      def self.register(name, &block)
        raise ArgumentError, "PostLoad.register requires a block" unless block_given?

        @mutex.synchronize do
          @callbacks[name.to_s] = block
        end
      end

      # Marks the game as loaded.
      # This method should be called when the game has finished loading.
      # @example Marking the game as loaded
      #   Lich::Common::PostLoad.game_loaded!
      def self.game_loaded!
        @@game_loaded = true
      end

      # Checks if the game has been loaded.
      # @return [Boolean] Returns true if the game is loaded, false otherwise.
      # @example Checking if the game is loaded
      #   if Lich::Common::PostLoad.game_loaded?
      #     puts "Game is loaded!"
      #   end
      def self.game_loaded?
        @@game_loaded
      end

      # Checks if all post-load operations are complete.
      # @return [Boolean] Returns true if all operations are complete, false otherwise.
      # @example Checking if operations are complete
      #   if Lich::Common::PostLoad.complete?
      #     puts "All operations complete!"
      #   end
      def self.complete?
        @@complete
      end

      # Starts a thread that watches for game readiness and executes callbacks.
      # This method will block until the game is ready and then run all registered callbacks.
      # @example Starting the watch thread
      #   Lich::Common::PostLoad.watch!
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
      # This method is called when the game is loaded and all conditions are met.
      # @example Running callbacks
      #   Lich::Common::PostLoad.run_callbacks
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
