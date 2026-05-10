
# The Lich module contains functionality for the Lich5 project.
# It serves as a namespace for various components.
module Lich
  # The DragonRealms module contains specific functionalities related to the DragonRealms game.
  # It groups related classes and modules.
  module DragonRealms
    # The DRSpells module manages spells and abilities in the DragonRealms game.
    # It provides access to known spells, features, and other related data.
    # @example Accessing known spells
    #   spells = Lich::DragonRealms::DRSpells.known_spells
    module DRSpells
      @@known_spells = {}
      @@known_feats = {}
      @@spellbook_format = nil # 'column-formatted' or 'non-column'

      @@grabbing_known_spells = false
      @@grabbing_known_barbarian_abilities = false
      @@grabbing_known_khri = false

      # Returns the currently active spells.
      # @return [Array] An array of active spells.
      def self.active_spells
        XMLData.dr_active_spells
      end

      # Returns a hash of known spells.
      # @return [Hash] A hash containing known spells.
      def self.known_spells
        @@known_spells
      end

      # Returns a hash of known feats.
      # @return [Hash] A hash containing known feats.
      def self.known_feats
        @@known_feats
      end

      # Returns the slivers of currently active spells.
      # @return [Array] An array of spell slivers.
      def self.slivers
        XMLData.dr_active_spells_slivers
      end

      # Returns the stellar percentage of active spells.
      # @return [Float] A float representing the stellar percentage.
      def self.stellar_percentage
        XMLData.dr_active_spells_stellar_percentage
      end

      # Checks if the system is currently grabbing known spells.
      # @return [Boolean] True if grabbing known spells, false otherwise.
      def self.grabbing_known_spells
        @@grabbing_known_spells
      end

      # Sets the state of grabbing known spells.
      # @param val [Boolean] The new state for grabbing known spells.
      def self.grabbing_known_spells=(val)
        @@grabbing_known_spells = val
      end

      # Checks if the system is currently grabbing known barbarian abilities.
      # @return [Boolean] True if grabbing known barbarian abilities, false otherwise.
      def self.check_known_barbarian_abilities
        @@grabbing_known_barbarian_abilities
      end

      # Sets the state of grabbing known barbarian abilities.
      # @param val [Boolean] The new state for grabbing known barbarian abilities.
      def self.check_known_barbarian_abilities=(val)
        @@grabbing_known_barbarian_abilities = val
      end

      # Checks if the system is currently grabbing known khri.
      # @return [Boolean] True if grabbing known khri, false otherwise.
      def self.grabbing_known_khri
        @@grabbing_known_khri
      end

      # Sets the state of grabbing known khri.
      # @param val [Boolean] The new state for grabbing known khri.
      def self.grabbing_known_khri=(val)
        @@grabbing_known_khri = val
      end

      # Returns the current format of the spellbook.
      # @return [String, nil] The spellbook format, or nil if not set.
      def self.spellbook_format
        @@spellbook_format
      end

      # Sets the format of the spellbook.
      # @param val [String] The new format for the spellbook.
      def self.spellbook_format=(val)
        @@spellbook_format = val
      end
    end
  end
end
