module Lich
  module Gemstone
    module Societies
      ##
      # Represents the Council of Light society in the game.
      #
      # This class provides methods to access and use various signs associated with the Council of Light.
      #
      # @see Gemstone::Society
      class CouncilOfLight < Gemstone::Society
        ##
        @@col_signs = {
          "sign_of_recognition"  => {
            rank: 1,
            short_name: "recognition",
            long_name: "Sign of Recognition",
            type: :utility,
            cost: { spirit: 0, mana: 0 },
            cost_type: nil,
            duration: nil,
            summary: "Allows the character to identify other members and their relative ranks.",
            spell_number: 9901,
          },
          "sign_of_signal"       => {
            rank: 2,
            short_name: "signal",
            long_name: "Sign of Signal",
            type: :utility,
            cost: { spirit: 0, mana: 0 },
            cost_type: nil,
            duration: nil,
            summary: "Use sign language to communicate with other society members in the room.",
            spell_number: 9902,
            usage: "signal"
          },
          "sign_of_warding"      => {
            rank: 3,
            short_name: "warding",
            long_name: "Sign of Warding",
            type: :defense,
            cost: { spirit: 0, mana: 1 },
            cost_type: :invoked,
            duration: -> { 10 * Stats.level },
            summary: -> { "Increases Defensive Strength by +5 for 10 seconds/level (#{10 * Stats.level})." },
            spell_number: 9903,
          },
          "sign_of_striking"     => {
            rank: 4,
            short_name: "striking",
            long_name: "Sign of Striking",
            type: :offense,
            cost: { spirit: 0, mana: 1 },
            cost_type: :invoked,
            duration: -> { 10 * Stats.level },
            summary: -> { "Increases Attack Strength by +5 for 10 seconds/level (#{10 * Stats.level})." },
            spell_number: 9904,
          },
          "sign_of_clotting"     => {
            rank: 5,
            short_name: "clotting",
            long_name: "Sign of Clotting",
            type: :utility,
            cost: { spirit: 0, mana: 1 },
            cost_type: :invoked,
            duration: -> { 10 * Stats.level },
            summary: -> { "Stops bleeding immediately for 10 seconds/level (#{10 * Stats.level})." },
            spell_number: 9905,
          },
          "sign_of_thought"      => {
            rank: 6,
            short_name: "thought",
            long_name: "Sign of Thought",
            type: :utility,
            cost: { spirit: 0, mana: 1 },
            cost_type: :invoked,
            duration: -> { 600 + (6 * Stats.level) },
            summary: -> { "Gives the same effect as rubbing a crystal amulet for 10 minutes + 6 seconds/level (#{600 + (6 * Stats.level)})." },
            spell_number: 9906,
          },
          "sign_of_defending"    => {
            rank: 7,
            short_name: "defending",
            long_name: "Sign of Defending",
            type: :defense,
            cost: { spirit: 0, mana: 2 },
            cost_type: :invoked,
            duration: -> { 10 * Stats.level },
            summary: -> { "Increases Defensive Strength by +10 for 10 seconds/level (#{10 * Stats.level})." },
            spell_number: 9907,
          },
          "sign_of_smiting"      => {
            rank: 8,
            short_name: "smiting",
            long_name: "Sign of Smiting",
            type: :offense,
            cost: { spirit: 0, mana: 2 },
            cost_type: :invoked,
            duration: -> { 10 * Stats.level },
            summary: -> { "Increases Attack Strength by +10 for 10 seconds/level (#{10 * Stats.level})." },
            spell_number: 9908,
          },
          "sign_of_staunching"   => {
            rank: 9,
            short_name: "staunching",
            long_name: "Sign of Staunching",
            type: :utility,
            cost: { spirit: 0, mana: 1 },
            cost_type: :invoked,
            duration: -> { 20 * Stats.level },
            summary: -> { "Stops all bleeding for 20 seconds/level (#{20 * Stats.level})." },
            spell_number: 9909,
          },
          "sign_of_deflection"   => {
            rank: 10,
            short_name: "deflection",
            long_name: "Sign of Deflection",
            type: :defense,
            cost: { spirit: 0, mana: 3 },
            cost_type: :invoked,
            duration: -> { 10 * Stats.level },
            summary: -> { "Increases Bolt DS by +20 for 10 seconds/level (#{10 * Stats.level})." },
            spell_number: 9910,
          },
          "sign_of_hypnosis"     => {
            rank: 11,
            short_name: "hypnosis",
            long_name: "Sign of Hypnosis",
            type: :utility,
            cost: { spirit: 1, mana: 0 },
            cost_type: :invoked,
            duration: nil,
            summary: -> { "Calms a random target with a hidden warding check for a variable duration." },
            spell_number: 9911,
          },
          "sign_of_swords"       => {
            rank: 12,
            short_name: "swords",
            long_name: "Sign of Swords",
            type: :offense,
            cost: { spirit: 1, mana: 0 },
            cost_type: :dissipates,
            duration: -> { 10 * Stats.level },
            summary: -> { "Increases Attack Strength by +20 for 10 seconds/level (#{10 * Stats.level})." },
            spell_number: 9912,
          },
          "sign_of_shields"      => {
            rank: 13,
            short_name: "shields",
            long_name: "Sign of Shields",
            type: :defense,
            cost: { spirit: 1, mana: 0 },
            cost_type: :dissipates,
            duration: -> { 10 * Stats.level },
            summary: -> { "Increases Defensive Strength by +20 for 10 seconds/level (#{10 * Stats.level})." },
            spell_number: 9913,
          },
          "sign_of_dissipation"  => {
            rank: 14,
            short_name: "dissipation",
            long_name: "Sign of Dissipation",
            type: :defense,
            cost: { spirit: 1, mana: 0 },
            cost_type: :dissipates,
            duration: -> { 10 * Stats.level },
            summary: -> { "Increases Target Defense by +15 for 10 seconds/level (#{10 * Stats.level})." },
            spell_number: 9914,
          },
          "sign_of_healing"      => {
            rank: 15,
            short_name: "healing",
            long_name: "Sign of Healing",
            type: :utility,
            cost: { spirit: 2, mana: 0 },
            cost_type: :invoked,
            duration: nil,
            summary: "Fully regenerates all hit points.",
            spell_number: 9915,
          },
          "sign_of_madness"      => {
            rank: 16,
            short_name: "madness",
            long_name: "Sign of Madness",
            type: :utility,
            cost: { spirit: 3, mana: 0 },
            cost_type: :dissipates,
            duration: 15,
            summary: "+50 to AS, -50 to DS for 15 seconds.",
            spell_number: 9916,
          },
          "sign_of_possession"   => {
            rank: 17,
            short_name: "possession",
            long_name: "Sign of Possession",
            type: :utility,
            cost: { spirit: 4, mana: 0 },
            cost_type: :invoked,
            duration: nil,
            summary: "Mass Calm the room with a hidden warding roll.",
            spell_number: 9917,
          },
          "sign_of_wracking"     => {
            rank: 18,
            short_name: "wracking",
            long_name: "Sign of Wracking",
            type: :utility,
            cost: { spirit: 5, mana: 0 },
            cost_type: :invoked,
            duration: nil,
            summary: "Instantly replenishes all mana.",
            spell_number: 9918,
          },
          "sign_of_darkness"     => {
            rank: 19,
            short_name: "darkness",
            long_name: "Sign of Darkness",
            type: :utility,
            cost: { spirit: 6, mana: 0 },
            cost_type: :invoked,
            duration: nil,
            summary: "Teleports the user to a \"safe point\" or to the nearest Council chapter (whichever is closer).",
            spell_number: 9919,
          },
          "sign_of_hopelessness" => {
            rank: 20,
            short_name: "hopelessness",
            long_name: "Sign of Hopelessness",
            type: :utility,
            cost: { spirit: 0, mana: 0 },
            cost_type: nil,
            duration: nil,
            summary: "Causes you to decay while dead.",
            spell_number: 9920,
          },
        }.freeze

        ##
        # Retrieves the sign metadata for a given sign name.
        #
        # @param name [String] the name of the sign to retrieve
        # @return [Hash, nil] the metadata of the sign or nil if not found
        # @example Retrieve sign metadata
        #   sign_metadata = CouncilOfLight["sign_of_recognition"]
        def self.[](name)
          lookup = Society.lookup(name, sign_lookups)
          return nil unless lookup

          key = lookup[:short_name]
          sign = @@col_signs.values.find { |entry| entry[:short_name] == key }
          return nil unless sign

          sign.transform_values do |v|
            if v.respond_to?(:call)
              v.arity == 1 ? v.call(sign) : v.call
            else
              v
            end
          end
        end

        ##
        # Provides a list of all available signs with their metadata.
        #
        # @return [Array<Hash>] an array of hashes containing sign metadata
        def self.sign_lookups
          @@col_signs.map do |_, sign|
            {
              long_name: sign[:long_name],
              short_name: sign[:short_name],
              rank: sign[:rank],
              cost: sign[:cost],
            }
          end
        end

        ##
        # Checks if a sign is known by the member and if its rank is accessible.
        #
        # @param sign_name [String] the name of the sign to check
        # @return [Boolean] true if the sign is known and accessible, false otherwise
        def self.known?(sign_name)
          return false unless member?
          sign = self[sign_name]
          return false unless sign

          sign[:rank] <= self.rank
        end

        ##
        # Uses a sign for the member, optionally targeting a specific entity.
        #
        # @param sign_name [String] the name of the sign to use
        # @param target [String, nil] the target for the sign, if applicable
        # @return [void]
        # @example Use a sign on a target
        #   CouncilOfLight.use("sign_of_signal", "friend")
        def self.use(sign_name, target = nil)
          unless member?
            Lich::Messaging.msg("error", "Not a member of Council of Light, can't use: #{sign_name}")
            return
          end
          sign = self[sign_name]

          unless sign
            Lich::Messaging.msg("error", "Unknown sign: #{sign_name}")
            return
          end

          if available?(sign_name)
            command = sign[:usage] || "sign of #{sign[:short_name]}"
            waitrt?
            waitcastrt?
            fput "#{command} #{target}".strip
          else
            Lich::Messaging.msg("warn", "You cannot use the #{sign_name} sign right now.")
          end
        end

        ##
        # Checks if the member can afford to use a specific sign based on its costs.
        #
        # @param sign_name [String] the name of the sign to check affordability
        # @return [Boolean] true if the sign can be afforded, false otherwise
        def self.affordable?(sign_name)
          return false unless member?
          sign = self[sign_name]
          return false unless sign

          cost = sign[:cost] || {}
          spirit_cost = cost[:spirit].to_i
          mana_cost = cost[:mana].to_i

          unless spirit_cost.zero?
            total_spirit = spirit_cost
            total_spirit += pending_spirit_loss if sign[:cost_type] == :dissipates

            return false unless total_spirit < Char.spirit
          end

          unless mana_cost.zero?
            return false unless mana_cost <= Char.mana
          end

          return true
        end

        ##
        # Calculates the total spirit loss from active dissipating signs.
        #
        # @return [Integer] the total spirit loss from active signs
        def self.pending_spirit_loss
          @@col_signs.values
                     .select { |sign| sign[:cost_type] == :dissipates }
                     .select { |sign| Effects::Buffs.active?(sign[:long_name]) }
                     .sum { |sign| sign.dig(:cost, :spirit).to_i }
        end

        ##
        # Retrieves all signs with their resolved metadata.
        #
        # @return [Array<Hash>] an array of hashes containing all sign metadata
        def self.all
          @@col_signs.values.map { |entry| entry.transform_values { |v| Society.resolve(v, entry) } }
        end

        ##
        # Checks if the member is a master of the Council of Light.
        #
        # @return [Boolean] true if the member is a master, false otherwise
        def self.master?
          return false unless member?
          Society.rank == 20 # is the rank of a COL Master
        end

        ##
        # Checks if the current member belongs to the Council of Light.
        #
        # @param rank [Integer, nil] optional rank to check against
        # @return [Boolean] true if the member belongs to the Council of Light, false otherwise
        def self.member?(rank = nil)
          return false unless Society.membership == "Council of Light"
          rank.nil? || Society.rank == rank
        end

        ##
        # Retrieves the rank of the current member in the Council of Light.
        #
        # @return [Integer] the rank of the member, or 0 if not a member
        def self.rank
          return 0 unless member?
          Society.rank
        end

        ##
        # Checks if a sign is available for use by the member.
        #
        # @param sign_name [String] the name of the sign to check
        # @return [Boolean] true if the sign is available, false otherwise
        def self.available?(sign_name)
          return false unless member?
          sign = self[sign_name]
          return false unless sign
          return false unless known?(sign_name) && affordable?(sign_name)

          if sign[:cost_type] == :dissipates
            return false if Effects::Buffs.active?(sign[:long_name])
          end

          true
        end

        ##
        # Dynamically defines singleton methods for each Council of Light sign.
        #
        # Each method allows accessing the sign's metadata by calling either its
        # short name or long name as a method. For example:
        #
        #   CouncilOfLight.striking  #=> metadata hash for "Sign of Striking"
        #   CouncilOfLight["Sign of Striking"] #=> same result
        #
        # This supports both `sign[:short_name]` and `sign[:long_name]`.
        #
        define_name_methods(self, @@col_signs)
      end
    end
  end
end
