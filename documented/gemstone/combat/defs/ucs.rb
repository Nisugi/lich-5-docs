

module Lich
  module Gemstone
    module Combat
      module Definitions
        module UCS
          # Pattern for position updates - use .+ not .*
          # Example: "You have good positioning against a kobold."
          # Pattern for position updates.
          #
          # Matches strings indicating the positioning against a target.
          #
          # @example
          #   "You have good positioning against a kobold."
          # @see TIERUP_PATTERN
          # @see SMITE_APPLIED_PATTERN
          POSITION_PATTERN = /^You have (decent|good|excellent) positioning against.+<a exist="([0-9]+)"/i.freeze

          # Pattern for tierup vulnerability
          # Example: "Strike leaves foe vulnerable to a followup jab attack!"
          # Pattern for tierup vulnerability.
          #
          # Matches strings indicating a foe is vulnerable to a followup attack.
          #
          # @example
          #   "Strike leaves foe vulnerable to a followup jab attack!"
          TIERUP_PATTERN = /Strike leaves foe vulnerable to a followup (jab|grapple|punch|kick) attack!/i.freeze

          # Pattern for smite applied (crimson mist)
          # Use .+ not .*
          # Pattern for smite applied (crimson mist).
          #
          # Matches strings indicating a target is surrounded by a crimson mist.
          #
          # @example
          #   "A crimson mist suddenly surrounds the target."
          SMITE_APPLIED_PATTERN = /^ *A crimson mist suddenly surrounds .+<a exist="([0-9]+)"/i.freeze

          # Pattern for smite held in corporeal plane
          # Pattern for smite held in corporeal plane.
          #
          # Matches strings indicating a target's crimson mist is held in the corporeal plane.
          #
          # @example
          #   "The crimson mist surrounding the target is held in the corporeal plane."
          SMITE_HELD_PATTERN = /The crimson mist surrounding .+<a exist="([0-9]+)".+held in the corporeal plane/i.freeze

          # Pattern for smite removed
          # Pattern for smite removed.
          #
          # Matches strings indicating a target's crimson mist returns to an ethereal state.
          #
          # @example
          #   "The crimson mist surrounding the target returns to an ethereal state."
          SMITE_REMOVED_PATTERN = /^ *The crimson mist surrounding .+<a exist="([0-9]+)".+returns to an ethereal state/i.freeze

          class << self
            # Parses a line of text to extract combat-related information.
            #
            # @param line [String] the line of text to parse.
            # @return [Hash, nil] a hash containing parsed information or nil if no match is found.
            # @example
            #   parse("You have good positioning against a kobold.")
            #   # => { type: :position, target_id: 123, value: "good" }
            # @api private
            def parse(line)
              # Position update
              if (match = POSITION_PATTERN.match(line))
                position = match[1]
                target_id = match[2].to_i
                return {
                  type: :position,
                  target_id: target_id,
                  value: position
                }
              end

              # Tierup vulnerability
              if (match = TIERUP_PATTERN.match(line))
                attack_type = match[1]
                return {
                  type: :tierup,
                  value: attack_type
                  # Note: target_id comes from most recent target in combat context
                }
              end

              # Smite applied or held
              if (match = SMITE_APPLIED_PATTERN.match(line))
                target_id = match[1].to_i
                return {
                  type: :smite_on,
                  target_id: target_id
                }
              end

              if (match = SMITE_HELD_PATTERN.match(line))
                target_id = match[1].to_i
                return {
                  type: :smite_on,
                  target_id: target_id
                }
              end

              # Smite removed
              if (match = SMITE_REMOVED_PATTERN.match(line))
                target_id = match[1].to_i
                return {
                  type: :smite_off,
                  target_id: target_id
                }
              end

              nil
            end
          end
        end
      end
    end
  end
end
