# frozen_string_literal: true

require_relative 'master_password_prompt_ui'

module Lich
  module Common
    module GUI
      module MasterPasswordPrompt
        # Shows a dialog for the user to create a master password.
        #
        # @return [String, nil] the created master password or nil if canceled
        # @example Create a master password dialog
        #   master_password = Lich::Common::GUI::MasterPasswordPrompt.show_create_master_password_dialog
        def self.show_create_master_password_dialog
          # Show UI dialog to user
          master_password = MasterPasswordPromptUI.show_dialog

          return nil if master_password.nil?

          # ====================================================================
          # VALIDATION: Check password requirements
          # ====================================================================
          if master_password.length < 8
            if show_warning_dialog(
              "Short Password",
              "Password is shorter than 8 characters.\n" +
              "Longer passwords (12+ chars) are stronger.\n\n" +
              "Continue with this password?"
            )
              # User chose to continue with weak password
              Lich.log "info: Master password strength validated (user override)"
              return master_password
            else
              # User declined weak password, restart
              Lich.log "info: User rejected weak password, prompting again"
              return show_create_master_password_dialog
            end
          end

          Lich.log "info: Master password strength validated"

          master_password
        end

        # Shows a dialog for the user to enter a master password for recovery.
        # Clearly indicates password recovery vs creation.
        #
        # @param validation_test [String, nil] optional test for validating the entered password
        # @return [String, nil] the entered master password or nil if canceled
        # @example Show enter master password dialog
        #   master_password = Lich::Common::GUI::MasterPasswordPrompt.show_enter_master_password_dialog
        def self.show_enter_master_password_dialog(validation_test = nil)
          # Show recovery UI dialog to user
          # Clearly indicates password recovery vs creation
          result = MasterPasswordPromptUI.show_recovery_dialog(validation_test)

          return nil if result.nil?

          Lich.log "info: Master password entered and validated for recovery"

          result
        end

        # Validates the provided master password against a validation test.
        #
        # @param master_password [String] the master password to validate
        # @param validation_test [String] the test to validate against
        # @return [Boolean] true if the password is valid, false otherwise
        # @example Validate a master password
        #   is_valid = Lich::Common::GUI::MasterPasswordPrompt.validate_master_password("my_password", "test")
        def self.validate_master_password(master_password, validation_test)
          return false if master_password.nil? || validation_test.nil?

          MasterPasswordManager.validate_master_password(master_password, validation_test)
        end

        # Displays a warning dialog to the user and waits for a response.
        #
        # @param title [String] the title of the warning dialog
        # @param message [String] the message to display in the dialog
        # @return [Boolean] true if the user confirms, false otherwise
        # @example Show a warning dialog
        #   user_confirmed = Lich::Common::GUI::MasterPasswordPrompt.show_warning_dialog("Warning", "This is a warning message.")
        def self.show_warning_dialog(title, message)
          # Block until dialog completes
          response = nil
          mutex = Mutex.new
          condition = ConditionVariable.new

          Gtk.queue do
            dialog = Gtk::MessageDialog.new(
              parent: nil,
              flags: :modal,
              type: :warning,
              buttons: :yes_no,
              message: title
            )
            dialog.secondary_text = message
            response = dialog.run
            dialog.destroy

            # Signal waiting thread
            mutex.synchronize { condition.signal }
          end

          # Wait for dialog to complete
          mutex.synchronize { condition.wait(mutex) }

          response == Gtk::ResponseType::YES
        end
      end
    end
  end
end
