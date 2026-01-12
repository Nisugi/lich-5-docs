# frozen_string_literal: true

#
# Combat Tracker - Main interface for combat event processing
# Integrates with Lich's game processing to track damage, wounds, and status effects
#

require_relative 'parser'
require_relative 'processor'
require_relative 'async_processor'
require_relative '../../common/db_store'

module Lich
  module Gemstone
    module Combat
      # Combat tracking system
      #
      # Main interface for the combat tracking system. Integrates with Lich's
      # Combat Tracker - Main interface for combat event processing
      # Integrates with Lich's game processing to track damage, wounds, and status effects
      # @example Using the Tracker module
      #   Lich::Gemstone::Combat::Tracker.enable!
      module Tracker
        @enabled = false
        @settings = {}
        @async_processor = nil
        @buffer = []
        @chunks_processed = 0
        @initialized = false

        # Default settings for combat tracking
        # Default settings for combat tracking
        DEFAULT_SETTINGS = {
          enabled: false,           # Disabled by default, user must enable
          track_damage: true,
          track_wounds: true,
          track_statuses: true,
          track_ucs: true,          # Track UCS (position, tierup, smite)
          max_threads: 2,           # Keep threading for performance
          debug: false,
          buffer_size: 200,         # Increase for large combat chunks
          fallback_max_hp: 350,     # Default max HP when template unavailable
          cleanup_interval: 100,    # Cleanup creature registry every N chunks
          cleanup_max_age: 600      # Remove creatures older than N seconds (10 minutes)
        }.freeze

        class << self
          attr_reader :settings, :buffer

          # Checks if combat tracking is enabled
          # @return [Boolean] true if combat tracking is enabled, false otherwise
          # @example
          #   if Lich::Gemstone::Combat::Tracker.enabled?
          #     puts "Tracking is enabled"
          #   end
          def enabled?
            initialize! unless @initialized
            @enabled && @settings[:enabled]
          end

          # Enables combat tracking
          # @return [void]
          # @example
          #   Lich::Gemstone::Combat::Tracker.enable!
          def enable!
            return if @enabled

            initialize! unless @initialized
            @enabled = true
            @settings[:enabled] = true # Force enabled in settings
            save_settings # Persist enabled state
            initialize_processor
            add_downstream_hook

            respond "[Combat] Combat tracking enabled" if debug?
          end

          # Disables combat tracking
          # @return [void]
          # @example
          #   Lich::Gemstone::Combat::Tracker.disable!
          def disable!
            return unless @enabled

            initialize! unless @initialized
            @enabled = false
            @settings[:enabled] = false
            save_settings # Persist disabled state
            remove_downstream_hook
            shutdown_processor

            respond "[Combat] Combat tracking disabled" if debug?
          end

          # Checks if debug mode is enabled
          # @return [Boolean] true if debug mode is enabled, false otherwise
          # @example
          #   if Lich::Gemstone::Combat::Tracker.debug?
          #     puts "Debugging is enabled"
          #   end
          def debug?
            @settings[:debug] || $combat_debug
          end

          # Enables debug mode for combat tracking
          # @return [void]
          # @example
          #   Lich::Gemstone::Combat::Tracker.enable_debug!
          def enable_debug!
            configure(debug: true, enabled: true)
            respond "[Combat] Debug mode enabled"
          end

          # Disables debug mode for combat tracking
          # @return [void]
          # @example
          #   Lich::Gemstone::Combat::Tracker.disable_debug!
          def disable_debug!
            configure(debug: false)
            respond "[Combat] Debug mode disabled"
          end

          # Sets the fallback maximum HP value
          # @param hp_value [Integer] The fallback maximum HP value
          # @return [void]
          # @example
          #   Lich::Gemstone::Combat::Tracker.set_fallback_hp(400)
          def set_fallback_hp(hp_value)
            configure(fallback_max_hp: hp_value.to_i)
            respond "[Combat] Fallback max HP set to #{hp_value}"
          end

          # Retrieves the fallback maximum HP value
          # @return [Integer] The fallback maximum HP value
          # @example
          #   hp = Lich::Gemstone::Combat::Tracker.fallback_hp
          def fallback_hp
            initialize! unless @initialized
            @settings[:fallback_max_hp]
          end

          # Processes a chunk of combat data
          # @param chunk [Array<String>] The chunk of combat data to process
          # @return [void]
          # @example
          #   Lich::Gemstone::Combat::Tracker.process(chunk)
          def process(chunk)
            return unless enabled?
            return if chunk.empty?

            # Quick filter - only process if combat-related content present
            return unless chunk.any? { |line| combat_relevant?(line) }

            if @settings[:max_threads] > 1
              @async_processor.process_async(chunk)
            else
              Processor.process(chunk)
            end

            # Periodic cleanup of old creature instances
            @chunks_processed += 1
            if @chunks_processed >= @settings[:cleanup_interval]
              cleanup_creatures
              @chunks_processed = 0
            end
          end

          # Checks if a line of text is relevant to combat
          # @param line [String] The line of text to check
          # @return [Boolean] true if the line is combat relevant, false otherwise
          # @example
          #   if Lich::Gemstone::Combat::Tracker.combat_relevant?(line)
          #     puts "This line is combat relevant"
          #   end
          def combat_relevant?(line)
            line.include?('swing') ||
              line.include?('thrust') ||
              line.include?('cast') ||
              line.include?('gesture') ||
              line.include?('points of damage') ||
              line.include?('**') || # Flares
              line.include?('<pushBold/>') || # Creatures
              line.include?('AS:') || # Attack rolls
              line.include?('positioning against') || # UCS position
              line.include?('vulnerable to a followup') || # UCS tierup
              line.include?('crimson mist') || # UCS smite
              line.match?(/\b(?:hit|miss|parr|block|dodge)\b/i)
          end

          # Configures the combat tracker with new settings
          # @param new_settings [Hash] A hash of settings to update
          # @return [void]
          # @example
          #   Lich::Gemstone::Combat::Tracker.configure(enabled: true)
          def configure(new_settings = {})
            initialize! unless @initialized
            @settings.merge!(new_settings)

            # Save to Lich settings system for persistence
            save_settings

            # Reinitialize processor if thread count changed
            if new_settings.key?(:max_threads)
              shutdown_processor
              initialize_processor
            end

            respond "[Combat] Settings updated: #{@settings}" if debug?
          end

          # Retrieves the current stats of the combat tracker
          # @return [Hash] A hash containing the current stats
          # @example
          #   stats = Lich::Gemstone::Combat::Tracker.stats
          def stats
            return { enabled: false } unless enabled?

            base_stats = {
              enabled: true,
              buffer_size: @buffer.size,
              settings: @settings
            }

            if @async_processor
              base_stats.merge(@async_processor.stats)
            else
              base_stats.merge(active: 0, total: 0)
            end
          end

          private

          def cleanup_creatures
            return unless defined?(Creature)

            max_age = @settings[:cleanup_max_age]
            removed = Creature.cleanup_old(max_age)

            if removed && removed > 0
              respond "[Combat] Cleaned up #{removed} old creature instances (age > #{max_age}s)" if debug?
            end
          rescue => e
            respond "[Combat] Error during creature cleanup: #{e.message}" if debug?
          end

          def load_settings
            # Load from DB_Store with per-character scope
            scope = "#{XMLData.game}:#{XMLData.name}"
            stored_settings = Lich::Common::DB_Store.read(scope, 'lich_combat_tracker')
            @settings = DEFAULT_SETTINGS.merge(stored_settings)
          end

          def save_settings
            # Save current settings to DB_Store with per-character scope
            scope = "#{XMLData.game}:#{XMLData.name}"
            Lich::Common::DB_Store.save(scope, 'lich_combat_tracker', @settings)
          end

          def initialize_processor
            return unless @settings[:max_threads] > 1
            @async_processor = AsyncProcessor.new(@settings[:max_threads])
          end

          def shutdown_processor
            return unless @async_processor
            @async_processor.shutdown
            @async_processor = nil
          end

          def add_downstream_hook
            @hook_id = 'Combat::Tracker::downstream'

            segment_buffer = proc do |server_string|
              @buffer << server_string

              # Process on prompt (natural break in game flow)
              if server_string.include?('<prompt time=')
                chunk = @buffer.slice!(0, @buffer.size)

                # Check if THIS chunk contains creatures (no persistent state)
                if chunk.any? { |line| line.match?(/<pushBold\/>.+?<a exist="[^"]+"[^>]*>.+?<\/a><popBold\/>/) }
                  process(chunk) unless chunk.empty?
                  respond "[Combat] Processed chunk with creatures (#{chunk.size} lines)" if debug?
                else
                  respond "[Combat] Discarded non-combat chunk (#{chunk.size} lines)" if debug?
                end
              end

              # Prevent buffer overflow
              if @buffer.size > @settings[:buffer_size]
                @buffer.shift(@buffer.size - @settings[:buffer_size])
              end

              server_string
            end

            DownstreamHook.add(@hook_id, segment_buffer)
          end

          def remove_downstream_hook
            DownstreamHook.remove(@hook_id) if @hook_id
            @hook_id = nil
          end

          def initialize!
            return if @initialized

            # Wait until XMLData is ready (avoid wrong scope)
            sleep 0.1 until !XMLData.game.nil? && !XMLData.game.empty? && !XMLData.name.nil? && !XMLData.name.empty?

            @initialized = true
            load_settings

            # Auto-enable if settings indicate it was previously enabled
            if @settings[:enabled]
              @enabled = true
              initialize_processor
              add_downstream_hook
              respond "[Combat] Auto-enabled combat tracking from saved settings" if debug?
            end
          end
        end

        # Trigger initialization check in a background thread
        Thread.new { initialize! }
      end
    end
  end
end
