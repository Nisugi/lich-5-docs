
module Lich
  module Gemstone
    # Represents the character's wounds and injuries in the game.
    #
    # This class provides methods to access and manipulate the wound data for various body parts.
    #
    # @see Lich::Gemstone::CharacterStatus
    class Wounds < Gemstone::CharacterStatus # GameBase::CharacterStatus
      class << self
        # Body part accessor methods
        # XML from Simutronics drives the structure of the wound naming (eg. leftEye)
        # The following is a hash of the body parts and shorthand aliases created for more idiomatic Ruby
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
        # Defines methods for each body part and its aliases.
        #
        # This dynamically creates methods for accessing wound data for each body part defined in the BODY_PARTS constant.
        BODY_PARTS.each do |part, aliases|
          # Define the primary method
          define_method(part) do
            fix_injury_mode('both') # continue to use 'both' (_injury2) for now

            XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['wound']
          end

          # Define alias methods
          aliases.each do |ali|
            alias_method ali, part
          end
        end

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

        # Returns the maximum wound level for both arms and hands.
        #
        # @return [Integer] the maximum wound level among the left arm, right arm, left hand, and right hand.
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['wound'],
            XMLData.injuries['rightArm']['wound'],
            XMLData.injuries['leftHand']['wound'],
            XMLData.injuries['rightHand']['wound']
          ].max
        end

        # Returns the maximum wound level for all limbs (arms and legs).
        #
        # @return [Integer] the maximum wound level among the left arm, right arm, left hand, right hand, left leg, and right leg.
        def limbs
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['wound'],
            XMLData.injuries['rightArm']['wound'],
            XMLData.injuries['leftHand']['wound'],
            XMLData.injuries['rightHand']['wound'],
            XMLData.injuries['leftLeg']['wound'],
            XMLData.injuries['rightLeg']['wound']
          ].max
        end

        # Returns the maximum wound level for the torso and head.
        #
        # @return [Integer] the maximum wound level among the right eye, left eye, chest, abdomen, and back.
        def torso
          fix_injury_mode('both')
          [
            XMLData.injuries['rightEye']['wound'],
            XMLData.injuries['leftEye']['wound'],
            XMLData.injuries['chest']['wound'],
            XMLData.injuries['abdomen']['wound'],
            XMLData.injuries['back']['wound']
          ].max
        end

        # Returns the wound level for a specific body part.
        #
        # @param part [Symbol] the body part to check (e.g., :leftArm)
        # @return [Integer, nil] the wound level for the specified body part, or nil if not found.
        def wound_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['wound']
        end

        # Returns a hash of all wounds for each body part.
        #
        # @return [Hash] a hash where keys are body part symbols and values are their corresponding wound levels.
        def all_wounds
          fix_injury_mode('both')
          XMLData.injuries.transform_values { |v| v['wound'] }
        end
      end
    end
  end
end
