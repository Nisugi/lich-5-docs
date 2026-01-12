# frozen_string_literal: true

require 'ostruct'

module Lich
  module Util
    # Provides utility methods for parsing command line options.
    # @example Parsing command line options
    #   options = Lich::Util::Opts.parse(ARGV, schema)
    class Opts
      # Parses command line arguments based on the provided schema.
      # @param argv [Array<String>] The command line arguments to parse.
      # @param schema [Hash] The schema defining the options and their configurations.
      # @return [OpenStruct] An OpenStruct containing the parsed options.
      # @example
      #   options = Lich::Util::Opts.parse(ARGV, { verbose: { default: false, type: :boolean } })
      def self.parse(argv, schema = {})
        options = {}

        # Set defaults
        schema.each do |key, config|
          options[key] = config[:default] if config.key?(:default)
        end

        # Parse ARGV
        i = 0
        while i < argv.length
          arg = argv[i]

          # Try each schema key to find a match
          matched = false
          schema.each do |key, config|
            option_name = "--#{key.to_s.gsub(/_/, '-')}"
            short_option = config[:short] ? "-#{config[:short]}" : nil

            if arg == option_name || (short_option && arg == short_option)
              matched = true
              options[key] = parse_value(argv, i, config)
              # Skip next arg if this option consumed it (not boolean or custom parser with = form)
              i += 1 if config[:type] != :boolean && !config[:parser]
              break
            elsif arg =~ /^#{option_name}=(.+)$/
              matched = true
              value = Regexp.last_match(1)
              options[key] = parse_value_with_content(value, config)
              break
            end
          end

          i += 1
        end

        # Return frozen OpenStruct
        OpenStruct.new(options).freeze
      end


      # Parses the value of a command line option based on its configuration.
      # @param argv [Array<String>] The command line arguments.
      # @param index [Integer] The index of the current argument in argv.
      # @param config [Hash] The configuration for the option being parsed.
      # @return [Object] The parsed value based on the option type.
      # @example
      #   value = Lich::Util::Opts.parse_value(ARGV, 0, { type: :string })
      def self.parse_value(argv, index, config)
        case config[:type]
        when :boolean
          true
        when :string
          argv[index + 1]
        when :integer
          argv[index + 1]&.to_i
        when :array
          # Collect following args until next --flag
          values = []
          j = index + 1
          while j < argv.length && !argv[j].start_with?('-')
            values << argv[j]
            j += 1
          end
          values
        else
          config[:parser] ? config[:parser].call(argv[index + 1]) : argv[index + 1]
        end
      end

      # Parses a value with content based on the provided configuration.
      # @param value [String] The value to parse.
      # @param config [Hash] The configuration for the option being parsed.
      # @return [Object] The parsed value based on the option type.
      # @example
      #   parsed_value = Lich::Util::Opts.parse_value_with_content("true", { type: :boolean })
      def self.parse_value_with_content(value, config)
        # If custom parser provided, use it first
        return config[:parser].call(value) if config[:parser]

        case config[:type]
        when :boolean
          value.match?(/^(true|on|yes|1)$/i)
        when :string
          value
        when :integer
          value.to_i
        else
          value
        end
      end
    end
  end
end
