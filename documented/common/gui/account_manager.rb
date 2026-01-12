
module Lich
  module Common
    module GUI
      module AccountManager
        # Adds or updates an account with the given username and password.
        # @param data_dir [String] The directory where account data is stored.
        # @param username [String] The username for the account.
        # @param password [String] The password for the account.
        # @param characters [Array<Hash>] (optional) An array of character data associated with the account.
        # @return [void]
        # @raise [StandardError] If the master password is required but not found.
        # @example Adding a new account
        #   AccountManager.add_or_update_account("/path/to/data", "user1", "password123", [{ char_name: "Hero", game_code: "game1" }])
        def self.add_or_update_account(data_dir, username, password, characters = [])
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Normalize username to UPCASE for consistent storage
          normalized_username = username.to_s.upcase

          # Load existing data or create new structure
          yaml_data = if File.exist?(yaml_file)
                        begin
                          YAML.load_file(yaml_file)
                        rescue StandardError => e
                          Lich.log "error: Error loading YAML entry file: #{e.message}"
                          { 'accounts' => {} }
                        end
                      else
                        { 'accounts' => {} }
                      end

          # Initialize accounts hash if not present
          yaml_data['accounts'] ||= {}

          # Determine encryption mode and get master password if needed
          encryption_mode = yaml_data['encryption_mode'] || 'plaintext'
          master_password = nil
          if encryption_mode.to_sym == :enhanced
            master_password = Lich::Common::GUI::MasterPasswordManager.retrieve_master_password
            if master_password.nil?
              Lich.log "error: Enhanced mode enabled but master password not found in Keychain"
              raise StandardError, "Master password required for enhanced mode encryption"
            end
          end

          # Encrypt the password based on encryption mode
          encrypted_password = Lich::Common::GUI::YamlState.encrypt_password(
            password,
            mode: encryption_mode,
            account_name: normalized_username,
            master_password: master_password
          )

          # Normalize character data if provided
          normalized_characters = characters.map do |char|
            {
              'char_name'         => char[:char_name].to_s.strip.split.map(&:capitalize).join(' '),
              'game_code'         => char[:game_code],
              'game_name'         => char[:game_name],
              'frontend'          => char[:frontend],
              'custom_launch'     => char[:custom_launch],
              'custom_launch_dir' => char[:custom_launch_dir]
            }
          end

          # Add or update account using normalized username
          if yaml_data['accounts'][normalized_username]
            # Update existing account password with encrypted value
            yaml_data['accounts'][normalized_username]['password'] = encrypted_password

            # Merge characters: preserve existing characters and their metadata (like favorites)
            # while adding any new characters from the provided list
            if !characters.empty?
              existing_characters = yaml_data['accounts'][normalized_username]['characters'] || []

              # Add new characters that don't already exist
              characters.each do |new_char|
                normalized_new_char_name = new_char[:char_name].to_s.capitalize

                # Check if character already exists (by char_name, game_code, frontend)
                existing_char = existing_characters.find do |existing|
                  existing['char_name'] == normalized_new_char_name &&
                    existing['game_code'] == new_char[:game_code] &&
                    existing['frontend'] == new_char[:frontend]
                end

                # Only add if character doesn't already exist
                unless existing_char
                  existing_characters << {
                    'char_name'         => normalized_new_char_name,
                    'game_code'         => new_char[:game_code],
                    'game_name'         => new_char[:game_name],
                    'frontend'          => new_char[:frontend],
                    'custom_launch'     => new_char[:custom_launch],
                    'custom_launch_dir' => new_char[:custom_launch_dir]
                  }
                end
              end

              yaml_data['accounts'][normalized_username]['characters'] = existing_characters
            end
          else
            # Create new account with normalized data and encrypted password
            yaml_data['accounts'][normalized_username] = {
              'password'   => encrypted_password,
              'characters' => normalized_characters
            }
          end

          # Save updated data with verification
          write_yaml_with_headers(yaml_file, yaml_data)
        end

        # Removes an account with the given username.
        # @param data_dir [String] The directory where account data is stored.
        # @param username [String] The username of the account to remove.
        # @return [Boolean] Returns true if the account was removed, false otherwise.
        # @raise [StandardError] If an error occurs while removing the account.
        # @example Removing an account
        #   AccountManager.remove_account("/path/to/data", "user1")
        def self.remove_account(data_dir, username)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Load existing data
          return false unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)

            # Normalize username to UPCASE for consistent lookup
            normalized_username = username.to_s.upcase

            # Check if account exists
            return false unless yaml_data['accounts'] && yaml_data['accounts'][normalized_username]

            # Remove account
            yaml_data['accounts'].delete(normalized_username)

            # Save updated data with verification
            write_yaml_with_headers(yaml_file, yaml_data)
          rescue StandardError => e
            Lich.log "error: Error removing account: #{e.message}"
            false
          end
        end

        # Changes the password for the specified account.
        # @param data_dir [String] The directory where account data is stored.
        # @param username [String] The username of the account.
        # @param new_password [String] The new password for the account.
        # @return [void]
        # @example Changing an account password
        #   AccountManager.change_password("/path/to/data", "user1", "newpassword456")
        def self.change_password(data_dir, username, new_password)
          # Normalize username to UPCASE for consistent storage
          normalized_username = username.to_s.upcase
          add_or_update_account(data_dir, normalized_username, new_password)
        end

        # Adds a character to the specified account.
        # @param data_dir [String] The directory where account data is stored.
        # @param username [String] The username of the account.
        # @param character_data [Hash] The character data to add.
        # @return [Hash] A hash containing success status and message.
        # @raise [StandardError] If an error occurs while adding the character.
        # @example Adding a character
        #   AccountManager.add_character("/path/to/data", "user1", { char_name: "Hero", game_code: "game1" })
        def self.add_character(data_dir, username, character_data)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Check if YAML file exists
          unless File.exist?(yaml_file)
            return { success: false, message: "No account data file found. Please add an account first." }
          end

          begin
            yaml_data = YAML.load_file(yaml_file)

            # Normalize username to UPCASE for consistent lookup
            normalized_username = username.to_s.upcase
            normalized_char_name = character_data[:char_name].to_s.capitalize

            # Check if account exists
            unless yaml_data['accounts'] && yaml_data['accounts'][normalized_username]
              return { success: false, message: "Account '#{username}' not found. Please add the account first." }
            end

            # Initialize characters array if not present
            yaml_data['accounts'][normalized_username]['characters'] ||= []

            # Check for duplicate character using normalized comparison
            existing_character = yaml_data['accounts'][normalized_username]['characters'].find do |char|
              char['char_name'] == normalized_char_name &&
                char['game_code'] == character_data[:game_code] &&
                char['frontend'] == character_data[:frontend]
            end

            # Return specific message if character already exists
            if existing_character
              return {
                success: false,
                message: "Character '#{normalized_char_name}' already exists for #{character_data[:game_code]} (#{character_data[:frontend]}). Duplicates are not allowed."
              }
            end

            # Add character data with normalized character name
            yaml_data['accounts'][normalized_username]['characters'] << {
              'char_name'         => normalized_char_name,
              'game_code'         => character_data[:game_code],
              'game_name'         => character_data[:game_name],
              'frontend'          => character_data[:frontend],
              'custom_launch'     => character_data[:custom_launch],
              'custom_launch_dir' => character_data[:custom_launch_dir]
            }

            # Save updated data with verification
            if write_yaml_with_headers(yaml_file, yaml_data)
              return { success: true, message: "Character '#{normalized_char_name}' added successfully." }
            else
              return { success: false, message: "Failed to save character data. Please check file permissions." }
            end
          rescue StandardError => e
            Lich.log "error: Error adding character: #{e.message}"
            return { success: false, message: "Error adding character: #{e.message}" }
          end
        end

        # Removes a character from the specified account.
        # @param data_dir [String] The directory where account data is stored.
        # @param username [String] The username of the account.
        # @param char_name [String] The name of the character to remove.
        # @param game_code [String] The game code of the character.
        # @param frontend [String, nil] (optional) The frontend of the character.
        # @return [Boolean] Returns true if the character was removed, false otherwise.
        # @raise [StandardError] If an error occurs while removing the character.
        # @example Removing a character
        #   AccountManager.remove_character("/path/to/data", "user1", "Hero", "game1")
        def self.remove_character(data_dir, username, char_name, game_code, frontend = nil)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Load existing data
          return false unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)

            # Normalize username and character name for consistent lookup
            normalized_username = username.to_s.upcase
            normalized_char_name = char_name.to_s.capitalize

            # Check if account exists
            return false unless yaml_data['accounts'] &&
                                yaml_data['accounts'][normalized_username] &&
                                yaml_data['accounts'][normalized_username]['characters']

            # Find and remove character with frontend precision
            characters = yaml_data['accounts'][normalized_username]['characters']
            initial_count = characters.size

            characters.reject! do |char|
              matches_basic = char['char_name'] == normalized_char_name && char['game_code'] == game_code

              if frontend.nil?
                # Backward compatibility: if no frontend specified, match any frontend
                matches_basic
              else
                # Frontend precision: must match exact frontend
                matches_basic && char['frontend'] == frontend
              end
            end

            # Check if any characters were removed
            return false if characters.size == initial_count

            # Save updated data with verification
            write_yaml_with_headers(yaml_file, yaml_data)
          rescue StandardError => e
            Lich.log "error: Error removing character: #{e.message}"
            false
          end
        end

        # Updates the properties of a character in the specified account.
        # @param data_dir [String] The directory where account data is stored.
        # @param username [String] The username of the account.
        # @param char_name [String] The name of the character to update.
        # @param game_code [String] The game code of the character.
        # @param updates [Hash] A hash of properties to update for the character.
        # @return [Boolean] Returns true if the character was updated, false otherwise.
        # @raise [StandardError] If an error occurs while updating the character.
        # @example Updating a character
        #   AccountManager.update_character("/path/to/data", "user1", "Hero", "game1", { game_name: "New Game" })
        def self.update_character(data_dir, username, char_name, game_code, updates)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Load existing data
          return false unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)

            # Check if account exists
            return false unless yaml_data['accounts'] &&
                                yaml_data['accounts'][username] &&
                                yaml_data['accounts'][username]['characters']

            # Find and update character
            characters = yaml_data['accounts'][username]['characters']
            character = characters.find { |char| char['char_name'] == char_name && char['game_code'] == game_code }

            return false unless character

            # Update properties
            updates.each do |key, value|
              character[key.to_s] = value
            end

            # Save updated data with verification
            write_yaml_with_headers(yaml_file, yaml_data)
          rescue StandardError => e
            Lich.log "error: Error updating character: #{e.message}"
            false
          end
        end

        # Converts authentication data into character format.
        # @param auth_data [Array<Hash>] The authentication data to convert.
        # @param frontend [String] (optional) The frontend to associate with the characters.
        # @return [Array<Hash>] An array of characters converted from the authentication data.
        # @example Converting auth data to characters
        #   characters = AccountManager.convert_auth_data_to_characters(auth_data, "stormfront")
        def self.convert_auth_data_to_characters(auth_data, frontend = 'stormfront')
          characters = []
          return characters unless auth_data.is_a?(Array)

          auth_data.each do |char_data|
            # Ensure we have the required fields with symbol keys (as returned by authentication)
            next unless char_data.is_a?(Hash) &&
                        char_data.key?(:char_name) &&
                        char_data.key?(:game_name) &&
                        char_data.key?(:game_code)

            characters << {
              char_name: char_data[:char_name],
              game_code: char_data[:game_code],
              game_name: char_data[:game_name],
              frontend: frontend
            }
          end

          characters
        end

        # Retrieves a list of account usernames.
        # @param data_dir [String] The directory where account data is stored.
        # @return [Array<String>] An array of account usernames.
        # @raise [StandardError] If an error occurs while retrieving accounts.
        # @example Getting account usernames
        #   usernames = AccountManager.get_accounts("/path/to/data")
        def self.get_accounts(data_dir)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Load existing data
          return [] unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)
            yaml_data['accounts']&.keys || []
          rescue StandardError => e
            Lich.log "error: Error getting accounts: #{e.message}"
            []
          end
        end

        # Retrieves all accounts with their associated characters.
        # @param data_dir [String] The directory where account data is stored.
        # @return [Hash] A hash of usernames and their associated characters.
        # @raise [StandardError] If an error occurs while retrieving all accounts.
        # @example Getting all accounts
        #   accounts = AccountManager.get_all_accounts("/path/to/data")
        def self.get_all_accounts(data_dir)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Load existing data
          return {} unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)
            return {} unless yaml_data['accounts']

            # Build accounts hash with characters
            accounts = {}
            yaml_data['accounts'].each do |username, account_data|
              accounts[username] = account_data['characters']&.map do |char|
                {
                  char_name: char['char_name'],
                  game_code: char['game_code'],
                  game_name: char['game_name'],
                  frontend: char['frontend'],
                  custom_launch: char['custom_launch'],
                  custom_launch_dir: char['custom_launch_dir']
                }
              end || []
            end

            accounts
          rescue StandardError => e
            Lich.log "error: Error getting all accounts: #{e.message}"
            {}
          end
        end

        # Retrieves characters for a specified account.
        # @param data_dir [String] The directory where account data is stored.
        # @param username [String] The username of the account.
        # @return [Array<Hash>] An array of characters associated with the account.
        # @raise [StandardError] If an error occurs while retrieving characters.
        # @example Getting characters for an account
        #   characters = AccountManager.get_characters("/path/to/data", "user1")
        def self.get_characters(data_dir, username)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Load existing data
          return [] unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)

            # Normalize username to UPCASE for consistent lookup
            normalized_username = username.to_s.upcase

            # Check if account exists
            return [] unless yaml_data['accounts'] &&
                             yaml_data['accounts'][normalized_username] &&
                             yaml_data['accounts'][normalized_username]['characters']

            # Return characters with symbolized keys
            yaml_data['accounts'][normalized_username]['characters'].map do |char|
              char.transform_keys(&:to_sym)
            end
          rescue StandardError => e
            Lich.log "error: Error getting characters: #{e.message}"
            []
          end
        end

        # Converts the account data to a legacy format.
        # @param data_dir [String] The directory where account data is stored.
        # @return [Array] An array of data in legacy format.
        # @raise [StandardError] If an error occurs while converting to legacy format.
        # @example Converting to legacy format
        #   legacy_data = AccountManager.to_legacy_format("/path/to/data")
        def self.to_legacy_format(data_dir)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Load existing data
          return [] unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)
            YamlState.convert_yaml_to_legacy_format(yaml_data)
          rescue StandardError => e
            Lich.log "error: Error converting to legacy format: #{e.message}"
            []
          end
        end

        def self.write_yaml_with_headers(yaml_file, yaml_data)
          # Prepare YAML with password preservation (clones to avoid mutation)
          prepared_yaml = Lich::Common::GUI::YamlState.prepare_yaml_for_serialization(yaml_data)

          content = "# Lich 5 Login Entries - YAML Format\n"
          content += "# Generated: #{Time.now}\n"
          # Use YAML dump with options to prevent multiline formatting of long strings
          content += YAML.dump(prepared_yaml, permitted_classes: [Symbol])

          Utilities.verified_file_operation(yaml_file, :write, content)
        end
        private_class_method :write_yaml_with_headers
      end
    end
  end
end
