# frozen_string_literal: true

require_relative 'entry_store'
require_relative 'authenticator'
require_relative 'launch_data'
require_relative 'login_helpers'
require_relative 'cli_password'

module Lich
  # Provides common functionality for the Lich project
  # This module contains authentication-related methods for the CLI.
  module Common
    module Authentication
      # CLI module for handling command line interface operations
      # This module provides methods to execute commands related to character authentication.
      # @example Executing a command
      #   Lich::Common::Authentication::CLI.execute("character_name", game_code: "game_code")
      module CLI
        # Executes the CLI command to authenticate a character.
        # @param character_name [String] The name of the character to authenticate.
        # @param game_code [String, nil] The game code for the character (optional).
        # @param frontend [String, nil] The frontend to use (optional).
        # @param custom_launch [String, nil] Custom launch options (optional).
        # @param data_dir [String, nil] Directory for data files (optional).
        # @return [LaunchData, nil] Returns launch data if successful, nil otherwise.
        # @raise [StandardError] Raises an error if any validation fails.
        # @example Executing with parameters
        #   Lich::Common::Authentication::CLI.execute("my_character", game_code: "my_game")
        def self.execute(character_name, game_code: nil, frontend: nil, custom_launch: nil, data_dir: nil)
          data_dir ||= DATA_DIR

          # Validate inputs
          unless character_name && !character_name.empty?
            Lich.log "error: Character name is required"
            return nil
          end

          # Validate master password availability before attempting login (required for Enhanced encryption mode)
          unless CLIPassword.validate_master_password_available
            Lich.log "error: Master password validation failed during CLI login"
            return nil
          end

          # Load raw YAML data (not decrypted yet)
          yaml_file = EntryStore.yaml_file_path(data_dir)
          unless File.exist?(yaml_file)
            Lich.log "error: No saved entries YAML file found"
            return nil
          end

          begin
            yaml_data = YAML.safe_load_file(yaml_file, permitted_classes: [Symbol])
            entry_data = LoginHelpers.symbolize_keys(yaml_data)
          rescue StandardError => e
            Lich.log "error: Failed to load YAML data: #{e.message}"
            return nil
          end

          # Find matching character(s) using login_helpers
          matching_entries = LoginHelpers.find_character_by_name_game_and_frontend(
            entry_data,
            character_name,
            game_code,
            frontend,
            custom_launch
          )

          if matching_entries.nil? || matching_entries.empty?
            Lich.log "error: No matching character found for: #{character_name}"
            return nil
          end

          # Select best match from candidates
          char_entry = LoginHelpers.select_best_fit(
            char_data_sets: matching_entries,
            requested_character: character_name,
            requested_instance: game_code,
            requested_fe: frontend
          )

          unless char_entry
            Lich.log "error: Could not select character entry from matches"
            return nil
          end

          # Decrypt password and authenticate
          decrypt_and_authenticate(char_entry, entry_data)
        end

        # Decrypts the password and authenticates the character.
        # @param char_entry [Hash] The character entry containing authentication details.
        # @param entry_data [Hash] The entry data containing additional information.
        # @return [LaunchData, nil] Returns launch data if authentication is successful, nil otherwise.
        # @raise [StandardError] Raises an error if decryption or authentication fails.
        # @example Authenticating a character
        #   Lich::Common::Authentication::CLI.decrypt_and_authenticate(char_entry, entry_data)
        def self.decrypt_and_authenticate(char_entry, entry_data)
          # Get encryption mode from YAML
          encryption_mode = (entry_data[:encryption_mode] || 'plaintext').to_sym

          # Decrypt the password
          begin
            plaintext_password = EntryStore.decrypt_password(
              char_entry[:password],
              mode: encryption_mode,
              account_name: char_entry[:username]
            )
          rescue StandardError => e
            Lich.log "error: Failed to decrypt password: #{e.message}"
            return nil
          end

          unless plaintext_password
            Lich.log "error: No password available for character"
            return nil
          end

          # Authenticate with game server
          begin
            auth_data = Authentication.authenticate(
              account: char_entry[:username],
              password: plaintext_password,
              character: char_entry[:char_name],
              game_code: char_entry[:game_code]
            )

            # Format and return launch data
            LaunchData.prepare(
              auth_data,
              char_entry[:frontend],
              char_entry[:custom_launch],
              char_entry[:custom_launch_dir]
            )
          rescue StandardError => e
            Lich.log "error: Authentication failed: #{e.message}"
            return nil
          end
        end
      end
    end
  end
end
