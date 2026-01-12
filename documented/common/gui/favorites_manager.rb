
module Lich
  module Common
    module GUI
      module FavoritesManager
        # Adds a character to the favorites list.
        # @param data_dir [String] The directory where data is stored.
        # @param username [String] The username associated with the character.
        # @param char_name [String] The name of the character to add.
        # @param game_code [String] The game code of the character.
        # @param frontend [String, nil] The frontend associated with the character (optional).
        # @return [Boolean] Returns true if the character was added successfully, false otherwise.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.add_favorite("/path/to/data", "user123", "Hero", "game_001")
        def self.add_favorite(data_dir, username, char_name, game_code, frontend = nil)
          return false if data_dir.nil? || username.nil? || char_name.nil? || game_code.nil?

          begin
            result = YamlState.add_favorite(data_dir, username, char_name, game_code, frontend)

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
        # @param data_dir [String] The directory where data is stored.
        # @param username [String] The username associated with the character.
        # @param char_name [String] The name of the character to remove.
        # @param game_code [String] The game code of the character.
        # @param frontend [String, nil] The frontend associated with the character (optional).
        # @return [Boolean] Returns true if the character was removed successfully, false otherwise.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.remove_favorite("/path/to/data", "user123", "Hero", "game_001")
        def self.remove_favorite(data_dir, username, char_name, game_code, frontend = nil)
          return false if data_dir.nil? || username.nil? || char_name.nil? || game_code.nil?

          begin
            result = YamlState.remove_favorite(data_dir, username, char_name, game_code, frontend)

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
        # @param data_dir [String] The directory where data is stored.
        # @param username [String] The username associated with the character.
        # @param char_name [String] The name of the character to toggle.
        # @param game_code [String] The game code of the character.
        # @param frontend [String, nil] The frontend associated with the character (optional).
        # @return [Boolean] Returns true if the character is now a favorite, false if it was removed.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.toggle_favorite("/path/to/data", "user123", "Hero", "game_001")
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
        # @param data_dir [String] The directory where data is stored.
        # @param username [String] The username associated with the character.
        # @param char_name [String] The name of the character to check.
        # @param game_code [String] The game code of the character.
        # @param frontend [String, nil] The frontend associated with the character (optional).
        # @return [Boolean] Returns true if the character is a favorite, false otherwise.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.is_favorite?("/path/to/data", "user123", "Hero", "game_001")
        def self.is_favorite?(data_dir, username, char_name, game_code, frontend = nil)
          return false if data_dir.nil? || username.nil? || char_name.nil? || game_code.nil?

          begin
            YamlState.is_favorite?(data_dir, username, char_name, game_code, frontend)
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.is_favorite?: #{e.message}"
            false
          end
        end

        # Retrieves all favorites for a given data directory.
        # @param data_dir [String] The directory where data is stored.
        # @return [Array<Hash>] An array of favorite characters.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.get_all_favorites("/path/to/data")
        def self.get_all_favorites(data_dir)
          return [] if data_dir.nil?

          begin
            YamlState.get_favorites(data_dir)
          rescue StandardError => e
            Lich.log "error: Error in FavoritesManager.get_all_favorites: #{e.message}"
            []
          end
        end

        # Reorders the favorites list based on the provided order.
        # @param data_dir [String] The directory where data is stored.
        # @param ordered_favorites [Array<Hash>] The ordered list of favorites.
        # @return [Boolean] Returns true if the reordering was successful, false otherwise.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.reorder_favorites("/path/to/data", [{:user_id => "user123", :char_name => "Hero", :game_code => "game_001"}])
        def self.reorder_favorites(data_dir, ordered_favorites)
          return false if data_dir.nil? || ordered_favorites.nil?

          begin
            result = YamlState.reorder_favorites(data_dir, ordered_favorites)

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

        # Counts the number of favorites in the specified data directory.
        # @param data_dir [String] The directory where data is stored.
        # @return [Integer] The count of favorites.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.favorites_count("/path/to/data")
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
        # @param data_dir [String] The directory where data is stored.
        # @param username [String] The username associated with the account.
        # @return [Array<Hash>] An array of favorite characters for the account.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.get_account_favorites("/path/to/data", "user123")
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
        # @param data_dir [String] The directory where data is stored.
        # @param game_code [String] The game code to filter favorites.
        # @return [Array<Hash>] An array of favorite characters for the game.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.get_game_favorites("/path/to/data", "game_001")
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

        # Validates and cleans up orphaned favorites in the specified data directory.
        # @param data_dir [String] The directory where data is stored.
        # @return [Hash] A hash containing validation results and cleanup statistics.
        # @raise [StandardError] If an error occurs during the operation.
        # @example
        #   FavoritesManager.validate_and_cleanup_favorites("/path/to/data")
        def self.validate_and_cleanup_favorites(data_dir)
          return { valid: false, cleaned: 0, errors: ['Invalid data directory'] } if data_dir.nil?

          begin
            # Load all entry data to validate against
            entry_data = YamlState.load_saved_entries(data_dir, false)
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
        # @param username [String] The username associated with the character.
        # @param char_name [String] The name of the character.
        # @param game_code [String] The game code of the character.
        # @param frontend [String, nil] The frontend associated with the character (optional).
        # @return [Hash] A hash representing the character ID.
        # @example
        #   FavoritesManager.create_character_id("user123", "Hero", "game_001")
        def self.create_character_id(username, char_name, game_code, frontend = nil)
          {
            username: username,
            char_name: char_name,
            game_code: game_code,
            frontend: frontend
          }
        end

        # Extracts character ID information from the provided entry data.
        # @param entry_data [Hash] The entry data containing character information.
        # @return [Hash] A hash representing the extracted character ID.
        # @example
        #   FavoritesManager.extract_character_id({:user_id => "user123", :char_name => "Hero", :game_code => "game_001"})
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
        # @param data_dir [String] The directory where data is stored.
        # @return [Boolean] Returns true if favorites are available, false otherwise.
        # @example
        #   FavoritesManager.favorites_available?("/path/to/data")
        def self.favorites_available?(data_dir)
          return false if data_dir.nil?

          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)
          File.exist?(yaml_file)
        end
      end
    end
  end
end
