# frozen_string_literal: true

require_relative '../authentication/entry_store'

module Lich
  # Provides common functionality for the Lich CLI.
  #
  # @see Lich::Common::Authentication for authentication-related methods.
  module Common
    module CLI
      # Provides methods for converting entry data formats in the CLI.
      #
      # This module handles the conversion of legacy entry data to the new format.
      module CLIConversion
        # Determines if conversion is needed based on the presence of entry.dat and entry.yaml files.
        # @param data_dir [String] the directory containing the entry files
        # @return [Boolean] true if conversion is needed, false otherwise
        def self.conversion_needed?(data_dir)
          dat_file = File.join(data_dir, 'entry.dat')
          yaml_file = Lich::Common::Authentication::EntryStore.yaml_file_path(data_dir)

          File.exist?(dat_file) && !File.exist?(yaml_file)
        end

        # Converts entry data from the legacy format to the new format.
        #
        # This method validates the existence of necessary files and performs the conversion.
        # @param data_dir [String] the directory containing the entry files
        # @param encryption_mode [String] the encryption mode to use for the conversion
        # @return [Boolean] true if conversion was successful, false otherwise
        # @raise StandardError if an error occurs during conversion
        def self.convert(data_dir, encryption_mode)
          # Normalize encryption_mode to symbol if string is passed
          mode = encryption_mode.to_sym

          # Validate preconditions
          dat_file = File.join(data_dir, 'entry.dat')
          yaml_file = Lich::Common::Authentication::EntryStore.yaml_file_path(data_dir)

          unless File.exist?(dat_file)
            Lich.log "error: entry.dat not found at #{dat_file}"
            return false
          end

          if File.exist?(yaml_file)
            Lich.log "error: entry.yaml already exists at #{yaml_file}"
            return false
          end

          # Delegate to EntryStore for the actual conversion
          # For enhanced mode, migrate_from_legacy will prompt user to create master password
          result = Lich::Common::Authentication::EntryStore.migrate_from_legacy(data_dir, encryption_mode: mode)

          unless result
            Lich.log "error: EntryStore.migrate_from_legacy returned false"
          end

          result
        rescue StandardError => e
          Lich.log "error: Conversion failed: #{e.class}: #{e.message}"
          Lich.log "error: Backtrace: #{e.backtrace.join("\n  ")}"
          false
        end

        # Prints a help message for users regarding entry conversion.
        #
        # This method provides instructions on how to convert saved entries to the new format.
        def self.print_conversion_help_message
          lich_script = File.join(LICH_DIR, 'lich.rbw')

          $stdout.puts "\n" + '=' * 80
          $stdout.puts "Saved entries conversion required"
          $stdout.puts '=' * 80
          $stdout.puts "\nYour login entries need to be converted to the new format."
          $stdout.puts "\nRun one of these commands:\n\n"

          $stdout.puts "For no encryption (least secure):"
          $stdout.puts "  ruby #{lich_script} --convert-entries plaintext\n\n"

          $stdout.puts "For account-based encryption (standard):"
          $stdout.puts "  ruby #{lich_script} --convert-entries standard\n\n"

          $stdout.puts "For master-password encryption (recommended):"
          $stdout.puts "  ruby #{lich_script} --convert-entries enhanced\n\n"

          $stdout.puts '=' * 80 + "\n"
        end
      end
    end
  end
end
