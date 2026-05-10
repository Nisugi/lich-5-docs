
module Lich
  module Common
    # Represents a watcher that triggers a block of code when a specified line matches a pattern.
    #
    # @see Lich::Common::Script
    class Watchfor
      # rubocop:disable Lint/ReturnInVoidContext
      # Initializes a new Watchfor instance.
      # @param line [String, Regexp] the line to watch for
      # @param theproc [Proc, nil] an optional proc to use if no block is given
      # @yield the block to execute when the line matches
      # @return [void]
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
      # @return [void]
      # @api private
      def Watchfor.clear
        script.watchfor = Hash.new
      end
    end
  end
end
