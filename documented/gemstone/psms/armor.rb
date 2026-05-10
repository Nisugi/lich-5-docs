module Lich
  module Gemstone
    # Provides logic for detecting, checking, and using PSM3 armor techniques in GemStone IV.
    #
    # This module defines a registry of available armor-related abilities and wraps common queries
    # Provides logic for detecting, checking, and using PSM3 armor techniques in GemStone IV.
    #
    # This module defines a registry of available armor-related abilities and wraps common queries.
    module Armor
      @@armor_techniques = {
        "armor_blessing"      => {
          :short_name => "blessing",
          :type       => :buff,
          :cost       => { stamina: 0 },
          :regex      => /As \w+ prays? over \w+(?:'s)? [\w\s]+, you sense that (?:the Arkati's|a) blessing will be granted against magical attacks\./i,
          :usage      => "blessing"
        },
        "armor_reinforcement" => {
          :short_name => "reinforcement",
          :type       => :buff,
          :cost       => { stamina: 0 },
          :regex      => /\w+ adjusts? \w+(?:'s)? [\w\s]+, reinforcing weak spots\./i,
          :usage      => "reinforcement"
        },
        "armor_spike_mastery" => {
          :short_name => "spikemastery",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Armor Spike Mastery is passive and always active once learned\./i,
          :usage      => "spikemastery"
        },
        "armor_support"       => {
          :short_name => "support",
          :type       => :buff,
          :cost       => { stamina: 0 },
          :regex      => /\w+ adjusts? \w+(?:'s)? [\w\s]+, improving its ability to support the weight of \w+ gear\./i,
          :usage      => "support"
        },
        "armored_casting"     => {
          :short_name => "casting",
          :type       => :buff,
          :cost       => { stamina: 0 },
          :regex      => /\w+ adjusts? \w+(?:'s)? [\w\s]+, making it easier for \w+ to recover from failed spell casting\./i,
          :usage      => "casting"
        },
        "armored_evasion"     => {
          :short_name => "evasion",
          :type       => :buff,
          :cost       => { stamina: 0 },
          :regex      => /\w+ adjusts? \w+(?:'s)? [\w\s]+, improving its comfort and maneuverability\./i,
          :usage      => "evasion"
        },
        "armored_fluidity"    => {
          :short_name => "fluidity",
          :type       => :buff,
          :cost       => { stamina: 0 },
          :regex      => /\w+ adjusts? \w+(?:'s)? [\w\s]+, making it easier for \w+ to cast spells\./i,
          :usage      => "fluidity"
        },
        "armored_stealth"     => {
          :short_name => "stealth",
          :type       => :buff,
          :cost       => { stamina: 0 },
          :regex      => /\w+ adjusts? \w+(?:'s)? [\w\s]+ to cushion \w+ movements\./i,
          :usage      => "stealth"
        },
        "crush_protection"    => {
          :short_name => "crush",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => Regexp.union(
            /You adjust \w+(?:'s)? [\w\s]+ with your (?:cloth|leather|scale|chain|plate|accessory) armor fittings, rearranging and reinforcing the armor to better protect against crushing damage\./i,
            /You must specify an armor slot\./,
            /You don't seem to have the necessary armor fittings in hand\./
          ),
          :usage      => "crush"
        },
        "puncture_protection" => {
          :short_name => "puncture",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => Regexp.union(
            /You adjust \w+(?:'s)? [\w\s]+ with your (?:cloth|leather|scale|chain|plate|accessory) armor fittings, rearranging and reinforcing the armor to better protect against puncturing damage\./i,
            /You must specify an armor slot\./,
            /You don't seem to have the necessary armor fittings in hand\./
          ),
          :usage      => "puncture"
        },
        "slash_protection"    => {
          :short_name => "slash",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => Regexp.union(
            /You adjust \w+(?:'s)? [\w\s]+ with your (?:cloth|leather|scale|chain|plate|accessory) armor fittings, rearranging and reinforcing the armor to better protect against slashing damage\./i,
            /You must specify an armor slot\./,
            /You don't seem to have the necessary armor fittings in hand\./
          ),
          :usage      => "slash"
        }
      }

      # Returns an array of armor techniques with their long and short names and costs.
      #
      # @return [Array<Hash>] an array of hashes containing armor technique details.
      def self.armor_lookups
        @@armor_techniques.map do |long_name, psm|
          {
            long_name: long_name,
            short_name: psm[:short_name],
            cost: psm[:cost]
          }
        end
      end

      # Retrieves the armor technique associated with the given name.
      #
      # @param name [String] the name of the armor technique to retrieve.
      # @return [Hash, nil] the armor technique details or nil if not found.
      def Armor.[](name)
        return PSMS.assess(name, 'Armor')
      end

      # Checks if the specified armor technique is known and meets the minimum rank requirement.
      #
      # @param name [String] the name of the armor technique to check.
      # @param min_rank [Integer] the minimum rank required to consider the technique known.
      # @return [Boolean] true if the technique is known and meets the rank requirement, false otherwise.
      def Armor.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Armor[name] >= min_rank
      end

      # Determines if the specified armor technique can be afforded based on the forcert count.
      #
      # @param name [String] the name of the armor technique to check affordability.
      # @param forcert_count [Integer] the number of forcerts available for the check.
      # @return [Boolean] true if the technique is affordable, false otherwise.
      def Armor.affordable?(name, forcert_count: 0)
        return PSMS.assess(name, 'Armor', true, forcert_count: forcert_count)
      end

      # Checks if the specified armor technique is known, affordable, and available for use.
      #
      # @param name [String] the name of the armor technique to check availability.
      # @param min_rank [Integer] the minimum rank required to consider the technique known.
      # @param forcert_count [Integer] the number of forcerts available for the check.
      # @return [Boolean] true if the technique is available, false otherwise.
      def Armor.available?(name, min_rank: 1, forcert_count: 0)
        Armor.known?(name, min_rank: min_rank) &&
          Armor.affordable?(name, forcert_count: forcert_count) &&
          PSMS.available?(name)
      end

      # Checks if the specified armor technique's buff is currently active.
      #
      # @param name [String] the name of the armor technique to check.
      # @return [Boolean, nil] true if the buff is active, false if not, or nil if the technique does not have a buff.
      def Armor.buff_active?(name)
        return unless @@armor_techniques.fetch(PSMS.find_name(name, "Armor")[:long_name]).key?(:buff)
        Effects::Buffs.active?(@@armor_techniques.fetch(PSMS.find_name(name, "Armor")[:long_name])[:buff])
      end

      # Uses the specified armor technique on a target, if available.
      #
      # @param name [String] the name of the armor technique to use.
      # @param target [String, Integer, GameObj] the target of the armor technique.
      # @param results_of_interest [Regexp, nil] optional regex to match specific results.
      # @param forcert_count [Integer] the number of forcerts available for the use.
      # @return [String, nil] the result of the usage or nil if the technique cannot be used.
      def Armor.use(name, target = "", results_of_interest: nil, forcert_count: 0)
        return unless Armor.available?(name, forcert_count: forcert_count)

        name_normalized = PSMS.name_normal(name)
        technique = @@armor_techniques.fetch(PSMS.find_name(name_normalized, "Armor")[:long_name])
        usage = technique[:usage]
        return if usage.nil?

        in_cooldown_regex = /^#{name} is still in cooldown\./i

        results_regex = Regexp.union(
          PSMS::FAILURES_REGEXES,
          /^#{name} what\?$/i,
          in_cooldown_regex,
          technique[:regex],
          /^Roundtime: [0-9]+ sec\.$/,
          /^\w+ [a-z]+ not wearing any armor that you can work with\.$/
        )

        results_regex = Regexp.union(results_regex, results_of_interest) if results_of_interest.is_a?(Regexp)

        usage_cmd = "armor #{usage}"
        if target.is_a?(GameObj)
          usage_cmd += " ##{target.id}"
        elsif target.is_a?(Integer)
          usage_cmd += " ##{target}"
        elsif target != ""
          usage_cmd += " #{target}"
        end

        if forcert_count > 0
          usage_cmd += " forcert"
        else # if we're using forcert, we don't want to wait for rt, but we need to otherwise
          waitrt?
          waitcastrt?
        end

        usage_result = dothistimeout usage_cmd, 5, results_regex
        if usage_result == "You don't seem to be able to move to do that."
          100.times { break if clear.any? { |line| line =~ /^You regain control of your senses!$/ }; sleep 0.1 }
          usage_result = dothistimeout usage_cmd, 5, results_regex
        end
        usage_result
      end

      # Retrieves the regex pattern associated with the specified armor technique.
      #
      # @param name [String] the name of the armor technique to retrieve the regex for.
      # @return [Regexp] the regex pattern for the armor technique.
      def Armor.regexp(name)
        @@armor_techniques.fetch(PSMS.find_name(name, "Armor")[:long_name])[:regex]
      end

      Armor.armor_lookups.each { |armor|
        self.define_singleton_method(armor[:short_name]) do
          Armor[armor[:short_name]]
        end

        self.define_singleton_method(armor[:long_name]) do
          Armor[armor[:short_name]]
        end
      }
    end
  end
end
