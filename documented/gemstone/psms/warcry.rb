module Lich
  module Gemstone
    # Represents a Warcry in the Lich Gemstone module.
    #
    # This class manages various warcries, their properties, and actions.
    #
    # @see Lich::Gemstone
    class Warcry
      @@warcries = {
        "bertrandts_bellow" => {
          :long_name  => "bertrandts_bellow",
          :short_name => "bellow",
          :type       => :setup,
          :cost       => { stamina: 20 }, # @todo only 10 for single
          :regex      => /You glare at .+ and let out a nerve-shattering bellow!/,
        },
        "yerties_yowlp"     => {
          :long_name  => "yerties_yowlp",
          :short_name => "yowlp",
          :type       => :buff,
          :cost       => { stamina: 20 },
          :regex      => /You throw back your shoulders and let out a resounding yowlp!/,
          :buff       => "Yertie's Yowlp",
        },
        "gerrelles_growl"   => {
          :long_name  => "gerrelles_growl",
          :short_name => "growl",
          :type       => :setup,
          :cost       => { stamina: 14 }, # @todo only 7 for single
          :regex      => /Your face contorts as you unleash a guttural, deep-throated growl at .+!/,
        },
        "seanettes_shout"   => {
          :long_name  => "seanettes_shout",
          :short_name => "shout",
          :type       => :buff,
          :cost       => { stamina: 20 },
          :regex      => /You let loose an echoing shout!/,
          :buff       => 'Empowered (+20)',
        },
        "carns_cry"         => {
          :long_name  => "carns_cry",
          :short_name => "cry",
          :type       => :setup,
          :cost       => { stamina: 20 },
          :regex      => /You stare down .+ and let out an eerie, modulating cry!/,
        },
        "horlands_holler"   => {
          :long_name  => "horlands_holler",
          :short_name => "holler",
          :type       => :buff,
          :cost       => { stamina: 20 },
          :regex      => /You throw back your head and let out a thundering holler!/,
          :buff       => 'Enh. Health (+20)',
        },
      }

      # Returns a list of warcry lookups with their long and short names and costs.
      # @return [Array<Hash>] an array of hashes containing warcry details
      # @example Get warcry lookups
      #   Warcry.warcry_lookups
      def self.warcry_lookups
        @@warcries.map do |long_name, psm|
          {
            long_name: long_name,
            short_name: psm[:short_name],
            cost: psm[:cost]
          }
        end
      end

      # Retrieves the warcry associated with the given name.
      # @param name [String] the name of the warcry to retrieve
      # @return [Integer, nil] the rank of the warcry or nil if not found
      # @example Get a warcry by name
      #   Warcry["bertrandts_bellow"]
      def Warcry.[](name)
        return PSMS.assess(name, 'Warcry')
      end

      # Checks if a warcry is known and meets the minimum rank requirement.
      # @param name [String] the name of the warcry to check
      # @param min_rank [Integer] the minimum rank to check against (default is 1)
      # @return [Boolean] true if known and meets rank, false otherwise
      # @example Check if a warcry is known
      #   Warcry.known?("bertrandts_bellow", 1)
      def Warcry.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Warcry[name] >= min_rank
      end

      # Determines if a warcry can be afforded based on the current stamina and forcert count.
      # @param name [String] the name of the warcry to check
      # @param forcert_count [Integer] the number of forcerts available (default is 0)
      # @return [Boolean] true if affordable, false otherwise
      # @example Check if a warcry is affordable
      #   Warcry.affordable?("bertrandts_bellow")
      def Warcry.affordable?(name, forcert_count: 0)
        return PSMS.assess(name, 'Warcry', true, forcert_count: forcert_count)
      end

      # Checks if a warcry is known, affordable, and available for use.
      # @param name [String] the name of the warcry to check
      # @param min_rank [Integer] the minimum rank to check against (default is 1)
      # @param forcert_count [Integer] the number of forcerts available (default is 0)
      # @return [Boolean] true if available, false otherwise
      # @example Check if a warcry is available
      #   Warcry.available?("bertrandts_bellow")
      def Warcry.available?(name, min_rank: 1, forcert_count: 0)
        Warcry.known?(name, min_rank: min_rank) &&
          Warcry.affordable?(name, forcert_count: forcert_count) &&
          PSMS.available?(name)
      end

      # Checks if the specified warcry buff is currently active.
      # @param name [String] the name of the warcry to check
      # @return [Boolean] true if the buff is active, false otherwise
      # @deprecated Use #buff_active? instead.
      def Warcry.buffActive?(name)
        ### DEPRECATED ###
        Lich.deprecated("Warcry.buffActive?", "Warcry.buff_active?", caller[0], fe_log: false)
        buff_active?(name)
      end

      # Checks if the specified warcry buff is currently active.
      # @param name [String] the name of the warcry to check
      # @return [Boolean] true if the buff is active, false otherwise
      # @example Check if a warcry buff is active
      #   Warcry.buff_active?("bertrandts_bellow")
      def Warcry.buff_active?(name)
        buff = @@warcries.fetch(PSMS.find_name(name, "Warcry")[:long_name])[:buff]
        return false if buff.nil?
        Lich::Util.normalize_lookup('Buffs', buff)
      end

      # Uses the specified warcry on a target, if available and not on cooldown.
      # @param name [String] the name of the warcry to use
      # @param target [String, Integer] the target of the warcry (optional)
      # @param results_of_interest [Regexp, nil] additional regex patterns to match results (optional)
      # @param forcert_count [Integer] the number of forcerts available (default is 0)
      # @return [String, nil] the result of the warcry usage or nil if not used
      # @example Use a warcry
      #   Warcry.use("bertrandts_bellow", "target_name")
      def Warcry.use(name, target = "", results_of_interest: nil, forcert_count: 0)
        return unless Warcry.available?(name, forcert_count: forcert_count)
        return if Warcry.buff_active?(name)

        name_normalized = PSMS.name_normal(name)
        technique = @@warcries.fetch(PSMS.find_name(name_normalized, "Warcry")[:long_name])
        usage = name_normalized
        return if usage.nil?

        in_cooldown_regex = /^#{name} is still in cooldown\./i

        results_regex = Regexp.union(
          PSMS::FAILURES_REGEXES,
          /^#{name} what\?$/i,
          in_cooldown_regex,
          technique[:regex],
          /^Roundtime: [0-9]+ sec\.$/,
        )

        results_regex = Regexp.union(results_regex, results_of_interest) if results_of_interest.is_a?(Regexp)

        usage_cmd = "warcry #{usage}"
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

        usage_result = dothistimeout(usage_cmd, 5, results_regex)
        if usage_result == "You don't seem to be able to move to do that."
          100.times { break if clear.any? { |line| line =~ /^You regain control of your senses!$/ }; sleep 0.1 }
          usage_result = dothistimeout(usage_cmd, 5, results_regex)
        end
        usage_result
      end

      # Retrieves the regex pattern associated with the specified warcry name.
      # @param name [String] the name of the warcry to retrieve the regex for
      # @return [Regexp] the regex pattern for the warcry
      # @example Get the regex for a warcry
      #   Warcry.regexp("bertrandts_bellow")
      def Warcry.regexp(name)
        @@warcries.fetch(PSMS.find_name(name, "Warcry")[:long_name])[:regex]
      end

      Warcry.warcry_lookups.each { |warcry|
        self.define_singleton_method(warcry[:short_name]) do
          Warcry[warcry[:short_name]]
        end

        self.define_singleton_method(warcry[:long_name]) do
          Warcry[warcry[:short_name]]
        end
      }
    end
  end
end
