
module Lich
  module Gemstone
    # Represents the character's wounds and injuries in the game.
    #
    # This class provides methods to access and manage the wounds of various body parts.
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

        # Returns the wound for the left eye.
        # @return [String, nil] the wound description or nil if no wound exists.
        def left_eye; leftEye; end
        # Returns the wound for the right eye.
        # @return [String, nil] the wound description or nil if no wound exists.
        def right_eye; rightEye; end
        def left_arm; leftArm; end
        def right_arm; rightArm; end
        def left_hand; leftHand; end
        def right_hand; rightHand; end
        def left_leg; leftLeg; end
        def right_leg; rightLeg; end
        def left_foot; leftFoot; end
        def right_foot; rightFoot; end

        # Returns the most severe wound among the arms and hands.
        # @return [String, nil] the most severe wound description or nil if no wounds exist.
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['wound'],
            XMLData.injuries['rightArm']['wound'],
            XMLData.injuries['leftHand']['wound'],
            XMLData.injuries['rightHand']['wound']
          ].max
        end

        # Returns the most severe wound among all limbs (arms and legs).
        # @return [String, nil] the most severe wound description or nil if no wounds exist.
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

        # Returns the most severe wound among the torso and head.
        # @return [String, nil] the most severe wound description or nil if no wounds exist.
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

        # Returns the wound level for a specified body part.
        # @param part [Symbol] the body part to check (e.g., :leftArm)
        # @return [String, nil] the wound description or nil if no wound exists.
        def wound_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['wound']
        end

        # Returns a hash of all wounds for each body part.
        # @return [Hash<Symbol, String, nil>] a hash mapping body parts to their wound descriptions.
        def all_wounds
          fix_injury_mode('both')
          XMLData.injuries.transform_values { |v| v['wound'] }
        end
      end
    end
  end
end
