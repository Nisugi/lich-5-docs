# Provides a unified interface for interacting with Player System Manager (PSM) skills
# in GemStone IV, such as Combat Maneuvers, Shield Specializations, Feats, Warcries,
# Weapon Techniques, and Armor Specializations.
#

require "ostruct"

require_relative('./psms/armor.rb')
require_relative('./psms/cman.rb')
require_relative('./psms/feat.rb')
require_relative('./psms/shield.rb')
require_relative('./psms/weapon.rb')
require_relative('./psms/warcry.rb')
require_relative('./psms/ascension.rb')
require_relative('./psms/qstrike.rb')

module Lich
  module Gemstone
    # Provides a unified interface for interacting with Player System Manager (PSM) skills in GemStone IV.
    #
    # This module includes methods for normalizing names, finding skills, assessing their availability,
    # and checking for special conditions related to skills.
    #
    # @see Lich::Gemstone::Util
    module PSMS
      # Normalizes the given skill name.
      #
      # @param name [String] the name of the skill to normalize
      # @return [String] the normalized skill name
      def self.name_normal(name)
        Lich::Util.normalize_name(name)
      end

      # Finds a skill by its name and type.
      #
      # @param name [String] the name of the skill to find
      # @param type [String] the type of skill (e.g., "Armor", "CMan")
      # @return [Hash, nil] the skill details if found, otherwise nil
      def self.find_name(name, type)
        name = self.name_normal(name)
        Object.const_get("Lich::Gemstone::#{type}").method("#{type.downcase}_lookups").call
              .find { |h| h[:long_name].eql?(name) || h[:short_name].eql?(name) }
      end

      # Assesses the availability of a skill based on its name and type.
      #
      # @param name [String] the name of the skill to assess
      # @param type [String] the type of skill (e.g., "Armor", "CMan")
      # @param costcheck [Boolean] whether to check costs (default: false)
      # @param forcert_count [Integer] the number of forcerts to consider (default: 0)
      # @return [Boolean] true if the skill is available, false otherwise
      # @raise ArgumentError if the skill is invalid
      def self.assess(name, type, costcheck = false, forcert_count: 0)
        return false unless forcert_count <= max_forcert_count
        name = self.name_normal(name)
        seek_psm = self.find_name(name, type)
        # this logs then raises an exception to stop (kill) the offending script
        if seek_psm.nil?
          Lich.log("error: PSMS request: #{$!}\n\t")
          raise ArgumentError, "Aborting script - The referenced #{type} skill #{name} is invalid.\r\nCheck your PSM category (Armor, CMan, Feat, Shield, Warcry, Weapon) and your spelling of #{name}.", (caller.find { |call| call =~ /^#{Script.current.name}/ })
        end
        # otherwise process request
        case costcheck
        when true
          base_cost = seek_psm[:cost]
          base_cost.each do |cost_type, cost_amount|
            if forcert_count > 0
              return false unless (cost_amount + (cost_amount * ((25 + (10.0 * forcert_count)) / 100))).truncate < XMLData.public_send(cost_type)
            else
              return false unless cost_amount < XMLData.public_send(cost_type)
            end
          end
          return true
        else
          Infomon.get("#{type.downcase}.#{seek_psm[:short_name]}")
        end
      end

      # Checks if a skill is available for use.
      #
      # @param name [String] the name of the skill to check
      # @param ignore_cooldown [Boolean] whether to ignore cooldowns (default: false)
      # @return [Boolean] true if the skill is available, false otherwise
      def self.available?(name, ignore_cooldown = false)
        return false if Lich::Util.normalize_lookup('Debuffs', 'Overexerted')
        return false if Lich::Util.normalize_lookup('Cooldowns', name) unless ignore_cooldown
        return true
      end

      # Checks if a specified number of forcerts can be used.
      #
      # @param times [Integer] the number of forcerts to check
      # @return [Boolean] true if the forcerts can be used, false otherwise
      def self.can_forcert?(times)
        max_forcert_count >= times
      end

      # Determines the maximum number of forcerts that can be used based on multi-opponent combat skills.
      #
      # @return [Integer] the maximum number of forcerts allowed
      def self.max_forcert_count
        case Skills.multi_opponent_combat
        when 0..9
          0
        when 10..34
          1
        when 35..74
          2
        when 75..124
          3
        else # 125+
          4
        end
      end

      # A regular expression pattern that matches various failure messages.
      #
      # @example
      #   FAILURES_REGEXES.match("You are unable to do that right now.") # => true
      #   FAILURES_REGEXES.match("You can't reach the target!") # => false
      FAILURES_REGEXES = Regexp.union(
        /^And give yourself away!  Never!$/,
        /^You are unable to do that right now\.$/,
        /^You don't seem to be able to move to do that\.$/,
        /^Provoking a GameMaster is not such a good idea\.$/,
        /^You do not currently have a target\.$/,
        /^Your mind clouds with confusion and you glance around uncertainly\.$/,
        /^But your hands are full\!$/,
        /^You are still stunned\.$/,
        /^You lack the momentum to attempt another skill\.$/,
        /^You can't reach .+!$/,
        / attempting to .+ would be a rather awkward proposition\.$/,
      )
    end
  end
end
