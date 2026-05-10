# frozen_string_literal: true

# InstanceSettings provides Settings-like access for core Lich functionality
# that runs outside of Script context (e.g., DRParser, command handlers).
#
# Unlike CharSettings and GameSettings which require Script.current.name,
# InstanceSettings uses a fixed script name ('core') that works in any context.
#
# This module supports two scoping modes:
# - Character-scoped: Data specific to current character (game:name)
# - Game-scoped: Data shared across all characters in the game (game only)
#
# Usage:
#   # Character-scoped access (like CharSettings)
#   InstanceSettings['my_key'] = 'value'
module Lich
  # Provides settings-like access for core Lich functionality
  # that runs outside of Script context.
  # @example Accessing character-scoped settings
  #   InstanceSettings["my_key"] = "value"
  module Common
    module InstanceSettings
      # Script name used for core Lich functionality
      # This allows Settings API to work without Script.current context
      # Script name used for core Lich functionality
      # This allows Settings API to work without Script.current context
      SCRIPT_NAME = 'core'

      # Returns the character scope string for settings access
      # @return [String] The character scope in the format "game:name"
      # @example
      #   scope = InstanceSettings.character_scope
      def self.character_scope
        "#{XMLData.game}:#{XMLData.name}"
      end

      # Returns the game scope string for settings access
      # @return [String] The game scope
      # @example
      #   scope = InstanceSettings.game_scope
      def self.game_scope
        XMLData.game
      end

      # Retrieves a setting by name in the character scope
      # @param name [String] The name of the setting to retrieve
      # @return [Object] The value of the setting
      # @example
      #   value = InstanceSettings["my_key"]
      def self.[](name)
        Settings.get_scoped_setting(character_scope, name, script_name: SCRIPT_NAME)
      end

      # Sets a setting by name in the character scope
      # @param name [String] The name of the setting to set
      # @param value [Object] The value to assign to the setting
      # @example
      #   InstanceSettings["my_key"] = "value"
      def self.[]=(name, value)
        Settings.set_script_settings(character_scope, name, value, script_name: SCRIPT_NAME)
      end

      # Provides a proxy for accessing character-scoped settings
      # @return [Object] The character proxy for settings access
      # @example
      #   proxy = InstanceSettings.character_proxy
      def self.character_proxy
        Settings.root_proxy_for(character_scope, script_name: SCRIPT_NAME)
      end

      # Provides a proxy for accessing game-scoped settings
      # @return [Object] The game proxy for settings access
      # @example
      #   proxy = InstanceSettings.game_proxy
      def self.game_proxy
        Settings.root_proxy_for(game_scope, script_name: SCRIPT_NAME)
      end

      # Provides access to game-scoped settings
      # @return [Module] The game settings module
      # @example
      #   value = InstanceSettings.game["my_key"]
      def self.game
        @game_accessor ||= Module.new do
          extend self

          def self.[](name)
            InstanceSettings.game_proxy[name]
          end

          def self.[]=(name, value)
            proxy = InstanceSettings.game_proxy
            proxy[name] = value
          end

          def self.to_hash
            Settings.current_script_settings(
              InstanceSettings.game_scope,
              script_name: InstanceSettings::SCRIPT_NAME
            )
          end
        end
      end

      # Converts character-scoped settings to a hash
      # @return [Hash] A hash representation of the character-scoped settings
      # @example
      #   settings_hash = InstanceSettings.to_hash
      def self.to_hash
        Settings.wrap_value_if_container(
          Settings.current_script_settings(character_scope, script_name: SCRIPT_NAME),
          character_scope,
          [],
          script_name: SCRIPT_NAME
        )
      end

      # Loads settings (deprecated)
      # @return [nil] Always returns nil
      # @note This method is deprecated and not applicable.
      def self.load
        Lich.deprecated('InstanceSettings.load', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Saves settings (deprecated)
      # @return [nil] Always returns nil
      # @note This method is deprecated and not applicable.
      def self.save
        Lich.deprecated('InstanceSettings.save', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end
    end
  end
end
