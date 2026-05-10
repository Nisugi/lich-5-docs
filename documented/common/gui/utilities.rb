
module Lich
  module Common
    module GUI
      module Utilities
        # Creates a CSS provider for buttons with a specified font size.
        #
        # @param font_size [Integer] the font size for the button text (default is 12)
        # @return [Gtk::CssProvider] the CSS provider for buttons
        def self.create_button_css_provider(font_size: 12)
          css = Gtk::CssProvider.new
          css.load_from_data("button {border-radius: 5px; font-size: #{font_size}px;}")
          css
        end

        # Creates a CSS provider for tabs.
        # @return [Gtk::CssProvider] the CSS provider for tabs
        def self.create_tab_css_provider
          css = Gtk::CssProvider.new
          css.load_from_data("notebook {border-width: 1px; border-color: #999999; border-style: solid;}")
          css
        end

        # Creates a message dialog with a specified parent and icon.
        #
        # @param parent [Gtk::Window, nil] the parent window for the dialog
        # @param icon [Gdk::Pixbuf, nil] the icon to display in the dialog
        # @return [Proc] a lambda that takes a message and displays the dialog
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
        #
        # @param game_code [String] the game code to convert
        # @return [String] the corresponding realm name or the original game code if not found
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
        #
        # @param realm [String] the realm name to convert
        # @return [String] the corresponding game code or "GS3" if not found
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

        # Performs a safe file operation (read, write, or backup) with error handling.
        #
        # @param file_path [String] the path to the file
        # @param operation [Symbol] the operation to perform (:read, :write, or :backup)
        # @param content [String, nil] the content to write (only for :write)
        # @return [String, Boolean] the file content for :read, true for successful write, false for backup failure
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

        # Performs a verified file operation (read or write) with error handling and verification.
        #
        # @param file_path [String] the path to the file
        # @param operation [Symbol] the operation to perform (:read or :write)
        # @param content [String, nil] the content to write (only for :write)
        # @return [String, Boolean] the file content for :read, true if write was successful, false otherwise
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

        # Sorts a list of entries based on the autosort state.
        #
        # @param entries [Array<Hash>] the entries to sort
        # @param autosort_state [Boolean] whether to sort automatically or not
        # @return [Array<Hash>] the sorted entries
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
