
module Lich
  module Common
    # Represents a character in the game.
    #
    # This class provides methods to access various character attributes.
    # @see Lich::Common
    class Char
      # Initializes the character (deprecated).
      #
      # This method is no longer used and should be updated in scripts.
      # @param _blah [Object] unused parameter
      # @return [void]
      # @deprecated
      def Char.init(_blah)
        echo 'Char.init is no longer used. Update or fix your script.'
      end

      # Returns the name of the character.
      # @return [String] the character's name
      def Char.name
        XMLData.name
      end

      # Returns the current stance of the character.
      # @return [String] the character's stance text
      def Char.stance
        XMLData.stance_text
      end

      # Returns the percentage of the character's stance.
      # @return [Integer] the percentage of stance
      def Char.percent_stance
        XMLData.stance_value
      end

      # Returns the current encumbrance of the character.
      # @return [String] the character's encumbrance text
      def Char.encumbrance
        XMLData.encumbrance_text
      end

      # Returns the percentage of the character's encumbrance.
      # @return [Integer] the percentage of encumbrance
      def Char.percent_encumbrance
        XMLData.encumbrance_value
      end

      # Returns the current health of the character.
      # @return [Integer] the character's health
      def Char.health
        XMLData.health
      end

      # Returns the current mana of the character.
      # @return [Integer] the character's mana
      def Char.mana
        XMLData.mana
      end

      # Returns the current spirit of the character.
      # @return [Integer] the character's spirit
      def Char.spirit
        XMLData.spirit
      end

      # Returns the current stamina of the character.
      # @return [Integer] the character's stamina
      def Char.stamina
        XMLData.stamina
      end

      # Returns the maximum health of the character.
      # @return [Integer] the character's maximum health
      def Char.max_health
        # Object.module_eval { XMLData.max_health }
        XMLData.max_health
      end

      # Returns the maximum health of the character (deprecated).
      #
      # This method is deprecated; use #max_health instead.
      # @return [Integer] the character's maximum health
      # @deprecated
      def Char.maxhealth
        Lich.deprecated("Char.maxhealth", "Char.max_health", caller[0], fe_log: true)
        Char.max_health
      end

      # Returns the maximum mana of the character.
      # @return [Integer] the character's maximum mana
      def Char.max_mana
        Object.module_eval { XMLData.max_mana }
      end

      # Returns the maximum mana of the character (deprecated).
      #
      # This method is deprecated; use #max_mana instead.
      # @return [Integer] the character's maximum mana
      # @deprecated
      def Char.maxmana
        Lich.deprecated("Char.maxmana", "Char.max_mana", caller[0], fe_log: true)
        Char.max_mana
      end

      # Returns the maximum spirit of the character.
      # @return [Integer] the character's maximum spirit
      def Char.max_spirit
        Object.module_eval { XMLData.max_spirit }
      end

      # Returns the maximum spirit of the character (deprecated).
      #
      # This method is deprecated; use #max_spirit instead.
      # @return [Integer] the character's maximum spirit
      # @deprecated
      def Char.maxspirit
        Lich.deprecated("Char.maxspirit", "Char.max_spirit", caller[0], fe_log: true)
        Char.max_spirit
      end

      # Returns the maximum stamina of the character.
      # @return [Integer] the character's maximum stamina
      def Char.max_stamina
        Object.module_eval { XMLData.max_stamina }
      end

      # Returns the maximum stamina of the character (deprecated).
      #
      # This method is deprecated; use #max_stamina instead.
      # @return [Integer] the character's maximum stamina
      # @deprecated
      def Char.maxstamina
        Lich.deprecated("Char.maxstamina", "Char.max_stamina", caller[0], fe_log: true)
        Char.max_stamina
      end

      # Returns the percentage of the character's health.
      # @return [Integer] the percentage of health
      def Char.percent_health
        ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i
      end

      # Returns the percentage of the character's mana.
      # @return [Integer] the percentage of mana
      def Char.percent_mana
        if XMLData.max_mana == 0
          100
        else
          ((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
        end
      end

      # Returns the percentage of the character's spirit.
      # @return [Integer] the percentage of spirit
      def Char.percent_spirit
        ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i
      end

      # Returns the percentage of the character's stamina.
      # @return [Integer] the percentage of stamina
      def Char.percent_stamina
        if XMLData.max_stamina == 0
          100
        else
          ((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
        end
      end

      # Dumps character information (deprecated).
      #
      # This method is no longer used and should be updated in scripts.
      # @return [void]
      # @deprecated
      def Char.dump_info
        echo "Char.dump_info is no longer used. Update or fix your script."
      end

      # Loads character information (deprecated).
      #
      # This method is no longer used and should be updated in scripts.
      # @param _string [String] unused parameter
      # @return [void]
      # @deprecated
      def Char.load_info(_string)
        echo "Char.load_info is no longer used. Update or fix your script."
      end

      # Checks if the character responds to a method.
      # @param m [Symbol] the method name to check
      # @param args [Array] additional arguments for the method
      # @return [Boolean] true if the method is supported
      def Char.respond_to?(m, *args)
        [Stats, Skills, Spellsong].any? { |k| k.respond_to?(m) } or super(m, *args)
      end

      # Handles calls to methods that are not defined.
      # @param meth [Symbol] the method name that was called
      # @param args [Array] arguments passed to the method
      # @return [Object] the result of the method call or raises an error
      def Char.method_missing(meth, *args)
        polyfill = [Stats, Skills, Spellsong].find { |klass|
          klass.respond_to?(meth, *args)
        }
        if polyfill
          Lich.deprecated("Char.#{meth}", "#{polyfill}.#{meth}", caller[0])
          return polyfill.send(meth, *args)
        end
        super(meth, *args)
      end

      # Returns character information (deprecated).
      #
      # This method is no longer supported and should be updated in scripts.
      # @return [void]
      # @deprecated
      def Char.info
        echo "Char.info is no longer supported. Update or fix your script."
      end

      # Returns character skills (deprecated).
      #
      # This method is no longer supported and should be updated in scripts.
      # @return [void]
      # @deprecated
      def Char.skills
        echo "Char.skills is no longer supported. Update or fix your script."
      end

      # Returns the citizenship of the character if applicable.
      # @return [String, nil] the character's citizenship or nil
      def Char.citizenship
        Infomon.get('citizenship') if XMLData.game =~ /^GS/
      end

      # Sets the citizenship of the character (deprecated).
      #
      # This method is no longer supported and should be updated in scripts.
      # @param _val [String] the new citizenship value
      # @return [void]
      # @deprecated
      def Char.citizenship=(_val)
        echo "Updating via Char.citizenship is no longer supported. Update or fix your script."
      end

      # Returns the 'che' attribute of the character if applicable.
      # @return [String, nil] the character's 'che' value or nil
      def Char.che
        Infomon.get('che') if XMLData.game =~ /^GS/
      end
    end
  end
end
