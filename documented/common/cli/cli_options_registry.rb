
module Lich
  module Common
    module CLI
      # Manages command-line options and their configurations.
      #
      # This class provides methods to define, retrieve, and validate
      # command-line options for the application.
      #
      # @see Lich::Common::CLI
      class CliOptionsRegistry
        @options = {}
        @handlers = {}

        class << self
          # Defines a command-line option with its configuration.
          #
          # @param name [Symbol] the name of the option
          # @param type [Symbol] the type of the option (default: :string)
          # @param default [Object, nil] the default value for the option
          # @param deprecated [Boolean] indicates if the option is deprecated (default: false)
          # @param deprecation_message [String, nil] message to show when the option is used
          # @param mutually_exclusive [Array<Symbol>] options that cannot be used together
          # @param handler [Proc, nil] a handler for the option
          # @return [void]
          def option(name, type: :string, default: nil, deprecated: false,
                     deprecation_message: nil, mutually_exclusive: [], handler: nil)
            @options[name] = {
              type: type,
              default: default,
              deprecated: deprecated,
              deprecation_message: deprecation_message,
              mutually_exclusive: Array(mutually_exclusive)
            }
            @handlers[name] = handler if handler
          end

          # Retrieves the configuration for a specified option.
          #
          # @param name [Symbol] the name of the option to retrieve
          # @return [Hash, nil] the option configuration or nil if not found
          def get_option(name)
            @options[name]
          end

          # Returns a duplicate of all defined options.
          #
          # @return [Hash] a hash of all options and their configurations
          def all_options
            @options.dup
          end

          # Retrieves the handler for a specified option.
          #
          # @param name [Symbol] the name of the option to retrieve the handler for
          # @return [Proc, nil] the handler for the option or nil if not found
          def get_handler(name)
            @handlers[name]
          end

          # Validates the parsed options against defined configurations.
          #
          # This method checks for mutually exclusive options and deprecation warnings.
          #
          # @param parsed_opts [OpenStruct] the parsed command-line options
          # @return [Array<String>] an array of error messages, if any
          def validate(parsed_opts)
            errors = []

            # Check mutually exclusive options
            @options.each do |option_name, config|
              next unless parsed_opts.respond_to?(option_name) && parsed_opts.public_send(option_name)
              next if config[:mutually_exclusive].empty?

              config[:mutually_exclusive].each do |exclusive_option|
                if parsed_opts.respond_to?(exclusive_option) && parsed_opts.public_send(exclusive_option)
                  errors << "Options --#{option_name} and --#{exclusive_option} are mutually exclusive"
                end
              end
            end

            # Check for deprecation warnings
            @options.each do |option_name, config|
              next unless config[:deprecated]
              next unless parsed_opts.respond_to?(option_name) && parsed_opts.public_send(option_name)

              message = config[:deprecation_message] || "Option --#{option_name} is deprecated and will be removed in a future version"
              Lich.log "warning: #{message}"
            end

            errors
          end

          # Converts the defined options into a schema format.
          #
          # @return [Hash] a schema representation of the options
          def to_opts_schema
            schema = {}
            @options.each do |name, config|
              schema[name] = {
                type: config[:type],
                default: config[:default]
              }
            end
            schema
          end
        end
      end
    end
  end
end
