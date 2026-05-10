
module Lich
  module Common
    module CharSettings

      # Returns the active scope for character settings.
      #
      # This scope is a combination of the current game and character name.
      # @return [String] the active scope in the format "game:name"
      def self.active_scope
        # Ensure XMLData.game and XMLData.name are available and up-to-date when scope is needed
        "#{XMLData.game}:#{XMLData.name}"
      end

      # Retrieves a scoped setting by name.
      #
      # @param name [String] the name of the setting to retrieve
      # @return [OpenStruct] the value of the setting
      def self.[](name)
        Settings.get_scoped_setting(active_scope, name)
      end

      # Sets a scoped setting by name.
      #
      # @param name [String] the name of the setting to set
      # @param value [OpenStruct] the value to assign to the setting
      # @return [void]
      def self.[]=(name, value)
        Settings.set_script_settings(active_scope, name, value)
      end

      # Converts the character settings to a hash-like structure.
      #
      # This method returns a root proxy for the character settings scope,
      # allowing persistent modifications on the returned object for legacy support.
      # @return [OpenStruct] a proxy for the character settings
      def self.to_hash
        # NB:  This method does not behave like a standard Ruby hash request.
        # It returns a root proxy for the character settings scope, allowing persistent
        # modifications on the returned object for legacy support.
        Settings.wrap_value_if_container(Settings.current_script_settings(active_scope), active_scope, [])
      end

      # Loads character settings (deprecated).
      #
      # This method is deprecated and not applicable.
      # @return [nil]
      def CharSettings.load
        Lich.deprecated("CharSettings.load", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves character settings (deprecated).
      #
      # This method is deprecated and not applicable.
      # @return [nil]
      def CharSettings.save
        Lich.deprecated("CharSettings.save", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves all character settings (deprecated).
      #
      # This method is deprecated and not applicable.
      # @return [nil]
      def CharSettings.save_all
        Lich.deprecated("CharSettings.save_all", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Clears character settings (deprecated).
      #
      # This method is deprecated and not applicable.
      # @return [nil]
      def CharSettings.clear
        Lich.deprecated("CharSettings.clear", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Sets the auto setting (deprecated).
      #
      # This method is deprecated and not applicable.
      # @param _val [Boolean] the value to set for auto
      # @return [void]
      def CharSettings.auto=(_val)
        Lich.deprecated("CharSettings.auto=(val)", "not using, not applicable,", caller[0], fe_log: true)
      end

      # Retrieves the auto setting (deprecated).
      #
      # This method is deprecated and not applicable.
      # @return [nil]
      def CharSettings.auto
        Lich.deprecated("CharSettings.auto", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Retrieves the autoload setting (deprecated).
      #
      # This method is deprecated and not applicable.
      # @return [nil]
      def CharSettings.autoload
        Lich.deprecated("CharSettings.autoload", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end
    end
  end
end
