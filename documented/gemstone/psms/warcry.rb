module Lich
  module Gemstone
    # Represents a Warcry in the Lich Gemstone module.
    # This class manages various warcries, their properties, and actions.
    # @example Accessing warcry information
    #   Warcry.warcry_lookups
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
      # @return [Array<Hash>] An array of hashes containing warcry details.
      # @example
      #   Warcry.warcry_lookups.each do |warcry|
      #     puts warcry[:long_name]
      #   end
      def self.warcry_lookups
        @@warcries.map do |long_name, psm|
          {
            long_name: long_name,
            short_name: psm[:short_name],
            cost: psm[:cost]
          }
        end
      end

      # Retrieves a warcry by its name.
      # @param name [String] The name of the warcry to retrieve.
      # @return [Hash, nil] The warcry details or nil if not found.
      # @example
      #   warcry = Warcry["bertrandts_bellow"]
      def Warcry.[](name)
        return PSMS.assess(name, 'Warcry')
      end

      # Checks if a warcry is known and meets the minimum rank requirement.
      # @param name [String] The name of the warcry to check.
      # @param min_rank [Integer] The minimum rank to check against (default is 1).
      # @return [Boolean] True if known and meets rank, false otherwise.
      # @example
      #   Warcry.known?("bertrandts_bellow", 2)
      def Warcry.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Warcry[name] >= min_rank
      end

      # Determines if a warcry can be afforded based on the current stamina.
      # @param name [String] The name of the warcry to check.
      # @param forcert_count [Integer] The number of forcerts used (default is 0).
      # @return [Boolean] True if affordable, false otherwise.
      # @example
      #   Warcry.affordable?("bertrandts_bellow")
      def Warcry.affordable?(name, forcert_count: 0)
        return PSMS.assess(name, 'Warcry', true, forcert_count: forcert_count)
      end

      # Checks if a warcry is available based on knowledge, affordability, and availability.
      # @param name [String] The name of the warcry to check.
      # @param min_rank [Integer] The minimum rank to check against (default is 1).
      # @param forcert_count [Integer] The number of forcerts used (default is 0).
      # @return [Boolean] True if available, false otherwise.
      # @example
      #   Warcry.available?("bertrandts_bellow")
      def Warcry.available?(name, min_rank: 1, forcert_count: 0)
        Warcry.known?(name, min_rank: min_rank) &&
          Warcry.affordable?(name, forcert_count: forcert_count) &&
          PSMS.available?(name)
      end

      # Checks if a buff from a warcry is currently active.
      # @param name [String] The name of the warcry to check.
      # @return [Boolean] True if the buff is active, false otherwise.
      # @note This method is deprecated; use Warcry.buff_active? instead.
      def Warcry.buffActive?(name)
        ### DEPRECATED ###
        Lich.deprecated("Warcry.buffActive?", "Warcry.buff_active?", caller[0], fe_log: false)
        buff_active?(name)
      end

      # Checks if the specified warcry's buff is currently active.
      # @param name [String] The name of the warcry to check.
      # @return [Boolean] True if the buff is active, false otherwise.
      # @example
      #   Warcry.buff_active?("bertrandts_bellow")
      def Warcry.buff_active?(name)
        buff = @@warcries.fetch(PSMS.find_name(name, "Warcry")[:long_name])[:buff]
        return false if buff.nil?
        Lich::Util.normalize_lookup('Buffs', buff)
      end

      # Uses a warcry on a target, executing the associated action.
      # @param name [String] The name of the warcry to use.
      # @param target [String, Integer, GameObj] The target of the warcry.
      # @param results_of_interest [Regexp, nil] Optional regex to match specific results.
      # @param forcert_count [Integer] The number of forcerts used (default is 0).
      # @return [String, nil] The result of the warcry action or nil if not executed.
      # @example
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

      # Retrieves the regex pattern associated with a warcry.
      # @param name [String] The name of the warcry to retrieve the regex for.
      # @return [Regexp] The regex pattern for the warcry.
      # @example
      #   regex = Warcry.regexp("bertrandts_bellow")
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
