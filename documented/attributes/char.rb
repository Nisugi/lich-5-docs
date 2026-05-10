
module Lich
  module Common
    # Represents a character in the game.
    #
    # This class provides methods to access various character attributes.
    #
    # @see XMLData for data retrieval.
    class Char
      # Initializes the character (deprecated).
      #
      # @param _blah [Object] unused parameter
      # @return [void]
      # @deprecated Char.init is no longer used.
      def Char.init(_blah)
        echo 'Char.init is no longer used. Update or fix your script.'
      end

      # Returns the name of the character.
      # @return [String] the character's name.
      def Char.name
        XMLData.name
      end

      # Returns the current stance of the character.
      # @return [String] the character's stance text.
      def Char.stance
        XMLData.stance_text
      end

      # Returns the percentage of the character's stance.
      # @return [Integer] the percentage value of the stance.
      def Char.percent_stance
        XMLData.stance_value
      end

      # Returns the current encumbrance of the character.
      # @return [String] the encumbrance text.
      def Char.encumbrance
        XMLData.encumbrance_text
      end

      # Returns the percentage of the character's encumbrance.
      # @return [Integer] the percentage value of the encumbrance.
      def Char.percent_encumbrance
        XMLData.encumbrance_value
      end

      # Returns the current health of the character.
      # @return [Integer] the character's health.
      def Char.health
        XMLData.health
      end

      # Returns the current mana of the character.
      # @return [Integer] the character's mana.
      def Char.mana
        XMLData.mana
      end

      # Returns the current spirit of the character.
      # @return [Integer] the character's spirit.
      def Char.spirit
        XMLData.spirit
      end

      # Returns the current stamina of the character.
      # @return [Integer] the character's stamina.
      def Char.stamina
        XMLData.stamina
      end

      # Returns the maximum health of the character.
      # @return [Integer] the character's maximum health.
      def Char.max_health
        # Object.module_eval { XMLData.max_health }
        XMLData.max_health
      end

      # Returns the maximum health of the character (deprecated).
      #
      # @return [Integer] the character's maximum health.
      # @deprecated Use Char.max_health instead.
      def Char.maxhealth
        Lich.deprecated("Char.maxhealth", "Char.max_health", caller[0], fe_log: true)
        Char.max_health
      end

      # Returns the maximum mana of the character.
      # @return [Integer] the character's maximum mana.
      def Char.max_mana
        Object.module_eval { XMLData.max_mana }
      end

      # Returns the maximum mana of the character (deprecated).
      #
      # @return [Integer] the character's maximum mana.
      # @deprecated Use Char.max_mana instead.
      def Char.maxmana
        Lich.deprecated("Char.maxmana", "Char.max_mana", caller[0], fe_log: true)
        Char.max_mana
      end

      # Returns the maximum spirit of the character.
      # @return [Integer] the character's maximum spirit.
      def Char.max_spirit
        Object.module_eval { XMLData.max_spirit }
      end

      # Returns the maximum spirit of the character (deprecated).
      #
      # @return [Integer] the character's maximum spirit.
      # @deprecated Use Char.max_spirit instead.
      def Char.maxspirit
        Lich.deprecated("Char.maxspirit", "Char.max_spirit", caller[0], fe_log: true)
        Char.max_spirit
      end

      # Returns the maximum stamina of the character.
      # @return [Integer] the character's maximum stamina.
      def Char.max_stamina
        Object.module_eval { XMLData.max_stamina }
      end

      # Returns the maximum stamina of the character (deprecated).
      #
      # @return [Integer] the character's maximum stamina.
      # @deprecated Use Char.max_stamina instead.
      def Char.maxstamina
        Lich.deprecated("Char.maxstamina", "Char.max_stamina", caller[0], fe_log: true)
        Char.max_stamina
      end

      # Returns the percentage of the character's health.
      # @return [Integer] the percentage value of the health.
      def Char.percent_health
        ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i
      end

      # Returns the percentage of the character's mana.
      # @return [Integer] the percentage value of the mana.
      def Char.percent_mana
        if XMLData.max_mana == 0
          100
        else
          ((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
        end
      end

      # Returns the percentage of the character's spirit.
      # @return [Integer] the percentage value of the spirit.
      def Char.percent_spirit
        ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i
      end

      # Returns the percentage of the character's stamina.
      # @return [Integer] the percentage value of the stamina.
      def Char.percent_stamina
        if XMLData.max_stamina == 0
          100
        else
          ((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
        end
      end

      # Dumps character information (deprecated).
      #
      # @return [void]
      # @deprecated Char.dump_info is no longer used.
      def Char.dump_info
        echo "Char.dump_info is no longer used. Update or fix your script."
      end

      # Loads character information from a string (deprecated).
      #
      # @param _string [String] the string to load
      # @return [void]
      # @deprecated Char.load_info is no longer used.
      def Char.load_info(_string)
        echo "Char.load_info is no longer used. Update or fix your script."
      end

      # Checks if the character responds to a method, including Stats, Skills, and Spellsong.
      # @param m [Symbol] the method name
      # @param args [Array] additional arguments
      # @return [Boolean] true if the method is available.
      def Char.respond_to?(m, *args)
        [Stats, Skills, Spellsong].any? { |k| k.respond_to?(m) } or super(m, *args)
      end

      # Handles missing methods by delegating to Stats, Skills, or Spellsong.
      # @param meth [Symbol] the method name
      # @param args [Array] additional arguments
      # @return [Object] the result of the delegated method or raises NoMethodError.
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

      # Provides character information (deprecated).
      #
      # @return [void]
      # @deprecated Char.info is no longer supported.
      def Char.info
        echo "Char.info is no longer supported. Update or fix your script."
      end

      # Provides character skills information (deprecated).
      #
      # @return [void]
      # @deprecated Char.skills is no longer supported.
      def Char.skills
        echo "Char.skills is no longer supported. Update or fix your script."
      end

      # Returns the citizenship of the character if applicable.
      # @return [String, nil] the citizenship value or nil if not applicable.
      def Char.citizenship
        Infomon.get('citizenship') if XMLData.game =~ /^GS/
      end

      # Sets the citizenship of the character (deprecated).
      #
      # @param _val [String] the citizenship value
      # @return [void]
      # @deprecated Updating via Char.citizenship is no longer supported.
      def Char.citizenship=(_val)
        echo "Updating via Char.citizenship is no longer supported. Update or fix your script."
      end

      # Returns the 'che' value of the character if applicable.
      # @return [String, nil] the 'che' value or nil if not applicable.
      def Char.che
        Infomon.get('che') if XMLData.game =~ /^GS/
      end
    end
  end
end
