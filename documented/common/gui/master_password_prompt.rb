# frozen_string_literal: true

require_relative 'master_password_prompt_ui'

module Lich
  module Common
    module GUI
      module MasterPasswordPrompt
        # Show the UI dialog to create a master password.
        # This method prompts the user to create a master password and validates its strength.
        # @return [String, nil] The master password if created, or nil if canceled.
        # @example Creating a master password
        #   password = Lich::Common::GUI::MasterPasswordPrompt.show_create_master_password_dialog
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

        # Show the UI dialog to enter a master password for recovery.
        # This method prompts the user to enter their master password for recovery purposes.
        # @param validation_test [Object] An optional validation test to verify the password.
        # @return [String, nil] The entered master password if valid, or nil if canceled.
        # @example Entering a master password for recovery
        #   password = Lich::Common::GUI::MasterPasswordPrompt.show_enter_master_password_dialog(validation_test)
        def self.show_enter_master_password_dialog(validation_test = nil)
          # Show recovery UI dialog to user
          # Clearly indicates password recovery vs creation
          result = MasterPasswordPromptUI.show_recovery_dialog(validation_test)

          return nil if result.nil?

          Lich.log "info: Master password entered and validated for recovery"

          result
        end

        # Validate the provided master password against a validation test.
        # This method checks if the given master password is valid based on the provided test.
        # @param master_password [String] The master password to validate.
        # @param validation_test [Object] The validation test to use for verification.
        # @return [Boolean] True if the password is valid, false otherwise.
        # @example Validating a master password
        #   is_valid = Lich::Common::GUI::MasterPasswordPrompt.validate_master_password(password, validation_test)
        def self.validate_master_password(master_password, validation_test)
          return false if master_password.nil? || validation_test.nil?

          MasterPasswordManager.validate_master_password(master_password, validation_test)
        end

        # Show a warning dialog to the user.
        # This method displays a modal dialog with a warning message and waits for user response.
        # @param title [String] The title of the warning dialog.
        # @param message [String] The message to display in the dialog.
        # @return [Boolean] True if the user clicked 'Yes', false if 'No'.
        # @example Showing a warning dialog
        #   user_accepted = Lich::Common::GUI::MasterPasswordPrompt.show_warning_dialog("Warning Title", "This is a warning message.")
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
