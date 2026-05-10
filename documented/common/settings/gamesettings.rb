
# Provides common game settings functionality.
#
# This module contains methods to access and manipulate game settings.
#
# @see Lich::Common::GameSettings
module Lich
  module Common
    module GameSettings
      # Returns the currently active game settings scope.
      # @return [OpenStruct] the active game settings scope
      def self.active_scope
        XMLData.game
      end

      # Retrieves a scoped setting by name.
      # @param name [String] the name of the setting to retrieve
      # @return [OpenStruct] the value of the setting
      def self.[](name)
        Settings.get_scoped_setting(active_scope, name)
      end

      # Sets a scoped setting by name.
      # @param name [String] the name of the setting to set
      # @param value [OpenStruct] the value to assign to the setting
      # @return [void]
      def self.[]=(name, value)
        Settings.set_script_settings(active_scope, name, value)
      end

      # Converts the game settings to a hash-like structure.
      #
      # This method does not behave like a standard Ruby hash request.
      # It returns a root proxy for the game settings scope, allowing persistent
      # modifications on the returned object for legacy support.
      # @return [OpenStruct] a hash-like representation of the game settings
      def self.to_hash
        # NB:  This method does not behave like a standard Ruby hash request.
        # It returns a root proxy for the game settings scope, allowing persistent
        # modifications on the returned object for legacy support.
        Settings.wrap_value_if_container(Settings.current_script_settings(active_scope), active_scope, [])
      end

      # Loads game settings (deprecated).
      # @return [void]
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.load
        Lich.deprecated("GameSettings.load", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves game settings (deprecated).
      # @return [void]
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.save
        Lich.deprecated("GameSettings.save", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves all game settings (deprecated).
      # @return [void]
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.save_all
        Lich.deprecated("GameSettings.save_all", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Clears game settings (deprecated).
      # @return [void]
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.clear
        Lich.deprecated("GameSettings.clear", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Sets the auto setting (deprecated).
      # @param _val [Boolean] the value to set for auto
      # @return [void]
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.auto=(_val)
        Lich.deprecated("GameSettings.auto=(val)", "not using, not applicable,", caller[0], fe_log: true)
      end

      # Retrieves the auto setting (deprecated).
      # @return [Boolean, nil] the current value of the auto setting or nil
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.auto
        Lich.deprecated("GameSettings.auto", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Retrieves the autoload setting (deprecated).
      # @return [Boolean, nil] the current value of the autoload setting or nil
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.autoload
        Lich.deprecated("GameSettings.autoload", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end
    end
  end
end
