# API for char Status
# todo: should include jaws / condemn / others?

require "ostruct"

# Lich module for the Gemstone project
# This module contains various functionalities related to the Lich project.
module Lich
  # Gemstone module within the Lich project
  # This module encompasses features and functionalities specific to the Gemstone aspect of Lich.
  module Gemstone
    # Status module for character status management
    # This module provides methods to check various character statuses.
    # @example Checking if a character is thorned
    #   Lich::Gemstone::Status.thorned?
    module Status
      # Checks if the character is thorned
      # @return [Boolean] true if the character is thorned, false otherwise
      # @example Checking thorned status
      #   Lich::Gemstone::Status.thorned?
      def self.thorned? # added 2024-09-08
        (Infomon.get_bool("status.thorned") && Effects::Debuffs.active?(/Wall of Thorns Poison [1-5]/))
      end

      # Checks if the character is bound
      # @return [Boolean] true if the character is bound, false otherwise
      # @example Checking bound status
      #   Lich::Gemstone::Status.bound?
      def self.bound?
        Infomon.get_bool("status.bound") && (Effects::Debuffs.active?('Bind') || Effects::Debuffs.active?(214))
      end

      # Checks if the character is calmed
      # @return [Boolean] true if the character is calmed, false otherwise
      # @example Checking calmed status
      #   Lich::Gemstone::Status.calmed?
      def self.calmed?
        Infomon.get_bool("status.calmed") && (Effects::Debuffs.active?('Calm') || Effects::Debuffs.active?(201))
      end

      # Checks if the character is in a cutthroat state
      # @return [Boolean] true if the character is cutthroat, false otherwise
      # @example Checking cutthroat status
      #   Lich::Gemstone::Status.cutthroat?
      def self.cutthroat?
        Infomon.get_bool("status.cutthroat") && Effects::Debuffs.active?('Major Bleed')
      end

      # Checks if the character is silenced
      # @return [Boolean] true if the character is silenced, false otherwise
      # @example Checking silenced status
      #   Lich::Gemstone::Status.silenced?
      def self.silenced?
        Infomon.get_bool("status.silenced") && Effects::Debuffs.active?('Silenced')
      end

      # Checks if the character is sleeping
      # @return [Boolean] true if the character is sleeping, false otherwise
      # @example Checking sleeping status
      #   Lich::Gemstone::Status.sleeping?
      def self.sleeping?
        Infomon.get_bool("status.sleeping") && (Effects::Debuffs.active?('Sleep') || Effects::Debuffs.active?(501))
      end

      # deprecate these in global_defs after warning, consider bringing other status maps over
      # Checks if the character is webbed
      # @return [Boolean] true if the character is webbed, false otherwise
      # @note This method is marked for deprecation.
      # @example Checking webbed status
      #   Lich::Gemstone::Status.webbed?
      def self.webbed?
        XMLData.indicator['IconWEBBED'] == 'y'
      end

      # Checks if the character is dead
      # @return [Boolean] true if the character is dead, false otherwise
      # @example Checking dead status
      #   Lich::Gemstone::Status.dead?
      def self.dead?
        XMLData.indicator['IconDEAD'] == 'y'
      end

      # Checks if the character is stunned
      # @return [Boolean] true if the character is stunned, false otherwise
      # @example Checking stunned status
      #   Lich::Gemstone::Status.stunned?
      def self.stunned?
        XMLData.indicator['IconSTUNNED'] == 'y'
      end

      # Checks if the character is muckled (webbed, dead, stunned, bound, or sleeping)
      # @return [Boolean] true if the character is muckled, false otherwise
      # @example Checking muckled status
      #   Lich::Gemstone::Status.muckled?
      def self.muckled?
        return Status.webbed? || Status.dead? || Status.stunned? || Status.bound? || Status.sleeping?
      end

      # todo: does this serve a purpose?
      # Serializes the current status of the character
      # @return [Array<Boolean>] an array of boolean values representing various statuses
      # @example Serializing status
      #   Lich::Gemstone::Status.serialize
      def self.serialize
        [self.bound?, self.calmed?, self.cutthroat?, self.silenced?, self.sleeping?]
      end
    end
  end
end
