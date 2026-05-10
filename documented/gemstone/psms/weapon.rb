# Contains the Lich game logic.
#
# @see Lich::Gemstone
module Lich
  module Gemstone
    # Provides weapon techniques and their management.
    #
    # This module includes various weapon techniques used in the game.
    module Weapon
      @@weapon_techniques = {
        "barrage"          => {
          :short_name => "barrage",
          :type       => :assault,
          :cost       => { stamina: 15 },
          :regex      => /Drawing several (?:arrows|bolts) from your .+, you grip them loosely between your fingers in preparation for a rapid barrage\./,
          :assault_rx => /Your satisfying display of dexterity bolsters you and inspires those around you\!/,
          :buff       => "Enh. Dexterity (+10)"
        },
        "charge"           => {
          :short_name => "charge",
          :type       => :setup,
          :cost       => { stamina: 14 },
          :regex      => /You rush forward at .+ with your .+ and attempt a charge\!/
        },
        "clash"            => {
          :short_name => "clash",
          :type       => :area_of_effect,
          :cost       => { stamina: 20 },
          :regex      => /Steeling yourself for a brawl, you plunge into the fray\!/
        },
        "clobber"          => {
          :short_name => "clobber",
          :type       => :reaction,
          :cost       => { stamina: 0 },
          :regex      => /You redirect the momentum of your parry, hauling your .+ around to clobber .+\!/
        },
        "cripple"          => {
          :short_name => "cripple",
          :type       => :setup,
          :cost       => { stamina: 7 },
          :regex      => /You reverse your grip on your .+ and dart toward .+ at an angle\!/
        },
        "cyclone"          => {
          :short_name => "cyclone",
          :type       => :area_of_effect,
          :cost       => { stamina: 20 },
          :regex      => /You weave your .+ in an under arm spin, swiftly picking up speed until it becomes a blurred cyclone of .+\!/
        },
        "dizzying_swing"   => {
          :short_name => "dizzyingswing",
          :type       => :setup,
          :cost       => { stamina: 7 },
          :regex      => /You heft your .+ and, looping it once to build momentum, lash out in a strike at .+ head\!/,
          :usage      => "dizzyingswing"
        },
        "flurry"           => {
          :short_name => "flurry",
          :type       => :assault,
          :cost       => { stamina: 15 },
          :regex      => /You rotate your wrist, your .+ executing a casual spin to establish your flow as you advance upon .+\!/,
          :assault_rx => /The mesmerizing sway of body and blade glides to its inevitable end with one final twirl of your .+\!/,
          :buff       => "Slashing Strikes"
        },
        "fury"             => {
          :short_name => "fury",
          :type       => :assault,
          :cost       => { stamina: 15 },
          :regex      => /With a percussive snap, you shake out your arms in quick succession and bear down on .+ in a fury\!/,
          :assault_rx => /Your furious assault bolsters you and inspires those around you\!/,
          :buff       => "Enh. Constitution (+10)"
        },
        "guardant_thrusts" => {
          :short_name => "gthrusts",
          :type       => :assault,
          :cost       => { stamina: 15 },
          :regex      => /Retaining a defensive profile, you raise your .+ in a hanging guard and prepare to unleash a barrage of guardant thrusts upon .+\!/,
          :usage      => "gthrusts"
        },
        "overpower"        => {
          :short_name => "overpower",
          :type       => :reaction,
          :cost       => { stamina: 0 },
          :regex      => /On the heels of .+ parry, you erupt into motion, determined to overpower .+ defenses\!/
        },
        "pin_down"         => {
          :short_name => "pindown",
          :type       => :area_of_effect,
          :cost       => { stamina: 14 },
          :regex      => /You take quick assessment and raise your .+, several (?:arrows|bolts) nocked to your string in parallel\./,
          :usage      => "pindown"
        },
        "pulverize"        => {
          :short_name => "pulverize",
          :type       => :area_of_effect,
          :cost       => { stamina: 20 },
          :regex      => /You wheel your .+ overhead before slamming it around in a wide arc to pulverize your foes\!/
        },
        "pummel"           => {
          :short_name => "pummel",
          :type       => :assault,
          :cost       => { stamina: 15 },
          :regex      => /You take a menacing step toward .+, sweeping your .+ out low to your side in your advance\./,
          :assault_rx => /With a final snap of your wrist, you sweep your .+ back to the ready, your assault complete\./,
          :buff       => "Concussive Blows"
        },
        "radial_sweep"     => {
          :short_name => "radialsweep",
          :type       => :reaction,
          :cost       => { stamina: 0 },
          :regex      => /Crouching low, you sweep your .+ in a broad arc\!/,
          :usage      => "radialsweep"
        },
        "reactive_shot"    => {
          :short_name => "reactiveshot",
          :type       => :reaction,
          :cost       => { stamina: 0 },
          :regex      => /You fire off a quick shot at the .+, then make a hasty retreat\!/,
          :usage      => "reactiveshot"
        },
        "reverse_strike"   => {
          :short_name => "reversestrike",
          :type       => :reaction,
          :cost       => { stamina: 0 },
          :regex      => /Spotting an opening in .+ defenses, you quickly reverse the direction of your .+ and strike from a different angle\!/,
          :usage      => "reversestrike"
        },
        "riposte"          => {
          :short_name => "riposte",
          :type       => :reaction,
          :cost       => { stamina: 0 },
          :regex      => /Before .+ can recover, you smoothly segue from parry to riposte\!/
        },
        "spin_kick"        => {
          :short_name => "spinkick",
          :type       => :reaction,
          :cost       => { stamina: 0 },
          :regex      => /Stepping with deliberation, you wheel into a leaping spin\!/,
          :usage      => "spinkick"
        },
        "thrash"           => {
          :short_name => "thrash",
          :type       => :assault,
          :cost       => { stamina: 15 },
          :regex      => /You rush .+, raising your .+ high to deliver a sound thrashing\!/
        },
        "twin_hammerfists" => {
          :short_name => "twinhammer",
          :type       => :setup,
          :cost       => { stamina: 7 },
          :regex      => /You raise your hands high, lace them together and bring them crashing down towards the .+\!/,
          :usage      => "twinhammer"
        },
        "volley"           => {
          :short_name => "volley",
          :type       => :area_of_effect,
          :cost       => { stamina: 20 },
          :regex      => /Raising your .+ high, you loose (?:arrow|bolt) after (?:arrow|bolt) as fast as you can, filling the sky with a volley of deadly projectiles\!/
        },
        "whirling_blade"   => {
          :short_name => "wblade",
          :type       => :area_of_effect,
          :cost       => { stamina: 20 },
          :regex      => /With a broad flourish, you sweep your .+ into a whirling display of keen-edged menace\!/,
          :usage      => "wblade"
        },
        "whirlwind"        => {
          :short_name => "whirlwind",
          :type       => :area_of_effect,
          :cost       => { stamina: 20 },
          :regex      => /Twisting and spinning among your foes, you lash out again and again with the force of a reaping whirlwind\!/
        }
      }

      # Retrieves a list of weapon techniques with their long and short names and costs.
      # @return [Array<Hash>] an array of hashes containing weapon technique details
      # @example
      #   weapon_lookups.each do |weapon|
      #     puts "Long Name: \\#{weapon[:long_name]}, Short Name: \\#{weapon[:short_name]}, Cost: \\#{weapon[:cost]}"
      #   end
      def self.weapon_lookups
        @@weapon_techniques.map do |long_name, psm|
          {
            long_name: long_name,
            short_name: psm[:short_name],
            cost: psm[:cost]
          }
        end
      end

      # Retrieves a weapon technique by its name.
      # @param name [String] the name of the weapon technique
      # @return [Hash, nil] the weapon technique details or nil if not found
      # @see .known?
      def Weapon.[](name)
        return PSMS.assess(name, 'Weapon')
      end

      # Checks if a weapon technique is known and meets the minimum rank requirement.
      # @param name [String] the name of the weapon technique
      # @param min_rank [Integer] the minimum rank to check against (default is 1)
      # @return [Boolean] true if known and meets rank, false otherwise
      def Weapon.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Weapon[name] >= min_rank
      end

      # Determines if a weapon technique can be afforded based on the current conditions.
      # @param name [String] the name of the weapon technique
      # @param forcert_count [Integer] the number of forcerts available (default is 0)
      # @return [Boolean] true if affordable, false otherwise
      def Weapon.affordable?(name, forcert_count: 0)
        return true if @@weapon_techniques.fetch(PSMS.find_name(name, "Weapon")[:long_name])[:type] == :area_of_effect && Effects::Buffs.active?("Glorious Momentum")
        return PSMS.assess(name, 'Weapon', true, forcert_count: forcert_count)
      end

      # Checks if a weapon technique is available for use based on known status, affordability, and buffs.
      # @param name [String] the name of the weapon technique
      # @param min_rank [Integer] the minimum rank required (default is 1)
      # @param forcert_count [Integer] the number of forcerts available (default is 0)
      # @return [Boolean] true if available, false otherwise
      def Weapon.available?(name, min_rank: 1, forcert_count: 0)
        return false unless Weapon.known?(name, min_rank: min_rank)
        return false unless Weapon.affordable?(name, forcert_count: forcert_count)
        if @@weapon_techniques.fetch(PSMS.find_name(name, "Weapon")[:long_name])[:type] == :area_of_effect && Effects::Buffs.active?("Glorious Momentum")
          return false unless PSMS.available?(name, true)
        elsif @@weapon_techniques.fetch(PSMS.find_name(name, "Weapon")[:long_name])[:type] == :assault && Effects::Buffs.active?("Ardor of the Scourge")
          return false unless PSMS.available?(name, true)
        else
          return false unless PSMS.available?(name)
        end
        return true
      end

      # Checks if a weapon technique is currently active.
      # @param name [String] the name of the weapon technique
      # @return [Boolean] true if active, false otherwise
      # @deprecated Use .buff_active? instead.
      def Weapon.active?(name)
        ## DEPRECATED ##
        Lich.deprecated("Weapon.active?", "Weapon.buff_active?", caller[0], fe_log: false)
        buff_active?(name)
      end

      # Checks if the buff associated with a weapon technique is currently active.
      # @param name [String] the name of the weapon technique
      # @return [Boolean] true if the buff is active, false otherwise
      def Weapon.buff_active?(name)
        buff = @@weapon_techniques.fetch(PSMS.find_name(name, "Weapon")[:long_name])[:buff]
        return false if buff.nil?
        Effects::Buffs.active?(@@weapon_techniques.fetch(PSMS.find_name(name, "Weapon")[:long_name])[:buff])
      end

      # Uses a weapon technique against a target, handling cooldowns and results.
      # @param name [String] the name of the weapon technique
      # @param target [String, Integer, GameObj] the target of the technique
      # @param results_of_interest [Regexp, nil] additional regex patterns to match results (default is nil)
      # @param forcert_count [Integer] the number of forcerts available (default is 0)
      # @return [String, nil] the result of the technique use or nil if not applicable
      def Weapon.use(name, target = "", results_of_interest: nil, forcert_count: 0)
        return unless Weapon.available?(name, forcert_count: forcert_count)

        name_normalized = PSMS.name_normal(name)
        technique = @@weapon_techniques.fetch(PSMS.find_name(name_normalized, "Weapon")[:long_name])
        usage = technique.key?(:usage) ? technique[:usage] : name_normalized
        return if usage.nil?

        in_cooldown_regex = /^#{name} is still in cooldown\./i

        results_regex = Regexp.union(
          PSMS::FAILURES_REGEXES,
          /^#{name} what\?$/i,
          in_cooldown_regex
        )

        results_regex = Regexp.union(results_regex, results_of_interest) if results_of_interest

        usage_cmd = "weapon #{usage}"
        if target.is_a?(GameObj)
          usage_cmd += " ##{target.id}"
        elsif target.is_a?(Integer)
          usage_cmd += " ##{target}"
        elsif target != ""
          usage_cmd += " #{target}"
        end

        usage_result = nil
        if (technique.key?(:assault_rx))
          results_regex = Regexp.union(results_regex, technique[:assault_rx])
          break_out = Time.now() + 12
          loop {
            usage_result = dothistimeout(usage_cmd, 10, results_regex)
            if usage_result =~ /\.\.\.wait/i
              waitrt?
              next
            end
            break if usage_result.eql?(false)
            break if usage_result =~ technique[:assault_rx]
            break if usage_result =~ /^#{name} what\?$/i
            break if usage_result =~ in_cooldown_regex
            break if Time.now() > break_out
            sleep 0.25
          }
        else
          results_regex = Regexp.union(results_regex, technique[:regex], /^Roundtime: [0-9]+ sec\.$/)

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
        end

        usage_result
      end

      # Retrieves the regex pattern associated with a weapon technique.
      # @param name [String] the name of the weapon technique
      # @return [Regexp] the regex pattern for the technique
      def Weapon.regexp(name)
        @@weapon_techniques.fetch(PSMS.find_name(name, "Weapon")[:long_name])[:regex]
      end

      Weapon.weapon_lookups.each { |weapon|
        self.define_singleton_method(weapon[:short_name]) do
          Weapon[weapon[:short_name]]
        end

        self.define_singleton_method(weapon[:long_name]) do
          Weapon[weapon[:short_name]]
        end
      }
    end
  end
end
