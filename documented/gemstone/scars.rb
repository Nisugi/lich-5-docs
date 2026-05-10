
module Lich
  module Gemstone
    # Represents the scars of a character in the game.
    #
    # This class provides methods to access and manipulate the scar data
    # associated with various body parts of a character.
    #
    # @see Lich::Gemstone::CharacterStatus
    class Scars < Gemstone::CharacterStatus # GameBase::CharacterStatus
      class << self
        # Body part accessor methods
        # XML from Simutronics drives the structure of the scar naming (eg. leftEye)
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
        # This dynamically creates methods for accessing scar data for each
        # body part defined in the BODY_PARTS constant.
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

        # Returns the scar level for the left eye.
        # @return [String, nil] the scar level for the left eye or nil if not present
        def left_eye; leftEye; end
        # Returns the scar level for the right eye.
        # @return [String, nil] the scar level for the right eye or nil if not present
        def right_eye; rightEye; end
        def left_arm; leftArm; end
        def right_arm; rightArm; end
        def left_hand; leftHand; end
        def right_hand; rightHand; end
        def left_leg; leftLeg; end
        def right_leg; rightLeg; end
        def left_foot; leftFoot; end
        def right_foot; rightFoot; end

        # Returns the maximum scar level for both arms and hands.
        # @return [String, nil] the maximum scar level for arms or nil if not present
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['scar'],
            XMLData.injuries['rightArm']['scar'],
            XMLData.injuries['leftHand']['scar'],
            XMLData.injuries['rightHand']['scar']
          ].max
        end

        # Returns the maximum scar level for both arms, hands, legs.
        # @return [String, nil] the maximum scar level for limbs or nil if not present
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
        # @return [String, nil] the maximum scar level for the torso or nil if not present
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

        # Returns the scar level for a specified body part.
        # @param part [Symbol] the body part to check (e.g., :leftEye)
        # @return [String, nil] the scar level for the specified body part or nil if not present
        def scar_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['scar']
        end

        # Returns a hash of all scars for the character.
        # @return [Hash<Symbol, String>] a hash mapping body parts to their scar levels
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
