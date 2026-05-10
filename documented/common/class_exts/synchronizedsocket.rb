
module Lich
  module Common
    # A socket wrapper that synchronizes access to a delegate socket.
    #
    # This class ensures that all operations on the delegate socket are thread-safe.
    #
    # @see Lich::Common::SynchronizedSocket#puts
    # @see Lich::Common::SynchronizedSocket#write
    class SynchronizedSocket
      # Initializes a new SynchronizedSocket instance.
      # @param o [Object] the delegate socket to synchronize access to
      # @return [void]
      def initialize(o)
        @delegate = o
        @mutex = Mutex.new
        # self # removed by robocop, needs broad testing
      end

      # Writes a line to the delegate socket.
      #
      # This method is thread-safe and will synchronize access to the delegate.
      # @param args [Array] the arguments to be passed to the delegate's puts method
      # @yield [Proc] an optional block to be executed
      # @return [void]
      def puts(*args, &block)
        @mutex.synchronize {
          @delegate.puts(*args, &block)
        }
      end

      # Conditionally writes a line to the delegate socket based on the block's return value.
      #
      # This method is thread-safe and will synchronize access to the delegate.
      # @param args [Array] the arguments to be passed to the delegate's puts method
      # @yield [Proc] a block that determines whether to write to the socket
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

      # Writes data to the delegate socket.
      #
      # This method is thread-safe and will synchronize access to the delegate.
      # @param args [Array] the arguments to be passed to the delegate's write method
      # @yield [Proc] an optional block to be executed
      # @return [void]
      def write(*args, &block)
        @mutex.synchronize {
          @delegate.write(*args, &block)
        }
      end

      # Handles calls to methods that are not defined in this class.
      #
      # This method delegates the call to the underlying socket.
      # @param method [Symbol] the name of the method being called
      # @param args [Array] the arguments to be passed to the method
      # @yield [Proc] an optional block to be executed
      # @return [Object] the result of the delegated method call
      def method_missing(method, *args, &block)
        @delegate.__send__ method, *args, &block
      end
    end
  end
end
