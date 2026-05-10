

# Namespace for the Lich project.
#
# This module contains various submodules related to the game's mechanics.
module Lich
  module Gemstone
    module Combat
      module Definitions
        module Attacks
          # Represents an attack definition with a name and associated patterns.
          #
          # @!attribute [r] name
          #   @return [Symbol] the name of the attack
          # @!attribute [r] patterns
          #   @return [Array<Regexp>] the patterns that match the attack description
          AttackDef = Struct.new(:name, :patterns)

          # Core attack patterns - most common combat actions
          # Core attack patterns - most common combat actions.
          #
          # @example Basic attack patterns
          #   BASIC_ATTACKS.each do |attack|
          #     puts attack.name
          #   end
          BASIC_ATTACKS = [
            AttackDef.new(:attack, [/You(?<aimed> take aim and)? swing .+? at (?<target>[^!]+)!/].freeze),
            AttackDef.new(:fire, [/You(?<aimed> take aim and)? fire .+? at (?<target>[^!]+)!/].freeze),
            AttackDef.new(:grapple, [/You(?: make a precise)? attempt to grapple (?<target>[^!]+)!/].freeze),
            AttackDef.new(:jab, [/You(?: make a precise)? attempt to jab (?<target>[^!]+)!/].freeze),
            AttackDef.new(:kick, [/You(?: make a precise)? attempt to kick (?<target>[^!]+)!/].freeze),
            AttackDef.new(:punch, [/You(?: make a precise)? attempt to punch (?<target>[^!]+)!/].freeze),
            AttackDef.new(:wand, [/You wave your .+ at (?<target>[^\.]+)\./].freeze)
          ].freeze

          # Spell-based attacks
          # Spell-based attacks.
          #
          # @example Spell attack patterns
          #   SPELL_ATTACKS.each do |attack|
          #     puts attack.name
          #   end
          SPELL_ATTACKS = [
            AttackDef.new(:balefire, [/You hurl a ball of greenish-black flame at (?<target>[^!]+)!/].freeze),
            AttackDef.new(:cold_snap, [/An airy mist rolls into the area, carrying a harsh chill with it./].freeze),
            AttackDef.new(:divine_fury, [/A shadowy figure briefly materializes behind (?<target>[^,]+), and a silent scream courses over .+? visage./].freeze),
            AttackDef.new(:earthen_fury, [
              /Fiery debris explodes from the ground beneath (?<target>[^!]+)!/,
              /Craggy debris explodes from the ground beneath (?<target>[^!]+)!/,
              /The earth cracks beneath (?<target>[^,]+), releasing a column of frigid air!/,
              /Icy stalagmites burst from the ground beneath (?<target>[^!]+)!/
            ].freeze),
            AttackDef.new(:ewave, [/(?:An?|Some) (?<target>.+?) is buffeted by the \w+ ethereal waves(?: and is knocked to the ground)?\./].freeze),
            AttackDef.new(:natures_fury, [/The surroundings advance upon (?<target>.+?) with relentless fury!/].freeze),
            AttackDef.new(:searing_light, [/The radiant burst of light engulfs (?<target>[^!]+)!/].freeze),
            AttackDef.new(:spikethorn, [/Dozens of long thorns suddenly grow out from the ground underneath (?<target>[^!]+)!/].freeze),
            AttackDef.new(:stone_fist, [/The ground beneath you rumbles, then erupts in a shower of rubble that coalesces in to a large hand with slender fingers in mid-air./].freeze),
            AttackDef.new(:sunburst, [/The dazzling solar blaze flashes before (?<target>[^!]+)!/].freeze),
            AttackDef.new(:tangleweed, [
              /The (?<weed>.+?) lashes out violently at (?<target>[^,]+), dragging .+? to the ground!/,
              /The (?<weed>.+?) lashes out at (?<target>[^,]+), wraps itself around .+? body and entangles .+? on the ground\./
            ].freeze),
            AttackDef.new(:tonis_bolt, [/You unleash a bolt of churning air at (?<target>[^!]+)!/].freeze),
            AttackDef.new(:unbalance, [/Bands of spectral mist ripple and surge beneath (?<target>[^!]+)!/].freeze),
            AttackDef.new(:web, [/Cloudy wisps swirl about (?<target>.+?)\./].freeze),
          ].freeze

          # Weapon maneuvers
          # Weapon maneuvers.
          #
          # @example Weapon attack patterns
          #   WEAPON_ATTACKS.each do |attack|
          #     puts attack.name
          #   end
          WEAPON_ATTACKS = [
            AttackDef.new(:cripple, [/You reverse your grip on your .+? and dart toward (?<target>.+?) at an angle!/].freeze),
            AttackDef.new(:flurry, [
              /Flowing with deadly grace, you smoothly reverse the direction of your blades and slash again!/,
              /With fluid motion, you guide your flashing blades, slicing toward (?<target>.+?) at the apex of their deadly arc!/
            ].freeze),
            AttackDef.new(:twinhammer, [/You raise your hands high, lace them together and bring them crashing down towards (?<target>[^!]+)!/].freeze),
            AttackDef.new(:wblade, [
              /You turn, blade spinning in your hand toward (?<target>[^!]+)!/,
              /You angle your blade at (?<target>.+?) in a crosswise slash!/,
              /In a fluid whirl, you sweep your blade at (?<target>[^!]+)!/,
              /Your blade licks out at (?<target>.+?) in a blurred arc!/
            ].freeze),
          ].freeze

          # Combat maneuvers
          # Combat maneuvers.
          #
          # @example Maneuver attack patterns
          #   MANEUVER_ATTACKS.each do |attack|
          #     puts attack.name
          #   end
          MANEUVER_ATTACKS = [
            # AttackDef.new(:hamstring, [/You(?: make a precise)? attempt to grapple (?<target>[^!]+)!/].freeze),
          ].freeze

          SHIELD_ATTACKS = [].freeze

          # Companion/pet attacks
          # Companion/pet attacks.
          #
          # @example Companion attack patterns
          #   COMPANION_ATTACKS.each do |attack|
          #     puts attack.name
          #   end
          COMPANION_ATTACKS = [
            AttackDef.new(:companion, [
              /(?<companion>.+?) pounces on (?<target>[^,]+), knocking the .+? painfully to the ground!/,
              /The (?<companion>.+?) takes the opportunity to slash .+? claws at the (?<target>.+?) \w+!/,
              /(?<companion>.+?) charges forward and slashes .+? claws at (?<target>.+?) faster than .+? can react!/
            ].freeze)
          ].freeze

          # Environmental attacks
          # Environmental attacks.
          #
          # @example Environmental attack patterns
          #   ENVIRONMENTAL_ATTACKS.each do |attack|
          #     puts attack.name
          #   end
          ENVIRONMENTAL_ATTACKS = [].freeze

          # All attack definitions combined
          # All attack definitions combined.
          #
          # @example All attack patterns
          #   ALL_ATTACKS.each do |attack|
          #     puts attack.name
          #   end
          ALL_ATTACKS = (BASIC_ATTACKS + SPELL_ATTACKS + MANEUVER_ATTACKS + WEAPON_ATTACKS +
                        SHIELD_ATTACKS + COMPANION_ATTACKS + ENVIRONMENTAL_ATTACKS).freeze

          # Create lookup table for fast pattern matching
          # Create lookup table for fast pattern matching.
          #
          # @example Lookup table usage
          #   ATTACK_LOOKUP.each do |pattern, name|
          #     puts "Pattern: \\#{pattern}, Attack: \\#{name}"
          #   end
          ATTACK_LOOKUP = ALL_ATTACKS.flat_map do |attack_def|
            attack_def.patterns.compact.map { |pattern| [pattern, attack_def.name] }
          end.freeze

          # Compiled regex for fast detection
          # Compiled regex for fast detection of attacks.
          #
          # @example Using the attack detector
          #   if input.match?(ATTACK_DETECTOR)
          #     puts "Attack detected!"
          #   end
          ATTACK_DETECTOR = Regexp.union(ATTACK_LOOKUP.map(&:first)).freeze
        end
      end
    end
  end
end
