

module Lich
  module Gemstone
    module Combat
      module Definitions
        module Damage
          # Core damage patterns - most common
          # Core damage patterns - most common.
          #
          # This constant holds regular expressions that match the most common damage messages.
          #
          # @example
          #   "... and hit for 10 points of damage!" matches BASIC_DAMAGE[0]
          #   "... 15 points of damage!" matches BASIC_DAMAGE[1]
          #   "... hits for 20 points of damage!" matches BASIC_DAMAGE[2]
          BASIC_DAMAGE = [
            /\.\.\. and hit for (?<damage>\d+) points? of damage!/,
            /\.\.\. (?<damage>\d+) points? of damage!/,
            /\.\.\. hits for (?<damage>\d+) points? of damage!/
          ].freeze

          # Spell damage patterns
          # Spell damage patterns.
          #
          # This constant holds regular expressions that match damage messages caused by spells.
          #
          # @example
          #   "Consumed by the hallowed flames, target is ravaged for 30 points of damage!" matches SPELL_DAMAGE[0]
          #   "Wisps of black smoke swirl around target and it bursts into flame causing 25 points of damage!" matches SPELL_DAMAGE[1]
          SPELL_DAMAGE = [
            /Consumed by the hallowed flames, (?<target>.+?) is ravaged for (?<damage>\d+) points? of damage!/,
            /Wisps of black smoke swirl around (?<target>.+?) and it bursts into flame causing (?<damage>\d+) points? of damage!/
          ].freeze

          # Environmental/cyclone damage patterns
          # Environmental/cyclone damage patterns.
          #
          # This constant holds regular expressions that match damage messages caused by environmental effects.
          #
          # @example
          #   "The whirlwind quickly swirls around target, causing 40 points of damage!" matches ENVIRONMENTAL_DAMAGE[0]
          #   "The flickering flames quickly swirl around target, causing 35 points of damage!" matches ENVIRONMENTAL_DAMAGE[1]
          #   "The shifting stones quickly orbit target, causing 50 points of damage!" matches ENVIRONMENTAL_DAMAGE[2]
          ENVIRONMENTAL_DAMAGE = [
            /The whirlwind quickly swirls around (?<target>.+?), causing (?<damage>\d+) points? of damage!/,
            /The flickering flames quickly swirl around (?<target>.+?), causing (?<damage>\d+) points? of damage!/,
            /The shifting stones quickly orbit (?<target>.+?), causing (?<damage>\d+) points? of damage!/
          ].freeze

          # All damage patterns combined
          # All damage patterns combined.
          #
          # This constant combines all damage patterns into a single array for easier access.
          #
          # @see BASIC_DAMAGE
          # @see SPELL_DAMAGE
          # @see ENVIRONMENTAL_DAMAGE
          ALL_DAMAGE = (BASIC_DAMAGE + SPELL_DAMAGE + ENVIRONMENTAL_DAMAGE).freeze

          # Compiled regex for fast detection
          # Compiled regex for fast detection.
          #
          # This constant compiles all damage patterns into a single regular expression for efficient matching.
          #
          # @see ALL_DAMAGE
          DAMAGE_DETECTOR = Regexp.union(ALL_DAMAGE).freeze

          # Parses a line to extract damage information.
          #
          # This method takes a line of text and attempts to match it against known damage patterns.
          #
          # @param line [String] the line of text to parse for damage information
          # @return [Hash, nil] a hash containing damage and optionally target if matched, or nil if no match found
          # @example
          #   parse("... and hit for 10 points of damage!") #=> { damage: 10 }
          #   parse("Consumed by the hallowed flames, target is ravaged for 30 points of damage!") #=> { damage: 30, target: "target" }
          # @note This method is intended for internal use within the Lich module.
          # @api private
          def self.parse(line)
            ALL_DAMAGE.each do |pattern|
              if (match = pattern.match(line))
                result = { damage: match[:damage].to_i }
                result[:target] = match[:target] if match.names.include?('target') && match[:target]
                return result
              end
            end
            nil
          end
        end
      end
    end
  end
end
