# frozen_string_literal: true

require_relative '../gui/yaml_state'

module Lich
  module Common
    module CLI
      module CLIConversion
        # Checks if conversion is needed based on the presence of entry.dat and absence of entry.yaml
        # @param data_dir [String] The directory containing the data files
        # @return [Boolean] True if conversion is needed, false otherwise
        # @example
        #   Lich::Common::CLI::CLIConversion.conversion_needed?("/path/to/data")
        def self.conversion_needed?(data_dir)
          dat_file = File.join(data_dir, 'entry.dat')
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          File.exist?(dat_file) && !File.exist?(yaml_file)
        end

        # Converts entry.dat to entry.yaml format with specified encryption mode
        # @param data_dir [String] The directory containing the data files
        # @param encryption_mode [String, Symbol] The encryption mode to use for the conversion
        # @return [Boolean] True if conversion was successful, false otherwise
        # @raise StandardError if conversion fails
        # @example
        #   Lich::Common::CLI::CLIConversion.convert("/path/to/data", :standard)
        def self.convert(data_dir, encryption_mode)
          # Normalize encryption_mode to symbol if string is passed
          mode = encryption_mode.to_sym

          # Validate preconditions
          dat_file = File.join(data_dir, 'entry.dat')
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          unless File.exist?(dat_file)
            Lich.log "error: entry.dat not found at #{dat_file}"
            return false
          end

          if File.exist?(yaml_file)
            Lich.log "error: entry.yaml already exists at #{yaml_file}"
            return false
          end

          # Delegate to YamlState for the actual conversion
          # For enhanced mode, migrate_from_legacy will prompt user to create master password
          result = Lich::Common::GUI::YamlState.migrate_from_legacy(data_dir, encryption_mode: mode)

          unless result
            Lich.log "error: YamlState.migrate_from_legacy returned false"
          end

          result
        rescue StandardError => e
          Lich.log "error: Conversion failed: #{e.class}: #{e.message}"
          Lich.log "error: Backtrace: #{e.backtrace.join("\n  ")}"
          false
        end

        # Prints a help message for users regarding the conversion process
        # @example
        #   Lich::Common::CLI::CLIConversion.print_conversion_help_message
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
