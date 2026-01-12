
module Lich
  module Common
    module GUI
      # Module for game selection GUI functionality
      # Provides methods to create and manage game selection interfaces.
      # @example Using the GameSelection module
      #   combo = Lich::Common::GUI::GameSelection.create_game_selection_combo
      module GameSelection
        # Game code to display name mapping
        # Maps internal game codes to user-friendly display names
        # Game code to display name mapping
        # Maps internal game codes to user-friendly display names.
        GAME_MAPPING = {
          'GS3' => 'GemStone IV',
          'GSX' => 'GemStone IV Platinum',
          'GST' => 'GemStone IV Prime Test',
          'GSF' => 'GemStone IV Shattered',
          'DR'  => 'DragonRealms',
          'DRX' => 'DragonRealms Platinum',
          'DRT' => 'DragonRealms Prime Test',
          'DRF' => 'DragonRealms Fallen'
        }.freeze

        # Display name to game code mapping (reverse of GAME_MAPPING)
        # Used for converting user-selected display names back to game codes
        # Display name to game code mapping (reverse of GAME_MAPPING)
        # Used for converting user-selected display names back to game codes.
        REVERSE_GAME_MAPPING = GAME_MAPPING.invert.freeze

        # Creates a combo box for game selection.
        # @param current_selection [String, nil] The game code to set as the default selection.
        # @return [Gtk::ComboBoxText] The combo box populated with game options.
        # @example Creating a game selection combo
        #   combo = Lich::Common::GUI::GameSelection.create_game_selection_combo("GS3")
        def self.create_game_selection_combo(current_selection = nil)
          combo = Gtk::ComboBoxText.new

          # Add all game options
          GAME_MAPPING.each do |_code, name|
            combo.append_text(name)
          end

          # Set default selection
          if current_selection && GAME_MAPPING.key?(current_selection)
            # Set to the provided game code
            index = GAME_MAPPING.keys.index(current_selection)
            combo.active = index if index
          else
            # Default to GS Prime
            combo.active = GAME_MAPPING.keys.index('GS3') || 0
          end

          # Add accessibility properties
          Accessibility.make_combo_accessible(
            combo,
            "Game Selection",
            "Select the game for this character"
          )

          combo
        end

        # Retrieves the game code corresponding to the selected game name in the combo box.
        # @param combo [Gtk::ComboBoxText] The combo box from which to get the selected game.
        # @return [String, nil] The game code of the selected game, or 'GS3' if not found.
        # @example Getting the selected game code
        #   code = Lich::Common::GUI::GameSelection.get_selected_game_code(combo)
        def self.get_selected_game_code(combo)
          return nil unless combo

          selected_text = combo.active_text
          REVERSE_GAME_MAPPING[selected_text] || 'GS3' # Default to GS3 if not found
        end

        # Gets the display name for a given game code.
        # @param game_code [String] The internal game code.
        # @return [String] The user-friendly display name for the game, or 'Unknown' if not found.
        # @example Getting a game name
        #   name = Lich::Common::GUI::GameSelection.get_game_name("GS3")
        def self.get_game_name(game_code)
          GAME_MAPPING[game_code] || 'Unknown'
        end

        # Updates the game selection combo box with the current game options.
        # @param combo [Gtk::ComboBoxText] The combo box to update.
        # @param current_selection [String, nil] The game code to set as the default selection.
        # @return [void]
        # @example Updating the game selection combo
        #   Lich::Common::GUI::GameSelection.update_game_selection_combo(combo, "GSF")
        def self.update_game_selection_combo(combo, current_selection = nil)
          return unless combo

          # Clear existing options
          while combo.remove_text(0)
            # Keep removing until empty
          end

          # Add all game options
          GAME_MAPPING.each do |_code, name|
            combo.append_text(name)
          end

          # Set selection
          if current_selection && GAME_MAPPING.key?(current_selection)
            # Set to the provided game code
            index = GAME_MAPPING.keys.index(current_selection)
            combo.active = index if index
          else
            # Default to GS Prime
            combo.active = GAME_MAPPING.keys.index('GS3') || 0
          end
        end
      end
    end
  end
end
