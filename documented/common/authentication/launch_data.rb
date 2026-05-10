
# Provides common functionality for the Lich project
# This module serves as a namespace for various common utilities.
module Lich
  module Common
    # Handles authentication-related functionalities
    # This module contains methods related to user authentication.
    module Authentication
      # Manages launch data preparation for different frontends
      # This module provides methods to prepare and create launch data entries.
      # @example Preparing launch data
      #   launch_data = Lich::Common::Authentication::LaunchData.prepare(auth_data, 'wizard')
      module LaunchData
        # Prepares launch data based on authentication information and frontend type
        # @param auth_data [Hash] The authentication data to be processed
        # @param frontend [String] The frontend type to modify the launch data
        # @param custom_launch [String, nil] Optional custom launch command
        # @param custom_launch_dir [String, nil] Optional custom launch directory
        # @return [Array<String>] The prepared launch data
        # @example Preparing launch data for wizard
        #   launch_data = Lich::Common::Authentication::LaunchData.prepare(auth_data, 'wizard')
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

        # Creates a launch data entry with the specified parameters
        # @param char_name [String] The character name
        # @param game_code [String] The game code
        # @param game_name [String] The game name
        # @param user_id [String] The user ID
        # @param password [String] The password
        # @param frontend [String] The frontend type
        # @param custom_launch [String, nil] Optional custom launch command
        # @param custom_launch_dir [String, nil] Optional custom launch directory
        # @return [Hash] The created launch data entry
        # @example Creating a launch entry
        #   entry = Lich::Common::Authentication::LaunchData.create_entry(char_name: 'Hero', game_code: 'G123', game_name: 'Adventure', user_id: 'user1', password: 'pass', frontend: 'wizard')
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
