
# Provides functionality for the Lich project.
#
# @see Lich::DragonRealms
module Lich
  module DragonRealms
    # Module for managing DragonRealms character statistics.
    #
    # This module contains methods to access and modify character stats such as race, guild, and attributes.
    module DRStats
      @@race = nil
      @@guild = nil
      @@gender = nil
      @@age ||= 0
      @@circle ||= 0
      @@strength ||= 0
      @@stamina ||= 0
      @@reflex ||= 0
      @@agility ||= 0
      @@intelligence ||= 0
      @@wisdom ||= 0
      @@discipline ||= 0
      @@charisma ||= 0
      @@favors ||= 0
      @@tdps ||= 0
      @@encumbrance = nil
      @@balance ||= 8
      @@luck ||= 0

      # Retrieves the character's race.
      # @return [String, nil] the character's race or nil if not set.
      def self.race
        @@race
      end

      # Sets the character's race.
      # @param val [String] the race to set for the character.
      # @return [void]
      def self.race=(val)
        @@race = val
      end

      # Retrieves the character's guild.
      # @return [String, nil] the character's guild or nil if not set.
      def self.guild
        @@guild
      end

      # Sets the character's guild.
      # @param val [String] the guild to set for the character.
      # @return [void]
      def self.guild=(val)
        @@guild = val
      end

      # Retrieves the character's gender.
      # @return [String, nil] the character's gender or nil if not set.
      def self.gender
        @@gender
      end

      # Sets the character's gender.
      # @param val [String] the gender to set for the character.
      # @return [void]
      def self.gender=(val)
        @@gender = val
      end

      # Retrieves the character's age.
      # @return [Integer] the character's age.
      def self.age
        @@age
      end

      # Sets the character's age.
      # @param val [Integer] the age to set for the character.
      # @return [void]
      def self.age=(val)
        @@age = val
      end

      # Retrieves the character's circle.
      # @return [Integer] the character's circle.
      def self.circle
        @@circle
      end

      # Sets the character's circle.
      # @param val [Integer] the circle to set for the character.
      # @return [void]
      def self.circle=(val)
        @@circle = val
      end

      # Retrieves the character's strength.
      # @return [Integer] the character's strength.
      def self.strength
        @@strength
      end

      # Sets the character's strength.
      # @param val [Integer] the strength to set for the character.
      # @return [void]
      def self.strength=(val)
        @@strength = val
      end

      # Retrieves the character's stamina.
      # @return [Integer] the character's stamina.
      def self.stamina
        @@stamina
      end

      # Sets the character's stamina.
      # @param val [Integer] the stamina to set for the character.
      # @return [void]
      def self.stamina=(val)
        @@stamina = val
      end

      # Retrieves the character's reflex.
      # @return [Integer] the character's reflex.
      def self.reflex
        @@reflex
      end

      # Sets the character's reflex.
      # @param val [Integer] the reflex to set for the character.
      # @return [void]
      def self.reflex=(val)
        @@reflex = val
      end

      # Retrieves the character's agility.
      # @return [Integer] the character's agility.
      def self.agility
        @@agility
      end

      # Sets the character's agility.
      # @param val [Integer] the agility to set for the character.
      # @return [void]
      def self.agility=(val)
        @@agility = val
      end

      # Retrieves the character's intelligence.
      # @return [Integer] the character's intelligence.
      def self.intelligence
        @@intelligence
      end

      # Sets the character's intelligence.
      # @param val [Integer] the intelligence to set for the character.
      # @return [void]
      def self.intelligence=(val)
        @@intelligence = val
      end

      # Retrieves the character's wisdom.
      # @return [Integer] the character's wisdom.
      def self.wisdom
        @@wisdom
      end

      # Sets the character's wisdom.
      # @param val [Integer] the wisdom to set for the character.
      # @return [void]
      def self.wisdom=(val)
        @@wisdom = val
      end

      # Retrieves the character's discipline.
      # @return [Integer] the character's discipline.
      def self.discipline
        @@discipline
      end

      # Sets the character's discipline.
      # @param val [Integer] the discipline to set for the character.
      # @return [void]
      def self.discipline=(val)
        @@discipline = val
      end

      # Retrieves the character's charisma.
      # @return [Integer] the character's charisma.
      def self.charisma
        @@charisma
      end

      # Sets the character's charisma.
      # @param val [Integer] the charisma to set for the character.
      # @return [void]
      def self.charisma=(val)
        @@charisma = val
      end

      # Retrieves the character's favors.
      # @return [Integer] the character's favors.
      def self.favors
        @@favors
      end

      # Sets the character's favors.
      # @param val [Integer] the favors to set for the character.
      # @return [void]
      def self.favors=(val)
        @@favors = val
      end

      # Retrieves the character's TDPS (Total Damage Per Second).
      # @return [Integer] the character's TDPS.
      def self.tdps
        @@tdps
      end

      # Sets the character's TDPS.
      # @param val [Integer] the TDPS to set for the character.
      # @return [void]
      def self.tdps=(val)
        @@tdps = val
      end

      # Retrieves the character's luck.
      # @return [Integer] the character's luck.
      def self.luck
        @@luck
      end

      # Sets the character's luck.
      # @param val [Integer] the luck to set for the character.
      # @return [void]
      def self.luck=(val)
        @@luck = val
      end

      # Retrieves the character's balance.
      # @return [Integer] the character's balance.
      def self.balance
        @@balance
      end

      # Sets the character's balance.
      # @param val [Integer] the balance to set for the character.
      # @return [void]
      def self.balance=(val)
        @@balance = val
      end

      # Retrieves the character's encumbrance.
      # @return [Integer, nil] the character's encumbrance or nil if not set.
      def self.encumbrance
        @@encumbrance
      end

      # Sets the character's encumbrance.
      # @param val [Integer, nil] the encumbrance to set for the character.
      # @return [void]
      def self.encumbrance=(val)
        @@encumbrance = val
      end

      # Retrieves the character's name from XML data.
      # @return [String] the character's name.
      def self.name
        XMLData.name
      end

      # Retrieves the character's health from XML data.
      # @return [Integer] the character's health.
      def self.health
        XMLData.health
      end

      # Retrieves the character's mana from XML data.
      # @return [Integer] the character's mana.
      def self.mana
        XMLData.mana
      end

      # Retrieves the character's fatigue from XML data.
      # @return [Integer] the character's fatigue.
      def self.fatigue
        XMLData.stamina
      end

      # Retrieves the character's spirit from XML data.
      # @return [Integer] the character's spirit.
      def self.spirit
        XMLData.spirit
      end

      # Retrieves the character's concentration from XML data.
      # @return [Integer] the character's concentration.
      def self.concentration
        XMLData.concentration
      end

      # Guilds and their native mana types, frozen for immutability.
      # Guilds and their native mana types, frozen for immutability.
      #
      # @example
      #   GUILD_MANA_TYPES["Necromancer"] # => "arcane"
      #   GUILD_MANA_TYPES["Barbarian"]   # => nil
      GUILD_MANA_TYPES = {
        'Necromancer'  => 'arcane',
        'Barbarian'    => nil,
        'Thief'        => nil,
        'Moon Mage'    => 'lunar',
        'Trader'       => 'lunar',
        'Warrior Mage' => 'elemental',
        'Bard'         => 'elemental',
        'Cleric'       => 'holy',
        'Paladin'      => 'holy',
        'Empath'       => 'life',
        'Ranger'       => 'life'
      }.freeze

      # Retrieves the native mana type for the character's guild.
      # @return [String, nil] the native mana type or nil if the guild has no native type.
      def self.native_mana
        GUILD_MANA_TYPES[@@guild]
      end

      # Serializes the character's stats into an array.
      # @return [Array] an array containing the character's stats.
      def self.serialize
        [@@race, @@guild, @@gender, @@age, @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance]
      end

      # Loads character stats from a serialized array.
      # @param array [Array] the array containing serialized stats.
      # @return [void]
      def self.load_serialized=(array)
        return if array.nil? || array.empty?

        @@race, @@guild, @@gender, @@age = array[0..3]
        @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance = array[4..16]
      end

      # Checks if the character's guild is Barbarian.
      # @return [Boolean] true if the character is a Barbarian, false otherwise.
      def self.barbarian?
        @@guild == 'Barbarian'
      end

      # Checks if the character's guild is Bard.
      # @return [Boolean] true if the character is a Bard, false otherwise.
      def self.bard?
        @@guild == 'Bard'
      end

      # Checks if the character's guild is Cleric.
      # @return [Boolean] true if the character is a Cleric, false otherwise.
      def self.cleric?
        @@guild == 'Cleric'
      end

      # Checks if the character's guild is Commoner.
      # @return [Boolean] true if the character is a Commoner, false otherwise.
      def self.commoner?
        @@guild == 'Commoner'
      end

      # Checks if the character's guild is Empath.
      # @return [Boolean] true if the character is an Empath, false otherwise.
      def self.empath?
        @@guild == 'Empath'
      end

      # Checks if the character's guild is Moon Mage.
      # @return [Boolean] true if the character is a Moon Mage, false otherwise.
      def self.moon_mage?
        @@guild == 'Moon Mage'
      end

      # Checks if the character's guild is Necromancer.
      # @return [Boolean] true if the character is a Necromancer, false otherwise.
      def self.necromancer?
        @@guild == 'Necromancer'
      end

      # Checks if the character's guild is Paladin.
      # @return [Boolean] true if the character is a Paladin, false otherwise.
      def self.paladin?
        @@guild == 'Paladin'
      end

      # Checks if the character's guild is Ranger.
      # @return [Boolean] true if the character is a Ranger, false otherwise.
      def self.ranger?
        @@guild == 'Ranger'
      end

      # Checks if the character's guild is Thief.
      # @return [Boolean] true if the character is a Thief, false otherwise.
      def self.thief?
        @@guild == 'Thief'
      end

      # Checks if the character's guild is Trader.
      # @return [Boolean] true if the character is a Trader, false otherwise.
      def self.trader?
        @@guild == 'Trader'
      end

      # Checks if the character's guild is Warrior Mage.
      # @return [Boolean] true if the character is a Warrior Mage, false otherwise.
      def self.warrior_mage?
        @@guild == 'Warrior Mage'
      end
    end
  end
end
