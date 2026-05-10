
# Provides functionality for the Lich project.
#
# @see Lich::DragonRealms for DragonRealms specific features.
module Lich
  module DragonRealms
    # Module for managing DragonRealms character statistics.
    #
    # This module handles various character attributes such as race, guild, and stats.
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

      # Returns the current race of the character.
      # @return [String, nil] the character's race or nil if not set.
      def self.race
        @@race
      end

      # Sets the race of the character.
      # @param val [String] the race to set for the character.
      # @return [void]
      def self.race=(val)
        @@race = val
      end

      # Returns the current guild of the character.
      # @return [String, nil] the character's guild or nil if not set.
      def self.guild
        @@guild
      end

      # Sets the guild of the character.
      # @param val [String] the guild to set for the character.
      # @return [void]
      def self.guild=(val)
        @@guild = val
      end

      # Returns the current gender of the character.
      # @return [String, nil] the character's gender or nil if not set.
      def self.gender
        @@gender
      end

      # Sets the gender of the character.
      # @param val [String] the gender to set for the character.
      # @return [void]
      def self.gender=(val)
        @@gender = val
      end

      # Returns the current age of the character.
      # @return [Integer] the character's age.
      def self.age
        @@age
      end

      # Sets the age of the character.
      # @param val [Integer] the age to set for the character.
      # @return [void]
      def self.age=(val)
        @@age = val
      end

      # Returns the current circle of the character.
      # @return [Integer] the character's circle.
      def self.circle
        @@circle
      end

      # Sets the circle of the character.
      # @param val [Integer] the circle to set for the character.
      # @return [void]
      def self.circle=(val)
        @@circle = val
      end

      # Returns the current strength of the character.
      # @return [Integer] the character's strength.
      def self.strength
        @@strength
      end

      # Sets the strength of the character.
      # @param val [Integer] the strength to set for the character.
      # @return [void]
      def self.strength=(val)
        @@strength = val
      end

      # Returns the current stamina of the character.
      # @return [Integer] the character's stamina.
      def self.stamina
        @@stamina
      end

      # Sets the stamina of the character.
      # @param val [Integer] the stamina to set for the character.
      # @return [void]
      def self.stamina=(val)
        @@stamina = val
      end

      # Returns the current reflex of the character.
      # @return [Integer] the character's reflex.
      def self.reflex
        @@reflex
      end

      # Sets the reflex of the character.
      # @param val [Integer] the reflex to set for the character.
      # @return [void]
      def self.reflex=(val)
        @@reflex = val
      end

      # Returns the current agility of the character.
      # @return [Integer] the character's agility.
      def self.agility
        @@agility
      end

      # Sets the agility of the character.
      # @param val [Integer] the agility to set for the character.
      # @return [void]
      def self.agility=(val)
        @@agility = val
      end

      # Returns the current intelligence of the character.
      # @return [Integer] the character's intelligence.
      def self.intelligence
        @@intelligence
      end

      # Sets the intelligence of the character.
      # @param val [Integer] the intelligence to set for the character.
      # @return [void]
      def self.intelligence=(val)
        @@intelligence = val
      end

      # Returns the current wisdom of the character.
      # @return [Integer] the character's wisdom.
      def self.wisdom
        @@wisdom
      end

      # Sets the wisdom of the character.
      # @param val [Integer] the wisdom to set for the character.
      # @return [void]
      def self.wisdom=(val)
        @@wisdom = val
      end

      # Returns the current discipline of the character.
      # @return [Integer] the character's discipline.
      def self.discipline
        @@discipline
      end

      # Sets the discipline of the character.
      # @param val [Integer] the discipline to set for the character.
      # @return [void]
      def self.discipline=(val)
        @@discipline = val
      end

      # Returns the current charisma of the character.
      # @return [Integer] the character's charisma.
      def self.charisma
        @@charisma
      end

      # Sets the charisma of the character.
      # @param val [Integer] the charisma to set for the character.
      # @return [void]
      def self.charisma=(val)
        @@charisma = val
      end

      # Returns the current favors of the character.
      # @return [Integer] the character's favors.
      def self.favors
        @@favors
      end

      # Sets the favors of the character.
      # @param val [Integer] the favors to set for the character.
      # @return [void]
      def self.favors=(val)
        @@favors = val
      end

      # Returns the current TDPS of the character.
      # @return [Integer] the character's TDPS.
      def self.tdps
        @@tdps
      end

      # Sets the TDPS of the character.
      # @param val [Integer] the TDPS to set for the character.
      # @return [void]
      def self.tdps=(val)
        @@tdps = val
      end

      # Returns the current luck of the character.
      # @return [Integer] the character's luck.
      def self.luck
        @@luck
      end

      # Sets the luck of the character.
      # @param val [Integer] the luck to set for the character.
      # @return [void]
      def self.luck=(val)
        @@luck = val
      end

      # Returns the current balance of the character.
      # @return [Integer] the character's balance.
      def self.balance
        @@balance
      end

      # Sets the balance of the character.
      # @param val [Integer] the balance to set for the character.
      # @return [void]
      def self.balance=(val)
        @@balance = val
      end

      # Returns the current encumbrance of the character.
      # @return [Integer, nil] the character's encumbrance or nil if not set.
      def self.encumbrance
        @@encumbrance
      end

      # Sets the encumbrance of the character.
      # @param val [Integer, nil] the encumbrance to set for the character.
      # @return [void]
      def self.encumbrance=(val)
        @@encumbrance = val
      end

      # Returns the name of the character from XML data.
      # @return [String] the character's name.
      def self.name
        XMLData.name
      end

      # Returns the health of the character from XML data.
      # @return [Integer] the character's health.
      def self.health
        XMLData.health
      end

      # Returns the mana of the character from XML data.
      # @return [Integer] the character's mana.
      def self.mana
        XMLData.mana
      end

      # Returns the stamina of the character from XML data as fatigue.
      # @return [Integer] the character's fatigue.
      def self.fatigue
        XMLData.stamina
      end

      # Returns the spirit of the character from XML data.
      # @return [Integer] the character's spirit.
      def self.spirit
        XMLData.spirit
      end

      # Returns the concentration of the character from XML data.
      # @return [Integer] the character's concentration.
      def self.concentration
        XMLData.concentration
      end

      # Guilds and their native mana types, frozen for immutability.
      # Guilds and their native mana types, frozen for immutability.
      #
      # @example
      #   GUILD_MANA_TYPES['Necromancer'] # => 'arcane'
      #   GUILD_MANA_TYPES['Barbarian'] # => nil
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

      # Returns the native mana type for the current guild.
      # @return [String, nil] the native mana type or nil if not applicable.
      def self.native_mana
        GUILD_MANA_TYPES[@@guild]
      end

      # Serializes the character's stats into an array.
      # @return [Array] an array containing the serialized stats.
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
