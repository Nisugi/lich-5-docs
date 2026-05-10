
module Lich
  module Common
    module GUI
      # UI class for prompting the user for a master password.
      #
      # This class provides methods to show various dialogs related to master password management.
      #
      # @see Lich::Common::GUI
      class MasterPasswordPromptUI
        # Displays a dialog for the user to enter their master password.
        #
        # @return [String, nil] the entered master password or nil if canceled.
        # @example Show master password dialog
        #   password = MasterPasswordPromptUI.show_dialog
        def self.show_dialog
          # Block until dialog completes, using condition variable for sync
          result = nil
          mutex = Mutex.new
          condition = ConditionVariable.new

          Gtk.queue do
            result = new.create_dialog
            mutex.synchronize { condition.signal }
          end

          # Wait for dialog to complete on main thread
          mutex.synchronize { condition.wait(mutex) }
          result
        end

        # Displays a dialog indicating that the master password recovery was successful.
        #
        # @return [void]
        def self.show_recovery_success_dialog
          # Block until dialog completes, using condition variable for sync
          result = nil
          mutex = Mutex.new
          condition = ConditionVariable.new

          Gtk.queue do
            result = new.create_recovery_success_dialog
            mutex.synchronize { condition.signal }
          end

          # Wait for dialog to complete on main thread
          mutex.synchronize { condition.wait(mutex) }
          result
        end

        # Displays a dialog to confirm the master password when changing encryption modes.
        #
        # @param validation_test [String, nil] optional validation test for the password.
        # @param leaving_enhanced [Boolean] indicates if the user is leaving enhanced mode.
        # @return [String, nil] the entered master password or nil if canceled.
        # @example Confirm password for mode change
        #   password = MasterPasswordPromptUI.show_password_confirmation_for_mode_change(validation_test)
        def self.show_password_confirmation_for_mode_change(validation_test = nil, leaving_enhanced: false)
          result = nil
          mutex = Mutex.new
          condition = ConditionVariable.new

          if leaving_enhanced
            message = "<b>Confirm Master Password</b>\n\n" +
                      "Enter your master password to change encryption modes.\n\n" +
                      "Your password will be removed from Keychain after the mode change."
          else
            message = "<b>Confirm Master Password</b>\n\n" +
                      "Enter your master password to enable enhanced encryption.\n\n" +
                      "Your password will be stored securely in your system Keychain."
          end

          Gtk.queue do
            result = new.create_password_validation_dialog(
              validation_test,
              title: "Confirm Master Password",
              instructions: message
            )
            mutex.synchronize { condition.signal }
          end

          mutex.synchronize { condition.wait(mutex) }
          result
        end

        # Displays a dialog for the user to enter their master password to access data.
        #
        # @param validation_test [String, nil] optional validation test for the password.
        # @return [String, nil] the entered master password or nil if canceled.
        # @example Show password for data access
        #   password = MasterPasswordPromptUI.show_password_for_data_access(validation_test)
        def self.show_password_for_data_access(validation_test = nil)
          result = nil
          mutex = Mutex.new
          condition = ConditionVariable.new

          Gtk.queue do
            result = new.create_password_validation_dialog(
              validation_test,
              title: "Enter Master Password",
              instructions: "<b>Provide Master Password</b>\n\n" +
                           "Your data is encrypted with a master password.\n\n" +
                           "Enter your master password to access and convert your saved entries."
            )
            mutex.synchronize { condition.signal }
          end

          mutex.synchronize { condition.wait(mutex) }
          result
        end

        # Displays a dialog for the user to recover their master password.
        #
        # @param validation_test [String, nil] optional validation test for the password.
        # @return [String, nil] the entered master password or nil if canceled.
        # @example Show password recovery dialog
        #   password = MasterPasswordPromptUI.show_password_recovery_dialog(validation_test)
        def self.show_password_recovery_dialog(validation_test = nil)
          result = nil
          mutex = Mutex.new
          condition = ConditionVariable.new

          Gtk.queue do
            result = new.create_password_validation_dialog(
              validation_test,
              title: "Recover Master Password",
              instructions: "<b>Recover Master Password</b>\n\n" +
                           "Your master password was removed from your system Keychain.\n\n" +
                           "Enter your existing master password to restore access to your encrypted credentials.",
              show_success_dialog: true
            )
            mutex.synchronize { condition.signal }
          end

          mutex.synchronize { condition.wait(mutex) }
          result
        end

        # Displays a dialog for recovering the master password.
        #
        # @param validation_test [String, nil] optional validation test for the password.
        # @return [String, nil] the entered master password or nil if canceled.
        def self.show_recovery_dialog(validation_test = nil)
          show_password_recovery_dialog(validation_test)
        end

        # Creates a modal dialog for master password creation.
        #
        # @return [String, nil] the created master password or nil if canceled.
        def create_dialog
          # Create modal dialog for master password creation
          dialog = Gtk::Dialog.new(
            title: "Create Master Password",
            parent: nil,
            flags: :modal,
            buttons: [
              [Gtk::Stock::OK, Gtk::ResponseType::OK],
              [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL]
            ]
          )

          dialog.set_default_size(500, 450)

          content_box = Gtk::Box.new(:vertical, 12)
          content_box.border_width = 12

          # ====================================================================
          # SECTION 1: Instructions
          # ====================================================================
          instructions = Gtk::Label.new
          instructions.markup = "<b>Create Master Password</b>\n\n" +
                                "This password protects all your saved login credentials.\n" +
                                "Choose a strong password you can remember.\n\n" +
                                "Suggested length: <b>12 characters minimum</b>"
          instructions.wrap = true
          instructions.justify = :left
          content_box.pack_start(instructions, expand: false)

          # ====================================================================
          # SECTION 2: Password Input
          # ====================================================================
          password_label = Gtk::Label.new("Enter Master Password:")
          content_box.pack_start(password_label, expand: false)

          password_entry = Gtk::Entry.new
          password_entry.visibility = false
          password_entry.placeholder_text = "Enter password here"
          content_box.pack_start(password_entry, expand: false)

          # ====================================================================
          # SECTION 3: Real-time Strength Meter
          # ====================================================================
          strength_box = Gtk::Box.new(:horizontal, 10)

          strength_label = Gtk::Label.new("Strength:")
          strength_label.width_request = 70
          strength_box.pack_start(strength_label, expand: false)

          strength_bar = Gtk::ProgressBar.new
          strength_bar.fraction = 0.0
          strength_box.pack_start(strength_bar, expand: true)

          strength_text = Gtk::Label.new("Very Weak")
          strength_text.width_request = 80
          strength_box.pack_start(strength_text, expand: false)

          content_box.pack_start(strength_box, expand: false)

          # ====================================================================
          # SECTION 4: Category Checklist
          # ====================================================================
          category_frame = Gtk::Frame.new("Password Requirements")
          category_box = Gtk::Box.new(:vertical, 5)
          category_box.border_width = 10

          uppercase_icon = Gtk::Label.new
          uppercase_icon.markup = "<span foreground='gray'>✗</span>"
          uppercase_label = Gtk::Label.new("Uppercase letters (A-Z)")
          uppercase_item = Gtk::Box.new(:horizontal, 5)
          uppercase_item.pack_start(uppercase_icon, expand: false)
          uppercase_item.pack_start(uppercase_label, expand: true)
          category_box.pack_start(uppercase_item, expand: false)

          lowercase_icon = Gtk::Label.new
          lowercase_icon.markup = "<span foreground='gray'>✗</span>"
          lowercase_label = Gtk::Label.new("Lowercase letters (a-z)")
          lowercase_item = Gtk::Box.new(:horizontal, 5)
          lowercase_item.pack_start(lowercase_icon, expand: false)
          lowercase_item.pack_start(lowercase_label, expand: true)
          category_box.pack_start(lowercase_item, expand: false)

          numbers_icon = Gtk::Label.new
          numbers_icon.markup = "<span foreground='gray'>✗</span>"
          numbers_label = Gtk::Label.new("Numbers (0-9)")
          numbers_item = Gtk::Box.new(:horizontal, 5)
          numbers_item.pack_start(numbers_icon, expand: false)
          numbers_item.pack_start(numbers_label, expand: true)
          category_box.pack_start(numbers_item, expand: false)

          special_icon = Gtk::Label.new
          special_icon.markup = "<span foreground='gray'>✗</span>"
          special_label = Gtk::Label.new("Special characters (!@#$%^&*)")
          special_item = Gtk::Box.new(:horizontal, 5)
          special_item.pack_start(special_icon, expand: false)
          special_item.pack_start(special_label, expand: true)
          category_box.pack_start(special_item, expand: false)

          length_icon = Gtk::Label.new
          length_icon.markup = "<span foreground='gray'>✗</span>"
          length_label = Gtk::Label.new("Length: 0 / 12")
          length_item = Gtk::Box.new(:horizontal, 5)
          length_item.pack_start(length_icon, expand: false)
          length_item.pack_start(length_label, expand: true)
          category_box.pack_start(length_item, expand: false)

          category_frame.add(category_box)
          content_box.pack_start(category_frame, expand: false)

          # ====================================================================
          # SECTION 5: Confirmation Password
          # ====================================================================
          confirm_label = Gtk::Label.new("Confirm Master Password:")
          content_box.pack_start(confirm_label, expand: false)

          confirm_entry = Gtk::Entry.new
          confirm_entry.visibility = false
          confirm_entry.placeholder_text = "Re-enter password to confirm"
          content_box.pack_start(confirm_entry, expand: false)

          # ====================================================================
          # SECTION 6: Password Match Status
          # ====================================================================
          match_status = Gtk::Label.new("")
          match_status.justify = :left
          content_box.pack_start(match_status, expand: false)

          # ====================================================================
          # SECTION 7: Show Password Checkbox
          # ====================================================================
          create_and_wire_show_password_checkbox(content_box, [password_entry, confirm_entry])

          # ====================================================================
          # Real-time strength updates and password matching
          # ====================================================================
          # Helper to update password match status
          update_match_status = lambda do
            if password_entry.text.empty? && confirm_entry.text.empty?
              match_status.markup = ""
            elsif password_entry.text == confirm_entry.text && !password_entry.text.empty?
              match_status.markup = "<span foreground='#44ff44'>✓ Passwords match</span>"
            else
              match_status.markup = "<span foreground='#ff4444'>✗ Passwords do not match</span>"
            end
          end

          password_entry.signal_connect('changed') do
            password = password_entry.text
            strength = calculate_password_strength(password)
            strength_bar.fraction = strength / 100.0
            strength_text.text = get_strength_label(strength)

            # Update category icons
            update_category_icon(uppercase_icon, password.match?(/[A-Z]/), '#44ff44')
            update_category_icon(lowercase_icon, password.match?(/[a-z]/), '#44ff44')
            update_category_icon(numbers_icon, password.match?(/[0-9]/), '#44ff44')
            update_category_icon(special_icon, password.match?(/[!@#$%^&*\-_=+\[\]{};:'\",.<>?\/\\|`~]/), '#44ff44')
            update_category_icon(length_icon, password.length >= 12, '#44ff44')
            length_label.text = "Length: #{password.length} / 12"

            # Update password match status
            update_match_status.call
          end

          confirm_entry.signal_connect('changed') do
            # Update password match status
            update_match_status.call
          end

          # Set content area
          dialog.child.add(content_box)
          dialog.show_all

          # ====================================================================
          # Dialog Response Handling
          # ====================================================================
          password = nil
          response = dialog.run

          if response == Gtk::ResponseType::OK
            entered_password = password_entry.text
            confirm_password = confirm_entry.text

            if entered_password.empty?
              show_error_dialog("Password cannot be empty")
              password = nil
            elsif entered_password != confirm_password
              show_error_dialog("Passwords do not match")
              password = nil
            else
              password = entered_password
            end
          end

          dialog.destroy
          password
        end

        # Creates a modal dialog for validating the master password.
        #
        # @param validation_test [String, nil] optional validation test for the password.
        # @param title [String] the title of the dialog.
        # @param instructions [String] instructions to display in the dialog.
        # @param show_success_dialog [Boolean] whether to show a success dialog after validation.
        # @return [String, nil] the validated master password or nil if canceled.
        def create_password_validation_dialog(validation_test = nil, title: "Validate Master Password", instructions: "Enter your master password:", show_success_dialog: false)
          # Create modal dialog for password validation
          # Single password entry - validates against PBKDF2 test
          dialog = Gtk::Dialog.new(
            title: title,
            parent: nil,
            flags: :modal,
            buttons: [
              [Gtk::Stock::OK, Gtk::ResponseType::OK],
              [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL]
            ]
          )

          dialog.set_default_size(500, 250)

          content_box = Gtk::Box.new(:vertical, 12)
          content_box.border_width = 12

          # ====================================================================
          # SECTION 1: Instructions
          # ====================================================================
          instructions_label = Gtk::Label.new
          instructions_label.markup = instructions
          instructions_label.wrap = true
          instructions_label.justify = :left
          content_box.pack_start(instructions_label, expand: false)

          # ====================================================================
          # SECTION 2: Password Input
          # ====================================================================
          password_label = Gtk::Label.new("Enter Master Password:")
          content_box.pack_start(password_label, expand: false)

          password_entry = Gtk::Entry.new
          password_entry.visibility = false
          password_entry.placeholder_text = "Enter your master password"
          content_box.pack_start(password_entry, expand: false)

          # ====================================================================
          # SECTION 3: Show Password Checkbox
          # ====================================================================
          create_and_wire_show_password_checkbox(content_box, [password_entry])

          # ====================================================================
          # Error Message Label
          # ====================================================================
          error_label = Gtk::Label.new("")
          error_label.justify = :left
          content_box.pack_start(error_label, expand: false)

          # Set content area
          dialog.child.add(content_box)
          dialog.show_all

          # ====================================================================
          # Dialog Response Handling with Validation
          # ====================================================================
          password = nil
          continue_session = false

          loop do
            response = dialog.run

            if response == Gtk::ResponseType::OK
              entered_password = password_entry.text

              if entered_password.empty?
                error_label.markup = "<span foreground='#ff4444'>Password cannot be empty</span>"
                next
              elsif validation_test && !validation_test.empty?
                # Validate password correctness against PBKDF2 test
                unless MasterPasswordManager.validate_master_password(entered_password, validation_test)
                  error_label.markup = "<span foreground='#ff4444'>Incorrect password. Please try again.</span>"
                  password_entry.text = ""
                  password_entry.grab_focus
                  next
                end
              end

              # Validation passed - password is correct
              password = entered_password

              # Show success confirmation if appropriate for this context
              if show_success_dialog
                success_result = create_recovery_success_dialog
                continue_session = success_result[:continue_session]
              end
              break
            elsif response == Gtk::ResponseType::CANCEL
              password = nil
              break
            end
          end

          dialog.destroy
          { password: password, continue_session: continue_session }
        end

        # Creates a recovery dialog for the master password.
        #
        # @param validation_test [String, nil] optional validation test for the password.
        # @return [String, nil] the recovered master password or nil if canceled.
        def create_recovery_dialog(validation_test = nil)
          create_password_validation_dialog(
            validation_test,
            title: "Recover Master Password",
            instructions: "<b>Recover Master Password</b>\n\n" +
                         "Your master password was removed from your system Keychain.\n\n" +
                         "Enter your existing master password to restore access to your encrypted credentials."
          )
        end

        # Creates a modal dialog for confirming the success of the master password recovery.
        #
        # @return [void]
        def create_recovery_success_dialog
          # Create modal dialog for master password recovery success confirmation
          dialog = Gtk::Dialog.new(
            title: "Password Recovered",
            parent: nil,
            flags: :modal,
            buttons: []
          )

          dialog.set_default_size(400, 250)

          content_box = Gtk::Box.new(:vertical, 12)
          content_box.border_width = 12

          # ====================================================================
          # Success Message
          # ====================================================================
          success_message = Gtk::Label.new
          success_message.markup = "<b>✓ Password Successfully Saved</b>\n\n" +
                                   "Your master password has been restored to your system Keychain.\n" +
                                   "You can now access your encrypted credentials."
          success_message.wrap = true
          success_message.justify = :center
          content_box.pack_start(success_message, expand: false)

          # Set content area
          dialog.child.add(content_box)
          dialog.show_all

          # ====================================================================
          # Button Setup with 1-second delay to prevent accidental clicks
          # ====================================================================
          continue_session = nil

          GLib::Timeout.add(1000) do
            # Add Continue and Close buttons
            continue_button = Gtk::Button.new(label: "Continue")
            close_button = Gtk::Button.new(label: "Close")

            dialog.action_area.pack_start(close_button, expand: false, fill: false, padding: 5)
            dialog.action_area.pack_start(continue_button, expand: false, fill: false, padding: 5)
            dialog.action_area.show_all

            # Set up button handlers
            continue_button.signal_connect('clicked') do
              continue_session = true
              dialog.destroy
            end

            close_button.signal_connect('clicked') do
              continue_session = false
              dialog.destroy
            end

            false # Don't repeat the timeout
          end

          # Wait for dialog to be destroyed by button click
          dialog.run

          { continue_session: continue_session }
        end

        # Creates and wires a checkbox to show/hide password characters.
        #
        # @param content_box [Gtk::Box] the content box to add the checkbox to.
        # @param entries_to_toggle [Array<Gtk::Entry>] the entries whose visibility will be toggled.
        def create_and_wire_show_password_checkbox(content_box, entries_to_toggle)
          show_password_check = Gtk::CheckButton.new("Show password")
          show_password_check.active = false

          Accessibility.make_accessible(
            show_password_check,
            "Show Password Checkbox",
            "Toggle to display password characters",
            :check_button
          )

          content_box.pack_start(show_password_check, expand: false)

          show_password_check.signal_connect('toggled') do |_widget|
            entries_to_toggle.each { |entry| entry.visibility = show_password_check.active? }
          end

          show_password_check
        end

        private

        # Calculates the strength of a given password.
        #
        # @param password [String] the password to evaluate.
        # @return [Integer] a score from 0 to 100 representing the password strength.
        def calculate_password_strength(password)
          return 0 if password.empty?

          score = 0

          # Length scoring (4 points per character, max 40)
          score += [(password.length * 4), 40].min

          # Character type bonuses (10 points each)
          score += 10 if password.match?(/[A-Z]/)
          score += 10 if password.match?(/[a-z]/)
          score += 10 if password.match?(/[0-9]/)
          score += 10 if password.match?(/[!@#$%^&*\-_=+\[\]{};:'",.<>?\/\\|`~]/)

          # Variety bonus (5 points per category type, max 20)
          variety_count = 0
          variety_count += 1 if password.match?(/[A-Z]/)
          variety_count += 1 if password.match?(/[a-z]/)
          variety_count += 1 if password.match?(/[0-9]/)
          variety_count += 1 if password.match?(/[!@#$%^&*\-_=+\[\]{};:'",.<>?\/\\|`~]/)
          score += (variety_count - 1) * 5

          # Cap at 100
          [score, 100].min
        end

        # Gets a label for the password strength score.
        #
        # @param score [Integer] the strength score.
        # @return [String] the strength label corresponding to the score.
        def get_strength_label(score)
          case score
          when 0..20
            "Very Weak"
          when 21..40
            "Weak"
          when 41..60
            "Fair"
          when 61..80
            "Good"
          else
            "Strong"
          end
        end

        # Updates the icon for a password category based on whether it meets the criteria.
        #
        # @param icon_label [Gtk::Label] the label to update with the icon.
        # @param has_category [Boolean] indicates if the category is met.
        # @param color_code [String] the color code to use for the icon.
        def update_category_icon(icon_label, has_category, color_code)
          if has_category
            icon_label.markup = "<span foreground='#{color_code}'>✓</span>"
          else
            icon_label.markup = "<span foreground='gray'>✗</span>"
          end
        end

        # Displays an error dialog with a message.
        #
        # @param message [String] the main error message to display.
        # @param secondary_message [String, nil] an optional secondary message.
        def show_error_dialog(message, secondary_message = nil)
          Gtk.queue do
            dialog = Gtk::MessageDialog.new(
              parent: nil,
              flags: :modal,
              type: :error,
              buttons: :ok,
              message: message
            )
            dialog.secondary_text = secondary_message if secondary_message
            dialog.run
            dialog.destroy
          end
        end
      end
    end
  end
end
