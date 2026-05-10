
module Lich
  module Common
    module GUI
      module GameSelection
        # Game code to display name mapping
        # Maps internal game codes to user-friendly display names
        # Game code to display name mapping.
        #
        # Maps internal game codes to user-friendly display names.
        # @see REVERSE_GAME_MAPPING
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
        REVERSE_GAME_MAPPING = GAME_MAPPING.invert.freeze

        # Creates a game selection combo box.
        #
        # @param current_selection [String, nil] the currently selected game code, if any
        # @return [Gtk::ComboBoxText] the combo box with game options
        # @example Create a game selection combo
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

        # Retrieves the selected game code from the combo box.
        #
        # @param combo [Gtk::ComboBoxText] the combo box to retrieve the selection from
        # @return [String] the selected game code or 'GS3' if not found
        # @example Get the selected game code
        #   code = Lich::Common::GUI::GameSelection.get_selected_game_code(combo)
        def self.get_selected_game_code(combo)
          return nil unless combo

          selected_text = combo.active_text
          REVERSE_GAME_MAPPING[selected_text] || 'GS3' # Default to GS3 if not found
        end

        # Retrieves the display name for a given game code.
        #
        # @param game_code [String] the internal game code
        # @return [String] the user-friendly display name or 'Unknown' if not found
        # @example Get the game name
        #   name = Lich::Common::GUI::GameSelection.get_game_name("GS3")
        def self.get_game_name(game_code)
          GAME_MAPPING[game_code] || 'Unknown'
        end

        # Updates the game selection combo box with new options.
        #
        # @param combo [Gtk::ComboBoxText] the combo box to update
        # @param current_selection [String, nil] the currently selected game code, if any
        # @return [void]
        # @example Update the game selection combo
        #   Lich::Common::GUI::GameSelection.update_game_selection_combo(combo, "GSX")
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
