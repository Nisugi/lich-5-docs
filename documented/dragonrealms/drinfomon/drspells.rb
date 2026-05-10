
# Provides functionality for the Lich5 project.
#
# @see Lich::DragonRealms
module Lich
  module DragonRealms
    # Module for managing spells in DragonRealms.
    #
    # This module contains methods to access and manipulate known spells and features.
    module DRSpells
      @@known_spells = {}
      @@known_feats = {}
      @@spellbook_format = nil # 'column-formatted' or 'non-column'

      @@grabbing_known_spells = false
      @@grabbing_known_barbarian_abilities = false
      @@grabbing_known_khri = false

      # Retrieves the currently active spells.
      # @return [Array<String>] list of active spells.
      def self.active_spells
        XMLData.dr_active_spells
      end

      # Returns a hash of known spells.
      # @return [Hash] known spells with their details.
      def self.known_spells
        @@known_spells
      end

      # Returns a hash of known feats.
      # @return [Hash] known feats with their details.
      def self.known_feats
        @@known_feats
      end

      # Retrieves the slivers of currently active spells.
      # @return [Array<String>] list of spell slivers.
      def self.slivers
        XMLData.dr_active_spells_slivers
      end

      # Retrieves the stellar percentage of active spells.
      # @return [Integer] percentage value.
      def self.stellar_percentage
        XMLData.dr_active_spells_stellar_percentage
      end

      def self.grabbing_known_spells
        @@grabbing_known_spells
      end

      def self.grabbing_known_spells=(val)
        @@grabbing_known_spells = val
      end

      # Checks if known barbarian abilities are being grabbed.
      # @return [Boolean] true if grabbing, false otherwise.
      # @api private
      def self.check_known_barbarian_abilities
        @@grabbing_known_barbarian_abilities
      end

      def self.check_known_barbarian_abilities=(val)
        @@grabbing_known_barbarian_abilities = val
      end

      # Checks if known khri are being grabbed.
      # @return [Boolean] true if grabbing, false otherwise.
      # @api private
      def self.grabbing_known_khri
        @@grabbing_known_khri
      end

      def self.grabbing_known_khri=(val)
        @@grabbing_known_khri = val
      end

      # Retrieves the current spellbook format.
      # @return [String, nil] the format of the spellbook or nil if not set.
      def self.spellbook_format
        @@spellbook_format
      end

      def self.spellbook_format=(val)
        @@spellbook_format = val
      end
    end
  end
end
