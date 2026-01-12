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
    # Combat Parser - Core parsing methods for combat events
    # Performance-optimized with lazy loading and selective pattern matching
    # @example Usage
    #   result = Lich::Gemstone::Combat::Parser.parse_attack(line)
    module Combat
      module Parser
        # Target link pattern - extract creatures/players from XML
        # Target link pattern - extract creatures/players from XML
        TARGET_LINK_PATTERN = /<a exist="(?<id>[^"]+)" noun="(?<noun>[^"]+)">(?<name>[^<]+)<\/a>/i.freeze

        # Bold tag pattern - creatures are wrapped in bold tags
        # Non-greedy match to avoid spanning multiple creatures
        # Allow zero or more characters before <a> tag (e.g., "a creature" or just "creature")
        # Bold tag pattern - creatures are wrapped in bold tags
        # Non-greedy match to avoid spanning multiple creatures
        # Allow zero or more characters before <a> tag (e.g., "a creature" or just "creature")
        BOLD_WRAPPER_PATTERN = /<pushBold\/>([^<]*<a exist="[^"]+"[^>]+>[^<]+<\/a>)<popBold\/>/i.freeze

        class << self
          # Parses an attack line and extracts relevant information.
          #
          # @param line [String] The line containing the attack information.
          # @return [Hash, nil] A hash containing attack details or nil if no attack is detected.
          # @example
          #   attack_info = Lich::Gemstone::Combat::Parser.parse_attack("You attack the creature.")
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

          # Parses a damage line and extracts the damage value.
          #
          # @param line [String] The line containing the damage information.
          # @return [Integer, nil] The damage value or nil if not found.
          # @example
          #   damage = Lich::Gemstone::Combat::Parser.parse_damage("You deal 10 damage.")
          def parse_damage(line)
            result = Definitions::Damage.parse(line)
            result ? result[:damage] : nil
          end

          # Parses a status line and extracts the status information.
          #
          # @param line [String] The line containing the status information.
          # @return [Hash, nil] A hash containing status details or nil if not found.
          # @example
          #   status_info = Lich::Gemstone::Combat::Parser.parse_status("You are now stunned.")
          def parse_status(line)
            return nil unless Tracker.settings[:track_statuses]

            # Return the full result including action field
            Definitions::Statuses.parse(line)
          end

          # Parses a UCS line and extracts the UCS information.
          #
          # @param line [String] The line containing the UCS information.
          # @return [Hash, nil] A hash containing UCS details or nil if not found.
          # @example
          #   ucs_info = Lich::Gemstone::Combat::Parser.parse_ucs("You are now under a curse.")
          def parse_ucs(line)
            return nil unless Tracker.settings[:track_ucs]

            Definitions::UCS.parse(line)
          end

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

          def attack_lookup
            @attack_lookup ||= Definitions::Attacks::ATTACK_LOOKUP
          end

          def attack_detector
            @attack_detector ||= Definitions::Attacks::ATTACK_DETECTOR
          end

          def reset_cache!
            @attack_lookup = nil
            @attack_detector = nil
          end
        end
      end
    end
  end
end
