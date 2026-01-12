
module Lich
  module Common
    module CLI
      # Manages command-line options and their configurations.
      # @example Registering an option
      #   CliOptionsRegistry.option(:verbose, type: :boolean, default: false)
      class CliOptionsRegistry
        @options = {}
        @handlers = {}

        class << self
          # Registers a command-line option with its configuration.
          # @param name [Symbol] The name of the option.
          # @param type [Symbol] The type of the option (default: :string).
          # @param default [Object] The default value for the option.
          # @param deprecated [Boolean] Indicates if the option is deprecated (default: false).
          # @param deprecation_message [String] The message to show when the option is used if deprecated.
          # @param mutually_exclusive [Array<Symbol>] An array of options that are mutually exclusive to this option.
          # @param handler [Proc] An optional handler for the option.
          # @return [void]
          # @example Registering a string option
          #   CliOptionsRegistry.option(:name, type: :string, default: "default_name")
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
          # @param name [Symbol] The name of the option to retrieve.
          # @return [Hash, nil] The option configuration or nil if not found.
          # @example Getting an option configuration
          #   config = CliOptionsRegistry.get_option(:verbose)
          def get_option(name)
            @options[name]
          end

          # Returns a duplicate of all registered options.
          # @return [Hash] A hash of all options and their configurations.
          # @example Retrieving all options
          #   options = CliOptionsRegistry.all_options
          def all_options
            @options.dup
          end

          # Retrieves the handler for a specified option.
          # @param name [Symbol] The name of the option whose handler is to be retrieved.
          # @return [Proc, nil] The handler for the option or nil if not found.
          # @example Getting an option handler
          #   handler = CliOptionsRegistry.get_handler(:verbose)
          def get_handler(name)
            @handlers[name]
          end

          # Validates the parsed options against the registered options.
          # @param parsed_opts [Object] The parsed options object to validate.
          # @return [Array<String>] An array of error messages for invalid options.
          # @example Validating options
          #   errors = CliOptionsRegistry.validate(parsed_options)
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

          # Converts the registered options into a schema format.
          # @return [Hash] A schema representation of the options.
          # @example Getting the options schema
          #   schema = CliOptionsRegistry.to_opts_schema
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
