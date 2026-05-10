# frozen_string_literal: true

require_relative 'gui/accessibility'
require_relative 'gui/account_manager'
require_relative 'gui/account_manager_ui'
require_relative 'authentication/authenticator'
require_relative 'authentication/entry_store'
require_relative 'authentication/gui'
require_relative 'session_launcher'
require_relative 'gui/components'
require_relative 'gui/conversion_ui'
require_relative 'gui/favorites_manager'
require_relative 'gui/game_selection'
require_relative 'gui/login_tab_utils'
require_relative 'gui/manual_login_tab'
require_relative 'gui/parameter_objects'
require_relative 'gui/password_change'
require_relative 'gui/saved_login_tab'
require_relative 'gui/state'
require_relative 'gui/theme_utils'
require_relative 'gui/utilities'
require_relative 'gui/tab_communicator'
require_relative 'gui/window_settings'

module Lich
  # Provides common GUI functionality for the Lich application.
  #
  # @see Lich::Common::GUI for GUI-related utilities.
  module Common
    # Initializes the GUI login process.
    #
    # This method sets up the login state, configures the GUI window,
    # and handles the entry data as needed.
    # @return [Hash, nil] launch data if successful, otherwise nil.
    def gui_login
      initialize_login_state
      setup_gui_window

      wait_until { @done }

      save_entry_data_if_needed

      return_launch_data_or_exit
    end

    private

    # Initializes the state required for the login GUI.
    #
    # This method sets up various states including autosort, theme,
    # and initializes the accessibility support.
    # @api private
    # @return [void]
    def initialize_login_state
      @autosort_state = Lich.track_autosort_state
      @tab_layout_state = Lich.track_layout_state
      @theme_state = Lich.track_dark_mode
      @persistent_launcher_mode = Lich.track_persistent_launcher_mode

      # Initialize accessibility support
      Lich::Common::GUI::Accessibility.initialize_accessibility if defined?(Lich::Common::GUI::Accessibility)

      # Use EntryStore instead of State for loading saved entries
      @entry_data = Lich::Common::Authentication::EntryStore.load_saved_entries(DATA_DIR, @autosort_state)
      @launch_data = nil
      @save_entry_data = false
      @done = false

      # Initialize cross-tab communication
      @tab_communicator = Lich::Common::GUI::TabCommunicator.new

      # Initialize account manager UI
      @account_manager_ui = Lich::Common::GUI::AccountManagerUI.new(DATA_DIR)
    end

    # Refreshes the GUI window after a conversion process.
    #
    # This method reloads entry data, updates UI elements,
    # and ensures the window is displayed correctly.
    # @return [void]
    def refresh_window_after_conversion
      begin
        # Reload entry data from newly created YAML file
        @entry_data = Lich::Common::Authentication::EntryStore.load_saved_entries(DATA_DIR, @autosort_state)

        # Enable favorites in saved login tab if YAML file now exists
        if @saved_login_tab
          # Force enable favorites since YAML file now exists
          @saved_login_tab.favorites_enabled = true
          @saved_login_tab.refresh_data
        end

        # Refresh manual login tab if it needs entry data updates
        if @manual_login_tab && @manual_login_tab.respond_to?(:refresh_data)
          @manual_login_tab.refresh_data
        end

        # Update entry data reference for manual login tab
        if @manual_login_tab && @manual_login_tab.respond_to?(:update_entry_data)
          @manual_login_tab.update_entry_data(@entry_data)
        end

        # Trigger account management refresh by programmatically clicking refresh button
        trigger_account_management_refresh

        # Update UI elements visibility based on new data
        update_ui_elements_after_conversion

        # Ensure window is visible and properly displayed
        if @window
          @window.show_all
          @window.present # Bring window to front
        end

        # Hide optional elements after show_all to ensure proper visibility state
        hide_optional_elements

        # Switch to saved entry tab if we now have data
        if @notebook && !@entry_data.empty?
          @notebook.set_page(0) # Switch to Saved Entry tab
        end

        # Notify via tab communicator that conversion refresh occurred
        yaml_file = Lich::Common::Authentication::EntryStore.yaml_file_path(DATA_DIR)
        encryption_mode = nil
        if File.exist?(yaml_file)
          yaml_data = YAML.load_file(yaml_file)
          encryption_mode = yaml_data['encryption_mode']
        end

        @tab_communicator.notify_data_changed(:conversion_complete, {
          entries_count: @entry_data.length,
          encryption_mode: encryption_mode
        })

        Lich.log "info: Window refreshed after conversion with #{@entry_data.length} entries"
      rescue StandardError => e
        Lich.log "error: Error refreshing window after conversion: #{e.message}"

        # Fallback to showing error message
        if @msgbox
          @msgbox.call("Conversion completed but failed to refresh window: #{e.message}")
        end
      end
    end

    # Triggers a refresh of the account management tab.
    #
    # This method programmatically clicks the refresh button in the
    # account management tab to update its data.
    # @return [void]
    def trigger_account_management_refresh
      return unless @account_mgmt_tab

      begin
        # Find the refresh button in the account management tab
        refresh_button = find_refresh_button_in_container(@account_mgmt_tab)

        if refresh_button
          # Programmatically click the refresh button
          refresh_button.clicked
          Lich.log "info: Account management refresh triggered successfully"
        else
          Lich.log "warning: Could not find refresh button in account management tab"
        end
      rescue StandardError => e
        Lich.log "error: Error triggering account management refresh: #{e.message}"
      end
    end

    # Finds the refresh button within a given container.
    #
    # This method searches through the container's children to locate
    # a button labeled "Refresh".
    # @param container [Gtk::Container] the container to search within
    # @return [Gtk::Button, nil] the refresh button if found, otherwise nil.
    def find_refresh_button_in_container(container)
      return nil unless container.respond_to?(:each)

      container.each do |child|
        # Check if this child is a refresh button
        if child.is_a?(Gtk::Button) && child.label == "Refresh"
          return child
        end

        # Recursively search in child containers
        if child.respond_to?(:each)
          result = find_refresh_button_in_container(child)
          return result if result
        end
      end

      nil
    end

    # Updates the visibility of UI elements after conversion.
    #
    # This method shows or hides optional elements based on the
    # availability of entry data.
    # @return [void]
    def update_ui_elements_after_conversion
      return unless @entry_data

      # Show/hide optional elements based on data availability
      if @entry_data.empty?
        # No data - keep elements hidden and show manual entry tab
        hide_optional_elements
      else
        # Data available - elements should still be hidden initially
        # Optional elements visibility is managed by individual tabs
        # but we ensure they start in the correct hidden state
      end
    end

    # Sets up the main GUI window for the application.
    #
    # This method creates the window, initializes tabs, and configures
    # properties such as theme and accessibility.
    # @return [void]
    def setup_gui_window
      Gtk.queue {
        @window = nil

        # Create message dialog utility
        @msgbox = Lich::Common::GUI::Utilities.create_message_dialog(parent: @window, icon: @default_icon)

        # Create tab instances
        create_tab_instances

        # Set up cross-tab communication
        setup_cross_tab_communication

        # Set up notebook with tabs
        setup_notebook

        # Configure window properties
        configure_window

        # Hide optional elements initially
        hide_optional_elements
      }
    end

    # Sets up communication between different tabs in the GUI.
    #
    # This method registers callbacks for data changes and ensures
    # synchronization between tabs.
    # @return [void]
    def setup_cross_tab_communication
      # Register saved login tab for data change notifications
      @tab_communicator.register_data_change_callback(->(change_type, data) {
        # Refresh main GUI entry data cache to prevent stale data issues
        @entry_data = Lich::Common::Authentication::EntryStore.load_saved_entries(DATA_DIR, @autosort_state)

        # Refresh saved login tab for all data changes to ensure synchronization
        @saved_login_tab.refresh_data if @saved_login_tab

        # Refresh manual login tab cache when accounts are removed to prevent stale data
        if @manual_login_tab && (change_type == :account_removed || change_type == :character_removed)
          @manual_login_tab.refresh_entry_data
        end

        # Sanitize data before logging to prevent password exposure
        sanitized_data = data.dup
        if sanitized_data[:entry].is_a?(Hash)
          sanitized_data[:entry] = sanitized_data[:entry].dup
          sanitized_data[:entry].delete(:password)
        end
        Lich.log "info: Data change notification (cache and UI refreshed): #{change_type} - #{sanitized_data}"
      })

      # Set up account manager to notify of data changes
      @account_manager_ui.set_data_change_callback(->(change_type, data) {
        @tab_communicator.notify_data_changed(change_type, data)
      })

      # Register account manager to receive data change notifications
      @account_manager_ui.register_for_notifications(@tab_communicator)
    end

    # Creates instances of the various tabs used in the GUI.
    #
    # This method initializes the saved login and manual login tabs,
    # along with their respective callbacks.
    # @return [void]
    def create_tab_instances
      # Create callbacks for saved login tab
      saved_login_callbacks = {
        on_play: ->(launch_data, login_context = nil) {
          handle_play_action(launch_data, login_context)
        },
        on_remove: ->(login_info) {
          # Use AccountManager to remove character directly from YAML to preserve encryption
          # This ensures encrypted passwords are not overwritten with plaintext
          if GUI::AccountManager.remove_character(
            DATA_DIR,
            login_info[:user_id],
            login_info[:char_name],
            login_info[:game_code],
            login_info[:frontend]
          )
            # Reload entry_data from updated YAML to stay in sync
            begin
              new_entry_data = Authentication::EntryStore.load_saved_entries(DATA_DIR, @autosort_state)
              @entry_data = new_entry_data

              # Create sanitized entry for notification (without password)
              sanitized_entry = login_info.dup
              sanitized_entry.delete(:password)
              @tab_communicator.notify_data_changed(:character_removed, { entry: sanitized_entry })
            rescue StandardError => e
              Lich.log "error: Failed to reload entries after character removal: #{e.message}"
              # Notification not sent - UI may show stale data, user must refresh manually
            end
          else
            Lich.log "warning: Could not remove character: #{login_info}"
          end
        },
        on_add_character: ->(character:, instance:, frontend:) {
          # Handle adding a character
        },
        on_theme_change: ->(state) {
          # Update theme state for all components
          @theme_state = state
          @manual_login_tab.update_theme_state(state)
          @saved_login_tab.update_theme_state(state)

          # Apply theme to notebook and window
          if state
            @notebook.override_background_color(:normal, GUI::ThemeUtils.darkmode_background)
            @window.override_background_color(:normal, GUI::ThemeUtils.darkmode_background)
          else
            @notebook.override_background_color(:normal, GUI::ThemeUtils.light_theme_background)
            @window.override_background_color(:normal, GUI::ThemeUtils.light_theme_background)
            # Apply button style for light mode
            apply_button_style_for_light_mode
          end
        },
        on_layout_change: ->(state) {
          # Handle layout change
        },
        on_sort_change: ->(state) {
          # Handle sort change
        },
        on_persistent_launcher_change: ->(state) {
          @persistent_launcher_mode = state
        },
        on_favorites_change: ->(username:, char_name:, game_code:, is_favorite:) {
          # Handle favorite status change - notify other tabs
          @tab_communicator.notify_data_changed(:favorite_toggled, {
            account: username,
            character: char_name,
            game_code: game_code,
            is_favorite: is_favorite
          })
        }
      }

      # Create callbacks for manual login tab
      manual_login_callbacks = {
        on_play: ->(launch_data, login_context = nil) {
          handle_play_action(launch_data, login_context)
        },
        on_save: ->(launch_data) {
          # Only refresh cache if we don't already have the latest data
          # This prevents redundant file I/O operations
          @entry_data = Lich::Common::Authentication::EntryStore.load_saved_entries(DATA_DIR, @autosort_state)
          # commenting out to assess impact, remove when cleared
          # @save_entry_data = true

          # Notify other tabs of data change
          @tab_communicator.notify_data_changed(:entry_added, { entry: launch_data })
        },
        on_error: ->(message) {
          @msgbox.call(message)
        }
      }

      # Create tab instances with favorites support
      @saved_login_tab = Lich::Common::GUI::SavedLoginTab.new(
        @window,
        @entry_data,
        @theme_state,
        @tab_layout_state,
        @autosort_state,
        @default_icon,
        DATA_DIR,
        saved_login_callbacks
      )

      @manual_login_tab = Lich::Common::GUI::ManualLoginTab.new(
        @window,
        @entry_data,
        @theme_state,
        @default_icon,
        DATA_DIR,
        manual_login_callbacks,
        @autosort_state
      )

      # Get UI elements from tabs
      @saved_login_ui = @saved_login_tab.ui_elements
      @manual_login_ui = @manual_login_tab.ui_elements

      # Set references to UI elements
      @quick_game_entry_tab = @saved_login_tab.tab_widget
      @game_entry_tab = @manual_login_tab.tab_widget
      @custom_launch_entry = @manual_login_ui[:custom_launch_entry]
      @custom_launch_dir = @manual_login_ui[:custom_launch_dir]
      @bonded_pair_char = @saved_login_ui[:bonded_pair_char]
      @bonded_pair_inst = @saved_login_ui[:bonded_pair_inst]
      @slider_box = @saved_login_ui[:slider_box]
    end

    # Configures the notebook widget that holds the tabs.
    #
    # This method sets up the initial theme, adds tabs for saved
    # and manual entries, and configures the account management tab.
    # @return [void]
    def setup_notebook
      @notebook = Gtk::Notebook.new

      # Apply initial theme
      if @theme_state
        @notebook.override_background_color(:normal, GUI::ThemeUtils.darkmode_background)
      else
        @notebook.override_background_color(:normal, GUI::ThemeUtils.light_theme_background)
        # Apply button style for light mode
        apply_button_style_for_light_mode
      end

      # Add the saved entry and manual entry tabs
      @notebook.append_page(@quick_game_entry_tab, Gtk::Label.new('Saved Entry'))
      @notebook.append_page(@game_entry_tab, Gtk::Label.new('Manual Entry'))

      # Create account management tab using AccountManagerUI
      account_notebook = Gtk::Notebook.new
      @account_mgmt_tab = Gtk::Box.new(:vertical, 10)
      @account_mgmt_tab.border_width = 10

      # Delegate account management tab creation to AccountManagerUI
      @account_manager_ui.create_accounts_tab(account_notebook)
      @account_manager_ui.create_add_character_tab(account_notebook)
      @account_manager_ui.create_add_account_tab(account_notebook)
      @account_manager_ui.create_encryption_management_tab(account_notebook)

      @account_manager_ui.register_notification_callback

      # Add the notebook to the box
      @account_mgmt_tab.pack_start(account_notebook, expand: true, fill: true, padding: 0)

      # Add the account management tab to the main notebook
      @notebook.append_page(@account_mgmt_tab, Gtk::Label.new('Account Management'))

      # Set tab position
      @notebook.set_tab_pos(:top)

      # Add keyboard navigation support for accessibility
      if defined?(Lich::Common::GUI::Accessibility)
        Lich::Common::GUI::Accessibility.add_keyboard_navigation(@notebook)
      end
    end

    # Configures the main application window properties.
    #
    # This method sets the window title, icon, and applies saved
    # settings. It also handles the window's close event.
    # @return [void]
    def configure_window
      @window = Gtk::Window.new(:toplevel)
      @window.set_icon(@default_icon)
      @window.title = "Lich v#{LICH_VERSION}"
      @window.border_width = 5
      @window.add(@notebook)

      # Load and apply saved window settings
      window_settings = Lich::Common::GUI::WindowSettings.load(DATA_DIR)
      Lich::Common::GUI::WindowSettings.apply_to_window(@window, window_settings)

      @window.signal_connect('delete_event') {
        # Save window geometry before destruction
        save_window_geometry

        # Clean up cross-tab communication
        @tab_communicator.clear_callbacks if @tab_communicator
        @window.destroy unless @window.destroyed?
        @done = true
      }

      # Apply initial theme to window
      if @theme_state
        @window.override_background_color(:normal, GUI::ThemeUtils.darkmode_background)
      else
        @window.override_background_color(:normal, GUI::ThemeUtils.light_theme_background)
        # Apply button style for light mode
        apply_button_style_for_light_mode
      end

      # Add accessibility support for the window
      if defined?(Lich::Common::GUI::Accessibility)
        Lich::Common::GUI::Accessibility.make_window_accessible(
          @window,
          "Lich Login",
          "Login window for Lich"
        )
      end

      unless Lich::Common::GUI::ConversionUI.conversion_needed?(DATA_DIR)
        @window.show_all
      else
        # YAML file conversion required
        # Show conversion dialog with targeted refresh callback
        Lich::Common::GUI::ConversionUI.show_conversion_dialog(@window, DATA_DIR, -> {
          # After conversion, refresh existing window instead of creating new one
          refresh_window_after_conversion
        })
      end
    end

    # Saves the current geometry of the window.
    #
    # This method captures the window's size and position and
    # stores it for future use.
    # @return [void]
    def save_window_geometry
      geometry = Lich::Common::GUI::WindowSettings.capture_geometry(@window)
      Lich::Common::GUI::WindowSettings.save(
        DATA_DIR,
        width: geometry[:width],
        height: geometry[:height],
        position: geometry[:position]
      )
    end

    # Applies a light mode style to buttons in the GUI.
    #
    # This method modifies the background color of buttons to
    # suit the light theme.
    # @return [void]
    def apply_button_style_for_light_mode
      # Use a slightly whiter shade for buttons in light mode
      whitergrey = Gdk::RGBA::parse("#f0f0f0")

      # Apply to all buttons in saved login tab
      apply_style_to_buttons(@saved_login_ui, whitergrey)

      # Apply to all buttons in manual login tab
      apply_style_to_buttons(@manual_login_ui, whitergrey)
    end

    def apply_style_to_buttons(ui_elements, color)
      ui_elements.each do |_key, element|
        if element.is_a?(Gtk::Button)
          element.override_background_color(:normal, color)
        end
      end
    end

    # Hides optional UI elements based on the current state.
    #
    # This method ensures that elements are only shown when
    # necessary, particularly when there is no entry data.
    # @return [void]
    def hide_optional_elements
      @custom_launch_entry.visible = false
      @custom_launch_dir.visible = false
      @bonded_pair_char.visible = false
      @bonded_pair_inst.visible = false
      @slider_box.visible = false

      @notebook.set_page(1) if @entry_data.empty?
    end

    # Handles the action of playing a game based on login data.
    #
    # This method launches a session using the provided launch data
    # and manages the window state accordingly.
    # @param launch_data [Hash] data required to launch the game
    # @param login_context [Hash, nil] context for the login session
    # @return [void]
    def handle_play_action(launch_data, login_context = nil)
      if use_persistent_launcher?(login_context)
        # Persistent mode: launch child session, keep the launcher window active.
        if login_context.is_a?(Hash) && !login_context.key?(:dark_mode)
          # Propagate the current launcher theme state into detached child startup.
          login_context = login_context.merge(dark_mode: Lich.track_dark_mode)
        end

        launch_result = if login_context.nil?
                          Lich::Common::SessionLauncher.launch(launch_data)
                        else
                          Lich::Common::SessionLauncher.launch(launch_data, launch_context: login_context)
                        end
        unless launch_result[:ok]
          @msgbox.call("Failed to launch session: #{launch_result[:error]}") if @msgbox
        end
      else
        # Default/single-launch path: used when persistent mode is disabled OR
        # when launch originates from manual login.
        @launch_data = launch_data
        Gtk.queue {
          @window.destroy unless @window.destroyed?
          @done = true
        }
      end
    end

    # Determines if the persistent launcher mode should be used.
    #
    # This method checks the current state and context to decide
    # whether to use the persistent launcher for the session.
    # @param login_context [Hash] context for the login session
    # @return [Boolean] true if persistent launcher mode is active, otherwise false.
    def use_persistent_launcher?(login_context)
      return false unless @persistent_launcher_mode
      return true unless login_context.is_a?(Hash)

      saved_entry_context?(login_context)
    end

    # Checks if the provided context is for a saved entry.
    #
    # This method verifies if the login context contains the necessary
    # keys to identify it as a saved entry.
    # @param login_context [Hash] context for the login session
    # @return [Boolean] true if the context is for a saved entry, otherwise false.
    def saved_entry_context?(login_context)
      login_context.key?(:user_id) && login_context.key?(:password)
    end

    # Saves entry data if the flag is set.
    #
    # This method performs the save operation to persist entry data
    # when required, avoiding redundant operations.
    # @return [void]
    def save_entry_data_if_needed
      if @save_entry_data
        # Save entry data - optimized to avoid redundant cache refresh
        Lich::Common::Authentication::EntryStore.save_entries(DATA_DIR, @entry_data)
        @save_entry_data = false
      end
    end

    # Returns the launch data or exits the application.
    #
    # This method checks if launch data is available and either
    # returns it or quits the application if not.
    # @return [Hash, nil] launch data if available, otherwise nil.
    def return_launch_data_or_exit
      if @launch_data.nil?
        Gtk.queue { Gtk.main_quit }
        exit
      end

      @launch_data
    end
  end
end
