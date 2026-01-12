# frozen_string_literal: true

require_relative 'state'
require_relative 'password_cipher'
require_relative 'master_password_manager'
require_relative 'master_password_prompt'

module Lich
  module Common
    module GUI
      # Provides methods for managing YAML state files for Lich.
      # This module includes functionality for loading, saving, and migrating
      # entries in YAML format.
      # @example Loading saved entries
      #   entries = Lich::Common::GUI::YamlState.load_saved_entries(data_dir, autosort_state)
      module YamlState
        # Returns the path to the YAML file in the specified data directory.
        # @param data_dir [String] The directory where the YAML file is located.
        # @return [String] The full path to the YAML file.
        def self.yaml_file_path(data_dir)
          File.join(data_dir, "entry.yaml")
        end

        # Loads saved entries from a YAML file, falling back to legacy format if necessary.
        # @param data_dir [String] The directory where the entry files are located.
        # @param autosort_state [Boolean] Indicates whether to sort entries by favorites.
        # @return [Array] The loaded entries.
        # @raise [StandardError] If there is an error loading the YAML file.
        # @example
        #   entries = Lich::Common::GUI::YamlState.load_saved_entries(data_dir, true)
        def self.load_saved_entries(data_dir, autosort_state)
          # Guard against nil data_dir
          return [] if data_dir.nil?

          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)
          dat_file = File.join(data_dir, "entry.dat")

          if File.exist?(yaml_file)
            # Load from YAML format
            begin
              yaml_data = YAML.load_file(yaml_file)

              # Migrate data structure if needed to support favorites and encryption
              yaml_data = migrate_to_favorites_format(yaml_data)
              yaml_data = migrate_to_encryption_format(yaml_data)

              entries = convert_yaml_to_legacy_format(yaml_data)

              # Apply sorting with favorites priority if enabled
              sort_entries_with_favorites(entries, autosort_state)

              entries
            rescue StandardError => e
              Lich.log "error: Error loading YAML entry file: #{e.message}"
              []
            end
          elsif File.exist?(dat_file)
            # Fall back to legacy format if YAML doesn't exist
            Lich.log "info: YAML entry file not found, falling back to legacy format"
            State.load_saved_entries(data_dir, autosort_state)
          else
            # No entry file exists
            []
          end
        end

        # Saves the provided entry data to a YAML file, preserving validation tests if they exist.
        # @param data_dir [String] The directory where the YAML file will be saved.
        # @param entry_data [Array] The entry data to save.
        # @return [Boolean] True if the save was successful, false otherwise.
        # @raise [StandardError] If there is an error saving the YAML file.
        # @example
        #   success = Lich::Common::GUI::YamlState.save_entries(data_dir, entry_data)
        def self.save_entries(data_dir, entry_data)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Preserve validation test from existing YAML if it exists
          original_validation_test = nil
          if File.exist?(yaml_file)
            begin
              original_data = YAML.load_file(yaml_file)
              original_validation_test = original_data['master_password_validation_test'] if original_data.is_a?(Hash)
            rescue StandardError => e
              Lich.log "warning: Could not load existing YAML to preserve validation test: #{e.message}"
            end
          end

          # Convert legacy format to YAML structure, passing validation test to preserve it
          yaml_data = convert_legacy_to_yaml_format(entry_data, original_validation_test)

          # Create backup of existing file if it exists
          if File.exist?(yaml_file)
            backup_file = "#{yaml_file}.bak"
            FileUtils.cp(yaml_file, backup_file)
          end

          # Write YAML data to file with secure permissions
          begin
            write_yaml_file(yaml_file, yaml_data)
            true
          rescue StandardError => e
            Lich.log "error: Error saving YAML entry file: #{e.message}"
            false
          end
        end

        # Migrates entries from the legacy DAT format to the YAML format.
        # @param data_dir [String] The directory where the legacy entry files are located.
        # @param encryption_mode [Symbol] The encryption mode to use for the migration.
        # @return [Boolean] True if the migration was successful, false otherwise.
        # @raise [StandardError] If there is an error during migration.
        # @example
        #   success = Lich::Common::GUI::YamlState.migrate_from_legacy(data_dir, encryption_mode: :enhanced)
        def self.migrate_from_legacy(data_dir, encryption_mode: :plaintext)
          dat_file = File.join(data_dir, "entry.dat")
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          # Skip if YAML file already exists or DAT file doesn't exist
          return false unless File.exist?(dat_file)
          return false if File.exist?(yaml_file)

          # ====================================================================
          # Handle master_password mode - check for existing or create new
          # ====================================================================
          master_password = nil
          validation_test = nil
          if encryption_mode == :enhanced
            # First check if master password already exists in keychain
            result = get_existing_master_password_for_migration

            # If no existing password, prompt user to create one
            if result.nil?
              result = ensure_master_password_exists
            end

            if result.nil?
              Lich.log "error: Master password not available for migration"
              return false
            end

            # Handle both new (Hash) and existing (String) password returns
            if result.is_a?(Hash)
              master_password = result[:password]
              validation_test = result[:validation_test]
            else
              master_password = result
            end
          end

          # Load legacy data
          legacy_entries = State.load_saved_entries(data_dir, false)

          # Add encryption_mode to entries
          legacy_entries.each do |entry|
            entry[:encryption_mode] = encryption_mode
          end

          # Encrypt passwords if not plaintext mode
          if encryption_mode != :plaintext
            legacy_entries.each do |entry|
              entry[:password] = encrypt_password(
                entry[:password],
                mode: encryption_mode,
                account_name: entry[:user_id],
                master_password: master_password # NEW: Pass master password
              )
            end
          end

          # Use save_entries to maintain test compatibility
          save_entries(data_dir, legacy_entries)

          # Save validation test to YAML if it was created
          if validation_test && encryption_mode == :enhanced
            yaml_file = yaml_file_path(data_dir)
            if File.exist?(yaml_file)
              yaml_data = YAML.load_file(yaml_file)
              yaml_data['master_password_validation_test'] = validation_test
              write_yaml_file(yaml_file, yaml_data)
            end
          end

          # Log conversion summary
          account_names = legacy_entries.map { |entry| entry[:user_id] }.uniq.sort.join(', ')
          Lich.log "info: Migration complete - Encryption mode: #{encryption_mode.upcase}, Converted accounts: #{account_names}"

          true
        end

        # Encrypts the given password using the specified mode and optional parameters.
        # @param password [String] The password to encrypt.
        # @param mode [Symbol] The encryption mode to use.
        # @param account_name [String, nil] The account name associated with the password.
        # @param master_password [String, nil] The master password for encryption.
        # @return [String] The encrypted password.
        # @raise [StandardError] If encryption fails.
        # @example
        #   encrypted = Lich::Common::GUI::YamlState.encrypt_password("my_password", mode: :enhanced)
        def self.encrypt_password(password, mode:, account_name: nil, master_password: nil)
          return password if mode == :plaintext || mode.to_sym == :plaintext

          PasswordCipher.encrypt(password, mode: mode.to_sym, account_name: account_name, master_password: master_password)
        rescue StandardError => e
          Lich.log "error: encrypt_password failed - #{e.class}: #{e.message}"
          raise
        end

        # Decrypts the given encrypted password using the specified mode and optional parameters.
        # @param encrypted_password [String] The encrypted password to decrypt.
        # @param mode [Symbol] The decryption mode to use.
        # @param account_name [String, nil] The account name associated with the password.
        # @param master_password [String, nil] The master password for decryption.
        # @return [String] The decrypted password.
        # @raise [StandardError] If decryption fails.
        # @example
        #   decrypted = Lich::Common::GUI::YamlState.decrypt_password(encrypted_password, mode: :enhanced)
        def self.decrypt_password(encrypted_password, mode:, account_name: nil, master_password: nil)
          return encrypted_password if mode == :plaintext || mode.to_sym == :plaintext

          # For enhanced mode: auto-retrieve from Keychain if not provided
          if mode.to_sym == :enhanced && master_password.nil?
            master_password = MasterPasswordManager.retrieve_master_password
            raise StandardError, "Master password not found in Keychain - cannot decrypt" if master_password.nil?
          end

          PasswordCipher.decrypt(encrypted_password, mode: mode.to_sym, account_name: account_name, master_password: master_password)
        rescue StandardError => e
          Lich.log "error: decrypt_password failed - #{e.class}: #{e.message}"
          raise
        end

        # Attempts to decrypt the given encrypted password, with recovery options for missing master password.
        # @param encrypted_password [String] The encrypted password to decrypt.
        # @param mode [Symbol] The decryption mode to use.
        # @param account_name [String, nil] The account name associated with the password.
        # @param master_password [String, nil] The master password for decryption.
        # @param validation_test [String, nil] The validation test for recovery.
        # @return [String] The decrypted password or nil if recovery fails.
        # @raise [StandardError] If decryption fails and recovery is not possible.
        # @example
        #   decrypted = Lich::Common::GUI::YamlState.decrypt_password_with_recovery(encrypted_password, mode: :enhanced)
        def self.decrypt_password_with_recovery(encrypted_password, mode:, account_name: nil, master_password: nil, validation_test: nil)
          # Try normal decryption first
          return decrypt_password(encrypted_password, mode: mode, account_name: account_name, master_password: master_password)
        rescue StandardError => e
          # Only attempt recovery for enhanced mode with missing master password
          if mode.to_sym == :enhanced && e.message.include?("Master password not found") && validation_test && !validation_test.empty?
            Lich.log "info: Master password missing from Keychain, attempting recovery via user prompt"

            # Show appropriate dialog based on context - use data access for conversion, recovery for actual recovery
            recovery_result = MasterPasswordPromptUI.show_password_for_data_access(validation_test)

            if recovery_result.nil? || recovery_result[:password].nil?
              Lich.log "info: User cancelled master password recovery"
              Gtk.main_quit
              return nil
            end

            recovered_password = recovery_result[:password]
            continue_session = recovery_result[:continue_session]

            # Password was validated by the UI layer, proceed with recovery
            Lich.log "info: Master password recovered and validated, storing to Keychain"

            # Save recovered password to Keychain for future use
            unless MasterPasswordManager.store_master_password(recovered_password)
              Lich.log "warning: Failed to store recovered master password to Keychain"
              # Continue anyway - decryption will still work with in-memory password
            end

            # Handle session continuation decision
            if !continue_session
              Lich.log "info: User chose to close application after password recovery"
              # Exit the application gracefully
              Gtk.main_quit
            end

            # Retry decryption with recovered password
            return decrypt_password(encrypted_password, mode: mode, account_name: account_name, master_password: recovered_password)
          else
            # Re-raise if not recoverable
            raise
          end
        end

        # Encrypts all passwords in the provided YAML data according to the specified mode.
        # @param yaml_data [Hash] The YAML data containing accounts and passwords.
        # @param mode [Symbol] The encryption mode to use.
        # @param master_password [String, nil] The master password for encryption.
        # @return [Hash] The YAML data with encrypted passwords.
        # @example
        #   updated_yaml = Lich::Common::GUI::YamlState.encrypt_all_passwords(yaml_data, :enhanced)
        def self.encrypt_all_passwords(yaml_data, mode, master_password: nil)
          return yaml_data if mode == :plaintext

          yaml_data['accounts'].each do |account_name, account_data|
            next unless account_data['password']

            # Encrypt password based on mode
            account_data['password'] = encrypt_password(
              account_data['password'],
              mode: mode,
              account_name: account_name,
              master_password: master_password
            )
          end

          yaml_data
        end

        # Changes the encryption mode for the YAML data and updates the master password if necessary.
        # @param data_dir [String] The directory where the YAML file is located.
        # @param new_mode [Symbol] The new encryption mode to set.
        # @param new_master_password [String, nil] The new master password for enhanced mode.
        # @return [Boolean] True if the change was successful, false otherwise.
        # @raise [StandardError] If there is an error changing the encryption mode.
        # @example
        #   success = Lich::Common::GUI::YamlState.change_encryption_mode(data_dir, :enhanced, new_master_password)
        def self.change_encryption_mode(data_dir, new_mode, new_master_password = nil)
          yaml_file = yaml_file_path(data_dir)

          # Load YAML
          begin
            yaml_data = YAML.load_file(yaml_file)
          rescue StandardError => e
            Lich.log "error: Failed to load YAML for encryption mode change: #{e.message}"
            return false
          end

          current_mode = yaml_data['encryption_mode']&.to_sym || :plaintext

          # If already in target mode, return success
          if current_mode == new_mode
            Lich.log "info: Already in #{new_mode} encryption mode"
            return true
          end

          # Determine old_master_password
          old_master_password = nil
          if current_mode == :enhanced
            # Auto-retrieve from keychain when leaving Enhanced
            old_master_password = MasterPasswordManager.retrieve_master_password
            if old_master_password.nil?
              Lich.log "error: Master password not found in keychain for encryption mode change"
              return false
            end
          end

          # Validate new_master_password if entering Enhanced mode
          if new_mode == :enhanced && new_master_password.nil?
            Lich.log "error: New master password required for Enhanced mode encryption"
            return false
          end

          # Create backup
          backup_file = "#{yaml_file}.bak"
          begin
            FileUtils.cp(yaml_file, backup_file)
            Lich.log "info: Backup created for encryption mode change: #{backup_file}"
          rescue StandardError => e
            Lich.log "error: Failed to create backup: #{e.message}"
            return false
          end

          begin
            # Re-encrypt all accounts
            accounts = yaml_data['accounts'] || {}
            accounts.each do |account_name, account_data|
              # Decrypt with current mode
              plaintext = decrypt_password(
                account_data['password'],
                mode: current_mode,
                account_name: account_name,
                master_password: old_master_password
              )

              if plaintext.nil?
                Lich.log "error: Failed to decrypt password for #{account_name}"
                return restore_backup_and_return_false(backup_file, yaml_file)
              end

              # Encrypt with new mode
              encrypted = encrypt_password(
                plaintext,
                mode: new_mode,
                account_name: account_name,
                master_password: new_master_password
              )

              if encrypted.nil?
                Lich.log "error: Failed to encrypt password for #{account_name}"
                return restore_backup_and_return_false(backup_file, yaml_file)
              end

              account_data['password'] = encrypted
            end

            # Update encryption_mode
            yaml_data['encryption_mode'] = new_mode.to_s

            # Handle Enhanced mode metadata
            if new_mode == :enhanced
              # Create validation test
              validation_test = MasterPasswordManager.create_validation_test(new_master_password)
              yaml_data['master_password_validation_test'] = validation_test

              # Store in keychain
              unless MasterPasswordManager.store_master_password(new_master_password)
                Lich.log "error: Failed to store master password in keychain"
                return restore_backup_and_return_false(backup_file, yaml_file)
              end
            elsif current_mode == :enhanced
              # Remove validation test and keychain when leaving Enhanced
              yaml_data.delete('master_password_validation_test')
              MasterPasswordManager.delete_master_password
            end

            # Save YAML with headers
            write_yaml_file(yaml_file, yaml_data)

            # Clean up backup on success
            FileUtils.rm(backup_file) if File.exist?(backup_file)

            Lich.log "info: Encryption mode changed successfully: #{current_mode} → #{new_mode}"
            true
          rescue StandardError => e
            Lich.log "error: Encryption mode change failed: #{e.class}: #{e.message}"
            restore_backup_and_return_false(backup_file, yaml_file)
          end
        end

        # Restores the backup file if it exists and returns false.
        # @param backup_file [String] The path to the backup file.
        # @param yaml_file [String] The path to the original YAML file.
        # @return [Boolean] Always returns false after restoring.
        def self.restore_backup_and_return_false(backup_file, yaml_file)
          if File.exist?(backup_file)
            FileUtils.cp(backup_file, yaml_file)
            FileUtils.rm(backup_file)
            Lich.log "info: Backup restored after encryption mode change failure"
          end
          false
        end

        # Migrates the provided YAML data to include encryption format fields.
        # @param yaml_data [Hash] The YAML data to migrate.
        # @return [Hash] The migrated YAML data.
        def self.migrate_to_encryption_format(yaml_data)
          return yaml_data unless yaml_data.is_a?(Hash)

          # Add encryption_mode if not present (defaults to plaintext for backward compatibility)
          yaml_data['encryption_mode'] ||= 'plaintext'
          # Add validation test field if master_password mode (for Phase 2)
          yaml_data['master_password_validation_test'] ||= nil

          yaml_data
        end

        # Adds a character to the favorites list in the YAML data.
        # @param data_dir [String] The directory where the YAML file is located.
        # @param username [String] The username associated with the character.
        # @param char_name [String] The name of the character to add as a favorite.
        # @param game_code [String] The game code associated with the character.
        # @param frontend [String, nil] The frontend associated with the character.
        # @return [Boolean] True if the character was added to favorites, false otherwise.
        # @raise [StandardError] If there is an error adding the favorite.
        # @example
        #   success = Lich::Common::GUI::YamlState.add_favorite(data_dir, username, char_name, game_code)
        def self.add_favorite(data_dir, username, char_name, game_code, frontend = nil)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)
          return false unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)
            yaml_data = migrate_to_favorites_format(yaml_data)

            # Find the character with frontend precision
            character = find_character(yaml_data, username, char_name, game_code, frontend)
            return false unless character

            # Don't add if already a favorite
            return true if character['is_favorite']

            # Mark as favorite and assign order
            character['is_favorite'] = true
            character['favorite_order'] = get_next_favorite_order(yaml_data)
            character['favorite_added'] = Time.now.to_s

            # Save updated data directly without conversion round-trip
            # This preserves the original YAML structure and account ordering
            content = generate_yaml_content(yaml_data)
            result = Utilities.safe_file_operation(yaml_file, :write, content)

            result ? true : false
          rescue StandardError => e
            Lich.log "error: Error adding favorite: #{e.message}"
            false
          end
        end

        # Removes a character from the favorites list in the YAML data.
        # @param data_dir [String] The directory where the YAML file is located.
        # @param username [String] The username associated with the character.
        # @param char_name [String] The name of the character to remove from favorites.
        # @param game_code [String] The game code associated with the character.
        # @param frontend [String, nil] The frontend associated with the character.
        # @return [Boolean] True if the character was removed from favorites, false otherwise.
        # @raise [StandardError] If there is an error removing the favorite.
        # @example
        #   success = Lich::Common::GUI::YamlState.remove_favorite(data_dir, username, char_name, game_code)
        def self.remove_favorite(data_dir, username, char_name, game_code, frontend = nil)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)
          return false unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)
            yaml_data = migrate_to_favorites_format(yaml_data)

            # Find the character with frontend precision
            character = find_character(yaml_data, username, char_name, game_code, frontend)
            return false unless character

            # Don't remove if not a favorite
            return true unless character['is_favorite']

            # Remove favorite status
            character['is_favorite'] = false
            character.delete('favorite_order')
            character.delete('favorite_added')

            # Reorder remaining favorites
            reorder_all_favorites(yaml_data)

            # Save updated data
            content = generate_yaml_content(yaml_data)
            result = Utilities.safe_file_operation(yaml_file, :write, content)

            result ? true : false
          rescue StandardError => e
            Lich.log "error: Error removing favorite: #{e.message}"
            false
          end
        end

        # Checks if a character is marked as a favorite in the YAML data.
        # @param data_dir [String] The directory where the YAML file is located.
        # @param username [String] The username associated with the character.
        # @param char_name [String] The name of the character to check.
        # @param game_code [String] The game code associated with the character.
        # @param frontend [String, nil] The frontend associated with the character.
        # @return [Boolean] True if the character is a favorite, false otherwise.
        # @raise [StandardError] If there is an error checking favorite status.
        # @example
        #   favorite = Lich::Common::GUI::YamlState.is_favorite?(data_dir, username, char_name, game_code)
        def self.is_favorite?(data_dir, username, char_name, game_code, frontend = nil)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)
          return false unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)
            yaml_data = migrate_to_favorites_format(yaml_data)

            character = find_character(yaml_data, username, char_name, game_code, frontend)
            character && character['is_favorite'] == true
          rescue StandardError => e
            Lich.log "error: Error checking favorite status: #{e.message}"
            false
          end
        end

        # Retrieves a list of favorite characters from the YAML data.
        # @param data_dir [String] The directory where the YAML file is located.
        # @return [Array] An array of favorite characters.
        # @raise [StandardError] If there is an error retrieving favorites.
        # @example
        #   favorites = Lich::Common::GUI::YamlState.get_favorites(data_dir)
        def self.get_favorites(data_dir)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)
          return [] unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)
            yaml_data = migrate_to_favorites_format(yaml_data)

            favorites = []

            yaml_data['accounts'].each do |username, account_data|
              next unless account_data['characters']

              account_data['characters'].each do |character|
                if character['is_favorite']
                  favorites << {
                    user_id: username,
                    char_name: character['char_name'],
                    game_code: character['game_code'],
                    game_name: character['game_name'],
                    frontend: character['frontend'],
                    favorite_order: character['favorite_order'] || 999,
                    favorite_added: character['favorite_added']
                  }
                end
              end
            end

            # Sort by favorite order
            favorites.sort_by { |fav| fav[:favorite_order] }
          rescue StandardError => e
            Lich.log "error: Error getting favorites: #{e.message}"
            []
          end
        end

        # Reorders the favorites list in the YAML data based on the provided order.
        # @param data_dir [String] The directory where the YAML file is located.
        # @param ordered_favorites [Array] An array of favorite characters in the desired order.
        # @return [Boolean] True if the reordering was successful, false otherwise.
        # @raise [StandardError] If there is an error reordering favorites.
        # @example
        #   success = Lich::Common::GUI::YamlState.reorder_favorites(data_dir, ordered_favorites)
        def self.reorder_favorites(data_dir, ordered_favorites)
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)
          return false unless File.exist?(yaml_file)

          begin
            yaml_data = YAML.load_file(yaml_file)
            yaml_data = migrate_to_favorites_format(yaml_data)

            # Update favorite order for each character in the provided order
            ordered_favorites.each_with_index do |favorite_info, index|
              character = find_character(
                yaml_data,
                favorite_info[:username] || favorite_info['username'],
                favorite_info[:char_name] || favorite_info['char_name'],
                favorite_info[:game_code] || favorite_info['game_code'],
                favorite_info[:frontend] || favorite_info['frontend']
              )

              if character && character['is_favorite']
                character['favorite_order'] = index + 1
              end
            end

            # Save updated data
            content = generate_yaml_content(yaml_data)
            result = Utilities.safe_file_operation(yaml_file, :write, content)

            result ? true : false
          rescue StandardError => e
            Lich.log "error: Error reordering favorites: #{e.message}"
            false
          end
        end

        # Converts YAML data to the legacy format for entries.
        # @param yaml_data [Hash] The YAML data to convert.
        # @return [Array] The converted entries in legacy format.
        def self.convert_yaml_to_legacy_format(yaml_data)
          entries = []

          return entries unless yaml_data['accounts']

          encryption_mode = (yaml_data['encryption_mode'] || 'plaintext').to_sym

          yaml_data['accounts'].each do |username, account_data|
            next unless account_data['characters']

            # Decrypt password if needed (with recovery for missing master password)
            password = if encryption_mode == :plaintext
                         account_data['password']
                       else
                         decrypt_password_with_recovery(
                           account_data['password'],
                           mode: encryption_mode,
                           account_name: username,
                           validation_test: yaml_data['master_password_validation_test']
                         )
                       end

            account_data['characters'].each do |character|
              entry = {
                user_id: username, # Already normalized to UPCASE in YAML
                password: password, # Decrypted password
                char_name: character['char_name'], # Already normalized to Title case in YAML
                game_code: character['game_code'],
                game_name: character['game_name'],
                frontend: character['frontend'],
                custom_launch: character['custom_launch'],
                custom_launch_dir: character['custom_launch_dir'],
                is_favorite: character['is_favorite'] || false,
                favorite_order: character['favorite_order'],
                encryption_mode: encryption_mode
              }

              entries << entry
            end
          end

          entries
        end

        # Converts legacy entry data to the YAML format.
        # @param entry_data [Array] The legacy entry data to convert.
        # @param validation_test [String, nil] The validation test for the master password.
        # @return [Hash] The converted YAML data.
        def self.convert_legacy_to_yaml_format(entry_data, validation_test = nil)
          yaml_data = { 'accounts' => {} }

          # Preserve encryption_mode if present in entries
          encryption_mode = entry_data.first&.[](:encryption_mode) || :plaintext
          yaml_data['encryption_mode'] = encryption_mode.to_s

          # Preserve master_password_validation_test if provided
          yaml_data['master_password_validation_test'] = validation_test

          entry_data.each do |entry|
            # Normalize account name to UPCASE for consistent storage
            normalized_username = normalize_account_name(entry[:user_id])

            # Initialize account if not exists, with password at account level
            yaml_data['accounts'][normalized_username] ||= {
              'password'   => entry[:password],
              'characters' => []
            }

            character_data = {
              'char_name'         => normalize_character_name(entry[:char_name]),
              'game_code'         => entry[:game_code],
              'game_name'         => entry[:game_name],
              'frontend'          => entry[:frontend],
              'custom_launch'     => entry[:custom_launch],
              'custom_launch_dir' => entry[:custom_launch_dir],
              'is_favorite'       => entry[:is_favorite] || false
            }

            # Add favorite metadata if character is a favorite
            if entry[:is_favorite]
              character_data['favorite_order'] = entry[:favorite_order]
              character_data['favorite_added'] = entry[:favorite_added] || Time.now.to_s
            end

            # Check for duplicate character using precision matching (account/character/game_code/frontend)
            existing_character = yaml_data['accounts'][normalized_username]['characters'].find do |char|
              char['char_name'] == character_data['char_name'] &&
                char['game_code'] == character_data['game_code'] &&
                char['frontend'] == character_data['frontend']
            end

            # Only add if no exact match exists
            unless existing_character
              yaml_data['accounts'][normalized_username]['characters'] << character_data
            end
          end

          yaml_data
        end

        # Sorts entries with favorites prioritized based on the autosort state.
        # @param entries [Array] The entries to sort.
        # @param autosort_state [Boolean] Indicates whether to sort by favorites.
        # @return [Array] The sorted entries.
        def self.sort_entries_with_favorites(entries, autosort_state)
          # If autosort is disabled, preserve original order without any reordering
          return entries unless autosort_state

          # Autosort enabled: apply favorites-first sorting
          # Separate favorites and non-favorites
          favorites = entries.select { |entry| entry[:is_favorite] }
          non_favorites = entries.reject { |entry| entry[:is_favorite] }

          # Sort favorites by favorite_order
          favorites.sort_by! { |entry| entry[:favorite_order] || 999 }

          # Sort non-favorites by account name (upcase), game name, and character name
          sorted_non_favorites = non_favorites.sort do |a, b|
            [a[:user_id].upcase, a[:game_name], a[:char_name]] <=> [b[:user_id].upcase, b[:game_name], b[:char_name]]
          end

          # Return favorites first, then non-favorites
          favorites + sorted_non_favorites
        end

        # Migrates the provided YAML data to include favorite fields.
        # @param yaml_data [Hash] The YAML data to migrate.
        # @return [Hash] The migrated YAML data.
        def self.migrate_to_favorites_format(yaml_data)
          return yaml_data unless yaml_data.is_a?(Hash) && yaml_data['accounts']

          yaml_data['accounts'].each do |_username, account_data|
            next unless account_data['characters'].is_a?(Array)

            account_data['characters'].each do |character|
              # Add favorites fields if not present
              character['is_favorite'] ||= false
              # Don't add favorite_order or favorite_added unless character is actually a favorite
            end
          end

          yaml_data
        end

        # Finds a character in the YAML data based on the provided criteria.
        # @param yaml_data [Hash] The YAML data containing accounts and characters.
        # @param username [String] The username associated with the character.
        # @param char_name [String] The name of the character to find.
        # @param game_code [String] The game code associated with the character.
        # @param frontend [String, nil] The frontend associated with the character.
        # @return [Hash, nil] The found character data or nil if not found.
        def self.find_character(yaml_data, username, char_name, game_code, frontend = nil)
          return nil unless yaml_data['accounts'] && yaml_data['accounts'][username]
          account_data = yaml_data['accounts'][username]
          return nil unless account_data['characters']

          # If frontend is specified, find exact match first
          if frontend
            exact_match = account_data['characters'].find do |character|
              character['char_name'] == char_name &&
                character['game_code'] == game_code &&
                character['frontend'] == frontend
            end
            return exact_match if exact_match
          end

          # Fallback to basic matching only if no exact match found and frontend is nil
          if frontend.nil?
            account_data['characters'].find do |character|
              character['char_name'] == char_name && character['game_code'] == game_code
            end
          else
            # If frontend was specified but no exact match found, return nil
            nil
          end
        end

        # Retrieves the next available favorite order number based on existing favorites.
        # @param yaml_data [Hash] The YAML data containing accounts and characters.
        # @return [Integer] The next favorite order number.
        def self.get_next_favorite_order(yaml_data)
          max_order = 0

          yaml_data['accounts'].each do |_username, account_data|
            next unless account_data['characters']

            account_data['characters'].each do |character|
              if character['is_favorite'] && character['favorite_order']
                max_order = [max_order, character['favorite_order']].max
              end
            end
          end

          max_order + 1
        end

        # Finds an entry in the legacy format based on the provided criteria.
        # @param entry_data [Array] The legacy entry data to search.
        # @param username [String] The username associated with the entry.
        # @param char_name [String] The name of the character to find.
        # @param game_code [String] The game code associated with the entry.
        # @param frontend [String, nil] The frontend associated with the entry.
        # @return [Hash, nil] The found entry data or nil if not found.
        def self.find_entry_in_legacy_format(entry_data, username, char_name, game_code, frontend = nil)
          entry_data.find do |entry|
            # Match on username first
            next unless entry[:user_id] == username

            # Apply same matching logic as find_character
            matches_basic = entry[:char_name] == char_name && entry[:game_code] == game_code

            if frontend.nil?
              # Backward compatibility: if no frontend specified, match any frontend
              matches_basic
            else
              # Frontend precision: must match exact frontend
              matches_basic && entry[:frontend] == frontend
            end
          end
        end

        # Reorders all favorite characters in the YAML data based on their current order.
        # @param yaml_data [Hash] The YAML data containing accounts and characters.
        def self.reorder_all_favorites(yaml_data)
          # Collect all favorites
          all_favorites = []

          yaml_data['accounts'].each do |_username, account_data|
            next unless account_data['characters']

            account_data['characters'].each do |character|
              if character['is_favorite']
                all_favorites << character
              end
            end
          end

          # Sort by current order and reassign consecutive numbers
          all_favorites.sort_by! { |char| char['favorite_order'] || 999 }
          all_favorites.each_with_index do |character, index|
            character['favorite_order'] = index + 1
          end
        end

        # Prepares YAML data for serialization, ensuring proper formatting and structure.
        # @param yaml_data [Hash] The YAML data to prepare.
        # @return [Hash] The prepared YAML data.
        def self.prepare_yaml_for_serialization(yaml_data)
          # Clone to avoid mutating caller's object
          prepared_data = Marshal.load(Marshal.dump(yaml_data))

          # Ensure top-level fields are explicitly present (defensive programming)
          prepared_data['encryption_mode'] ||= 'plaintext'
          prepared_data['master_password_validation_test'] ||= nil

          # Preserve encrypted passwords by ensuring they are serialized as quoted strings
          # This prevents YAML from using multiline formatting (|, >) which breaks Base64 decoding
          if prepared_data['accounts']
            prepared_data['accounts'].each do |_username, account_data|
              if account_data.is_a?(Hash) && account_data['password']
                # Force password to be treated as a plain scalar string
                account_data['password'] = account_data['password'].to_s
              end
            end
          end

          prepared_data
        end

        # Normalizes the account name by stripping whitespace and converting to uppercase.
        # @param name [String, nil] The account name to normalize.
        # @return [String] The normalized account name.
        def self.normalize_account_name(name)
          return '' if name.nil?
          name.to_s.strip.upcase
        end

        # Normalizes the character name by stripping whitespace and capitalizing.
        # @param name [String, nil] The character name to normalize.
        # @return [String] The normalized character name.
        def self.normalize_character_name(name)
          return '' if name.nil?
          name.to_s.strip.capitalize
        end

        # Generates the YAML content from the provided data, including headers.
        # @param yaml_data [Hash] The YAML data to generate content from.
        # @return [String] The generated YAML content.
        def self.generate_yaml_content(yaml_data)
          # Prepare YAML with password preservation (clones to avoid mutation)
          prepared_yaml = prepare_yaml_for_serialization(yaml_data)

          content = "# Lich 5 Login Entries - YAML Format\n" \
                  + "# Generated: #{Time.now}\n" \
                  + YAML.dump(prepared_yaml, permitted_classes: [Symbol])
          return content
        end

        # Writes the provided YAML data to a file with secure permissions.
        # @param yaml_file [String] The path to the YAML file.
        # @param yaml_data [Hash] The YAML data to write.
        def self.write_yaml_file(yaml_file, yaml_data)
          prepared_yaml = prepare_yaml_for_serialization(yaml_data)

          File.open(yaml_file, 'w', 0o600) do |file|
            file.puts "# Lich 5 Login Entries - YAML Format"
            file.puts "# Generated: #{Time.now}"
            file.write(YAML.dump(prepared_yaml, permitted_classes: [Symbol]))
          end
        end

        # Ensures that a master password exists, prompting the user to create one if necessary.
        # @return [Hash, nil] The master password and validation test if created, nil otherwise.
        def self.ensure_master_password_exists
          # Check if master password already in Keychain
          existing = MasterPasswordManager.retrieve_master_password
          return existing if !existing.nil? && !existing.empty?

          # Show UI prompt to CREATE master password
          master_password = MasterPasswordPrompt.show_create_master_password_dialog

          if master_password.nil?
            Lich.log "info: User declined to create master password"
            return nil
          end

          # Create validation test (expensive 100k iterations, one-time)
          validation_test = MasterPasswordManager.create_validation_test(master_password)

          if validation_test.nil?
            Lich.log "error: Failed to create validation test"
            return nil
          end

          # Store in Keychain
          stored = MasterPasswordManager.store_master_password(master_password)

          unless stored
            Lich.log "error: Failed to store master password in Keychain"
            return nil
          end

          Lich.log "info: Master password created and stored in Keychain"
          # Return both password and validation test for YAML storage
          { password: master_password, validation_test: validation_test }
        end

        # Retrieves the existing master password for migration purposes, creating a validation test.
        # @return [Hash, nil] The existing master password and validation test if found, nil otherwise.
        def self.get_existing_master_password_for_migration
          # Retrieve existing master password from keychain
          existing_password = MasterPasswordManager.retrieve_master_password

          if existing_password.nil? || existing_password.empty?
            Lich.log "info: No existing master password found in keychain - user should create one"
            return nil
          end

          Lich.log "info: Found existing master password in keychain - creating validation test for migration"

          # Create a NEW validation test with the existing password
          # This is needed because we don't have the old validation test in YAML yet
          validation_test = MasterPasswordManager.create_validation_test(existing_password)

          if validation_test.nil?
            Lich.log "error: Failed to create validation test for existing master password"
            return nil
          end

          Lich.log "info: Validation test created for existing master password"
          { password: existing_password, validation_test: validation_test }
        end
      end
    end
  end
end
