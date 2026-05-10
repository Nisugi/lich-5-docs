
module Lich
  module Common
    # A class that wraps a socket to provide synchronized access.
    #
    # This class ensures that all operations on the socket are thread-safe.
    #
    # @see Lich::Common
    class SynchronizedSocket
      # Initializes a new SynchronizedSocket instance.
      # @param o [Object] the socket object to delegate to
      # @return [void]
      def initialize(o)
        @delegate = o
        @mutex = Mutex.new
        # self # removed by robocop, needs broad testing
      end

      # Writes a line to the socket, followed by a newline.
      # @param args [Array] the arguments to write to the socket
      # @param block [Proc] an optional block to be executed
      # @return [void]
      def puts(*args, &block)
        @mutex.synchronize {
          @delegate.puts(*args, &block)
        }
      end

      # Conditionally writes a line to the socket if the block returns true.
      # @param args [Array] the arguments to write to the socket
      # @return [Boolean] true if the line was written, false otherwise
      def puts_if(*args)
        @mutex.synchronize {
          if yield
            @delegate.puts(*args)
            return true
          else
            return false
          end
        }
      end

      # Writes data to the socket.
      # @param args [Array] the arguments to write to the socket
      # @param block [Proc] an optional block to be executed
      # @return [void]
      def write(*args, &block)
        @mutex.synchronize {
          @delegate.write(*args, &block)
        }
      end

      # Handles calls to methods that are not defined in this class.
      # @param method [Symbol] the name of the method being called
      # @param args [Array] the arguments passed to the method
      # @param block [Proc] an optional block to be executed
      # @return [Object] the result of the method call on the delegate
      def method_missing(method, *args, &block)
        @delegate.__send__ method, *args, &block
      end
    end
  end
end
