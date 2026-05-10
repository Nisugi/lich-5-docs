
# Lich module
# This module serves as a namespace for the Lich project.
module Lich
  module Common
    # GameSettings module
    # This module provides methods to access and modify game settings.
    # @example Accessing a game setting
    #   setting_value = GameSettings["setting_name"]
    module GameSettings
      # Returns the active game scope.
      # @return [Object] The current game scope.
      def self.active_scope
        XMLData.game
      end

      # Retrieves a game setting by name.
      # @param name [String] The name of the setting to retrieve.
      # @return [Object] The value of the requested setting.
      # @example
      #   value = GameSettings["setting_name"]
      def self.[](name)
        Settings.get_scoped_setting(active_scope, name)
      end

      # Sets a game setting by name.
      # @param name [String] The name of the setting to set.
      # @param value [Object] The value to assign to the setting.
      # @return [Object] The value that was set.
      # @example
      #   GameSettings["setting_name"] = "new_value"
      def self.[]=(name, value)
        Settings.set_script_settings(active_scope, name, value)
      end

      # Converts the game settings to a hash-like structure.
      # @return [Hash] A hash representation of the game settings.
      # @note This method does not behave like a standard Ruby hash request.
      # It returns a root proxy for the game settings scope, allowing persistent
      # modifications on the returned object for legacy support.
      def self.to_hash
        # NB:  This method does not behave like a standard Ruby hash request.
        # It returns a root proxy for the game settings scope, allowing persistent
        # modifications on the returned object for legacy support.
        Settings.wrap_value_if_container(Settings.current_script_settings(active_scope), active_scope, [])
      end

      # Loads game settings (deprecated).
      # @return [nil] Always returns nil as this method is deprecated.
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.load
        Lich.deprecated("GameSettings.load", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves game settings (deprecated).
      # @return [nil] Always returns nil as this method is deprecated.
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.save
        Lich.deprecated("GameSettings.save", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves all game settings (deprecated).
      # @return [nil] Always returns nil as this method is deprecated.
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.save_all
        Lich.deprecated("GameSettings.save_all", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Clears game settings (deprecated).
      # @return [nil] Always returns nil as this method is deprecated.
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.clear
        Lich.deprecated("GameSettings.clear", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Sets the auto setting (deprecated).
      # @param _val [Object] The value to set for auto.
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.auto=(_val)
        Lich.deprecated("GameSettings.auto=(val)", "not using, not applicable,", caller[0], fe_log: true)
      end

      # Retrieves the auto setting (deprecated).
      # @return [nil] Always returns nil as this method is deprecated.
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.auto
        Lich.deprecated("GameSettings.auto", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Retrieves the autoload setting (deprecated).
      # @return [nil] Always returns nil as this method is deprecated.
      # @deprecated This method is not applicable and should not be used.
      def GameSettings.autoload
        Lich.deprecated("GameSettings.autoload", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end
    end
  end
end
