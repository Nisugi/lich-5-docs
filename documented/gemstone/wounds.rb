
module Lich
  module Gemstone
    # Represents the Wounds class that manages character injuries in the game.
    # This class provides methods to access and manipulate the wound data for various body parts.
    # @example Accessing wounds for a character
    #   wounds = Lich::Gemstone::Wounds.new
    class Wounds < Gemstone::CharacterStatus # GameBase::CharacterStatus
      class << self
        # Body part accessor methods
        # XML from Simutronics drives the structure of the wound naming (eg. leftEye)
        # The following is a hash of the body parts and shorthand aliases created for more idiomatic Ruby
        # A hash mapping body parts to their shorthand aliases.
        # This constant is used to define methods for accessing wounds on different body parts.
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

        # Retrieves the wound information for the left eye using snake_case.
        # @return [String, nil] The wound description for the left eye or nil if not present.
        # @example Getting the left eye wound using snake_case
        #   wound_description = Wounds.left_eye
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

        # Retrieves the maximum wound level for both arms and hands.
        # @return [String, nil] The highest wound description among the left arm, right arm, left hand, and right hand.
        # @example Getting the maximum wound for arms
        #   max_wound = Wounds.arms
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['wound'],
            XMLData.injuries['rightArm']['wound'],
            XMLData.injuries['leftHand']['wound'],
            XMLData.injuries['rightHand']['wound']
          ].max
        end

        # Retrieves the maximum wound level for all limbs including arms and legs.
        # @return [String, nil] The highest wound description among all limbs.
        # @example Getting the maximum wound for limbs
        #   max_wound = Wounds.limbs
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

        # Retrieves the maximum wound level for the torso including chest, abdomen, and back.
        # @return [String, nil] The highest wound description for the torso.
        # @example Getting the maximum wound for the torso
        #   max_wound = Wounds.torso
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

        # Retrieves the wound level for a specific body part.
        # @param part [Symbol] The body part to check (e.g., :leftEye).
        # @return [String, nil] The wound description for the specified body part or nil if not present.
        # @example Getting the wound level for a specific part
        #   wound_description = Wounds.wound_level(:leftEye)
        def wound_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['wound']
        end

        # Retrieves a hash of all wounds for all body parts.
        # @return [Hash] A hash where keys are body parts and values are their wound descriptions.
        # @example Getting all wounds
        #   all_wounds = Wounds.all_wounds
        def all_wounds
          fix_injury_mode('both')
          XMLData.injuries.transform_values { |v| v['wound'] }
        end
      end
    end
  end
end
