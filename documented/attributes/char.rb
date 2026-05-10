
module Lich
  module Common
    # Represents a character in the game.
    # This class provides various attributes and methods related to the character.
    # @example Creating a character instance
    #   character = Lich::Common::Char.new
    class Char
      # Initializes the character (deprecated).
      # This method is no longer used and should be updated in scripts.
      # @param _blah [Object] Unused parameter.
      # @return [void]
      # @deprecated Char.init is no longer used.
      def Char.init(_blah)
        echo 'Char.init is no longer used. Update or fix your script.'
      end

      # Returns the name of the character.
      # @return [String] The name of the character.
      # @example
      #   character_name = Char.name
      def Char.name
        XMLData.name
      end

      # Returns the current stance of the character.
      # @return [String] The stance text of the character.
      # @example
      #   current_stance = Char.stance
      def Char.stance
        XMLData.stance_text
      end

      # Returns the percentage of the character's stance.
      # @return [Integer] The percentage value of the stance.
      # @example
      #   stance_percentage = Char.percent_stance
      def Char.percent_stance
        XMLData.stance_value
      end

      # Returns the encumbrance text of the character.
      # @return [String] The encumbrance description.
      # @example
      #   encumbrance_info = Char.encumbrance
      def Char.encumbrance
        XMLData.encumbrance_text
      end

      # Returns the percentage of the character's encumbrance.
      # @return [Integer] The percentage value of the encumbrance.
      # @example
      #   encumbrance_percentage = Char.percent_encumbrance
      def Char.percent_encumbrance
        XMLData.encumbrance_value
      end

      # Returns the current health of the character.
      # @return [Integer] The current health value.
      # @example
      #   current_health = Char.health
      def Char.health
        XMLData.health
      end

      # Returns the current mana of the character.
      # @return [Integer] The current mana value.
      # @example
      #   current_mana = Char.mana
      def Char.mana
        XMLData.mana
      end

      # Returns the current spirit of the character.
      # @return [Integer] The current spirit value.
      # @example
      #   current_spirit = Char.spirit
      def Char.spirit
        XMLData.spirit
      end

      # Returns the current stamina of the character.
      # @return [Integer] The current stamina value.
      # @example
      #   current_stamina = Char.stamina
      def Char.stamina
        XMLData.stamina
      end

      # Returns the maximum health of the character.
      # @return [Integer] The maximum health value.
      # @example
      #   max_health_value = Char.max_health
      def Char.max_health
        # Object.module_eval { XMLData.max_health }
        XMLData.max_health
      end

      # Returns the maximum health of the character (deprecated).
      # This method is deprecated and should be replaced with Char.max_health.
      # @return [Integer] The maximum health value.
      # @example
      #   max_health_value = Char.maxhealth
      # @deprecated Use Char.max_health instead.
      def Char.maxhealth
        Lich.deprecated("Char.maxhealth", "Char.max_health", caller[0], fe_log: true)
        Char.max_health
      end

      # Returns the maximum mana of the character.
      # @return [Integer] The maximum mana value.
      # @example
      #   max_mana_value = Char.max_mana
      def Char.max_mana
        Object.module_eval { XMLData.max_mana }
      end

      # Returns the maximum mana of the character (deprecated).
      # This method is deprecated and should be replaced with Char.max_mana.
      # @return [Integer] The maximum mana value.
      # @example
      #   max_mana_value = Char.maxmana
      # @deprecated Use Char.max_mana instead.
      def Char.maxmana
        Lich.deprecated("Char.maxmana", "Char.max_mana", caller[0], fe_log: true)
        Char.max_mana
      end

      # Returns the maximum spirit of the character.
      # @return [Integer] The maximum spirit value.
      # @example
      #   max_spirit_value = Char.max_spirit
      def Char.max_spirit
        Object.module_eval { XMLData.max_spirit }
      end

      # Returns the maximum spirit of the character (deprecated).
      # This method is deprecated and should be replaced with Char.max_spirit.
      # @return [Integer] The maximum spirit value.
      # @example
      #   max_spirit_value = Char.maxspirit
      # @deprecated Use Char.max_spirit instead.
      def Char.maxspirit
        Lich.deprecated("Char.maxspirit", "Char.max_spirit", caller[0], fe_log: true)
        Char.max_spirit
      end

      # Returns the maximum stamina of the character.
      # @return [Integer] The maximum stamina value.
      # @example
      #   max_stamina_value = Char.max_stamina
      def Char.max_stamina
        Object.module_eval { XMLData.max_stamina }
      end

      # Returns the maximum stamina of the character (deprecated).
      # This method is deprecated and should be replaced with Char.max_stamina.
      # @return [Integer] The maximum stamina value.
      # @example
      #   max_stamina_value = Char.maxstamina
      # @deprecated Use Char.max_stamina instead.
      def Char.maxstamina
        Lich.deprecated("Char.maxstamina", "Char.max_stamina", caller[0], fe_log: true)
        Char.max_stamina
      end

      # Returns the percentage of the character's health.
      # @return [Integer] The percentage value of health.
      # @example
      #   health_percentage = Char.percent_health
      def Char.percent_health
        ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i
      end

      # Returns the percentage of the character's mana.
      # @return [Integer] The percentage value of mana.
      # @example
      #   mana_percentage = Char.percent_mana
      def Char.percent_mana
        if XMLData.max_mana == 0
          100
        else
          ((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
        end
      end

      # Returns the percentage of the character's spirit.
      # @return [Integer] The percentage value of spirit.
      # @example
      #   spirit_percentage = Char.percent_spirit
      def Char.percent_spirit
        ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i
      end

      # Returns the percentage of the character's stamina.
      # @return [Integer] The percentage value of stamina.
      # @example
      #   stamina_percentage = Char.percent_stamina
      def Char.percent_stamina
        if XMLData.max_stamina == 0
          100
        else
          ((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
        end
      end

      # Dumps character information (deprecated).
      # This method is no longer used and should be updated in scripts.
      # @return [void]
      # @deprecated Char.dump_info is no longer used.
      def Char.dump_info
        echo "Char.dump_info is no longer used. Update or fix your script."
      end

      # Loads character information (deprecated).
      # This method is no longer used and should be updated in scripts.
      # @param _string [String] Unused parameter.
      # @return [void]
      # @deprecated Char.load_info is no longer used.
      def Char.load_info(_string)
        echo "Char.load_info is no longer used. Update or fix your script."
      end

      # Checks if the character responds to a method.
      # @param m [Symbol] The method name to check.
      # @param args [Array] Additional arguments for the method.
      # @return [Boolean] True if the method is supported, false otherwise.
      # @example
      #   can_respond = Char.respond_to?(:some_method)
      def Char.respond_to?(m, *args)
        [Stats, Skills, Spellsong].any? { |k| k.respond_to?(m) } or super(m, *args)
      end

      # Handles method calls that are not defined.
      # @param meth [Symbol] The method name that was called.
      # @param args [Array] Arguments passed to the method.
      # @return [Object] The result of the method call or raises an error.
      # @raise [NoMethodError] If the method is not found.
      # @example
      #   result = Char.some_undefined_method
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
      # This method is no longer supported and should be updated in scripts.
      # @return [void]
      # @deprecated Char.info is no longer supported.
      def Char.info
        echo "Char.info is no longer supported. Update or fix your script."
      end

      # Provides character skills information (deprecated).
      # This method is no longer supported and should be updated in scripts.
      # @return [void]
      # @deprecated Char.skills is no longer supported.
      def Char.skills
        echo "Char.skills is no longer supported. Update or fix your script."
      end

      # Returns the citizenship of the character if applicable.
      # @return [String, nil] The citizenship value or nil if not applicable.
      # @example
      #   citizenship_value = Char.citizenship
      def Char.citizenship
        Infomon.get('citizenship') if XMLData.game =~ /^GS/
      end

      # Sets the citizenship of the character (deprecated).
      # This method is no longer supported and should be updated in scripts.
      # @param _val [Object] The value to set.
      # @return [void]
      # @deprecated Updating via Char.citizenship is no longer supported.
      def Char.citizenship=(_val)
        echo "Updating via Char.citizenship is no longer supported. Update or fix your script."
      end

      # Returns the 'che' value of the character if applicable.
      # @return [String, nil] The 'che' value or nil if not applicable.
      # @example
      #   che_value = Char.che
      def Char.che
        Infomon.get('che') if XMLData.game =~ /^GS/
      end
    end
  end
end
