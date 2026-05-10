# The Lich module contains all the components related to the Lich game.
# @example Including the Lich module
#   include Lich
module Lich
  # The Gemstone module contains functionalities related to gemstones in the Lich game.
  # @example Including the Gemstone module
  #   include Lich::Gemstone
  module Gemstone
    # The Shield module provides various techniques and functionalities related to shields.
    # @example Including the Shield module
    #   include Lich::Gemstone::Shield
    module Shield
      @@shield_techniques = {
        "adamantine_bulwark"    => {
          :short_name => "bulwark",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Adamantine Bulwark does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "block_specialization"  => {
          :short_name => "blockspec",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /The Block Specialization combat maneuver is always active once you have learned it\./,
          :usage      => nil
        },
        "block_the_elements"    => {
          :short_name => "blockelements",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Block the Elements does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "deflect_magic"         => {
          :short_name => "deflectmagic",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Deflect Magic does not need to be activated once you have learned it\.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization\./,
          :usage      => nil
        },
        "deflect_missiles"      => {
          :short_name => "deflectmissiles",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Deflect Missiles does not need to be activated once you have learned it\.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization\./,
          :usage      => nil
        },
        "deflect_the_elements"  => {
          :short_name => "deflectelements",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Deflect the Elements does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "disarming_presence"    => {
          :short_name => "dpresence",
          :type       => :martial_stance,
          :cost       => { stamina: 20 },
          :regex      => Regexp.union(/You assume the Disarming Presence Stance, adjusting your footing and grip to allow for the proper pivot and thrust technique to disarm attacking foes\./,
                                      /You re\-settle into the Disarming Presence Stance, re-ensuring your footing and grip are properly positioned\./),
          :usage      => "dpresence"
        },
        "guard_mastery"         => {
          :short_name => "gmastery",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Guard Mastery does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "large_shield_focus"    => {
          :short_name => "lfocus",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Large Shield Focus does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "medium_shield_focus"   => {
          :short_name => "mfocus",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Medium Shield Focus does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "phalanx"               => {
          :short_name => "phalanx",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Phalanx does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "prop_up"               => {
          :short_name => "prop",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Prop Up does not need to be activated once you have learned it\.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization\./,
          :usage      => nil
        },
        "protective_wall"       => {
          :short_name => "pwall",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Protective Wall does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "shield_bash"           => {
          :short_name => "bash",
          :type       => :setup,
          :cost       => { stamina: 9 },
          :regex      => /You lunge forward at .+ with your .+ and attempt a shield bash\!/,
          :usage      => "bash"
        },
        "shield_charge"         => {
          :short_name => "charge",
          :type       => :setup,
          :cost       => { stamina: 14 },
          :regex      => /You charge forward at .+ with your .+ and attempt a shield charge\!/,
          :usage      => "charge"
        },
        "shield_forward"        => {
          :short_name => "forward",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Shield Forward does not need to be activated once you have learned it\.  It will automatically activate upon the use of a shield attack\./,
          :usage      => "forward"
        },
        "shield_mind"           => {
          :short_name => "mind",
          :type       => :buff,
          :cost       => { stamina: 10 },
          :regex      => /You must be wielding an ensorcelled or anti-magical shield to be able to properly shield your mind and soul\./,
          :usage      => "mind"
        },
        "shield_pin"            => {
          :short_name => "pin",
          :type       => :attack,
          :cost       => { stamina: 15 },
          :regex      => /You attempt to expose a vulnerability with a diversionary shield bash on .+\!/,
          :usage      => "pin"
        },
        "shield_push"           => {
          :short_name => "push",
          :type       => :setup,
          :cost       => { stamina: 7 },
          :regex      => /You raise your .+ before you and attempt to push .+ away\!/,
          :usage      => "push"
        },
        "shield_riposte"        => {
          :short_name => "riposte",
          :type       => :martial_stance,
          :cost       => { stamina: 20 },
          :regex      => Regexp.union(/You assume the Shield Riposte Stance, preparing yourself to lash out at a moment's notice\./,
                                      /You re\-settle into the Shield Riposte Stance, preparing yourself to lash out at a moment's notice\./),
          :usage      => "riposte"
        },
        "shield_spike_mastery"  => {
          :short_name => "spikemastery",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Shield Spike Mastery does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "shield_strike"         => {
          :short_name => "strike",
          :type       => :attack,
          :cost       => { stamina: 15 },
          :regex      => /You launch a quick bash with your .+ at .+\!/,
          :usage      => "strike"
        },
        "shield_strike_mastery" => {
          :short_name => "strikemastery",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Shield Strike Mastery does not need to be activated once you have learned it\.  It will automatically apply to all relevant focused multi\-attacks, provided that you maintain the prerequisite ranks of Shield Bash\./,
          :usage      => nil
        },
        "shield_swiftness"      => {
          :short_name => "swiftness",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Shield Swiftness does not need to be activated once you have learned it\.  It will automatically apply to all relevant attacks, provided that you are wielding a small or medium shield and have at least 3 ranks of the relevant Shield Focus specialization\./,
          :usage      => nil
        },
        "shield_throw"          => {
          :short_name => "throw",
          :type       => :area_of_effect,
          :cost       => { stamina: 20 },
          :regex      => /You snap your arm forward, hurling your .+ at .+ with all your might\!/,
          :usage      => "throw"
        },
        "shield_trample"        => {
          :short_name => "trample",
          :type       => :area_of_effect,
          :cost       => { stamina: 14 },
          :regex      => /You raise your .+ before you and charge headlong towards .+\!/,
          :usage      => "trample"
        },
        "shielded_brawler"      => {
          :short_name => "brawler",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Shielded Brawler does not need to be activated once you have learned it\.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization\./,
          :usage      => nil
        },
        "small_shield_focus"    => {
          :short_name => "sfocus",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Small Shield Focus does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./,
          :usage      => nil
        },
        "spell_block"           => {
          :short_name => "spellblock",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Spell Block does not need to be activated once you have learned it\.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization\./,
          :usage      => nil
        },
        "steady_shield"         => {
          :short_name => "steady",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Steady Shield does not need to be activated once you have learned it\.  It will automatically apply to all relevant attacks against you, provided that you maintain the prerequisite ranks of Stun Maneuvers\./,
          :usage      => nil
        },
        "steely_resolve"        => {
          :short_name => "resolve",
          :type       => :buff,
          :cost       => { stamina: 30 },
          :regex      => Regexp.union(/You focus your mind in a steely resolve to block all attacks against you\./,
                                      /You are still mentally fatigued from your last invocation of your Steely Resolve\./),
          :usage      => "resolve"
        },
        "tortoise_stance"       => {
          :short_name => "tortoise",
          :type       => :martial_stance,
          :cost       => { stamina: 20 },
          :regex      => Regexp.union(/You assume the Stance of the Tortoise, holding back some of your offensive power in order to maximize your defense\./,
                                      /You re\-settle into the Stance of the Tortoise, holding back your offensive power in order to maximize your defense\./),
          :usage      => "tortoise"
        },
        "tower_shield_focus"    => {
          :short_name => "tfocus",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Tower Shield Focus does not need to be activated\.  If you are wielding the appropriate type of shield, it will always be active\./i,
          :usage      => nil
        }
      }

      # Retrieves a list of shield techniques with their long and short names and costs.
      # @return [Array<Hash>] An array of hashes containing shield technique details.
      # @example Retrieving shield lookups
      #   techniques = Shield.shield_lookups
      def self.shield_lookups
        @@shield_techniques.map do |long_name, psm|
          {
            long_name: long_name,
            short_name: psm[:short_name],
            cost: psm[:cost]
          }
        end
      end

      # Retrieves a shield technique by its name.
      # @param name [String] The name of the shield technique.
      # @return [Hash, nil] The shield technique details or nil if not found.
      # @example Accessing a shield technique
      #   technique = Shield["shield_bash"]
      def Shield.[](name)
        return PSMS.assess(name, 'Shield')
      end

      # Checks if a shield technique is known and meets the minimum rank requirement.
      # @param name [String] The name of the shield technique.
      # @param min_rank [Integer] The minimum rank required to consider the technique known.
      # @return [Boolean] True if known and meets the rank requirement, false otherwise.
      # @example Checking if a technique is known
      #   known = Shield.known?("shield_bash", 1)
      def Shield.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Shield[name] >= min_rank
      end

      # Determines if a shield technique can be afforded based on the current conditions.
      # @param name [String] The name of the shield technique.
      # @param forcert_count [Integer] The count of forcerts available.
      # @return [Boolean] True if the technique is affordable, false otherwise.
      # @example Checking affordability
      #   affordable = Shield.affordable?("shield_bash", 2)
      def Shield.affordable?(name, forcert_count: 0)
        return true if @@shield_techniques.fetch(PSMS.find_name(name, "Shield")[:long_name])[:type] == :area_of_effect && Effects::Buffs.active?("Glorious Momentum")
        return PSMS.assess(name, 'Shield', true, forcert_count: forcert_count)
      end

      # Checks if a shield technique is available for use based on known status, affordability, and availability.
      # @param name [String] The name of the shield technique.
      # @param min_rank [Integer] The minimum rank required to consider the technique available.
      # @param forcert_count [Integer] The count of forcerts available.
      # @return [Boolean] True if the technique is available, false otherwise.
      # @example Checking availability
      #   available = Shield.available?("shield_bash", 1, 0)
      def Shield.available?(name, min_rank: 1, forcert_count: 0)
        Shield.known?(name, min_rank: min_rank) &&
          Shield.affordable?(name, forcert_count: forcert_count) &&
          PSMS.available?(name)
      end

      # Checks if a buff related to a shield technique is currently active.
      # @param name [String] The name of the shield technique.
      # @return [Boolean, nil] True if the buff is active, false if not, nil if no buff exists.
      # @example Checking if a buff is active
      #   active = Shield.buff_active?("shield_bash")
      def Shield.buff_active?(name)
        return unless @@shield_techniques.fetch(PSMS.find_name(name, "Shield")[:long_name]).key?(:buff)
        Effects::Buffs.active?(@@shield_techniques.fetch(PSMS.find_name(name, "Shield")[:long_name])[:buff])
      end

      # Uses a shield technique on a target, processing the action and returning the result.
      # @param name [String] The name of the shield technique to use.
      # @param target [String, GameObj, Integer] The target of the technique.
      # @param results_of_interest [Regexp, nil] Additional regex to match results of interest.
      # @param forcert_count [Integer] The count of forcerts available.
      # @return [String, nil] The result of the technique use or nil if it cannot be used.
      # @example Using a shield technique
      #   result = Shield.use("shield_bash", "enemy")
      def Shield.use(name, target = "", results_of_interest: nil, forcert_count: 0)
        return unless Shield.available?(name, forcert_count: forcert_count)

        name_normalized = PSMS.name_normal(name)
        technique = @@shield_techniques.fetch(PSMS.find_name(name_normalized, "Shield")[:long_name])
        usage = technique[:usage]
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

        usage_cmd = "shield #{usage}"
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

      # Retrieves the regular expression associated with a shield technique.
      # @param name [String] The name of the shield technique.
      # @return [Regexp] The regex pattern for the technique.
      # @example Getting the regex for a technique
      #   regex = Shield.regexp("shield_bash")
      def Shield.regexp(name)
        @@shield_techniques.fetch(PSMS.find_name(name, "Shield")[:long_name])[:regex]
      end

      Shield.shield_lookups.each { |shield|
        self.define_singleton_method(shield[:short_name]) do
          Shield[shield[:short_name]]
        end

        self.define_singleton_method(shield[:long_name]) do
          Shield[shield[:short_name]]
        end
      }
    end
  end
end
