# frozen_string_literal: true

module Lich
  module Gemstone
    # Scars class for tracking character scars
    # Scars class for tracking character scars
    #
    # This class provides methods to access and manage scars on various body parts of a character.
    # It defines both primary and alias methods for body parts, as well as composite methods for groups of body parts.
    # @example Accessing a character's left eye scar
    #   scars = Lich::Gemstone::Scars.new
    #   scars.leftEye
    class Scars < Gemstone::CharacterStatus # GameBase::CharacterStatus
      class << self
        # Body part accessor methods
        # XML from Simutronics drives the structure of the scar naming (eg. leftEye)
        # The following is a hash of the body parts and shorthand aliases created for more idiomatic Ruby
        # A hash of body parts and their shorthand aliases.
        # This constant is used to define methods for accessing scars on different body parts.
        BODY_PARTS = {
          leftEye: ['leye'],
          rightEye: ['reye'],
          head: [],
          neck: [],
          back: [],
          chest: [],
          abdomen: ['abs'],
          leftArm: ['larm'],
          rightArm: ['rarm'],
          rightHand: ['rhand'],
          leftHand: ['lhand'],
          leftLeg: ['lleg'],
          rightLeg: ['rleg'],
          leftFoot: ['lfoot'],
          rightFoot: ['rfoot'],
          nsys: ['nerves']
        }.freeze

        # Define methods for each body part and its aliases
        BODY_PARTS.each do |part, aliases|
          # Define the primary method
          define_method(part) do
            fix_injury_mode('both') # continue to use 'both' (_injury2) for now

            XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['scar']
          end

          # Define shorthand alias methods
          aliases.each do |ali|
            alias_method ali, part
          end
        end

        # Alias snake_case methods for overachievers
        # Returns the scar level for the left eye using snake_case.
        # @return [Integer, nil] The scar level for the left eye or nil if not present.
        # @note This method is an alias for leftEye.
        def left_eye; leftEye; end
        def right_eye; rightEye; end
        def left_arm; leftArm; end
        def right_arm; rightArm; end
        def left_hand; leftHand; end
        def right_hand; rightHand; end
        def left_leg; leftLeg; end
        def right_leg; rightLeg; end
        def left_foot; leftFoot; end
        def right_foot; rightFoot; end

        # Composite scar methods
        # Returns the maximum scar level for both arms and hands.
        # @return [Integer, nil] The maximum scar level for arms or nil if not present.
        # @note This method uses 'both' injury mode for consistency.
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['scar'],
            XMLData.injuries['rightArm']['scar'],
            XMLData.injuries['leftHand']['scar'],
            XMLData.injuries['rightHand']['scar']
          ].max
        end

        # Returns the maximum scar level for both arms and legs.
        # @return [Integer, nil] The maximum scar level for limbs or nil if not present.
        # @note This method uses 'both' injury mode for consistency.
        def limbs
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['scar'],
            XMLData.injuries['rightArm']['scar'],
            XMLData.injuries['leftHand']['scar'],
            XMLData.injuries['rightHand']['scar'],
            XMLData.injuries['leftLeg']['scar'],
            XMLData.injuries['rightLeg']['scar']
          ].max
        end

        # Returns the maximum scar level for the torso.
        # @return [Integer, nil] The maximum scar level for the torso or nil if not present.
        # @note This method uses 'both' injury mode for consistency.
        def torso
          fix_injury_mode('both')
          [
            XMLData.injuries['rightEye']['scar'],
            XMLData.injuries['leftEye']['scar'],
            XMLData.injuries['chest']['scar'],
            XMLData.injuries['abdomen']['scar'],
            XMLData.injuries['back']['scar']
          ].max
        end

        # Helper method to get scar level for any body part
        # Returns the scar level for a specified body part.
        # @param part [Symbol] The body part to check (e.g., :leftEye).
        # @return [Integer, nil] The scar level for the specified body part or nil if not present.
        # @note This method uses 'both' injury mode for consistency.
        def scar_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['scar']
        end

        # Helper method to get all scar levels
        # Returns a hash of all scar levels for each body part.
        # @return [Hash<Symbol, Integer>] A hash mapping body parts to their scar levels.
        # @raise [StandardError] If there is an issue retrieving the scar data.
        # @note This method temporarily changes the injury mode to 'scar' to retrieve actual scar level data.
        def all_scars
          begin
            fix_injury_mode('scar') # for this one call, we want to get actual scar level data
            result = XMLData.injuries.transform_values { |v| v['scar'] }
          ensure
            fix_injury_mode('both') # reset to both
          end
          return result
        end
      end
    end
  end
end
