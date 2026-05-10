# frozen_string_literal: true

require_relative 'cli_options_registry'
require_relative 'active_sessions_query'
require_relative '../authentication/cli_password'
require_relative 'cli_conversion'
require_relative 'cli_encryption_mode_change'
require_relative '../authentication/cli'

module Lich
  module Common
    module CLI
      # Provides orchestration for CLI commands in the Lich application.
      # @example Executing CLI orchestration
      #   Lich::Common::CLI::CLIOrchestration.execute
      module CLIOrchestration
        # Executes the CLI orchestration by processing command line arguments.
        # @return [void]
        # @example Executing the orchestration
        #   Lich::Common::CLI::CLIOrchestration.execute
        def self.execute
          ActiveSessionsQuery.execute

          ARGV.each do |arg|
            case arg
            when /^--change-account-password$/, /^-cap$/
              handle_change_account_password
            when /^--add-account$/, /^-aa$/
              handle_add_account
            when /^--change-master-password$/, /^-cmp$/
              handle_change_master_password
            when /^--recover-master-password$/, /^-rmp$/
              handle_recover_master_password
            when /^--convert-entries$/
              handle_convert_entries
            when /^--change-encryption-mode$/, /^-cem$/
              handle_change_encryption_mode
            end
          end

          # Check for conversion needed before login attempt
          # This is not an early-exit operation - it detects a precondition for login
          if ARGV.include?('--login')
            check_conversion_needed_for_login
          end
        end

        # Checks if conversion is required before a login attempt.
        # @return [void]
        # @raise [SystemExit] if conversion is needed
        # @example Checking conversion before login
        #   Lich::Common::CLI::CLIOrchestration.check_conversion_needed_for_login
        def self.check_conversion_needed_for_login
          # Check if conversion is required
          if Lich::Common::CLI::CLIConversion.conversion_needed?(DATA_DIR)
            Lich::Common::CLI::CLIConversion.print_conversion_help_message
            exit 1
          end
        end

        # Handles the change of an account password via CLI.
        # @param account [String] The account whose password is to be changed.
        # @param new_password [String] The new password for the account.
        # @return [Integer] Exit status code.
        # @raise [SystemExit] if arguments are missing or invalid.
        # @example Changing an account password
        #   Lich::Common::CLI::CLIOrchestration.handle_change_account_password
        def self.handle_change_account_password
          idx = ARGV.index { |a| a =~ /^--change-account-password$|^-cap$/ }
          account = ARGV[idx + 1]
          new_password = ARGV[idx + 2]

          if account.nil? || new_password.nil?
            lich_script = File.join(LICH_DIR, 'lich.rbw')
            $stdout.puts 'error: Missing required arguments'
            $stdout.puts "Usage: ruby #{lich_script} --change-account-password ACCOUNT NEWPASSWORD"
            $stdout.puts "   or: ruby #{lich_script} -cap ACCOUNT NEWPASSWORD"
            exit 1
          end

          exit Lich::Common::Authentication::CLIPassword.change_account_password(account, new_password)
        end

        # Handles the addition of a new account via CLI.
        # @param account [String] The account to be added.
        # @param password [String] The password for the new account.
        # @param frontend [String, nil] Optional frontend specification.
        # @return [Integer] Exit status code.
        # @raise [SystemExit] if arguments are missing or invalid.
        # @example Adding a new account
        #   Lich::Common::CLI::CLIOrchestration.handle_add_account
        def self.handle_add_account
          idx = ARGV.index { |a| a =~ /^--add-account$|^-aa$/ }
          account = ARGV[idx + 1]
          password = ARGV[idx + 2]

          if account.nil? || password.nil?
            lich_script = File.join(LICH_DIR, 'lich.rbw')
            $stdout.puts 'error: Missing required arguments'
            $stdout.puts "Usage: ruby #{lich_script} --add-account ACCOUNT PASSWORD [--frontend FRONTEND]"
            $stdout.puts "   or: ruby #{lich_script} -aa ACCOUNT PASSWORD [--frontend FRONTEND]"
            exit 1
          end

          # Check if YAML file exists; if not, check for DAT and auto-convert to plaintext
          yaml_file = Lich::Common::Authentication::EntryStore.yaml_file_path(DATA_DIR)
          unless File.exist?(yaml_file)
            if Lich::Common::CLI::CLIConversion.conversion_needed?(DATA_DIR)
              $stdout.puts ''
              $stdout.puts '=' * 80
              $stdout.puts 'WARNING: No YAML entry file found. Legacy entry.dat detected.'
              $stdout.puts 'Creating plaintext YAML file to support this operation.'
              $stdout.puts '=' * 80
              $stdout.puts ''
              $stdout.puts 'SECURITY NOTICE: Plaintext storage is not recommended except for'
              $stdout.puts 'accessibility requirements. Passwords will be stored in clear text.'
              $stdout.puts ''
              $stdout.puts 'To upgrade encryption later, use:'
              $stdout.puts "  ruby #{File.join(LICH_DIR, 'lich.rbw')} --change-encryption-mode enhanced"
              $stdout.puts '  or: -cem enhanced'
              $stdout.puts '=' * 80
              $stdout.puts ''

              # Perform plaintext conversion
              success = Lich::Common::CLI::CLIConversion.convert(DATA_DIR, :plaintext)
              unless success
                $stdout.puts 'error: Failed to create YAML file from legacy data.'
                exit 1
              end
              # Continue with add-account operation below
            end
            # No DAT file either - CLIPassword.add_account will create new YAML
          end

          frontend = ARGV[ARGV.index('--frontend') + 1] if ARGV.include?('--frontend')
          exit Lich::Common::Authentication::CLIPassword.add_account(account, password, frontend)
        end

        # Handles the change of the master password via CLI.
        # @param old_password [String] The current master password.
        # @param new_password [String, nil] The new master password (optional).
        # @return [Integer] Exit status code.
        # @raise [SystemExit] if arguments are missing or invalid.
        # @example Changing the master password
        #   Lich::Common::CLI::CLIOrchestration.handle_change_master_password
        def self.handle_change_master_password
          idx = ARGV.index { |a| a =~ /^--change-master-password$|^-cmp$/ }
          old_password = ARGV[idx + 1]
          new_password = ARGV[idx + 2]

          if old_password.nil?
            lich_script = File.join(LICH_DIR, 'lich.rbw')
            $stdout.puts 'error: Missing required arguments'
            $stdout.puts "Usage: ruby #{lich_script} --change-master-password OLDPASSWORD [NEWPASSWORD]"
            $stdout.puts "   or: ruby #{lich_script} -cmp OLDPASSWORD [NEWPASSWORD]"
            $stdout.puts 'Note: If NEWPASSWORD is not provided, you will be prompted for confirmation'
            exit 1
          end

          exit Lich::Common::Authentication::CLIPassword.change_master_password(old_password, new_password)
        end

        # Handles the recovery of the master password via CLI.
        # @param new_password [String, nil] The new master password (optional).
        # @return [Integer] Exit status code.
        # @example Recovering the master password
        #   Lich::Common::CLI::CLIOrchestration.handle_recover_master_password
        def self.handle_recover_master_password
          idx = ARGV.index { |a| a =~ /^--recover-master-password$|^-rmp$/ }
          new_password = ARGV[idx + 1]

          # new_password is optional - if not provided, user will be prompted interactively
          exit Lich::Common::Authentication::CLIPassword.recover_master_password(new_password)
        end

        # Handles the conversion of entries to a specified encryption mode via CLI.
        # @param encryption_mode_str [String] The encryption mode to convert to.
        # @return [Integer] Exit status code.
        # @raise [SystemExit] if arguments are missing or invalid.
        # @example Converting entries
        #   Lich::Common::CLI::CLIOrchestration.handle_convert_entries
        def self.handle_convert_entries
          idx = ARGV.index('--convert-entries')
          encryption_mode_str = ARGV[idx + 1]

          if encryption_mode_str.nil?
            lich_script = File.join(LICH_DIR, 'lich.rbw')
            $stdout.puts 'error: Missing required argument'
            $stdout.puts "Usage: ruby #{lich_script} --convert-entries [plaintext|standard|enhanced]"
            exit 1
          end

          unless %w[plaintext standard enhanced].include?(encryption_mode_str)
            $stdout.puts "error: Invalid encryption mode: #{encryption_mode_str}"
            $stdout.puts 'Valid modes: plaintext, standard, enhanced'
            exit 1
          end

          # For enhanced mode, prompt for master password and store in keychain before conversion
          # This way migrate_from_legacy will find it in keychain and not try to show GUI dialog
          if encryption_mode_str == 'enhanced'
            master_password = Lich::Common::Authentication::CLIPassword.prompt_and_confirm_password('Enter new master password for enhanced encryption')
            if master_password.nil?
              puts 'error: Master password creation cancelled'
              exit 1
            end

            # Store password in keychain so ensure_master_password_exists finds it
            require_relative '../gui/master_password_manager'
            stored = Lich::Common::GUI::MasterPasswordManager.store_master_password(master_password)
            unless stored
              puts 'error: Failed to store master password in keychain'
              exit 1
            end
          end

          # Perform conversion
          success = Lich::Common::CLI::CLIConversion.convert(
            DATA_DIR,
            encryption_mode_str
          )

          if success
            $stdout.puts 'Conversion completed successfully!'
            exit 0
          else
            $stdout.puts 'Conversion failed. Please check the logs for details.'
            exit 1
          end
        end

        # Handles the change of encryption mode via CLI.
        # @param mode_arg [String] The new encryption mode to set.
        # @return [Integer] Exit status code.
        # @raise [SystemExit] if arguments are missing or invalid.
        # @example Changing encryption mode
        #   Lich::Common::CLI::CLIOrchestration.handle_change_encryption_mode
        def self.handle_change_encryption_mode
          idx = ARGV.index { |a| a =~ /^--change-encryption-mode$|^-cem$/ }
          mode_arg = ARGV[idx + 1]

          if mode_arg.nil?
            lich_script = File.join(LICH_DIR, 'lich.rbw')
            $stdout.puts 'error: Missing encryption mode'
            $stdout.puts "Usage: ruby #{lich_script} --change-encryption-mode MODE [--master-password PASSWORD]"
            $stdout.puts "       ruby #{lich_script} -cem MODE [-mp PASSWORD]"
            $stdout.puts 'Modes: plaintext, standard, enhanced'
            exit 1
          end

          new_mode = mode_arg.to_sym

          # Check for optional master password (for Enhanced mode, if automating)
          mp_index = ARGV.index('--master-password') || ARGV.index('-mp')
          master_password = ARGV[mp_index + 1] if mp_index

          exit Lich::Common::CLI::EncryptionModeChange.change_mode(new_mode, master_password)
        end
      end
    end
  end
end
