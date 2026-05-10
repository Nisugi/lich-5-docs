
# Lich module containing DragonRealms related functionality
#
# This module serves as a namespace for the DragonRealms game features.
module Lich
  module DragonRealms
    # DRStats module for managing character statistics in DragonRealms
    #
    # This module provides methods to access and modify character stats such as race, guild, and attributes.
    # @example Accessing character race
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

      # Retrieves the current race of the character
      # @return [String, nil] The character's race or nil if not set
      # @example Getting the character's race
      #   race = Lich::DragonRealms::DRStats.race
      def self.race
        @@race
      end

      # Sets the race of the character
      # @param val [String] The race to set for the character
      # @return [String] The set race
      # @example Setting the character's race
      #   Lich::DragonRealms::DRStats.race = "Elf"
      def self.race=(val)
        @@race = val
      end

      # Retrieves the current guild of the character
      # @return [String, nil] The character's guild or nil if not set
      # @example Getting the character's guild
      #   guild = Lich::DragonRealms::DRStats.guild
      def self.guild
        @@guild
      end

      # Sets the guild of the character
      # @param val [String] The guild to set for the character
      # @return [String] The set guild
      # @example Setting the character's guild
      #   Lich::DragonRealms::DRStats.guild = "Warrior Mage"
      def self.guild=(val)
        @@guild = val
      end

      # Retrieves the current gender of the character
      # @return [String, nil] The character's gender or nil if not set
      # @example Getting the character's gender
      #   gender = Lich::DragonRealms::DRStats.gender
      def self.gender
        @@gender
      end

      # Sets the gender of the character
      # @param val [String] The gender to set for the character
      # @return [String] The set gender
      # @example Setting the character's gender
      #   Lich::DragonRealms::DRStats.gender = "Female"
      def self.gender=(val)
        @@gender = val
      end

      # Retrieves the current age of the character
      # @return [Integer, nil] The character's age or nil if not set
      # @example Getting the character's age
      #   age = Lich::DragonRealms::DRStats.age
      def self.age
        @@age
      end

      # Sets the age of the character
      # @param val [Integer] The age to set for the character
      # @return [Integer] The set age
      # @example Setting the character's age
      #   Lich::DragonRealms::DRStats.age = 25
      def self.age=(val)
        @@age = val
      end

      # Retrieves the current circle of the character
      # @return [Integer, nil] The character's circle or nil if not set
      # @example Getting the character's circle
      #   circle = Lich::DragonRealms::DRStats.circle
      def self.circle
        @@circle
      end

      # Sets the circle of the character
      # @param val [Integer] The circle to set for the character
      # @return [Integer] The set circle
      # @example Setting the character's circle
      #   Lich::DragonRealms::DRStats.circle = 5
      def self.circle=(val)
        @@circle = val
      end

      # Retrieves the current strength of the character
      # @return [Integer] The character's strength
      # @example Getting the character's strength
      #   strength = Lich::DragonRealms::DRStats.strength
      def self.strength
        @@strength
      end

      # Sets the strength of the character
      # @param val [Integer] The strength to set for the character
      # @return [Integer] The set strength
      # @example Setting the character's strength
      #   Lich::DragonRealms::DRStats.strength = 15
      def self.strength=(val)
        @@strength = val
      end

      # Retrieves the current stamina of the character
      # @return [Integer] The character's stamina
      # @example Getting the character's stamina
      #   stamina = Lich::DragonRealms::DRStats.stamina
      def self.stamina
        @@stamina
      end

      # Sets the stamina of the character
      # @param val [Integer] The stamina to set for the character
      # @return [Integer] The set stamina
      # @example Setting the character's stamina
      #   Lich::DragonRealms::DRStats.stamina = 10
      def self.stamina=(val)
        @@stamina = val
      end

      # Retrieves the current reflex of the character
      # @return [Integer] The character's reflex
      # @example Getting the character's reflex
      #   reflex = Lich::DragonRealms::DRStats.reflex
      def self.reflex
        @@reflex
      end

      # Sets the reflex of the character
      # @param val [Integer] The reflex to set for the character
      # @return [Integer] The set reflex
      # @example Setting the character's reflex
      #   Lich::DragonRealms::DRStats.reflex = 12
      def self.reflex=(val)
        @@reflex = val
      end

      # Retrieves the current agility of the character
      # @return [Integer] The character's agility
      # @example Getting the character's agility
      #   agility = Lich::DragonRealms::DRStats.agility
      def self.agility
        @@agility
      end

      # Sets the agility of the character
      # @param val [Integer] The agility to set for the character
      # @return [Integer] The set agility
      # @example Setting the character's agility
      #   Lich::DragonRealms::DRStats.agility = 14
      def self.agility=(val)
        @@agility = val
      end

      # Retrieves the current intelligence of the character
      # @return [Integer] The character's intelligence
      # @example Getting the character's intelligence
      #   intelligence = Lich::DragonRealms::DRStats.intelligence
      def self.intelligence
        @@intelligence
      end

      # Sets the intelligence of the character
      # @param val [Integer] The intelligence to set for the character
      # @return [Integer] The set intelligence
      # @example Setting the character's intelligence
      #   Lich::DragonRealms::DRStats.intelligence = 18
      def self.intelligence=(val)
        @@intelligence = val
      end

      # Retrieves the current wisdom of the character
      # @return [Integer] The character's wisdom
      # @example Getting the character's wisdom
      #   wisdom = Lich::DragonRealms::DRStats.wisdom
      def self.wisdom
        @@wisdom
      end

      # Sets the wisdom of the character
      # @param val [Integer] The wisdom to set for the character
      # @return [Integer] The set wisdom
      # @example Setting the character's wisdom
      #   Lich::DragonRealms::DRStats.wisdom = 16
      def self.wisdom=(val)
        @@wisdom = val
      end

      # Retrieves the current discipline of the character
      # @return [Integer] The character's discipline
      # @example Getting the character's discipline
      #   discipline = Lich::DragonRealms::DRStats.discipline
      def self.discipline
        @@discipline
      end

      # Sets the discipline of the character
      # @param val [Integer] The discipline to set for the character
      # @return [Integer] The set discipline
      # @example Setting the character's discipline
      #   Lich::DragonRealms::DRStats.discipline = 20
      def self.discipline=(val)
        @@discipline = val
      end

      # Retrieves the current charisma of the character
      # @return [Integer] The character's charisma
      # @example Getting the character's charisma
      #   charisma = Lich::DragonRealms::DRStats.charisma
      def self.charisma
        @@charisma
      end

      # Sets the charisma of the character
      # @param val [Integer] The charisma to set for the character
      # @return [Integer] The set charisma
      # @example Setting the character's charisma
      #   Lich::DragonRealms::DRStats.charisma = 11
      def self.charisma=(val)
        @@charisma = val
      end

      # Retrieves the current favors of the character
      # @return [Integer] The character's favors
      # @example Getting the character's favors
      #   favors = Lich::DragonRealms::DRStats.favors
      def self.favors
        @@favors
      end

      # Sets the favors of the character
      # @param val [Integer] The favors to set for the character
      # @return [Integer] The set favors
      # @example Setting the character's favors
      #   Lich::DragonRealms::DRStats.favors = 5
      def self.favors=(val)
        @@favors = val
      end

      # Retrieves the current TDPS (Total Damage Per Second) of the character
      # @return [Integer] The character's TDPS
      # @example Getting the character's TDPS
      #   tdps = Lich::DragonRealms::DRStats.tdps
      def self.tdps
        @@tdps
      end

      # Sets the TDPS of the character
      # @param val [Integer] The TDPS to set for the character
      # @return [Integer] The set TDPS
      # @example Setting the character's TDPS
      #   Lich::DragonRealms::DRStats.tdps = 30
      def self.tdps=(val)
        @@tdps = val
      end

      # Retrieves the current luck of the character
      # @return [Integer] The character's luck
      # @example Getting the character's luck
      #   luck = Lich::DragonRealms::DRStats.luck
      def self.luck
        @@luck
      end

      # Sets the luck of the character
      # @param val [Integer] The luck to set for the character
      # @return [Integer] The set luck
      # @example Setting the character's luck
      #   Lich::DragonRealms::DRStats.luck = 7
      def self.luck=(val)
        @@luck = val
      end

      # Retrieves the current balance of the character
      # @return [Integer] The character's balance
      # @example Getting the character's balance
      #   balance = Lich::DragonRealms::DRStats.balance
      def self.balance
        @@balance
      end

      # Sets the balance of the character
      # @param val [Integer] The balance to set for the character
      # @return [Integer] The set balance
      # @example Setting the character's balance
      #   Lich::DragonRealms::DRStats.balance = 100
      def self.balance=(val)
        @@balance = val
      end

      # Retrieves the current encumbrance of the character
      # @return [Integer, nil] The character's encumbrance or nil if not set
      # @example Getting the character's encumbrance
      #   encumbrance = Lich::DragonRealms::DRStats.encumbrance
      def self.encumbrance
        @@encumbrance
      end

      # Sets the encumbrance of the character
      # @param val [Integer] The encumbrance to set for the character
      # @return [Integer] The set encumbrance
      # @example Setting the character's encumbrance
      #   Lich::DragonRealms::DRStats.encumbrance = 50
      def self.encumbrance=(val)
        @@encumbrance = val
      end

      def self.name
        XMLData.name
      end

      def self.health
        XMLData.health
      end

      def self.mana
        XMLData.mana
      end

      def self.fatigue
        XMLData.stamina
      end

      def self.spirit
        XMLData.spirit
      end

      def self.concentration
        XMLData.concentration
      end

      # Guilds and their native mana types, frozen for immutability.
      # Guilds and their native mana types, frozen for immutability.
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

      # Retrieves the native mana type for the current guild
      # @return [String, nil] The native mana type or nil if the guild has no native type
      # @example Getting the native mana type
      #   mana_type = Lich::DragonRealms::DRStats.native_mana
      def self.native_mana
        GUILD_MANA_TYPES[@@guild]
      end

      # Serializes the character's stats into an array
      # @return [Array] An array containing the serialized stats
      # @example Serializing character stats
      #   stats_array = Lich::DragonRealms::DRStats.serialize
      def self.serialize
        [@@race, @@guild, @@gender, @@age, @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance]
      end

      # Loads character stats from a serialized array
      # @param array [Array] The array containing serialized stats
      # @return [void]
      # @example Loading character stats
      #   Lich::DragonRealms::DRStats.load_serialized = ["Elf", "Warrior Mage", "Male", 25, 5, 15, 10, 12, 14, 18, 16, 20, 11, 5, 30, 7, 50]
      def self.load_serialized=(array)
        return if array.nil? || array.empty?

        @@race, @@guild, @@gender, @@age = array[0..3]
        @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance = array[4..16]
      end

      # Checks if the character's guild is Barbarian
      # @return [Boolean] True if the guild is Barbarian, false otherwise
      # @example Checking if the character is a Barbarian
      #   is_barbarian = Lich::DragonRealms::DRStats.barbarian?
      def self.barbarian?
        @@guild == 'Barbarian'
      end

      # Checks if the character's guild is Bard
      # @return [Boolean] True if the guild is Bard, false otherwise
      # @example Checking if the character is a Bard
      #   is_bard = Lich::DragonRealms::DRStats.bard?
      def self.bard?
        @@guild == 'Bard'
      end

      # Checks if the character's guild is Cleric
      # @return [Boolean] True if the guild is Cleric, false otherwise
      # @example Checking if the character is a Cleric
      #   is_cleric = Lich::DragonRealms::DRStats.cleric?
      def self.cleric?
        @@guild == 'Cleric'
      end

      # Checks if the character's guild is Commoner
      # @return [Boolean] True if the guild is Commoner, false otherwise
      # @example Checking if the character is a Commoner
      #   is_commoner = Lich::DragonRealms::DRStats.commoner?
      def self.commoner?
        @@guild == 'Commoner'
      end

      # Checks if the character's guild is Empath
      # @return [Boolean] True if the guild is Empath, false otherwise
      # @example Checking if the character is an Empath
      #   is_empath = Lich::DragonRealms::DRStats.empath?
      def self.empath?
        @@guild == 'Empath'
      end

      # Checks if the character's guild is Moon Mage
      # @return [Boolean] True if the guild is Moon Mage, false otherwise
      # @example Checking if the character is a Moon Mage
      #   is_moon_mage = Lich::DragonRealms::DRStats.moon_mage?
      def self.moon_mage?
        @@guild == 'Moon Mage'
      end

      # Checks if the character's guild is Necromancer
      # @return [Boolean] True if the guild is Necromancer, false otherwise
      # @example Checking if the character is a Necromancer
      #   is_necromancer = Lich::DragonRealms::DRStats.necromancer?
      def self.necromancer?
        @@guild == 'Necromancer'
      end

      # Checks if the character's guild is Paladin
      # @return [Boolean] True if the guild is Paladin, false otherwise
      # @example Checking if the character is a Paladin
      #   is_paladin = Lich::DragonRealms::DRStats.paladin?
      def self.paladin?
        @@guild == 'Paladin'
      end

      # Checks if the character's guild is Ranger
      # @return [Boolean] True if the guild is Ranger, false otherwise
      # @example Checking if the character is a Ranger
      #   is_ranger = Lich::DragonRealms::DRStats.ranger?
      def self.ranger?
        @@guild == 'Ranger'
      end

      # Checks if the character's guild is Thief
      # @return [Boolean] True if the guild is Thief, false otherwise
      # @example Checking if the character is a Thief
      #   is_thief = Lich::DragonRealms::DRStats.thief?
      def self.thief?
        @@guild == 'Thief'
      end

      # Checks if the character's guild is Trader
      # @return [Boolean] True if the guild is Trader, false otherwise
      # @example Checking if the character is a Trader
      #   is_trader = Lich::DragonRealms::DRStats.trader?
      def self.trader?
        @@guild == 'Trader'
      end

      # Checks if the character's guild is Warrior Mage
      # @return [Boolean] True if the guild is Warrior Mage, false otherwise
      # @example Checking if the character is a Warrior Mage
      #   is_warrior_mage = Lich::DragonRealms::DRStats.warrior_mage?
      def self.warrior_mage?
        @@guild == 'Warrior Mage'
      end
    end
  end
end
