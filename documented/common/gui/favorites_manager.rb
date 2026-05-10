
module Lich
  module Common
    module GUI
      module FavoritesManager
        # Adds a character to the favorites list.
        #
        # @param data_dir [String] the directory containing data files
        # @param username [String] the user's account name
        # @param char_name [String] the name of the character to add
        # @param game_code [String] the game code associated with the character
        # @param frontend [String, nil] optional frontend identifier
        # @return [Boolean] true if the character was added successfully, false otherwise
        # @raise [StandardError] if an error occurs during the operation
        def self.add_favorite(data_dir, username, char_name, game_code, frontend = nil)
          return false if data_dir.nil? || username.nil? || char_name.nil? || game_code.nil?

          begin
            result = Lich::Common::Authentication::EntryStore.add_favorite(data_dir, username, char_name, game_code, frontend)

            if result
              frontend_info = frontend ? " (#{frontend})" : ""
              Lich.log "info: Added character '#{char_name}' (#{game_code})#{frontend_info} from account '#{username}' to favorites"
            else
              frontend_info = frontend ? " (#{frontend})" : ""
              Lich.log "warning: Failed to add character '#{char_name}' (#{game_code})#{frontend_info} from account '#{username}' to favorites"
            end

            result
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.add_favorite: #{e.message}"
            false
          end
        end

        # Removes a character from the favorites list.
        #
        # @param data_dir [String] the directory containing data files
        # @param username [String] the user's account name
        # @param char_name [String] the name of the character to remove
        # @param game_code [String] the game code associated with the character
        # @param frontend [String, nil] optional frontend identifier
        # @return [Boolean] true if the character was removed successfully, false otherwise
        # @raise [StandardError] if an error occurs during the operation
        def self.remove_favorite(data_dir, username, char_name, game_code, frontend = nil)
          return false if data_dir.nil? || username.nil? || char_name.nil? || game_code.nil?

          begin
            result = Lich::Common::Authentication::EntryStore.remove_favorite(data_dir, username, char_name, game_code, frontend)

            if result
              frontend_info = frontend ? " (#{frontend})" : ""
              Lich.log "info: Removed character '#{char_name}' (#{game_code})#{frontend_info} from account '#{username}' from favorites"
            else
              frontend_info = frontend ? " (#{frontend})" : ""
              Lich.log "warning: Failed to remove character '#{char_name}' (#{game_code})#{frontend_info} from account '#{username}' from favorites"
            end

            result
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.remove_favorite: #{e.message}"
            false
          end
        end

        # Toggles a character's favorite status.
        #
        # @param data_dir [String] the directory containing data files
        # @param username [String] the user's account name
        # @param char_name [String] the name of the character to toggle
        # @param game_code [String] the game code associated with the character
        # @param frontend [String, nil] optional frontend identifier
        # @return [Boolean] true if the character is now a favorite, false if it was removed
        # @raise [StandardError] if an error occurs during the operation
        def self.toggle_favorite(data_dir, username, char_name, game_code, frontend = nil)
          return false if data_dir.nil? || username.nil? || char_name.nil? || game_code.nil?

          begin
            if is_favorite?(data_dir, username, char_name, game_code, frontend)
              remove_favorite(data_dir, username, char_name, game_code, frontend)
              false
            else
              add_favorite(data_dir, username, char_name, game_code, frontend)
              true
            end
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.toggle_favorite: #{e.message}"
            false
          end
        end

        # Checks if a character is in the favorites list.
        #
        # @param data_dir [String] the directory containing data files
        # @param username [String] the user's account name
        # @param char_name [String] the name of the character to check
        # @param game_code [String] the game code associated with the character
        # @param frontend [String, nil] optional frontend identifier
        # @return [Boolean] true if the character is a favorite, false otherwise
        # @raise [StandardError] if an error occurs during the operation
        def self.is_favorite?(data_dir, username, char_name, game_code, frontend = nil)
          return false if data_dir.nil? || username.nil? || char_name.nil? || game_code.nil?

          begin
            Lich::Common::Authentication::EntryStore.is_favorite?(data_dir, username, char_name, game_code, frontend)
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.is_favorite?: #{e.message}"
            false
          end
        end

        # Retrieves all favorites for the specified data directory.
        #
        # @param data_dir [String] the directory containing data files
        # @return [Array<Hash>] an array of favorite characters, each represented as a hash
        # @raise [StandardError] if an error occurs during the operation
        def self.get_all_favorites(data_dir)
          return [] if data_dir.nil?

          begin
            Lich::Common::Authentication::EntryStore.get_favorites(data_dir)
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.get_all_favorites: #{e.message}"
            []
          end
        end

        # Reorders the favorites list based on the provided order.
        #
        # @param data_dir [String] the directory containing data files
        # @param ordered_favorites [Array<Hash>] the new order of favorites
        # @return [Boolean] true if the reorder was successful, false otherwise
        # @raise [StandardError] if an error occurs during the operation
        def self.reorder_favorites(data_dir, ordered_favorites)
          return false if data_dir.nil? || ordered_favorites.nil?

          begin
            result = Lich::Common::Authentication::EntryStore.reorder_favorites(data_dir, ordered_favorites)

            if result
              Lich.log "info: Successfully reordered #{ordered_favorites.length} favorites"
            else
              Lich.log "warning: Failed to reorder favorites"
            end

            result
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.reorder_favorites: #{e.message}"
            false
          end
        end

        # Returns the count of favorites for the specified data directory.
        #
        # @param data_dir [String] the directory containing data files
        # @return [Integer] the number of favorites
        # @raise [StandardError] if an error occurs during the operation
        def self.favorites_count(data_dir)
          return 0 if data_dir.nil?

          begin
            get_all_favorites(data_dir).length
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.favorites_count: #{e.message}"
            0
          end
        end

        # Retrieves all favorites for a specific account.
        #
        # @param data_dir [String] the directory containing data files
        # @param username [String] the user's account name
        # @return [Array<Hash>] an array of favorites associated with the account
        # @raise [StandardError] if an error occurs during the operation
        def self.get_account_favorites(data_dir, username)
          return [] if data_dir.nil? || username.nil?

          begin
            all_favorites = get_all_favorites(data_dir)
            all_favorites.select { |fav| fav[:user_id] == username }
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.get_account_favorites: #{e.message}"
            []
          end
        end

        # Retrieves all favorites for a specific game.
        #
        # @param data_dir [String] the directory containing data files
        # @param game_code [String] the game code to filter favorites
        # @return [Array<Hash>] an array of favorites associated with the game
        # @raise [StandardError] if an error occurs during the operation
        def self.get_game_favorites(data_dir, game_code)
          return [] if data_dir.nil? || game_code.nil?

          begin
            all_favorites = get_all_favorites(data_dir)
            all_favorites.select { |fav| fav[:game_code] == game_code }
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.get_game_favorites: #{e.message}"
            []
          end
        end

        # Validates the favorites list and removes any orphaned entries.
        #
        # @param data_dir [String] the directory containing data files
        # @return [Hash] a hash containing validation results, including:
        #   - valid [Boolean] indicates if the validation was successful
        #   - cleaned [Integer] number of cleaned favorites
        #   - errors [Array<String>] list of errors encountered during cleanup
        # @raise [StandardError] if an error occurs during the operation
        def self.validate_and_cleanup_favorites(data_dir)
          return { valid: false, cleaned: 0, errors: ['Invalid data directory'] } if data_dir.nil?

          begin
            # Load all entry data to validate against
            entry_data = Lich::Common::Authentication::EntryStore.load_saved_entries(data_dir, false)
            favorites = get_all_favorites(data_dir)

            cleaned_count = 0
            errors = []

            favorites.each do |favorite|
              # Check if the character still exists in the entry data
              character_exists = entry_data.any? do |entry|
                entry[:user_id] == favorite[:user_id] &&
                  entry[:char_name] == favorite[:char_name] &&
                  entry[:game_code] == favorite[:game_code] &&
                  (favorite[:frontend].nil? || entry[:frontend] == favorite[:frontend])
              end

              unless character_exists
                # Remove orphaned favorite
                if remove_favorite(data_dir, favorite[:user_id], favorite[:char_name], favorite[:game_code], favorite[:frontend])
                  cleaned_count += 1
                  frontend_info = favorite[:frontend] ? " (#{favorite[:frontend]})" : ""
                  Lich.log "info: Removed orphaned favorite: #{favorite[:char_name]} (#{favorite[:game_code]})#{frontend_info} from #{favorite[:user_id]}"
                else
                  frontend_info = favorite[:frontend] ? " (#{favorite[:frontend]})" : ""
                  errors << "Failed to remove orphaned favorite: #{favorite[:char_name]} (#{favorite[:game_code]})#{frontend_info} from #{favorite[:user_id]}"
                end
              end
            end

            {
              valid: true,
              total_favorites: favorites.length,
              cleaned: cleaned_count,
              remaining: favorites.length - cleaned_count,
              errors: errors
            }
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.validate_and_cleanup_favorites: #{e.message}"
            { valid: false, cleaned: 0, errors: [e.message] }
          end
        end

        # Creates a character ID hash from the provided parameters.
        #
        # @param username [String] the user's account name
        # @param char_name [String] the name of the character
        # @param game_code [String] the game code associated with the character
        # @param frontend [String, nil] optional frontend identifier
        # @return [Hash] a hash representing the character ID
        def self.create_character_id(username, char_name, game_code, frontend = nil)
          {
            username: username,
            char_name: char_name,
            game_code: game_code,
            frontend: frontend
          }
        end

        # Extracts character ID information from the provided entry data.
        #
        # @param entry_data [Hash] the entry data containing character information
        # @return [Hash] a hash containing the extracted character ID information, or an empty hash if input is invalid
        def self.extract_character_id(entry_data)
          return {} unless entry_data.is_a?(Hash)

          {
            username: entry_data[:user_id],
            char_name: entry_data[:char_name],
            game_code: entry_data[:game_code],
            frontend: entry_data[:frontend]
          }
        end

        # Checks if favorites are available in the specified data directory.
        #
        # @param data_dir [String] the directory containing data files
        # @return [Boolean] true if favorites are available, false otherwise
        def self.favorites_available?(data_dir)
          return false if data_dir.nil?

          yaml_file = Lich::Common::Authentication::EntryStore.yaml_file_path(data_dir)
          File.exist?(yaml_file)
        end
      end
    end
  end
end
