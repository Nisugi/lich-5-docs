# frozen_string_literal: true

require_relative '../eaccess'

module Lich
  module Common
    module GUI
      module Authentication
        # Authenticates a user account with the provided credentials.
        # @param account [String] The user account name.
        # @param password [String] The user password.
        # @param character [String, nil] The character name (optional).
        # @param game_code [String, nil] The game code (optional).
        # @param legacy [Boolean] Indicates if legacy authentication should be used.
        # @return [Boolean] Returns true if authentication is successful, false otherwise.
        # @raise [StandardError] Raises an error if authentication fails.
        # @example Authenticating a user
        #   Lich::Common::GUI::Authentication.authenticate(account: "user", password: "pass")
        def self.authenticate(account:, password:, character: nil, game_code: nil, legacy: false)
          if character && game_code
            EAccess.auth(
              account: account,
              password: password,
              character: character,
              game_code: game_code
            )
          elsif legacy
            EAccess.auth(
              account: account,
              password: password,
              legacy: true
            )
          else
            EAccess.auth(
              account: account,
              password: password
            )
          end
        end

        # Prepares launch data for the specified frontend based on authentication data.
        # @param auth_data [Hash] The authentication data to prepare.
        # @param frontend [String] The frontend type (e.g., 'wizard', 'avalon').
        # @param custom_launch [String, nil] Custom launch command (optional).
        # @param custom_launch_dir [String, nil] Custom launch directory (optional).
        # @return [Array<String>] Returns an array of launch data strings.
        # @example Preparing launch data
        #   launch_data = Lich::Common::GUI::Authentication.prepare_launch_data(auth_data, 'wizard')
        def self.prepare_launch_data(auth_data, frontend, custom_launch = nil, custom_launch_dir = nil)
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

        # Creates a hash of entry data for a character.
        # @param char_name [String] The character name.
        # @param game_code [String] The game code.
        # @param game_name [String] The game name.
        # @param user_id [String] The user ID.
        # @param password [String] The user password.
        # @param frontend [String] The frontend type.
        # @param custom_launch [String, nil] Custom launch command (optional).
        # @param custom_launch_dir [String, nil] Custom launch directory (optional).
        # @return [Hash] Returns a hash containing the entry data.
        # @example Creating entry data
        #   entry_data = Lich::Common::GUI::Authentication.create_entry_data(char_name: "Hero", game_code: "123", game_name: "Adventure", user_id: "user1", password: "pass", frontend: "wizard")
        def self.create_entry_data(char_name:, game_code:, game_name:, user_id:, password:, frontend:, custom_launch: nil, custom_launch_dir: nil)
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
