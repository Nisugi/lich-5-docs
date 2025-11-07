# Lich5 Carve out - GTK3 lich-login code stuff

module Lich
  # Provides common GUI functionality for Lich
  # @example Including the Common module
  #   class MyClass
  #     include Lich::Common
  #   end
  module Common
    # Initiates the GUI login process, handling user entry data and displaying the login window.
    # @return [void]
    # @raise [StandardError] Raises an error if the entry data cannot be loaded.
    # @example Starting the GUI login
    #   gui_login
    def gui_login
      @autosort_state = Lich.track_autosort_state
      @tab_layout_state = Lich.track_layout_state
      @theme_state = Lich.track_dark_mode

      @launch_data = nil
      # Checks if the entry data file exists and loads it if available.
      if File.exist?(File.join(DATA_DIR, "entry.dat"))
        # Opens the entry data file for reading.
        @entry_data = File.open(File.join(DATA_DIR, "entry.dat"), 'r') { |file|
          begin
            # Sorts the entry data based on the autosort state.
            if @autosort_state == true
              # Sort in list by instance name, account name, and then character name
              Marshal.load(file.read.unpack('m').first).sort do |a, b|
                [a[:game_name], a[:user_id], a[:char_name]] <=> [b[:game_name], b[:user_id], b[:char_name]]
              end
            # Sorts the entry data in the old Lich 4 format if autosort is disabled.
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
        @entry_data = Array.new
      end
      @save_entry_data = false

      # Queues the GUI setup to be executed in the GTK main loop.
      Gtk.queue {
        @window = nil
        install_tab_loaded = false

        # Creates a message dialog for displaying error messages.
        # @param msg [String] The message to display in the dialog.
        @msgbox = proc { |msg|
          dialog = Gtk::MessageDialog.new(:parent => @window, :flags => Gtk::DialogFlags::DESTROY_WITH_PARENT, :type => Gtk::MessageType::ERROR, :buttons => Gtk::ButtonsType::CLOSE, :message => msg)
          #			dialog.set_icon(default_icon)
          dialog.run
          dialog.destroy
        }
        # the following files are split out to ease interface design
        # they have to be included in the method's Gtk queue block to
        # be used, so they have to be called at this specific point.
        require_relative 'gui-saved-login'
        require_relative 'gui-manual-login'

        #
        # put it together and show the window
        #
        lightgrey = Gdk::RGBA::parse("#d3d3d3")
        @notebook = Gtk::Notebook.new
        @notebook.override_background_color(:normal, lightgrey) unless @theme_state == true
        @notebook.append_page(@quick_game_entry_tab, Gtk::Label.new('Saved Entry'))
        @notebook.append_page(@game_entry_tab, Gtk::Label.new('Manual Entry'))

        @notebook.signal_connect('switch-page') { |_who, _page, page_num|
          if (page_num == 2) and not install_tab_loaded
            refresh_button.clicked
          end
        }

        #    grey = Gdk::RGBA::parse("#d3d3d3")
        # Initializes a new GTK window for the login interface.
        @window = Gtk::Window.new
        @window.set_icon(@default_icon)
        # Sets the title of the login window to include the Lich version.
        @window.title = "Lich v#{LICH_VERSION}"
        @window.border_width = 5
        @window.add(@notebook)
        @window.signal_connect('delete_event') { @window.destroy; @done = true }
        @window.default_width = 590
        @window.default_height = 550
        @window.show_all

        @custom_launch_entry.visible = false
        @custom_launch_dir.visible = false
        @bonded_pair_char.visible = false
        @bonded_pair_inst.visible = false
        @slider_box.visible = false

        @notebook.set_page(1) if @entry_data.empty?
      }

      # Waits until the login process is completed.
      wait_until { @done }

      # Saves the entry data to the file if the save flag is set.
      if @save_entry_data
        File.open(File.join(DATA_DIR, "entry.dat"), 'w') { |file|
          file.write([Marshal.dump(@entry_data)].pack('m'))
        }
      end
      @entry_data = nil

      # Checks if no launch data was provided and quits the GTK main loop.
      unless !@launch_data.nil?
        Gtk.queue { Gtk.main_quit }
        Lich.log "info: exited without selection"
        exit
      end
    end
  end
end
