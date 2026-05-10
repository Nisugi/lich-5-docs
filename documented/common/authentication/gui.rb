# frozen_string_literal: true

require_relative 'authenticator'
require_relative 'launch_data'

module Lich
  module Common
    module Authentication
      module GUI
        # Debounce duration (ms) before restoring Play button after successful launch.
        # This limits accidental rapid repeat launches while keeping persistent UI usable.
        # Debounce duration (ms) before restoring Play button after successful launch.
        # This limits accidental rapid repeat launches while keeping persistent UI usable.
        BUTTON_REENABLE_DEBOUNCE_MS = 2000

        # Authenticates the user and launches the game.
        #
        # @param button [Gtk::Button] the button that triggers the launch
        # @param login_info [Hash] user login information including :user_id, :password, :char_name, and :game_code
        # @param on_success [Proc] callback to execute on successful authentication
        # @param on_error [Proc, nil] optional callback to execute on authentication error
        # @return [void]
        # @raise [FatalAuthError] if authentication fails
        # @raise [StandardError] for unexpected errors
        def self.authenticate_and_launch(button:, login_info:, on_success:, on_error: nil)
          button.sensitive = false

          begin
            # Authenticate with game server
            auth_data = Authentication.authenticate(
              account: login_info[:user_id],
              password: login_info[:password],
              character: login_info[:char_name],
              game_code: login_info[:game_code]
            )

            # Format launch data for frontend
            launch_data = LaunchData.prepare(
              auth_data,
              login_info[:frontend],
              login_info[:custom_launch],
              login_info[:custom_launch_dir]
            )

            if on_success
              # Backward compatibility: existing callbacks may still expect 1 arg.
              if on_success.respond_to?(:arity) && on_success.arity == 1
                on_success.call(launch_data)
              else
                on_success.call(launch_data, login_info)
              end
            end

            schedule_button_reenable(button)
          rescue FatalAuthError => e
            handle_auth_error(button, e, on_error)
          rescue StandardError => e
            Lich.log "error: GUI auth unexpected error: #{e.class}: #{e.message}"
            Lich.log e.backtrace.join("\n\t") if e.backtrace
            handle_auth_error(button, StandardError.new("Unexpected login error. See debug log for details."), on_error)
            raise
          end
        end

        # Handles authentication errors by updating the button state and invoking error callbacks.
        #
        # @param button [Gtk::Button] the button that triggered the authentication
        # @param error [StandardError] the error that occurred during authentication
        # @param on_error [Proc, nil] optional callback to execute on authentication error
        # @return [void]
        def self.handle_auth_error(button, error, on_error)
          button.sensitive = true

          if on_error
            on_error.call(error.message)
          else
            show_error_dialog(button, error.message)
          end
        end

        # Displays an error dialog to the user when authentication fails.
        #
        # @param button [Gtk::Button] the button that triggered the authentication
        # @param message [String] the error message to display
        # @return [void]
        def self.show_error_dialog(button, message)
          dialog = Gtk::MessageDialog.new(
            parent: button.toplevel,
            flags: :modal,
            type: :error,
            buttons: :ok,
            message: "Authentication Failed"
          )
          dialog.secondary_text = message
          dialog.run
          dialog.destroy
        end

        # Schedules the re-enabling of the button after a debounce period.
        #
        # @param button [Gtk::Button] the button to re-enable
        # @return [void]
        def self.schedule_button_reenable(button)
          GLib::Timeout.add(BUTTON_REENABLE_DEBOUNCE_MS) do
            button.sensitive = true unless button.respond_to?(:destroyed?) && button.destroyed?
            false
          end
        end
      end
    end
  end
end
