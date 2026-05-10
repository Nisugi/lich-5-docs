# frozen_string_literal: true

require_relative 'entry_store'
require_relative 'authenticator'
require_relative 'launch_data'
require_relative 'login_helpers'
require_relative 'cli_password'

module Lich
  # Common functionality for the Lich project.
  #
  # @see Lich::Authentication
  # @see Lich::CLI
  module Common
    module Authentication
      # CLI-related authentication methods for the Lich project.
      #
      # @see Lich::Common::Authentication
      module CLI
        # Executes the CLI login process for a character.
        #
        # @param character_name [String] the name of the character to log in
        # @param game_code [String, nil] optional game code for the character
        # @param frontend [String, nil] optional frontend identifier
        # @param custom_launch [String, nil] optional custom launch parameters
        # @param data_dir [String, nil] optional directory for data files
        # @return [LaunchData, nil] returns launch data on success, or nil on failure
        # @example
        #   Lich::Common::Authentication::CLI.execute("my_character", game_code: "game1")
        # @raise [StandardError] raises an error if login fails
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

        # Decrypts the character's password and authenticates with the game server.
        #
        # @param char_entry [Hash] the character entry containing authentication details
        # @param entry_data [Hash] the entry data containing additional information
        # @return [LaunchData, nil] returns launch data on successful authentication, or nil on failure
        # @example
        #   Lich::Common::Authentication::CLI.decrypt_and_authenticate(char_entry, entry_data)
        # @raise [StandardError] raises an error if authentication fails
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
