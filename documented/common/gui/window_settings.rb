
module Lich
  module Common
    module GUI
      module WindowSettings
        SETTINGS_FILE = 'login_gui_settings.yml'
        MIN_DIMENSION = 100
        DARWIN_SPACER = 28

        # Provides methods to load, save, and apply window settings.
        #
        # @see Lich::Common::GUI
        class << self
          # Loads window settings from a YAML file.
          # @param data_dir [String] the directory where the settings file is located
          # @return [Hash] the loaded settings or an empty hash if loading fails
          # @raise [StandardError] if there is an error reading the file
          def load(data_dir)
            settings_file = File.join(data_dir, SETTINGS_FILE)
            return {} unless File.exist?(settings_file)

            settings = YAML.safe_load(File.read(settings_file), permitted_classes: [Symbol], symbolize_names: true)
            validate_settings(settings) ? settings : {}
          rescue StandardError => e
            Lich.log "warning: Could not load window settings: #{e.message}"
            {}
          end

          # Saves the window settings to a YAML file.
          # @param data_dir [String] the directory where the settings file will be saved
          # @param width [Integer] the width of the window
          # @param height [Integer] the height of the window
          # @param position [Array<Integer>] the position of the window as [x, y]
          # @return [Boolean] true if the settings were saved successfully, false otherwise
          # @raise [StandardError] if there is an error writing to the file
          def save(data_dir, width:, height:, position:)
            return false unless valid_dimensions?(width, height) && valid_position?(position)

            settings_file = File.join(data_dir, SETTINGS_FILE)
            settings = {
              width: width,
              height: height,
              position: position
            }

            File.open(settings_file, 'w') { |f| f.write(YAML.dump(settings)) }
            true
          rescue StandardError => e
            Lich.log "warning: Could not save window settings: #{e.message}"
            false
          end

          # Applies the given settings to the specified window.
          # @param window [Object] the window to apply settings to
          # @param settings [Hash] the settings to apply, including width, height, and position
          # @return [void]
          def apply_to_window(window, settings)
            return if settings.empty?

            width = [settings[:width], MIN_DIMENSION].max
            height = [settings[:height], MIN_DIMENSION].max
            position = settings[:position]

            window.resize(width, height)

            return unless valid_position?(position)

            constrained_position = constrain_to_monitor(position, width, height)
            spacer = darwin? ? DARWIN_SPACER : 0
            window.move(constrained_position[0], constrained_position[1] + spacer)
          end

          # Captures the current geometry of the specified window.
          # @param window [Object] the window to capture geometry from
          # @return [Hash] a hash containing the width, height, and position of the window
          def capture_geometry(window)
            {
              width: window.allocation.width,
              height: window.allocation.height,
              position: window.position
            }
          end

          private

          # Validates the provided settings to ensure they are correct.
          # @param settings [Hash] the settings to validate
          # @return [Boolean] true if the settings are valid, false otherwise
          def validate_settings(settings)
            return false unless settings.is_a?(Hash)

            valid_dimensions?(settings[:width], settings[:height]) &&
              valid_position?(settings[:position])
          end

          # Checks if the provided dimensions are valid.
          # @param width [Integer] the width to validate
          # @param height [Integer] the height to validate
          # @return [Boolean] true if both dimensions are greater than the minimum, false otherwise
          def valid_dimensions?(width, height)
            width.is_a?(Integer) && width > MIN_DIMENSION &&
              height.is_a?(Integer) && height > MIN_DIMENSION
          end

          # Validates the provided position to ensure it is an array of two integers.
          # @param position [Array] the position to validate
          # @return [Boolean] true if the position is valid, false otherwise
          def valid_position?(position)
            position.is_a?(Array) &&
              position.length == 2 &&
              position[0].is_a?(Integer) && position[0] >= 0 &&
              position[1].is_a?(Integer) && position[1] >= 0
          end

          # Constrains the given position to fit within the monitor's geometry.
          # @param position [Array<Integer>] the original position to constrain
          # @param width [Integer] the width of the window
          # @param height [Integer] the height of the window
          # @return [Array<Integer>] the constrained position as [x, y]
          def constrain_to_monitor(position, width, height)
            display = Gdk::Display.default
            geometry = display.default_screen.get_monitor_geometry(
              display.default_screen.get_monitor_at_point(position[0], position[1])
            )

            monitor_x = geometry.x || 0
            monitor_y = geometry.y || 0
            monitor_width = geometry.width || 0
            monitor_height = geometry.height || 0

            constrained_x = [[monitor_x, position[0]].max, monitor_x + monitor_width - width].min
            constrained_y = [[monitor_y, position[1]].max, monitor_y + monitor_height - height].min

            [constrained_x, constrained_y]
          end

          # Checks if the current platform is Darwin (macOS).
          # @return [Boolean] true if the platform is Darwin, false otherwise
          # @api private
          def darwin?
            RUBY_PLATFORM =~ /darwin/i
          end
        end
      end
    end
  end
end
