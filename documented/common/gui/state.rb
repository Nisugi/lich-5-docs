
module Lich
  module Common
    module GUI
      module State
        # Loads saved entries from a specified data directory.
        # @param data_dir [String] The directory where the entry.dat file is located.
        # @param autosort_state [Boolean] Determines the sorting order of the entries.
        # @return [Array] The sorted array of entries or an empty array if loading fails.
        # @raise [StandardError] If there is an issue reading the file.
        # @example
        #   entries = Lich::Common::GUI::State.load_saved_entries("/path/to/data", true)
        def self.load_saved_entries(data_dir, autosort_state)
          if File.exist?(File.join(data_dir, "entry.dat"))
            File.open(File.join(data_dir, "entry.dat"), 'r') { |file|
              begin
                if autosort_state
                  # Sort in list by instance name, account name, and then character name
                  Marshal.load(file.read.unpack('m').first).sort do |a, b|
                    [a[:game_name], a[:user_id], a[:char_name]] <=> [b[:game_name], b[:user_id], b[:char_name]]
                  end
                else
                  # Sort in list by account name, and then character name (old Lich 4)
                  Marshal.load(file.read.unpack('m').first).sort do |a, b|
                    [a[:user_id].downcase, a[:char_name]] <=> [b[:user_id].downcase, b[:char_name]]
                  end
                end
              rescue
                Array.new
              end
            }
          else
            Lich.log "Info: No entry.dat file detected, probable new installation."
            Array.new
          end
        end

        # Saves the given entry data to the specified data directory.
        # @param data_dir [String] The directory where the entry.dat file will be saved.
        # @param entry_data [Array] The data to be saved as entries.
        # @return [Boolean] Returns true if the entries were saved successfully, false otherwise.
        # @raise [StandardError] If there is an issue writing to the file.
        # @example
        #   success = Lich::Common::GUI::State.save_entries("/path/to/data", entries)
        def self.save_entries(data_dir, entry_data)
          File.open(File.join(data_dir, "entry.dat"), 'w') { |file|
            file.write([Marshal.dump(entry_data)].pack('m'))
          }
          true
        rescue
          false
        end

        # Applies the theme settings based on the provided state.
        # @param theme_state [Boolean] Indicates whether to prefer a dark theme.
        # @return [void]
        # @example
        #   Lich::Common::GUI::State.apply_theme_settings(true)
        def self.apply_theme_settings(theme_state)
          Gtk::Settings.default.gtk_application_prefer_dark_theme = true if theme_state == true
        end
      end
    end
  end
end
