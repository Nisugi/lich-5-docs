
# Lich module
# This module serves as a namespace for the Lich project.
module Lich
  module Common
    module GUI
      # Utilities module
      # This module contains utility methods for GUI components.
      # @example Using the Utilities module
      #   css_provider = Lich::Common::GUI::Utilities.create_button_css_provider(font_size: 14)
      module Utilities
        # Creates a CSS provider for buttons.
        # @param font_size [Integer] The font size for the button.
        # @return [Gtk::CssProvider] The CSS provider for buttons.
        # @example
        #   css = Lich::Common::GUI::Utilities.create_button_css_provider(font_size: 16)
        def self.create_button_css_provider(font_size: 12)
          css = Gtk::CssProvider.new
          css.load_from_data("button {border-radius: 5px; font-size: #{font_size}px;}")
          css
        end

        # Creates a CSS provider for tabs.
        # @return [Gtk::CssProvider] The CSS provider for tabs.
        # @example
        #   css = Lich::Common::GUI::Utilities.create_tab_css_provider
        def self.create_tab_css_provider
          css = Gtk::CssProvider.new
          css.load_from_data("notebook {border-width: 1px; border-color: #999999; border-style: solid;}")
          css
        end

        # Creates a message dialog.
        # @param parent [Gtk::Window, nil] The parent window for the dialog.
        # @param icon [Gdk::Pixbuf, nil] The icon to display in the dialog.
        # @return [Proc] A lambda that takes a message and shows the dialog.
        # @example
        #   dialog = Lich::Common::GUI::Utilities.create_message_dialog(parent: window, icon: my_icon)
        #   dialog.call("Hello, World!")
        def self.create_message_dialog(parent: nil, icon: nil)
          ->(message) {
            dialog = Gtk::MessageDialog.new(
              parent: parent,
              flags: :modal,
              type: :info,
              buttons: :ok,
              message: message
            )
            dialog.title = "Message"
            dialog.set_icon(icon) if icon
            dialog.run
            dialog.destroy
          }
        end

        # Converts a game code to its corresponding realm name.
        # @param game_code [String] The game code to convert.
        # @return [String] The corresponding realm name or the original game code if not found.
        # @example
        #   realm = Lich::Common::GUI::Utilities.game_code_to_realm("GS3")
        def self.game_code_to_realm(game_code)
          case game_code
          when "GS3"
            "GS Prime"
          when "GSF"
            "GS Shattered"
          when "GSX"
            "GS Platinum"
          when "GST"
            "GS Test"
          when "DR"
            "DR Prime"
          when "DRF"
            "DR Fallen"
          when "DRT"
            "DR Test"
          else
            game_code
          end
        end

        # Converts a realm name to its corresponding game code.
        # @param realm [String] The realm name to convert.
        # @return [String] The corresponding game code or "GS3" if not found.
        # @example
        #   game_code = Lich::Common::GUI::Utilities.realm_to_game_code("gemstone iv")
        def self.realm_to_game_code(realm)
          case realm.downcase
          when "gemstone iv", "prime"
            "GS3"
          when "gemstone iv shattered", "shattered"
            "GSF"
          when "gemstone iv platinum", "platinum"
            "GSX"
          when "gemstone iv prime test", "test"
            "GST"
          when "dragonrealms", "dr prime"
            "DR"
          when "dragonrealms the fallen", "dr fallen"
            "DRF"
          when "dragonrealms prime test", "dr test"
            "DRT"
          else
            "GS3" # Default to GS3 if unknown
          end
        end

        # Performs a safe file operation (read, write, or backup).
        # @param file_path [String] The path to the file.
        # @param operation [Symbol] The operation to perform (:read, :write, :backup).
        # @param content [String, nil] The content to write (only for :write).
        # @return [String, true, false] The content read, true if write was successful, or false if backup failed.
        # @raise [StandardError] If an error occurs during the file operation.
        # @example
        #   content = Lich::Common::GUI::Utilities.safe_file_operation("file.txt", :read")
        def self.safe_file_operation(file_path, operation, content = nil)
          case operation
          when :read
            File.read(file_path)
          when :write
            # Create backup if file exists
            safe_file_operation(file_path, :backup) if File.exist?(file_path)

            # Write content to file with secure permissions
            File.open(file_path, 'w', 0600) do |file|
              file.write(content)
            end
            true
          when :backup
            return false unless File.exist?(file_path)

            backup_file = "#{file_path}.bak"
            FileUtils.cp(file_path, backup_file)
            true
          end
        rescue StandardError => e
          Lich.log "error: Error in file operation (#{operation}): #{e.message}"
          operation == :read ? "" : false
        end

        # Performs a verified file operation (read, write, or backup).
        # @param file_path [String] The path to the file.
        # @param operation [Symbol] The operation to perform (:read, :write, :backup).
        # @param content [String, nil] The content to write (only for :write).
        # @return [String, true, false] The content read, true if write was successful, or false if backup failed.
        # @raise [StandardError] If an error occurs during the file operation.
        # @example
        #   success = Lich::Common::GUI::Utilities.verified_file_operation("file.txt", :write, "new content")
        def self.verified_file_operation(file_path, operation, content = nil)
          case operation
          when :read
            File.read(file_path)
          when :write
            # Create backup if file exists
            safe_file_operation(file_path, :backup) if File.exist?(file_path)

            # Write content with forced synchronization and secure permissions
            File.open(file_path, 'w', 0600) do |file|
              file.write(content)
              file.flush    # Force write to OS buffer
              file.fsync    # Force OS to write to disk
            end

            # Verify write completed by reading back and comparing
            written_content = File.read(file_path)
            return written_content == content
          when :backup
            return false unless File.exist?(file_path)

            backup_file = "#{file_path}.bak"
            FileUtils.cp(file_path, backup_file)

            # Verify backup was created successfully
            File.exist?(backup_file) && File.size(backup_file) == File.size(file_path)
          end
        rescue StandardError => e
          Lich.log "error: Error in verified file operation (#{operation}): #{e.message}"
          operation == :read ? "" : false
        end

        # Sorts entries based on the autosort state.
        # @param entries [Array<Hash>] The entries to sort.
        # @param autosort_state [Boolean] The state indicating whether to use autosorting.
        # @return [Array<Hash>] The sorted entries.
        # @example
        #   sorted_entries = Lich::Common::GUI::Utilities.sort_entries(entries, true)
        def self.sort_entries(entries, autosort_state)
          if autosort_state
            # Sort by game name, account name, and character name
            entries.sort do |a, b|
              [a[:game_name], a[:user_id], a[:char_name]] <=> [b[:game_name], b[:user_id], b[:char_name]]
            end
          else
            # Sort by account name and character name (old Lich 4 style)
            entries.sort do |a, b|
              [a[:user_id].downcase, a[:char_name]] <=> [b[:user_id].downcase, b[:char_name]]
            end
          end
        end
      end
    end
  end
end
