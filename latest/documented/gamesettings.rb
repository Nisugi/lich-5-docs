# Carve out from Lich 5 for module GameSettings
# 2024-06-13

module Lich
  module Common
    # Provides methods to manage game settings.
    # This module allows access to game settings scoped to the current game context.
    # @example Accessing a game setting
    #   setting_value = GameSettings[:some_setting]
    module GameSettings
      # Helper to get the active scope for GameSettings
      # Assumes XMLData.game is available and provides the correct scope string.
      # Retrieves the active scope for game settings.
      # @return [String] The current game scope string.
      # @note Assumes XMLData.game is available.
      def self.active_scope
        XMLData.game
      end

      # Retrieves a scoped game setting by name.
      # @param name [Symbol] The name of the setting to retrieve.
      # @return [Object] The value of the specified game setting.
      # @example
      #   value = GameSettings[:setting_name]
      def self.[](name)
        Settings.get_scoped_setting(active_scope, name)
      end

      # Sets a scoped game setting by name.
      # @param name [Symbol] The name of the setting to set.
      # @param value [Object] The value to assign to the setting.
      # @return [Object] The value that was set.
      # @example
      #   GameSettings[:setting_name] = new_value
      def self.[]=(name, value)
        Settings.set_script_settings(active_scope, name, value)
      end

      # Converts the current game settings to a hash-like structure.
      # @return [Object] A proxy object representing the current game settings.
      # @note This method does not behave like a standard Ruby hash request.
      def self.to_hash
        # NB:  This method does not behave like a standard Ruby hash request.
        # It returns a root proxy for the game settings scope, allowing persistent
        # modifications on the returned object for legacy support.
        Settings.wrap_value_if_container(Settings.current_script_settings(active_scope), active_scope, [])
      end

      # deprecated
      # Loads game settings (deprecated).
      # @deprecated This method is no longer applicable.
      # @return [nil] Always returns nil.
      def GameSettings.load
        Lich.deprecated("GameSettings.load", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves game settings (deprecated).
      # @deprecated This method is no longer applicable.
      # @return [nil] Always returns nil.
      def GameSettings.save
        Lich.deprecated("GameSettings.save", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves all game settings (deprecated).
      # @deprecated This method is no longer applicable.
      # @return [nil] Always returns nil.
      def GameSettings.save_all
        Lich.deprecated("GameSettings.save_all", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Clears game settings (deprecated).
      # @deprecated This method is no longer applicable.
      # @return [nil] Always returns nil.
      def GameSettings.clear
        Lich.deprecated("GameSettings.clear", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Sets the auto setting (deprecated).
      # @param _val [Object] The value to set for auto.
      # @deprecated This method is no longer applicable.
      def GameSettings.auto=(_val)
        Lich.deprecated("GameSettings.auto=(val)", "not using, not applicable,", caller[0], fe_log: true)
      end

      # Retrieves the auto setting (deprecated).
      # @return [nil] Always returns nil.
      # @deprecated This method is no longer applicable.
      def GameSettings.auto
        Lich.deprecated("GameSettings.auto", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Retrieves the autoload setting (deprecated).
      # @return [nil] Always returns nil.
      # @deprecated This method is no longer applicable.
      def GameSettings.autoload
        Lich.deprecated("GameSettings.autoload", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end
    end
  end
end
