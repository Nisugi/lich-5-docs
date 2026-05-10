# frozen_string_literal: true

require_relative '../authentication/gui'

# Provides common GUI utilities for the Lich application
# This module contains methods for creating and managing UI elements.
module Lich
  module Common
    module GUI
      # Utility methods for managing login tab UI elements
      # This module provides methods to create CSS providers and handle UI interactions.
      module LoginTabUtils
        # Creates a CSS provider for buttons
        # @param font_size [Integer] The font size for the button
        # @return [Gtk::CssProvider] The CSS provider for the button
        # @example
        #   provider = LoginTabUtils.create_button_css_provider(font_size: 14)
        def self.create_button_css_provider(font_size: 12)
          css = Gtk::CssProvider.new
          css.load_from_data("button {border-radius: 5px; font-size: #{font_size}px;}")
          css
        end

        # Creates a compact CSS provider for buttons
        # @param font_size [Integer] The font size for the button
        # @return [Gtk::CssProvider] The compact CSS provider for the button
        # @example
        #   provider = LoginTabUtils.create_compact_button_css_provider(font_size: 10)
        def self.create_compact_button_css_provider(font_size: 11)
          css = Gtk::CssProvider.new
          css.load_from_data("button {border-radius: 3px; font-size: #{font_size}px; padding: 2px 6px; min-height: 0; min-width: 0;}")
          css
        end

        # Creates a CSS provider for toggle buttons
        # @return [Gtk::CssProvider] The CSS provider for the toggle button
        # @example
        #   provider = LoginTabUtils.create_toggle_button_css_provider
        def self.create_toggle_button_css_provider
          css = Gtk::CssProvider.new
          css.load_from_data("togglebutton {border-radius: 5px; font-size: 12px;}")
          css
        end

        # Applies the selected theme to UI elements
        # @param theme_state [Boolean] Indicates if the dark theme is enabled
        # @param ui_elements [Hash] A hash of UI elements to apply the theme to
        # @param providers [Hash] A hash of CSS providers for the UI elements
        # @return [void]
        # @example
        #   LoginTabUtils.apply_theme_to_ui_elements(true, ui_elements, providers)
        def self.apply_theme_to_ui_elements(theme_state, ui_elements, providers)
          if theme_state
            # Enable dark theme
            Gtk::Settings.default.gtk_application_prefer_dark_theme = true
            # Remove styling providers that might conflict with dark theme
            ui_elements[:play_button]&.style_context&.remove_provider(providers[:button]) if providers[:button] && ui_elements[:play_button]
            ui_elements[:account_book]&.style_context&.remove_provider(providers[:tab]) if providers[:tab] && ui_elements[:account_book]
            # Reset background colors to transparent for dark theme
            ui_elements[:account_book]&.override_background_color(:normal, ThemeUtils.darkmode_background) if ui_elements[:account_book]
            ui_elements[:notebook]&.override_background_color(:normal, ThemeUtils.darkmode_background) if ui_elements[:notebook]
          else
            # Disable dark theme
            Gtk::Settings.default.gtk_application_prefer_dark_theme = false
            # Set light grey background for light theme
            ui_elements[:account_book]&.override_background_color(:normal, ThemeUtils.light_theme_background) if ui_elements[:account_book]
            ui_elements[:notebook]&.override_background_color(:normal, ThemeUtils.light_theme_background) if ui_elements[:notebook]
            # Re-apply styling providers for light theme
            if providers[:button] && ui_elements[:play_button]
              ui_elements[:play_button].style_context.add_provider(providers[:button], Gtk::StyleProvider::PRIORITY_USER)
            end
            if providers[:tab] && ui_elements[:account_book]
              ui_elements[:account_book].style_context.add_provider(providers[:tab], Gtk::StyleProvider::PRIORITY_USER)
            end
          end
        end

        # Sets up the handler for the play button
        # @param button [Gtk::Button] The play button to set up
        # @param login_info [Hash] The login information for authentication
        # @param callback [Proc] The callback to execute on successful authentication
        # @return [void]
        # @example
        #   LoginTabUtils.setup_play_button_handler(play_button, login_info, -> { puts "Authenticated!" })
        def self.setup_play_button_handler(button, login_info, callback)
          button.signal_connect('button-release-event') { |_owner, ev|
            if ev.event_type == Gdk::EventType::BUTTON_RELEASE && ev.button == 1
              Lich::Common::Authentication::GUI.authenticate_and_launch(
                button: button,
                login_info: login_info,
                on_success: callback
              )
            elsif ev.button == 3
              pp "I would be adding to a team tab"
            end
          }
        end

        # Sets up the handler for the remove button
        # @param button [Gtk::Button] The remove button to set up
        # @param login_info [Hash] The login information for the character
        # @param char_box [Gtk::Box] The character box to hide
        # @param default_icon [Gtk::Icon] The default icon for the dialog
        # @param callback [Proc] The callback to execute on removal
        # @return [void]
        # @example
        #   LoginTabUtils.setup_remove_button_handler(remove_button, login_info, char_box, default_icon, -> { puts "Removed!" })
        def self.setup_remove_button_handler(button, login_info, char_box, default_icon, callback)
          button.signal_connect('button-release-event') { |_owner, ev|
            if (ev.event_type == Gdk::EventType::BUTTON_RELEASE) and (ev.button == 1)
              if (ev.state & Gdk::ModifierType::SHIFT_MASK) != 0
                # Call the remove callback if provided
                callback.call(login_info) if callback
                char_box.visible = false
              else
                dialog = Gtk::MessageDialog.new(
                  parent: nil,
                  flags: :modal,
                  type: :question,
                  buttons: :yes_no,
                  message: "Delete record?"
                )
                dialog.title = "Confirm"
                dialog.set_icon(default_icon) if default_icon
                response = dialog.run
                dialog.destroy
                if response == Gtk::ResponseType::YES
                  # Call the remove callback if provided
                  callback.call(login_info) if callback
                  char_box.visible = false
                end
              end
            end
          }
        end

        # Creates global settings components for the UI
        # @param parent_container [Gtk::Container] The parent container to add components to
        # @param theme_state [Boolean] The current theme state
        # @param tab_layout_state [Boolean] The current tab layout state
        # @param autosort_state [Boolean] The current autosort state
        # @param persistent_launcher_state [Boolean] The current persistent launcher state
        # @param callbacks [Hash] A hash of callback functions for state changes
        # @return [Hash] A hash containing created UI components
        # @example
        #   components = LoginTabUtils.create_global_settings_components(parent_container, true, false, true, false, callbacks)
        def self.create_global_settings_components(parent_container, theme_state, tab_layout_state, autosort_state, persistent_launcher_state, callbacks)
          # Create toggle button styling
          togglebutton_provider = create_toggle_button_css_provider

          # Global settings components
          slider_box = Gtk::Box.new(:horizontal, 5)
          theme_select = Gtk::Switch.new
          tab_select = Gtk::Switch.new
          sort_select = Gtk::Switch.new
          persistent_launcher_select = Gtk::Switch.new
          theme_select_label = Gtk::Label.new('Dark Theme')
          tab_select_label = Gtk::Label.new('Tab Layout')
          sort_select_label = Gtk::Label.new('AutoSort')
          persistent_launcher_label = Gtk::Label.new('Multi-Launch')
          theme_select.set_active(true) if theme_state == true
          tab_select.set_active(true) if tab_layout_state == true
          sort_select.set_active(true) if autosort_state == true
          # Keep the helper pure/testable by taking this state as input.
          persistent_launcher_select.set_active(true) if persistent_launcher_state == true

          # Add switches to slider box
          # slider_box = Gtk::Box.new(:vertical, 5)

          row1 = Gtk::Box.new(:horizontal, 10)
          row1.pack_start(theme_select, expand: false, fill: false, padding: 0)
          row1.pack_start(theme_select_label, expand: false, fill: false, padding: 0)
          row1.pack_start(tab_select, expand: false, fill: false, padding: 0)
          row1.pack_start(tab_select_label, expand: false, fill: false, padding: 0)

          # row2 = Gtk::Box.new(:horizontal, 10)
          row1.pack_start(sort_select, expand: false, fill: false, padding: 0)
          row1.pack_start(sort_select_label, expand: false, fill: false, padding: 0)
          row1.pack_start(persistent_launcher_select, expand: false, fill: false, padding: 0)
          row1.pack_start(persistent_launcher_label, expand: false, fill: false, padding: 0)

          slider_box.pack_start(row1, expand: false, fill: false, padding: 0)
          # slider_box.pack_start(row2, expand: false, fill: false, padding: 0)

          # Settings toggle button
          settings_option = Gtk::ToggleButton.new(label: 'GUI Settings')
          settings_option.style_context.add_provider(togglebutton_provider, Gtk::StyleProvider::PRIORITY_USER)
          parent_container.pack_start(settings_option, expand: false, fill: false, padding: 5)
          parent_container.pack_start(slider_box, expand: false, fill: false, padding: 5)

          # Settings toggle handler
          settings_option.signal_connect('toggled') {
            slider_box.visible = settings_option.active?
          }

          # Theme switch handler
          theme_select.signal_connect('notify::active') { |_s|
            if theme_select.active?
              # Update state tracking variable
              Lich.track_dark_mode = true

              # Call the theme change callback if provided
              callbacks[:on_theme_change]&.call(true)
            else
              # Update state tracking variable
              Lich.track_dark_mode = false

              # Call the theme change callback if provided
              callbacks[:on_theme_change]&.call(false)
            end
          }

          # Tab layout switch handler
          tab_select.signal_connect('state-set') { |_widget, state|
            Lich.track_layout_state = state
            callbacks[:on_layout_change]&.call(state)
            false
          }

          # Auto sort switch handler
          sort_select.signal_connect('state-set') { |_widget, state|
            Lich.track_autosort_state = state
            callbacks[:on_sort_change]&.call(state)
            false
          }

          # Persistent launcher switch handler
          persistent_launcher_select.signal_connect('state-set') { |_widget, state|
            Lich.track_persistent_launcher_mode = state
            callbacks[:on_persistent_launcher_change]&.call(state)
            false
          }

          # Initially hide the slider box
          slider_box.visible = false

          # Return created elements
          {
            slider_box: slider_box,
            settings_option: settings_option,
            theme_select: theme_select,
            tab_select: tab_select,
            sort_select: sort_select,
            persistent_launcher_select: persistent_launcher_select
          }
        end

        # Creates a custom launch entry for commands
        # @return [Gtk::ComboBoxText] The custom launch entry component
        # @example
        #   entry = LoginTabUtils.create_custom_launch_entry
        def self.create_custom_launch_entry
          custom_launch_entry = Gtk::ComboBoxText.new(entry: true)
          custom_launch_entry.child.set_placeholder_text("(enter custom launch command)")
          custom_launch_entry.append_text("Wizard.Exe /GGS /H127.0.0.1 /P%port% /K%key%")
          custom_launch_entry.append_text("Stormfront.exe /GGS /Hlocalhost /P%port% /K%key%")
          custom_launch_entry.append_text("/Applications/Warlock.app/Contents/MacOS/Warlock --host localhost --port %port% --key %key%") if OS.mac?
          custom_launch_entry.append_text("warlock --host localhost --port %port% --key %key%") if OS.windows?
          custom_launch_entry.append_text("/usr/bin/warlock --host localhost --port %port% --key %key%") if OS.linux?
          custom_launch_entry
        end

        # Creates a custom launch directory entry
        # @return [Gtk::ComboBoxText] The custom launch directory component
        # @example
        #   dir = LoginTabUtils.create_custom_launch_dir
        def self.create_custom_launch_dir
          custom_launch_dir = Gtk::ComboBoxText.new(entry: true)
          custom_launch_dir.child.set_placeholder_text("(enter working directory for command)")
          custom_launch_dir.append_text("../wizard")
          custom_launch_dir.append_text("../StormFront")
          custom_launch_dir
        end
      end
    end
  end
end
