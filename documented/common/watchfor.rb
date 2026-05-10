
module Lich
  module Common
    # Represents a watcher that triggers a block when a specified string or regular expression is matched.
    # This class allows you to monitor specific patterns in the script's execution.
    # @example Creating a Watchfor instance
    #   watcher = Lich::Common::Watchfor.new("pattern") { puts 'Matched!' }
    class Watchfor
      # rubocop:disable Lint/ReturnInVoidContext
      # Initializes a new Watchfor instance.
      # @param line [String, Regexp] The string or regular expression to watch for.
      # @param theproc [Proc, nil] An optional proc to use if no block is given.
      # @param block [Proc] The block to execute when the pattern is matched.
      # @return [nil] Returns nil if initialization fails due to invalid parameters.
      # @raise [ArgumentError] Raises an error if neither a string nor a regexp is provided.
      def initialize(line, theproc = nil, &block)
        return nil unless (script = Script.current)

        if line.is_a?(String)
          line = Regexp.new(Regexp.escape(line))
        elsif !line.is_a?(Regexp)
          echo 'watchfor: no string or regexp given'
          return nil
        end
        if block.nil?
          if theproc.respond_to? :call
            block = theproc
          else
            echo 'watchfor: no block or proc given'
            return nil
          end
        end
        script.watchfor[line] = block
      end

      # rubocop:enable Lint/ReturnInVoidContext
      # Clears all watchfor patterns.
      # @return [Hash] Returns an empty hash after clearing the patterns.
      # @example Clearing all watchfor patterns
      #   Lich::Common::Watchfor.clear
      def Watchfor.clear
        script.watchfor = Hash.new
      end
    end
  end
end
