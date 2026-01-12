
module Lich
  module Gemstone
    # Represents the character's injury status in the Gemstone module.
    # @example Creating an instance of Injured
    #   injured_status = Lich::Gemstone::Injured
    class Injured < Gemstone::CharacterStatus
      class << self
        # A constant that groups body parts for injury checks.
        # Each key represents a group of body parts.
        BODY_PART_GROUPS = {
          eyes: %i[leftEye rightEye],
          arms: %i[leftArm rightArm],
          hands: %i[leftHand rightHand],
          legs: %i[leftLeg rightLeg],
          feet: %i[leftFoot rightFoot],
          head_and_nerves: %i[head nsys]
        }.freeze

        # Cache variables
        @injury_cache_key = nil
        @wounds_cache = nil
        @scars_cache = nil
        @cache_mutex = Mutex.new

        # Retrieves injury data, utilizing caching for efficiency.
        # @return [Array] An array containing wounds and scars data.
        # @note This method uses a mutex for thread safety.
        # @example
        #   wounds, scars = get_injury_data
        def get_injury_data
          current_key = XMLData.injuries

          # Fast path: return cached data if key hasn't changed
          if @injury_cache_key == current_key && @wounds_cache && @scars_cache
            return [@wounds_cache, @scars_cache]
          end

          # Slow path: fetch new data with mutex protection
          @cache_mutex.synchronize do
            # Double-check after acquiring lock (another thread may have updated)
            if @injury_cache_key == current_key && @wounds_cache && @scars_cache
              return [@wounds_cache, @scars_cache]
            end

            # Fetch fresh data
            wounds = Wounds.all_wounds
            scars = Scars.all_scars

            # Update cache
            @wounds_cache = wounds
            @scars_cache = scars
            @injury_cache_key = current_key

            [wounds, scars]
          end
        end

        # Calculates the effective injury from wounds and scars for a given body part.
        # @param body_part [Symbol] The body part to check (e.g., :leftArm).
        # @param wounds_hash [Hash] A hash containing wounds data.
        # @param scars_hash [Hash] A hash containing scars data.
        # @return [Integer] The effective injury value.
        # @example
        #   effective_injury = effective_injury_from_hashes(:leftArm, wounds_hash, scars_hash)
        def effective_injury_from_hashes(body_part, wounds_hash, scars_hash)
          scar = scars_hash[body_part.to_s] || 0
          wound = wounds_hash[body_part.to_s] || 0
          effective_scar = (scar == 1) ? 0 : scar

          [wound, effective_scar].max
        end

        # Checks if there are injuries at a specific rank for given body parts.
        # @param rank [Integer] The rank of injury to check.
        # @param wounds_hash [Hash] A hash containing wounds data.
        # @param scars_hash [Hash] A hash containing scars data.
        # @param parts [Array<Symbol>] The body parts to check.
        # @return [Boolean] True if any part has an injury at the specified rank.
        # @example
        #   has_injuries = injuries_at_rank?(2, wounds_hash, scars_hash, :leftArm, :rightArm)
        def injuries_at_rank?(rank, wounds_hash, scars_hash, *parts)
          parts.flatten.any? do |part|
            effective_injury_from_hashes(part, wounds_hash, scars_hash) == rank
          end
        end

        # Checks if there are injuries at or above a specific rank for given body parts.
        # @param rank [Integer] The rank of injury to check.
        # @param wounds_hash [Hash] A hash containing wounds data.
        # @param scars_hash [Hash] A hash containing scars data.
        # @param parts [Array<Symbol>] The body parts to check.
        # @return [Boolean] True if any part has an injury at or above the specified rank.
        # @example
        #   has_injuries = injuries_at_or_above_rank?(2, wounds_hash, scars_hash, :leftArm, :rightArm)
        def injuries_at_or_above_rank?(rank, wounds_hash, scars_hash, *parts)
          parts.flatten.any? do |part|
            effective_injury_from_hashes(part, wounds_hash, scars_hash) >= rank
          end
        end

        # Determines if the character can bypass injuries based on active effects.
        # @return [Boolean] True if the character can bypass injuries.
        # @example
        #   can_bypass = bypasses_injuries?
        def bypasses_injuries?
          Effects::Buffs.active?("Sigil of Determination")
        end

        # Checks if the character is able to cast spells based on their injury status.
        # @return [Boolean] True if the character can cast spells.
        # @example
        #   can_cast = able_to_cast?
        def able_to_cast?
          fix_injury_mode("both")

          # Fetch cached or fresh injury data
          wounds, scars = get_injury_data

          # Rank 3 critical injuries prevent casting (Sigil cannot bypass)
          return false if injuries_at_rank?(3, wounds, scars, :head, :nsys, *BODY_PART_GROUPS[:eyes])

          # Check for rank 3 in arms/hands (worst of arm vs hand per side)
          left_arm = effective_injury_from_hashes(:leftArm, wounds, scars)
          left_hand = effective_injury_from_hashes(:leftHand, wounds, scars)
          right_arm = effective_injury_from_hashes(:rightArm, wounds, scars)
          right_hand = effective_injury_from_hashes(:rightHand, wounds, scars)

          left_side = [left_arm, left_hand].max
          right_side = [right_arm, right_hand].max

          return false if left_side == 3 || right_side == 3

          # Sigil of Determination bypasses rank 2 or lower injuries
          return true if bypasses_injuries?

          # Head or nerve injuries > rank 1 prevent casting
          return false if injuries_at_or_above_rank?(2, wounds, scars, *BODY_PART_GROUPS[:head_and_nerves])

          # Cumulative injuries >= 3 prevent casting
          eyes_total = BODY_PART_GROUPS[:eyes].sum { |part| effective_injury_from_hashes(part, wounds, scars) }
          return false if eyes_total >= 3

          arms_total = left_side + right_side
          return false if arms_total >= 3

          true
        end

        # Checks if the character is able to sneak based on their injury status.
        # @return [Boolean] True if the character can sneak.
        # @example
        #   can_sneak = able_to_sneak?
        def able_to_sneak?
          fix_injury_mode("both")

          wounds, scars = get_injury_data

          # Rank 3 leg/foot injuries always prevent sneaking, but these are NOT critical
          # (Sigil cannot bypass, but they're not in the critical list for other actions)
          return false if injuries_at_rank?(3, wounds, scars, *BODY_PART_GROUPS[:legs], *BODY_PART_GROUPS[:feet])

          # Sigil of Determination bypasses rank 2 or lower injuries
          return true if bypasses_injuries?

          # Any leg or foot injury > rank 1 prevents sneaking
          return false if injuries_at_or_above_rank?(2, wounds, scars, *BODY_PART_GROUPS[:legs], *BODY_PART_GROUPS[:feet])

          true
        end

        # Checks if the character is able to search based on their injury status.
        # @return [Boolean] True if the character can search.
        # @example
        #   can_search = able_to_search?
        def able_to_search?
          fix_injury_mode("both")

          wounds, scars = get_injury_data

          # Rank 3 critical injuries prevent searching (Sigil cannot bypass)
          return false if injuries_at_rank?(3, wounds, scars, :head, :nsys, *BODY_PART_GROUPS[:eyes])

          # Sigil of Determination bypasses rank 2 or lower injuries
          return true if bypasses_injuries?

          # Rank 2+ head or nerve injury prevents searching
          return false if injuries_at_or_above_rank?(2, wounds, scars, *BODY_PART_GROUPS[:head_and_nerves])

          true
        end

        # Checks if the character is able to use ranged weapons based on their injury status.
        # @return [Boolean] True if the character can use ranged weapons.
        # @example
        #   can_use_ranged = able_to_use_ranged?
        def able_to_use_ranged?
          fix_injury_mode("both")

          wounds, scars = get_injury_data

          # Rank 3 critical injuries prevent ranged weapon use (Sigil cannot bypass)
          return false if injuries_at_rank?(3, wounds, scars, :head, :nsys, *BODY_PART_GROUPS[:eyes], *BODY_PART_GROUPS[:arms], *BODY_PART_GROUPS[:hands])

          # Sigil of Determination bypasses rank 2 or lower injuries
          return true if bypasses_injuries?

          # Any single arm or hand injury >= rank 2 prevents ranged weapon use
          return false if injuries_at_or_above_rank?(2, wounds, scars, *BODY_PART_GROUPS[:arms], *BODY_PART_GROUPS[:hands], :nsys)

          true
        end
      end
    end
  end
end
