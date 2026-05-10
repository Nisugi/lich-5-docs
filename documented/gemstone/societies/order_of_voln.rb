module Lich
  module Gemstone
    module Societies
      ##
      # Represents the Order of Voln, a society in the Lich game.
      # This class provides methods to access and use various symbols associated with the Order.
      # @example Accessing a symbol
      #   symbol = OrderOfVoln["symbol_of_recognition"]
      class OrderOfVoln < Gemstone::Society

        ##
        #
        @@voln_symbols = {
          "symbol_of_recognition"   => {
            rank: 1,
            short_name: "recognition",
            long_name: "Symbol of Recognition",
            type: :utility,
            cost_modifier: 0.00,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Detect other members of the Order and any undead creatures present in the room.",
            spell_number: 9801,
          },
          "symbol_of_blessing"      => {
            rank: 2,
            short_name: "blessing",
            long_name: "Symbol of Blessing",
            type: :utility,
            cost_modifier: 0.20, # 0.04 if not magical
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            alt_cost_modifier: 0.04,
            alt_cost_reason: "non-magical",
            duration: -> { Society.rank * 2 },
            summary: -> { "Bless weapons and other combat gear, up to 2x rank (+#{(Society.rank * 2)}) for Level + 2x Rank (#{Stats.level + (Society.rank * 2)}) swings." },
            spell_number: 9802,
          },
          "symbol_of_thought"       => {
            rank: 3,
            short_name: "thought",
            long_name: "Symbol of Thought",
            type: :utility,
            cost_modifier: nil,
            duration: nil,
            summary: "[Symbol of Thought is no longer required and will be replaced in the future.  Click ESP to learn more about the Society ESP channel.]",
            spell_number: 9803,
          },
          "symbol_of_diminishment"  => {
            rank: 4,
            short_name: "diminishment",
            long_name: "Symbol of Diminishment",
            type: :attack,
            cost_modifier: 0.30,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: -> { Society.rank * 2 },
            summary: -> { "Successful SSR check will temporarily reduce target undead creature's DS, TD, and CMAN -1 per rank (#{Society.rank * 2}) for rank x 2 (#{Society.rank * 2}) seconds." },
            spell_number: 9804,
          },
          "symbol_of_courage"       => {
            rank: 5,
            short_name: "courage",
            long_name: "Symbol of Courage",
            type: :offense,
            cost_modifier: 0.10,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: -> { Society.rank * 10 },
            summary: -> { "Increases your generic AS and UAF by +1 per rank (+#{Society.rank}).  Adds 3 phantom levels against fear-based attacks." },
            spell_number: 9805,
          },
          "symbol_of_protection"    => {
            rank: 6,
            short_name: "protection",
            long_name: "Symbol of Protection",
            type: :defense,
            cost_modifier: 0.10,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: -> { Society.rank * 20 },
            summary: -> { "Increases your DS +1 and TD +.5 per rank (+#{Society.rank} DS / +#{(Society.rank * 0.5).floor} TD)." },
            spell_number: 9806,
          },
          "symbol_of_submission"    => {
            rank: 7,
            short_name: "submission",
            long_name: "Symbol of Submission",
            type: :attack,
            cost_modifier: 0.30,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Successful SSR forces undead to offensive stance and to briefly kneel.",
            spell_number: 9807,
          },
          "kais_strike"             => {
            rank: 8,
            short_name: "strike",
            long_name: "Kai's Strike",
            type: :utility,
            cost_modifier: 0.00,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Enables unarmed combat attacks to damage undead creatures without the normal requirement of blessed gear.",
            spell_number: 9808,
          },
          "symbol_of_holiness"      => {
            rank: 9,
            short_name: "holiness",
            long_name: "Symbol of Holiness",
            type: :attack,
            cost_modifier: 0.30,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "A SSR-based fire attack against an Undead creature.",
            spell_number: 9809,
          },
          "symbol_of_recall"        => {
            rank: 10,
            short_name: "recall",
            long_name: "Symbol of Recall",
            type: :utility,
            cost_modifier: 0.40,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Restores spells after death.  Must be invoked while dead.  No effect for voluntary departs.",
            spell_number: 9810,
          },
          "symbol_of_sleep"         => {
            rank: 11,
            short_name: "sleep",
            long_name: "Symbol of Sleep",
            type: :attack,
            cost_modifier: 0.20, # base cost is 0.20, but it can be increased by the number of targets
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "SSR-based targeted or mass disabling attack used against most creatures. Player friendly.",
            spell_number: 9811,
          },
          "symbol_of_transcendence" => {
            rank: 12,
            short_name: "transcendence",
            long_name: "Symbol of Transcendence",
            type: :defense,
            cost_modifier: 0.60,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: 30,
            cooldown_duration: 180, # 3 minutes cooldown, or 10 minutes if used in an emergency, appear in effects??
            summary: "Take damage as if incorporeal for 30 seconds.  3m cooldown or 10 if used in an emergency.",
            spell_number: 9812,
          },
          "symbol_of_mana"          => {
            rank: 13,
            short_name: "mana",
            long_name: "Symbol of Mana",
            type: :utility,
            cost_modifier: 0.30,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Restores 50 mana. Initially, no deed cost, 5 min cooldown.",
            spell_number: 9813,
          },
          "symbol_of_sight"         => {
            rank: 14,
            short_name: "sight",
            long_name: "Symbol of Sight",
            type: :utility,
            cost_modifier: 0.30,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: 10,
            summary: "Locate voln member within range.",
            spell_number: 9814,
          },
          "symbol_of_retribution"   => {
            rank: 15,
            short_name: "retribution",
            long_name: "Symbol of Retribution",
            type: :attack,
            cost_modifier: 0.04, # attack version, 0.30 for selfcast
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "SSR-based direct attack against undead when you are dead.  Living use grants SSR-based reactive flare when struck by undead.",
            spell_number: 9815,
          },
          "symbol_of_supremacy"     => {
            rank: 16,
            short_name: "supremacy",
            long_name: "Symbol of Supremacy",
            type: :offense,
            cost_modifier: 0.50,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: -> { Society.rank * 10 },
            summary: -> { "Bonus of +1 per 2 ranks (+#{(Society.rank / 2).floor}) to AS/CS, CMAN, UAF against undead for (#{Society.rank * 10}) seconds." },
            spell_number: 9816,
          },
          "symbol_of_restoration"   => {
            rank: 17,
            short_name: "restoration",
            long_name: "Symbol of Restoration",
            type: :utility,
            cost_modifier: 0.40,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Restores half (10min/50max) hit points.",
            spell_number: 9817,
          },
          "symbol_of_need"          => {
            rank: 18,
            short_name: "need",
            long_name: "Symbol of Need",
            type: :utility,
            cost_modifier: 0.40,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Transmits an image of the member's location to all other members within range.",
            spell_number: 9818,
          },
          "symbol_of_renewal"       => {
            rank: 19,
            short_name: "renewal",
            long_name: "Symbol of Renewal",
            type: :utility,
            cost_modifier: 0.50,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            cooldown_duration: 120, # 2 minutes cooldown
            summary: "Restores 1 Spirit Point. 2 min hard cooldown.",
            spell_number: 9819,
          },
          "symbol_of_disruption"    => {
            rank: 20,
            short_name: "disruption",
            long_name: "Symbol of Disruption",
            type: :attack,
            cost_modifier: 0.30, # Base cost is 0.30, but it can be increased by the number of targets
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: -> { Society.rank * 10 },
            summary: -> { "Group defense penalizing (AS/DS, CS/TD, UDF, CMAN) noncorporeal undead that are struck. Duration: #{Society.rank * 10} seconds stackable." },
            spell_number: 9820,
          },
          "kais_smite"              => {
            rank: 21,
            short_name: "smite",
            long_name: "Kai's Smite",
            type: :attack,
            cost_modifier: 0.00,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Temporarily make a non-corporeal undead creature corporeal and more susceptible to damage using SMITE (unarmed attack).",
            spell_number: 9821,
            usage: "smite",
          },
          "symbol_of_turning"       => {
            rank: 22,
            short_name: "turning",
            long_name: "Symbol of Turning",
            type: :attack,
            cost_modifier: 0.30, # Base cost is 0.30, but it can be increased by the number of targets
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Targeted or mass SSR-based attack similar to fear effects with possible instant death result.",
            spell_number: 9822,
          },
          "symbol_of_preservation"  => {
            rank: 23,
            short_name: "preservation",
            long_name: "Symbol of Preservation",
            type: :utility,
            cost_modifier: 0.60,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: -> { Society.rank * 30 },
            summary: "Lifekeep. Can be used on self and other characters.",
            spell_number: 9823,
          },
          "symbol_of_dreams"        => {
            rank: 24,
            short_name: "dreams",
            long_name: "Symbol of Dreams",
            type: :utility,
            cost_modifier: 0.60,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Dream state - increases recovery of health, mana, spirit and reduced stats from Death's Sting.",
            spell_number: 9824,
          },
          "symbol_of_return"        => {
            rank: 25,
            short_name: "return",
            long_name: "Symbol of Return",
            type: :utility,
            cost_modifier: 1.00,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Immediate Teleportation of member and group to the nearest Voln outpost.",
            spell_number: 9825,
          },
          "symbol_of_seeking"       => {
            rank: 26,
            short_name: "seeking",
            long_name: "Symbol of Seeking",
            type: :utility,
            cost_modifier: 0.00,
            cost: ->(s) { OrderOfVoln.calculate_cost(s[:cost_modifier]) },
            duration: nil,
            summary: "Teleportation of group from a Voln outpost to an undead hunting area.",
            spell_number: 9826,
          },
        }.freeze

        ##
        #
        BASE_FAVOR_COST_BY_LEVEL = [
          nil, nil, nil, 13, 22, 32, 43, 56, 70, 85, 100, 117, 134, 151, 169, 188,
          207, 226, 246, 266, 286, 307, 328, 349, 370, 391, 412, 434, 456, 478,
          500, 522, 544, 577, 590, 613, 636, 659, 682, 705, 728, 751, 774, 797,
          820, 843, 866, 889, 912, 935, 958, 981, 1004, 1027, 1050, 1073, 1097,
          1121, 1145, 1169, 1193, 1217, 1241, 1265, 1289, 1313, 1337, 1361, 1385,
          1409, 1433, 1457, 1481, 1505, 1529, 1553, 1577, 1601, 1625, 1649, 1674,
          1699, 1724, 1749, 1774, 1799, 1824, 1849, 1874, 1899, 1924, 1949, 1974,
          1999, 2024, 2049, 2074, 2099, 2124, 2149, 2174
        ]

        ##
        # Retrieves the symbol metadata for a given symbol name.
        # @param name [String] The name of the symbol to retrieve.
        # @return [Hash, nil] The metadata hash for the symbol or nil if not found.
        # @example Retrieving a symbol
        #   symbol = OrderOfVoln["symbol_of_recognition"]
        def self.[](name)
          lookup = Society.lookup(name, symbol_lookups)
          return nil unless lookup

          key = lookup[:short_name]
          symbol = @@voln_symbols.values.find { |entry| entry[:short_name] == key }
          return nil unless symbol

          symbol.transform_values do |v|
            if v.respond_to?(:call)
              # Provide the hash as context to lambdas expecting it
              v.arity == 1 ? v.call(symbol) : v.call
            else
              v
            end
          end
        end

        ##
        # Returns an array of all symbols in the Order of Voln.
        # @return [Array<Hash>] An array of metadata hashes for all symbols.
        # @example Getting all symbols
        #   symbols = OrderOfVoln.all
        def self.all
          @@voln_symbols.values.map { |entry| entry.transform_values { |v| Society.resolve(v, entry) } }
        end

        ##
        # Calculates the cost of using a symbol based on its cost modifier.
        # @param cost_modifier [Float] The cost modifier for the symbol.
        # @return [Integer, nil] The calculated cost or nil if the cost modifier is nil.
        # @example Calculating cost
        #   cost = OrderOfVoln.calculate_cost(0.20)
        def self.calculate_cost(cost_modifier)
          return nil if cost_modifier.nil?

          base_cost = BASE_FAVOR_COST_BY_LEVEL[Stats.level]
          (base_cost * cost_modifier).to_f.ceil
        end

        ##
        # Provides a list of symbol lookups for the Order of Voln.
        # @return [Array<Hash>] An array of hashes containing symbol metadata for lookups.
        def self.symbol_lookups
          @@voln_symbols.map do |_, symbol|
            {
              long_name: symbol[:long_name],
              short_name: symbol[:short_name],
              rank: symbol[:rank],
              cost: Society.resolve(symbol[:cost], symbol),
            }
          end
        end

        ##
        # Checks if a symbol is known by the member and if its rank is accessible.
        # @param symbol_name [String] The name of the symbol to check.
        # @return [Boolean] True if the symbol is known and accessible, false otherwise.
        # @example Checking if a symbol is known
        #   known = OrderOfVoln.known?("symbol_of_recognition")
        def self.known?(symbol_name)
          return false unless member?
          symbol = self[symbol_name]
          return false unless symbol

          symbol[:rank] <= self.rank
        end

        ##
        # Uses a symbol for the member, optionally targeting a specific entity.
        # @param symbol_name [String] The name of the symbol to use.
        # @param target [String, nil] The target for the symbol usage, if applicable.
        # @return [void]
        # @example Using a symbol
        #   OrderOfVoln.use("symbol_of_blessing", "target_name")
        def self.use(symbol_name, target = nil)
          unless member?
            Lich::Messaging.msg("error", "Not a member of Order of Voln, can't use: #{symbol_name}")
            return
          end
          symbol = self[symbol_name]

          unless symbol
            Lich::Messaging.msg("error", "Unknown symbol: #{symbol_name}")
            return
          end

          if self.available?(symbol_name)
            command = symbol[:usage] || "symbol of #{symbol[:short_name]}"
            waitrt?
            waitcastrt?
            fput "#{command} #{target}".strip
          else
            Lich::Messaging.msg("warn", "You cannot use the #{symbol_name} symbol right now.")
          end
        end

        ##
        # Checks if a symbol can be afforded by the member.
        # @param symbol_name [String] The name of the symbol to check affordability for.
        # @return [Boolean] True if the symbol is affordable, false otherwise.
        # @example Checking affordability
        #   affordable = OrderOfVoln.affordable?("symbol_of_recognition")
        def self.affordable?(symbol_name)
          return false unless member?
          symbol = self[symbol_name]
          return false unless symbol

          cost = symbol[:cost]
          return true if cost.nil? # No cost defined, so it's always affordable

          favor >= cost
        end

        ##
        # Checks if a symbol is available for use by the member.
        # @param symbol_name [String] The name of the symbol to check availability for.
        # @return [Boolean] True if the symbol is available, false otherwise.
        # @example Checking availability
        #   available = OrderOfVoln.available?("symbol_of_blessing")
        def self.available?(symbol_name)
          return false unless member?
          self.known?(symbol_name) && self.affordable?(symbol_name)
        end

        ##
        # Retrieves the current favor of the member in the Order of Voln.
        # @return [Integer] The current favor amount.
        def self.favor
          Infomon.get('resources.voln_favor')
        end

        ##
        # Checks if the member is a master of the Order of Voln.
        # @return [Boolean] True if the member is a master, false otherwise.
        def self.master?
          return false unless member?
          Society.rank == 26 # is the rank of a Voln Master
        end

        ##
        # Retrieves the rank of the member in the Order of Voln.
        # @return [Integer] The rank of the member, or 0 if not a member.
        def self.rank
          return 0 unless member?
          Society.rank
        end

        ##
        # Retrieves the current step (rank) of the member in the Order of Voln.
        # @return [Integer] The current step of the member.
        def self.step
          self.rank
        end

        ##
        # Checks if the member belongs to the Order of Voln.
        # @param rank [Integer, nil] The rank to check against, or nil to check membership only.
        # @return [Boolean] True if the member belongs to the Order, false otherwise.
        def self.member?(rank = nil)
          return false unless Society.membership == "Order of Voln"
          rank.nil? || Society.rank == rank
        end

        ##
        # Dynamically defines singleton methods for each Order of Voln symbol.
        # Each method allows accessing the symbol's metadata by calling either its
        # short name or long name as a method. For example:
        #
        #   OrderOfVoln.defense  #=> metadata hash for "Symbol of Defense"
        #   OrderOfVoln["Symbol of Defense"] #=> same result
        #
        # This supports both `symbol[:short_name]` and `symbol[:long_name]`.
        # Dynamically defines singleton methods for each Order of Voln symbol.
        #
        # Each method allows accessing the symbol's metadata by calling either its
        # short name or long name as a method. For example:
        #
        #   OrderOfVoln.defense  #=> metadata hash for "Symbol of Defense"
        #   OrderOfVoln["Symbol of Defense"] #=> same result
        #
        # This supports both `symbol[:short_name]` and `symbol[:long_name]`.
        #
        define_name_methods(self, @@voln_symbols)
      end
    end
  end
end
