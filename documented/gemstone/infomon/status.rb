# API for char Status
# todo: should include jaws / condemn / others?

require "ostruct"

# Lich module provides functionality related to the Lich5 project.
# @example Including the Lich module
#   include Lich
module Lich
  # Gemstone module contains functionalities specific to the Gemstone game.
  # @example Including the Gemstone module
  #   include Lich::Gemstone
  module Gemstone
    # Status module provides methods to check various character statuses.
    # @example Checking if a character is bound
    #   Status.bound?
    module Status
      # Checks if the character is thorned.
      # @return [Boolean] true if the character is thorned, false otherwise
      # @example Checking thorned status
      #   Status.thorned?
      def self.thorned? # added 2024-09-08
        (Infomon.get_bool("status.thorned") && Effects::Debuffs.active?(/Wall of Thorns Poison [1-5]/))
      end

      # Checks if the character is bound.
      # @return [Boolean] true if the character is bound, false otherwise
      # @example Checking bound status
      #   Status.bound?
      def self.bound?
        Infomon.get_bool("status.bound") && (Effects::Debuffs.active?('Bind') || Effects::Debuffs.active?(214))
      end

      # Checks if the character is calmed.
      # @return [Boolean] true if the character is calmed, false otherwise
      # @example Checking calmed status
      #   Status.calmed?
      def self.calmed?
        Infomon.get_bool("status.calmed") && (Effects::Debuffs.active?('Calm') || Effects::Debuffs.active?(201))
      end

      # Checks if the character is cutthroat.
      # @return [Boolean] true if the character is cutthroat, false otherwise
      # @example Checking cutthroat status
      #   Status.cutthroat?
      def self.cutthroat?
        Infomon.get_bool("status.cutthroat") && (Effects::Debuffs.active?('Major Bleed') || Effects::Debuffs.active?('Silenced'))
      end

      # Checks if the character is silenced.
      # @return [Boolean] true if the character is silenced, false otherwise
      # @example Checking silenced status
      #   Status.silenced?
      def self.silenced?
        Infomon.get_bool("status.silenced") && Effects::Debuffs.active?('Silenced')
      end

      # Checks if the character is sleeping.
      # @return [Boolean] true if the character is sleeping, false otherwise
      # @example Checking sleeping status
      #   Status.sleeping?
      def self.sleeping?
        Infomon.get_bool("status.sleeping") && (Effects::Debuffs.active?('Sleep') || Effects::Debuffs.active?(501))
      end

      # Checks if the character is webbed.
      # @return [Boolean] true if the character is webbed, false otherwise
      # @example Checking webbed status
      #   Status.webbed?
      def self.webbed?
        XMLData.indicator['IconWEBBED'] == 'y'
      end

      # Checks if the character is dead.
      # @return [Boolean] true if the character is dead, false otherwise
      # @example Checking dead status
      #   Status.dead?
      def self.dead?
        XMLData.indicator['IconDEAD'] == 'y'
      end

      # Checks if the character is stunned.
      # @return [Boolean] true if the character is stunned, false otherwise
      # @example Checking stunned status
      #   Status.stunned?
      def self.stunned?
        XMLData.indicator['IconSTUNNED'] == 'y'
      end

      # Checks if the character is muckled (webbed, dead, stunned, bound, or sleeping).
      # @return [Boolean] true if the character is muckled, false otherwise
      # @example Checking muckled status
      #   Status.muckled?
      def self.muckled?
        return Status.webbed? || Status.dead? || Status.stunned? || Status.bound? || Status.sleeping?
      end

      # Serializes the current status of the character.
      # @return [Array<Boolean>] an array of booleans representing various statuses
      # @example Serializing status
      #   Status.serialize
      def self.serialize
        [self.bound?, self.calmed?, self.cutthroat?, self.silenced?, self.sleeping?]
      end
    end
  end
end
