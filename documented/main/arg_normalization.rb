
module Lich
  module Main
    module ArgNormalization
      # Regular expression pattern for matching headless argument
      # @example Using the HEADLESS_PATTERN
      #   if arg.match?(HEADLESS_PATTERN)
      HEADLESS_PATTERN = /^--headless(?:=(.+))?$/i.freeze
      DETACHABLE_CLIENT_PREFIX = '--detachable-client='.freeze

      # Normalizes command line arguments for headless mode.
      # This method modifies the argv array in place to ensure that
      # the headless argument is correctly formatted and valid.
      # @param argv [Array<String>] The command line arguments to normalize.
      # @return [Array<String>] The normalized command line arguments.
      # @raise [ArgumentError] if the headless argument is specified more than once
      # @raise [ArgumentError] if the headless argument is combined with detachable client
      # @raise [ArgumentError] if the headless argument does not have a valid port number
      # @example Normalizing arguments
      #   normalized_args = Lich::Main::ArgNormalization.normalize!(ARGV)
      def self.normalize!(argv)
        headless_indices = argv.each_index.select { |index| argv[index].match?(HEADLESS_PATTERN) }
        return argv if headless_indices.empty?
        raise ArgumentError, '--headless may only be specified once' if headless_indices.length > 1

        if argv.any? { |arg| arg.start_with?(DETACHABLE_CLIENT_PREFIX) }
          raise ArgumentError, '--headless cannot be combined with --detachable-client'
        end

        headless_index = headless_indices.first
        headless_arg = argv[headless_index]
        inline_match = HEADLESS_PATTERN.match(headless_arg)
        port_token = inline_match[1]

        if port_token.nil?
          next_arg = argv[headless_index + 1]
          if next_arg.nil? || next_arg.start_with?('--')
            raise ArgumentError, '--headless requires a port number or auto'
          end

          port_token = next_arg
          argv.delete_at(headless_index + 1)
        end

        argv[headless_index] = '--without-frontend'
        argv.insert(headless_index + 1, "#{DETACHABLE_CLIENT_PREFIX}#{normalize_headless_port(port_token)}")
        argv
      end

      # Normalizes the port token for headless mode.
      # This method checks if the token is 'auto' or a valid port number.
      # @param token [String] The port token to normalize.
      # @return [Integer] The normalized port number.
      # @raise [ArgumentError] if the port number is not between 1 and 65535 or is not 'auto'
      # @example Normalizing a port token
      #   port = Lich::Main::ArgNormalization.normalize_headless_port("8080")
      def self.normalize_headless_port(token)
        return 0 if token.to_s.casecmp('auto').zero?

        port = Integer(token, 10)
        return port if port.positive? && port <= 65_535

        raise ArgumentError, '--headless requires a port number between 1 and 65535, or auto'
      rescue ArgumentError
        raise ArgumentError, '--headless requires a port number between 1 and 65535, or auto'
      end
    end
  end
end
