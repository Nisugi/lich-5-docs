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
  # Provides settings-like access for core Lich functionality.
  #
  # This module allows access to settings in both character-scoped and game-scoped modes.
  #
  # @see Lich::Common::CharSettings
  # @see Lich::Common::GameSettings
  module Common
    module InstanceSettings
      # Script name used for core Lich functionality
      # This allows Settings API to work without Script.current context
      SCRIPT_NAME = 'core'

      # Returns the character scope string for settings access.
      #
      # @return [String] the character scope in the format "game:name"
      def self.character_scope
        "#{XMLData.game}:#{XMLData.name}"
      end

      # Returns the game scope string for settings access.
      #
      # @return [String] the game scope
      def self.game_scope
        XMLData.game
      end

      # Retrieves a setting value by name in the character scope.
      #
      # @param name [String] the name of the setting
      # @return [OpenStruct] the setting value
      def self.[](name)
        Settings.get_scoped_setting(character_scope, name, script_name: SCRIPT_NAME)
      end

      # Sets a setting value by name in the character scope.
      #
      # @param name [String] the name of the setting
      # @param value [OpenStruct] the value to set
      def self.[]=(name, value)
        Settings.set_script_settings(character_scope, name, value, script_name: SCRIPT_NAME)
      end

      # Provides a proxy for accessing character-scoped settings.
      #
      # @return [OpenStruct] the character settings proxy
      def self.character_proxy
        Settings.root_proxy_for(character_scope, script_name: SCRIPT_NAME)
      end

      # Provides a proxy for accessing game-scoped settings.
      #
      # @return [OpenStruct] the game settings proxy
      def self.game_proxy
        Settings.root_proxy_for(game_scope, script_name: SCRIPT_NAME)
      end

      # Provides access to game-scoped settings.
      #
      # @return [OpenStruct] the game settings accessor
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

      # Converts the character-scoped settings to a hash.
      #
      # @return [Hash] the character settings as a hash
      def self.to_hash
        Settings.wrap_value_if_container(
          Settings.current_script_settings(character_scope, script_name: SCRIPT_NAME),
          character_scope,
          [],
          script_name: SCRIPT_NAME
        )
      end

      # Loads the instance settings (deprecated).
      #
      # @return [nil]
      # @deprecated This method is not applicable and will not be used.
      def self.load
        Lich.deprecated('InstanceSettings.load', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Saves the instance settings (deprecated).
      #
      # @return [nil]
      # @deprecated This method is not applicable and will not be used.
      def self.save
        Lich.deprecated('InstanceSettings.save', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end
    end
  end
end
