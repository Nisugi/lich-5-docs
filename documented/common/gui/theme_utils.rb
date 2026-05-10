
module Lich
  module Common
    module GUI
      module ThemeUtils
        # Applies the specified theme settings to the application.
        #
        # @param theme_state [Boolean] true for dark theme, false for light theme.
        # @return [void]
        def self.apply_theme_settings(theme_state)
          Gtk::Settings.default.gtk_application_prefer_dark_theme = theme_state
        end

        # Returns the background color for the light theme.
        # @return [Gdk::RGBA] the light theme background color.
        def self.light_theme_background
          Gdk::RGBA::parse("#d3d3d3")
        end

        # Returns the button color for the light theme.
        # @return [Gdk::RGBA] the light theme button color.
        def self.light_theme_button
          Gdk::RGBA::parse("#f0f0f0")
        end

        # Returns the background color for the dark theme.
        # @return [Gdk::RGBA] the dark theme background color.
        def self.darkmode_background
          Gdk::RGBA::parse("rgba(40,40,40,1)")
        end

        # Applies the specified theme to the given window.
        #
        # @param window [Gtk::Window] the window to apply the theme to.
        # @param theme_state [Boolean] true for dark theme, false for light theme.
        # @return [void]
        def self.apply_theme_to_window(window, theme_state)
          if theme_state
            window.override_background_color(:normal, darkmode_background)
          else
            window.override_background_color(:normal, light_theme_background)
          end
        end

        # Applies the specified theme to the given notebook.
        #
        # @param notebook [Gtk::Notebook] the notebook to apply the theme to.
        # @param theme_state [Boolean] true for dark theme, false for light theme.
        # @return [void]
        def self.apply_theme_to_notebook(notebook, theme_state)
          if theme_state
            notebook.override_background_color(:normal, darkmode_background)
          else
            notebook.override_background_color(:normal, light_theme_background)
          end
        end

        # Applies the specified color style to the buttons in the UI elements.
        #
        # @param ui_elements [Hash] a hash of UI elements to style.
        # @param color [Gdk::RGBA] the color to apply to the buttons.
        # @return [void]
        def self.apply_style_to_buttons(ui_elements, color)
          ui_elements.each do |_key, element|
            if element.is_a?(Gtk::Button)
              element.override_background_color(:normal, color)
            end
          end
        end

        # Creates CSS for favorite items based on the theme state.
        #
        # @param theme_state [Boolean] true for dark theme, false for light theme.
        # @return [String] the generated CSS string.
        def self.create_favorites_css(theme_state)
          if theme_state
            # Dark theme favorites styling
            <<~CSS
              .favorite-character {
                background: linear-gradient(135deg, #2d3748 0%, #4a5568 100%);
                border: 2px solid #ffd700;
                border-radius: 4px;
                box-shadow: 0 2px 4px rgba(255, 215, 0, 0.3);
              }

              .favorite-character:hover {
                background: linear-gradient(135deg, #4a5568 0%, #2d3748 100%);
                border-color: #ffed4e;
                box-shadow: 0 4px 8px rgba(255, 215, 0, 0.4);
              }

              .favorite-button {
                color: #ffd700;
                font-weight: bold;
                font-size: 16px;
              }

              .favorite-button:hover {
                color: #ffed4e;
                background: rgba(255, 215, 0, 0.1);
              }
            CSS
          else
            # Light theme favorites styling
            <<~CSS
              .favorite-character {
                background: linear-gradient(135deg, #fff8dc 0%, #f0f8ff 100%);
                border: 2px solid #daa520;
                border-radius: 4px;
                box-shadow: 0 2px 4px rgba(218, 165, 32, 0.3);
              }

              .favorite-character:hover {
                background: linear-gradient(135deg, #f0f8ff 0%, #fff8dc 100%);
                border-color: #b8860b;
                box-shadow: 0 4px 8px rgba(218, 165, 32, 0.4);
              }

              .favorite-button {
                color: #b8860b;
                font-weight: bold;
                font-size: 16px;
              }

              .favorite-button:hover {
                color: #daa520;
                background: rgba(218, 165, 32, 0.1);
              }
            CSS
          end
        end

        # Creates a CSS provider for the favorites styling based on the theme state.
        #
        # @param theme_state [Boolean] true for dark theme, false for light theme.
        # @return [Gtk::CssProvider] the CSS provider for the favorites.
        def self.create_favorites_css_provider(theme_state)
          provider = Gtk::CssProvider.new
          css_data = create_favorites_css(theme_state)

          begin
            provider.load_from_data(css_data)
          rescue StandardError => e
            Lich.log "error: Error loading favorites CSS: #{e.message}"
          end

          provider
        end

        # Applies the favorites styling to the specified widget.
        #
        # @param widget [Gtk::Widget] the widget to apply styling to.
        # @param theme_state [Boolean] true for dark theme, false for light theme.
        # @param is_favorite [Boolean] indicates if the widget is a favorite.
        # @return [void]
        def self.apply_favorites_styling(widget, theme_state, is_favorite = false)
          provider = create_favorites_css_provider(theme_state)
          widget.style_context.add_provider(provider, Gtk::StyleProvider::PRIORITY_USER)

          if is_favorite
            widget.style_context.add_class('favorite-character')
          end
        end

        # Returns the color for the favorite indicator based on the theme state.
        #
        # @param theme_state [Boolean] true for dark theme, false for light theme.
        # @return [Gdk::RGBA] the color for the favorite indicator.
        def self.favorite_indicator_color(theme_state)
          if theme_state
            Gdk::RGBA::parse("#ffd700")  # Gold for dark theme
          else
            Gdk::RGBA::parse("#b8860b")  # Dark goldenrod for light theme
          end
        end

        # Returns the background color for the favorite button based on the theme state.
        #
        # @param theme_state [Boolean] true for dark theme, false for light theme.
        # @return [Gdk::RGBA] the background color for the favorite button.
        def self.favorite_button_background(theme_state)
          if theme_state
            Gdk::RGBA::parse("rgba(255, 215, 0, 0.1)") # Transparent gold
          else
            Gdk::RGBA::parse("rgba(218, 165, 32, 0.1)") # Transparent goldenrod
          end
        end
      end
    end
  end
end
