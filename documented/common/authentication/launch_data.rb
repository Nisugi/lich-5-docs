
module Lich
  module Common
    module Authentication
      module LaunchData
        # Prepares the launch data based on authentication information and frontend type.
        #
        # @param auth_data [Hash] authentication data as key-value pairs
        # @param frontend [String] the frontend type (e.g., "wizard", "avalon")
        # @param custom_launch [String, nil] optional custom launch command
        # @param custom_launch_dir [String, nil] optional custom launch directory
        # @return [Array<String>] formatted launch data strings
        # @example
        #   Lich::Common::Authentication::LaunchData.prepare(auth_data, "wizard")
        # @note This method modifies the launch data based on the frontend type.
        def self.prepare(auth_data, frontend, custom_launch = nil, custom_launch_dir = nil)
          launch_data = auth_data.map { |k, v| "#{k.upcase}=#{v}" }

          # Modify launch data based on frontend
          case frontend.to_s.downcase
          when 'wizard'
            launch_data.collect! { |line|
              line.sub(/GAMEFILE=.+/, 'GAMEFILE=WIZARD.EXE')
                  .sub(/GAME=.+/, 'GAME=WIZ')
                  .sub(/FULLGAMENAME=.+/, 'FULLGAMENAME=Wizard Front End')
            }
          when 'avalon'
            launch_data.collect! { |line| line.sub(/GAME=.+/, 'GAME=AVALON') }
          when 'suks'
            launch_data.collect! { |line|
              line.sub(/GAMEFILE=.+/, 'GAMEFILE=WIZARD.EXE')
                  .sub(/GAME=.+/, 'GAME=SUKS')
            }
          end

          # Add custom launch information if provided
          if custom_launch
            launch_data.push "CUSTOMLAUNCH=#{custom_launch}"
            launch_data.push "CUSTOMLAUNCHDIR=#{custom_launch_dir}" if custom_launch_dir
          end

          launch_data
        end

        # Creates a new entry for the launch data.
        #
        # @param char_name [String] the character's name
        # @param game_code [String] the game's code
        # @param game_name [String] the game's name
        # @param user_id [String] the user's ID
        # @param password [String] the user's password
        # @param frontend [String] the frontend type
        # @param custom_launch [String, nil] optional custom launch command
        # @param custom_launch_dir [String, nil] optional custom launch directory
        # @return [Hash] a hash representing the launch entry
        # @example
        #   Lich::Common::Authentication::LaunchData.create_entry(char_name: "Hero", game_code: "H1", game_name: "Hero's Journey", user_id: "user123", password: "pass", frontend: "wizard")
        def self.create_entry(char_name:, game_code:, game_name:, user_id:, password:, frontend:, custom_launch: nil, custom_launch_dir: nil)
          {
            char_name: char_name,
            game_code: game_code,
            game_name: game_name,
            user_id: user_id,
            password: password,
            frontend: frontend,
            custom_launch: custom_launch,
            custom_launch_dir: custom_launch_dir
          }
        end
      end
    end
  end
end
