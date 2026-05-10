# Provides functionality related to the Lich game framework.
#
# @see Lich::Gemstone for gemstone-related features.
module Lich
  module Gemstone
    # Contains features (feats) that can be used in the game.
    #
    # This module manages the feats available to characters, including their properties and usage.
    module Feat
      @@feats = {
        "absorb_magic"              => {
          :short_name => "absorbmagic",
          :type       => :buff,
          :cost       => { stamina: 0 },
          :regex      => Regexp.union(/You open yourself to the ravenous void at the core of your being, allowing it to surface\.  Muted veins of metallic grey ripple just beneath your skin\./,
                                      /You strain, but the void within remains stubbornly out of reach\.  You need more time\./),
          :usage      => "absorbmagic"
        },
        "chain_armor_proficiency"   => {
          :short_name => "chainarmor",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Chain Armor Proficiency is passive and cannot be activated\./,
          :usage      => nil
        },
        "chastise"                  => {
          :short_name => "chastise",
          :type       => :attack,
          :cost       => { stamina: 10 },
          :regex      => /as you lunge at .+? in a quick and vicious strike!$/,
          :usage      => "chastise"
        },
        "combat_mastery"            => {
          :short_name => "combatmastery",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Combat Mastery is passive and cannot be activated\./,
          :usage      => nil
        },
        "covert_art_escape_artist"  => {
          :short_name => "escapeartist",
          :type       => :reaction,
          :cost       => { stamina: 0 },
          :regex      => Regexp.union(/You roll your shoulders and subtly test the flexion of your joints, staying limber for ready escapes\./,
                                      /You were unable to find any targets that meet Covert Art\: Escape Artist's reaction requirements\./),
          :usage      => "escapeartist"
        },
        "covert_art_keen_eye"       => {
          :short_name => "keeneye",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Covert Art\: Keen Eye is always active as long as you stay up to date on training\./,
          :usage      => nil
        },
        "covert_art_poisoncraft"    => {
          :short_name => "poisoncraft",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /USAGE\: FEAT POISONCRAFT \{options\} \[args\]/,
          :usage      => nil
        },
        "covert_art_sidestep"       => {
          :short_name => "sidestep",
          :type       => :buff,
          :cost       => { stamina: 10 },
          :regex      => /You tread lightly and keep your head on a swivel, prepared to sidestep any loose salvos that might stray your way\./,
          :usage      => "sidestep"
        },
        "covert_art_swift_recovery" => {
          :short_name => "swiftrecovery",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Covert Art\: Swift Recovery is always active as long as you stay up to date on training\./,
          :usage      => nil
        },
        "covert_art_throw_poison"   => {
          :short_name => "throwpoison",
          :type       => :attack,
          :cost       => { stamina: 15 },
          :regex      => Regexp.union(/What did the .+ ever do to you\?/,
                                      /You pop the cork on .+ and, with a nimble flick of the wrist, fling a portion of its contents in a wide arc\!/,
                                      /Covert Art\: Throw Poison what\?/),
          :usage      => "throwpoison"
        },
        "covert_arts"               => {
          :short_name => "covert",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /USAGE\: FEAT COVERT \{options\} \[args\]/,
          :usage      => nil
        },
        "critical_counter"          => {
          :short_name => "criticalcounter",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Critical Counter is passive and cannot be activated\./,
          :usage      => nil
        },
        "dispel_magic"              => {
          :short_name => "dispelmagic",
          :type       => :buff,
          :cost       => { stamina: 30 },
          :regex      => Regexp.union(/You reach for the emptiness within, but there are no spells afflicting you to dispel\./,
                                      /You reach for the emptiness within\.  A single, hollow note reverberates through your core, resonating outward and scouring away the energies that cling to you\./),
          :usage      => "dispelmagic"
        },
        "dragonscale_skin"          => {
          :short_name => "dragonscaleskin",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /The Dragonscale Skin\s{1,2}feat is always active once you have learned it\./,
          :usage      => nil
        },
        "excoriate"                 => {
          :short_name => "excoriate",
          :type       => :attack,
          :cost       => { mana: 10 },
          :regex      => /You level your .+? at .+? and call down the excoriating power of .+? to smite (?:him|her|it)!/,
          :usage      => "excoriate"
        },
        "guard"                     => {
          :short_name => "guard",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => Regexp.union(/Guard what\?/,
                                      /You move over to .+ and prepare to guard [a-z]+ from attack\./,
                                      /You stop guarding .+, move over to .+, and prepare to guard [a-z]+ from attack\./,
                                      /You stop protecting .+, move over to .+, and prepare to guard [a-z]+ from attack\./,
                                      /You stop protecting .+ and prepare to guard [a-z]+ instead\./,
                                      /You are already guarding .+\./),
          :usage      => "guard"
        },
        "kroderine_soul"            => {
          :short_name => "kroderinesoul",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Kroderine Soul is passive and always active as long as you do not learn any spells\.  You have access to two new abilities\:/,
          :usage      => nil
        },
        "light_armor_proficiency"   => {
          :short_name => "lightarmor",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Light Armor Proficiency is passive and cannot be activated\./,
          :usage      => nil
        },
        "martial_arts_mastery"      => {
          :short_name => "martialarts",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Martial Arts Mastery is passive and cannot be activated\./,
          :usage      => nil
        },
        "martial_mastery"           => {
          :short_name => "martialmastery",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Martial Mastery is passive and cannot be activated\./,
          :usage      => nil
        },
        "mental_acuity"             => {
          :short_name => "mentalacuity",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /The Mental Acuity\s{1,2}feat is always active once you have learned it\./,
          :usage      => nil
        },
        "mystic_strike"             => {
          :short_name => "mysticstrike",
          :type       => :buff,
          :cost       => { stamina: 10 },
          :regex      => /You prepare yourself to deliver a Mystic Strike with your next attack\./,
          :usage      => "mysticstrike"
        },
        "mystic_tattoo"             => {
          :short_name => "tattoo",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Usage\:/,
          :usage      => nil
        },
        "perfect_self"              => {
          :short_name => "perfectself",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /The Perfect Self feat is always active once you have learned it\.  It provides a constant enhancive bonus to all your stats\./,
          :usage      => nil
        },
        "plate_armor_proficiency"   => {
          :short_name => "platearmor",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Plate Armor Proficiency is passive and cannot be activated\./,
          :usage      => nil
        },
        "protect"                   => {
          :short_name => "protect",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => Regexp.union(/Protect what\?/,
                                      /You move over to .+ and prepare to protect [a-z]+ from attack\./,
                                      /You stop protecting .+, move over to .+, and prepare to protect [a-z]+ from attack\./,
                                      /You stop guarding .+, move over to .+, and prepare to protect [a-z]+ from attack\./,
                                      /You stop guarding .+ and prepare to protect [a-z]+ instead\./,
                                      /You are already protecting .+\./),
          :usage      => "protect"
        },
        "scale_armor_proficiency"   => {
          :short_name => "scalearmor",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /Scale Armor Proficiency is passive and cannot be activated\./,
          :usage      => nil
        },
        "shadow_dance"              => {
          :short_name => "shadowdance",
          :type       => :buff,
          :cost       => { stamina: 30 },
          :regex      => /You focus your mind and body on the shadows\./,
          :usage      => nil
        },
        "silent_strike"             => {
          :short_name => "silentstrike",
          :type       => :attack,
          :cost       => { stamina: 20 },
          :regex      => Regexp.union(/Silent Strike can not be used with fire as the attack type\./,
                                      /You quickly leap from hiding to attack\!/),
          :usage      => "silentstrike"
        },
        "vanish"                    => {
          :short_name => "vanish",
          :type       => :buff,
          :cost       => { stamina: 30 },
          :regex      => /With subtlety and speed, you aim to clandestinely vanish into the shadows\./,
          :usage      => "vanish"
        },
        "weapon_bonding"            => {
          :short_name => "weaponbonding",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /USAGE\:/,
          :usage      => nil
        },
        "weighting"                 => {
          :short_name => "wps",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /USAGE\: FEAT WPS \{options\} \[args\]/,
          :usage      => nil
        },
        "padding"                   => {
          :short_name => "wps",
          :type       => :passive,
          :cost       => { stamina: 0 },
          :regex      => /USAGE\: FEAT WPS \{options\} \[args\]/,
          :usage      => nil
        }
      }

      # Returns a list of all feats with their long and short names and costs.
      # @return [Array<Hash>] an array of hashes containing feat details
      # @example Get all feats
      #   feats = Feat.feat_lookups
      def self.feat_lookups
        @@feats.map do |long_name, psm|
          {
            long_name: long_name,
            short_name: psm[:short_name],
            cost: psm[:cost]
          }
        end
      end

      # Retrieves a feat by its name.
      # @param name [String] the name of the feat to retrieve
      # @return [Hash, nil] the feat details or nil if not found
      # @example Get a specific feat
      #   feat = Feat["absorb_magic"]
      def Feat.[](name)
        return PSMS.assess(name, 'Feat')
      end

      # Checks if a feat is known by the character and meets the minimum rank requirement.
      # @param name [String] the name of the feat to check
      # @param min_rank [Integer] the minimum rank required to consider the feat known
      # @return [Boolean] true if the feat is known and meets the rank requirement, false otherwise
      # @example Check if a feat is known
      #   known = Feat.known?("absorb_magic", 1)
      def Feat.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Feat[name] >= min_rank
      end

      # Determines if a feat can be afforded based on the current resources.
      # @param name [String] the name of the feat to check
      # @param forcert_count [Integer] the number of forcerts available
      # @return [Boolean] true if the feat is affordable, false otherwise
      # @example Check if a feat is affordable
      #   affordable = Feat.affordable?("chastise", 1)
      def Feat.affordable?(name, forcert_count: 0)
        return PSMS.assess(name, 'Feat', true, forcert_count: forcert_count)
      end

      # Checks if a feat is available for use based on known status, affordability, and availability.
      # @param name [String] the name of the feat to check
      # @param min_rank [Integer] the minimum rank required to consider the feat available
      # @param forcert_count [Integer] the number of forcerts available
      # @return [Boolean] true if the feat is available, false otherwise
      # @example Check if a feat is available
      #   available = Feat.available?("absorb_magic", 1, 0)
      def Feat.available?(name, min_rank: 1, forcert_count: 0)
        Feat.known?(name, min_rank: min_rank) &&
          Feat.affordable?(name, forcert_count: forcert_count) &&
          PSMS.available?(name)
      end

      # Checks if a buff feat is currently active.
      # @param name [String] the name of the buff feat to check
      # @return [Boolean, nil] true if the buff is active, false if not, or nil if the feat is not found
      # @example Check if a buff is active
      #   active = Feat.buff_active?("mysticstrike")
      def Feat.buff_active?(name)
        return unless @@feats.fetch(PSMS.find_name(name, "Feat")[:long_name]).key?(:buff)
        Effects::Buffs.active?(@@feats.fetch(PSMS.find_name(name, "Feat")[:long_name])[:buff])
      end

      # Uses a feat on a target, processing the action and returning the result.
      # @param name [String] the name of the feat to use
      # @param target [String, Integer] the target of the feat
      # @param results_of_interest [Regexp, nil] additional regex patterns to match results
      # @param forcert_count [Integer] the number of forcerts to use
      # @return [String, nil] the result of using the feat or nil if not available
      # @example Use a feat on a target
      #   result = Feat.use("chastise", "enemy")
      def Feat.use(name, target = "", results_of_interest: nil, forcert_count: 0)
        return unless Feat.available?(name, forcert_count: forcert_count)

        name_normalized = PSMS.name_normal(name)
        technique = @@feats.fetch(PSMS.find_name(name_normalized, "Feat")[:long_name])
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

        usage_cmd = (['guard', 'protect'].include?(usage) ? "#{usage}" : "feat #{usage}")
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

      # Retrieves the regex pattern associated with a feat.
      # @param name [String] the name of the feat to retrieve the regex for
      # @return [Regexp] the regex pattern for the feat
      # @example Get the regex for a feat
      #   pattern = Feat.regexp("absorb_magic")
      def Feat.regexp(name)
        @@feats.fetch(PSMS.find_name(name, "Feat")[:long_name])[:regex]
      end

      Feat.feat_lookups.each { |feat|
        self.define_singleton_method(feat[:short_name]) do
          Feat[feat[:short_name]]
        end

        self.define_singleton_method(feat[:long_name]) do
          Feat[feat[:short_name]]
        end
      }
    end
  end
end
