module Lich
  module DragonRealms
    # Provides methods to manage and access character statistics in DragonRealms.
    # @example Accessing race
    #   Lich::DragonRealms::DRStats.race
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

      # Returns the race of the character.
      # @return [String, nil] The race of the character or nil if not set.
      def self.race
        @@race
      end

      # Sets the race of the character.
      # @param val [String] The race to set for the character.
      def self.race=(val)
        @@race = val
      end

      # Returns the guild of the character.
      # @return [String, nil] The guild of the character or nil if not set.
      def self.guild
        @@guild
      end

      # Sets the guild of the character.
      # @param val [String] The guild to set for the character.
      def self.guild=(val)
        @@guild = val
      end

      # Returns the gender of the character.
      # @return [String, nil] The gender of the character or nil if not set.
      def self.gender
        @@gender
      end

      # Sets the gender of the character.
      # @param val [String] The gender to set for the character.
      def self.gender=(val)
        @@gender = val
      end

      # Returns the age of the character.
      # @return [Integer] The age of the character.
      def self.age
        @@age
      end

      # Sets the age of the character.
      # @param val [Integer] The age to set for the character.
      def self.age=(val)
        @@age = val
      end

      # Returns the circle of the character.
      # @return [Integer] The circle of the character.
      def self.circle
        @@circle
      end

      # Sets the circle of the character.
      # @param val [Integer] The circle to set for the character.
      def self.circle=(val)
        @@circle = val
      end

      # Returns the strength of the character.
      # @return [Integer] The strength of the character.
      def self.strength
        @@strength
      end

      # Sets the strength of the character.
      # @param val [Integer] The strength to set for the character.
      def self.strength=(val)
        @@strength = val
      end

      # Returns the stamina of the character.
      # @return [Integer] The stamina of the character.
      def self.stamina
        @@stamina
      end

      # Sets the stamina of the character.
      # @param val [Integer] The stamina to set for the character.
      def self.stamina=(val)
        @@stamina = val
      end

      # Returns the reflex of the character.
      # @return [Integer] The reflex of the character.
      def self.reflex
        @@reflex
      end

      # Sets the reflex of the character.
      # @param val [Integer] The reflex to set for the character.
      def self.reflex=(val)
        @@reflex = val
      end

      # Returns the agility of the character.
      # @return [Integer] The agility of the character.
      def self.agility
        @@agility
      end

      # Sets the agility of the character.
      # @param val [Integer] The agility to set for the character.
      def self.agility=(val)
        @@agility = val
      end

      # Returns the intelligence of the character.
      # @return [Integer] The intelligence of the character.
      def self.intelligence
        @@intelligence
      end

      # Sets the intelligence of the character.
      # @param val [Integer] The intelligence to set for the character.
      def self.intelligence=(val)
        @@intelligence = val
      end

      # Returns the wisdom of the character.
      # @return [Integer] The wisdom of the character.
      def self.wisdom
        @@wisdom
      end

      # Sets the wisdom of the character.
      # @param val [Integer] The wisdom to set for the character.
      def self.wisdom=(val)
        @@wisdom = val
      end

      # Returns the discipline of the character.
      # @return [Integer] The discipline of the character.
      def self.discipline
        @@discipline
      end

      # Sets the discipline of the character.
      # @param val [Integer] The discipline to set for the character.
      def self.discipline=(val)
        @@discipline = val
      end

      # Returns the charisma of the character.
      # @return [Integer] The charisma of the character.
      def self.charisma
        @@charisma
      end

      # Sets the charisma of the character.
      # @param val [Integer] The charisma to set for the character.
      def self.charisma=(val)
        @@charisma = val
      end

      # Returns the favors of the character.
      # @return [Integer] The favors of the character.
      def self.favors
        @@favors
      end

      # Sets the favors of the character.
      # @param val [Integer] The favors to set for the character.
      def self.favors=(val)
        @@favors = val
      end

      # Returns the TDPS of the character.
      # @return [Integer] The TDPS of the character.
      def self.tdps
        @@tdps
      end

      # Sets the TDPS of the character.
      # @param val [Integer] The TDPS to set for the character.
      def self.tdps=(val)
        @@tdps = val
      end

      # Returns the luck of the character.
      # @return [Integer] The luck of the character.
      def self.luck
        @@luck
      end

      # Sets the luck of the character.
      # @param val [Integer] The luck to set for the character.
      def self.luck=(val)
        @@luck = val
      end

      # Returns the balance of the character.
      # @return [Integer] The balance of the character.
      def self.balance
        @@balance
      end

      # Sets the balance of the character.
      # @param val [Integer] The balance to set for the character.
      def self.balance=(val)
        @@balance = val
      end

      # Returns the encumbrance of the character.
      # @return [Integer, nil] The encumbrance of the character or nil if not set.
      def self.encumbrance
        @@encumbrance
      end

      # Sets the encumbrance of the character.
      # @param val [Integer] The encumbrance to set for the character.
      def self.encumbrance=(val)
        @@encumbrance = val
      end

      # Returns the name of the character from XMLData.
      # @return [String] The name of the character.
      def self.name
        XMLData.name
      end

      # Returns the health of the character from XMLData.
      # @return [Integer] The health of the character.
      def self.health
        XMLData.health
      end

      # Returns the mana of the character from XMLData.
      # @return [Integer] The mana of the character.
      def self.mana
        XMLData.mana
      end

      # Returns the stamina of the character from XMLData.
      # @return [Integer] The stamina of the character.
      def self.fatigue
        XMLData.stamina
      end

      # Returns the spirit of the character from XMLData.
      # @return [Integer] The spirit of the character.
      def self.spirit
        XMLData.spirit
      end

      # Returns the concentration of the character from XMLData.
      # @return [Integer] The concentration of the character.
      def self.concentration
        XMLData.concentration
      end

      # Determines the native mana type based on the character's guild.
      # @return [String, nil] The native mana type or nil if not applicable.
      def self.native_mana
        case DRStats.guild
        when 'Necromancer'
          'arcane'
        when 'Barbarian', 'Thief'
          nil
        when 'Moon Mage', 'Trader'
          'lunar'
        when 'Warrior Mage', 'Bard'
          'elemental'
        when 'Cleric', 'Paladin'
          'holy'
        when 'Empath', 'Ranger'
          'life'
        end
      end

      # Serializes the character's statistics into an array.
      # @return [Array] An array containing the serialized statistics.
      def self.serialize
        [@@race, @@guild, @@gender, @@age, @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance]
      end

      # Loads character statistics from a serialized array.
      # @param array [Array] The array containing serialized statistics.
      def self.load_serialized=(array)
        @@race, @@guild, @@gender, @@age = array[0..3]
        @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance = array[5..12]
      end

      # Checks if the character's guild is 'Barbarian'.
      # @return [Boolean] True if the character is a Barbarian, false otherwise.
      def self.barbarian?
        @@guild == 'Barbarian'
      end

      # Checks if the character's guild is 'Bard'.
      # @return [Boolean] True if the character is a Bard, false otherwise.
      def self.bard?
        @@guild == 'Bard'
      end

      # Checks if the character's guild is 'Cleric'.
      # @return [Boolean] True if the character is a Cleric, false otherwise.
      def self.cleric?
        @@guild == 'Cleric'
      end

      # Checks if the character's guild is 'Commoner'.
      # @return [Boolean] True if the character is a Commoner, false otherwise.
      def self.commoner?
        @@guild == 'Commoner'
      end

      # Checks if the character's guild is 'Empath'.
      # @return [Boolean] True if the character is an Empath, false otherwise.
      def self.empath?
        @@guild == 'Empath'
      end

      # Checks if the character's guild is 'Moon Mage'.
      # @return [Boolean] True if the character is a Moon Mage, false otherwise.
      def self.moon_mage?
        @@guild == 'Moon Mage'
      end

      # Checks if the character's guild is 'Necromancer'.
      # @return [Boolean] True if the character is a Necromancer, false otherwise.
      def self.necromancer?
        @@guild == 'Necromancer'
      end

      # Checks if the character's guild is 'Paladin'.
      # @return [Boolean] True if the character is a Paladin, false otherwise.
      def self.paladin?
        @@guild == 'Paladin'
      end

      # Checks if the character's guild is 'Ranger'.
      # @return [Boolean] True if the character is a Ranger, false otherwise.
      def self.ranger?
        @@guild == 'Ranger'
      end

      # Checks if the character's guild is 'Thief'.
      # @return [Boolean] True if the character is a Thief, false otherwise.
      def self.thief?
        @@guild == 'Thief'
      end

      # Checks if the character's guild is 'Trader'.
      # @return [Boolean] True if the character is a Trader, false otherwise.
      def self.trader?
        @@guild == 'Trader'
      end

      # Checks if the character's guild is 'Warrior Mage'.
      # @return [Boolean] True if the character is a Warrior Mage, false otherwise.
      def self.warrior_mage?
        @@guild == 'Warrior Mage'
      end
    end
  end
end
