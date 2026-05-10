
module Lich
  module Main
    module ArgNormalization
      # Regular expression pattern for matching the --headless argument.
      #
      # @example Matching examples
      #   "--headless"
      #   "--headless=8080"
      #   "--headless=auto"
      # @see #normalize! for usage
      HEADLESS_PATTERN = /^--headless(?:=(.+))?$/i.freeze
      DETACHABLE_CLIENT_PREFIX = '--detachable-client='.freeze

      # Normalizes command-line arguments for headless mode.
      # This method modifies the argv array in place to replace the
      # --headless argument with --without-frontend and appends the
      # detachable client prefix with the specified port.
      #
      # @param argv [Array<String>] the command-line arguments to normalize
      # @return [Array<String>] the modified command-line arguments
      # @raise [ArgumentError] if --headless is specified more than once
      # @raise [ArgumentError] if --headless is combined with --detachable-client
      # @raise [ArgumentError] if --headless does not have a valid port number
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

      # Normalizes the headless port token.
      # Converts the token to an integer if it's not 'auto'.
      #
      # @param token [String] the port token to normalize
      # @return [Integer] the normalized port number
      # @raise [ArgumentError] if the port number is not between 1 and 65535 or if it's not 'auto'
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
