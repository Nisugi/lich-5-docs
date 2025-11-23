# frozen_string_literal: true

#
# Combat Parser - Core parsing methods for combat events
# Performance-optimized with lazy loading and selective pattern matching
#

require_relative 'defs/attacks'
require_relative 'defs/damage'
require_relative 'defs/statuses'
require_relative 'defs/ucs'

module Lich
  module Gemstone
    module Combat
      # Combat event parser
      #
      # Parses game lines to extract combat events including attacks, damage,
      # status effects, and UCS (Unarmed Combat System) data. Uses lazy-loaded
      # pattern matching for performance.
      #
      # @example Parse an attack
      #   attack = Parser.parse_attack(line)
      #   # => { name: :swing, target: { id: 1234, noun: 'troll', name: 'troll' }, damaging: true }
      #
      # @example Parse damage
      #   damage = Parser.parse_damage(line)  # => 50
      #
      module Parser
        # Target link pattern - extract creatures/players from XML
        TARGET_LINK_PATTERN = /<a exist="(?<id>[^"]+)" noun="(?<noun>[^"]+)">(?<name>[^<]+)<\/a>/i.freeze

        # Bold tag pattern - creatures are wrapped in bold tags
        # Non-greedy match to avoid spanning multiple creatures
        BOLD_WRAPPER_PATTERN = /<pushBold\/>([^<]+<a exist="[^"]+"[^>]+>[^<]+<\/a>)<popBold\/>/i.freeze

        class << self
          # Parse attack initiation from a game line
          #
          # Identifies the type of attack and extracts target information.
          #
          # @param line [String] Game line to parse
          # @return [Hash, nil] Attack data with :name, :target, :damaging or nil if no attack
          # @option return [Symbol] :name Attack type (:swing, :cast, :thrust, etc.)
          # @option return [Hash] :target Target info with :id, :noun, :name
          # @option return [Boolean] :damaging Whether attack deals damage
          def parse_attack(line)
            return nil unless attack_detector.match?(line)

            attack_lookup.each do |pattern, name|
              if (match = pattern.match(line))
                target_info = extract_target_from_match(match) || extract_target_from_line(line)
                return {
                  name: name,
                  target: target_info || {},
                  damaging: true
                }
              end
            end
            nil
          end

          # Parse damage amount from a game line
          #
          # @param line [String] Game line to parse
          # @return [Integer, nil] Damage points or nil if no damage found
          def parse_damage(line)
            result = Definitions::Damage.parse(line)
            result ? result[:damage] : nil
          end

          # Parse status effects from a game line
          #
          # Only active if track_statuses setting is enabled.
          #
          # @param line [String] Game line to parse
          # @return [Hash, nil] Status data with :status, :target, :action or nil
          # @option return [Symbol] :status Status effect type (:stunned, :prone, etc.)
          # @option return [String] :target Target creature name
          # @option return [Symbol] :action :add or :remove
          def parse_status(line)
            return nil unless Tracker.settings[:track_statuses]

            # Return the full result including action field
            Definitions::Statuses.parse(line)
          end
          
          # Parse UCS (Unarmed Combat System) events
          #
          # Detects position changes, tierup vulnerabilities, and smite effects.
          # Only active if track_ucs setting is enabled.
          #
          # @param line [String] Game line to parse
          # @return [Hash, nil] UCS event data or nil
          # @option return [Symbol] :type Event type (:position, :tierup, :smite_on, :smite_off)
          # @option return [Object] :value Event-specific value
          # @option return [Integer] :target_id Target creature ID if available
          def parse_ucs(line)
            return nil unless Tracker.settings[:track_ucs]

            Definitions::UCS.parse(line)
          end

          # Extract creature target from game line
          #
          # Creatures must be wrapped in bold tags (<pushBold/> ... <popBold/>)
          # and contain a valid creature link with ID.
          #
          # @param line [String] Game line to parse
          # @return [Hash, nil] Target data with :id, :noun, :name or nil
          def extract_creature_target(line)
            # Check if line contains a bolded link
            bold_match = BOLD_WRAPPER_PATTERN.match(line)
            return nil unless bold_match

            # Extract the link from within the bold tags
            link_text = bold_match[1]
            link_match = TARGET_LINK_PATTERN.match(link_text)
            return nil unless link_match

            id = link_match[:id].to_i
            return nil if id <= 0 # Skip invalid IDs

            {
              id: id,
              noun: link_match[:noun],
              name: link_match[:name]
            }
          end

          # Try to extract target from regex match first, then from line
          def extract_target_from_match(match)
            return nil unless match.names.include?('target')
            target_text = match[:target]
            return nil if target_text.nil? || target_text.strip.empty?

            # Look for creature in target text
            if (target_match = TARGET_LINK_PATTERN.match(target_text))
              id = target_match[:id].to_i
              return nil if id < 0

              return {
                id: id,
                noun: target_match[:noun],
                name: target_match[:name]
              }
            end

            nil
          end

          def extract_target_from_line(line)
            # ONLY accept bolded creatures as targets
            # Non-bolded links are equipment, objects, or other non-combatants
            extract_creature_target(line)
          end

          private

          # Lazy-loaded pattern lookups for performance
          # @api private
          def attack_lookup
            @attack_lookup ||= Definitions::Attacks::ATTACK_LOOKUP
          end

          def attack_detector
            @attack_detector ||= Definitions::Attacks::ATTACK_DETECTOR
          end

          # Clear cached patterns when settings change
          def reset_cache!
            @attack_lookup = nil
            @attack_detector = nil
          end
        end
      end
    end
  end
end
