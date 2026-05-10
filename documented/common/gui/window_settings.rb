
module Lich
  module Common
    module GUI
      module WindowSettings
        # The file name for storing window settings
        SETTINGS_FILE = 'login_gui_settings.yml'
        # The minimum dimension for window width and height
        MIN_DIMENSION = 100
        # The spacer value for positioning on Darwin (macOS)
        DARWIN_SPACER = 28

        class << self
          # Loads window settings from a YAML file
          def load(data_dir)
            settings_file = File.join(data_dir, SETTINGS_FILE)
            return {} unless File.exist?(settings_file)

            settings = YAML.safe_load(File.read(settings_file), permitted_classes: [Symbol], symbolize_names: true)
            validate_settings(settings) ? settings : {}
          rescue StandardError => e
            Lich.log "warning: Could not load window settings: #{e.message}"
            {}
          end

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

          def capture_geometry(window)
            {
              width: window.allocation.width,
              height: window.allocation.height,
              position: window.position
            }
          end

          private

          def validate_settings(settings)
            return false unless settings.is_a?(Hash)

            valid_dimensions?(settings[:width], settings[:height]) &&
              valid_position?(settings[:position])
          end

          def valid_dimensions?(width, height)
            width.is_a?(Integer) && width > MIN_DIMENSION &&
              height.is_a?(Integer) && height > MIN_DIMENSION
          end

          def valid_position?(position)
            position.is_a?(Array) &&
              position.length == 2 &&
              position[0].is_a?(Integer) && position[0] >= 0 &&
              position[1].is_a?(Integer) && position[1] >= 0
          end

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

          def darwin?
            RUBY_PLATFORM =~ /darwin/i
          end
        end
      end
    end
  end
end
