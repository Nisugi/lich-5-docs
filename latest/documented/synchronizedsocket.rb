# Carve out from lich.rbw
# extension to SynchronizedSocket class 2024-06-13

module Lich
  module Common
    # A class that provides synchronized access to a delegate socket.
    # This class wraps a socket object and ensures that all operations on it are thread-safe.
    # @example Creating a synchronized socket
    #   socket = SynchronizedSocket.new(delegate_socket)
    class SynchronizedSocket
      # Initializes a new SynchronizedSocket instance.
      # @param o [Object] The delegate socket object to synchronize.
      # @return [SynchronizedSocket] The new instance of SynchronizedSocket.
      def initialize(o)
        @delegate = o
        @mutex = Mutex.new
        # self # removed by robocop, needs broad testing
      end

      # Outputs a string to the delegate socket.
      # @param args [*Object] The arguments to be output.
      # @param block [Proc] An optional block to be executed.
      # @return [nil] Returns nil after outputting.
      # @example Sending a message to the socket
      #   socket.puts('Hello, World!')
      def puts(*args, &block)
        @mutex.synchronize {
          @delegate.puts(*args, &block)
        }
      end

      # Conditionally outputs a string to the delegate socket based on a block's return value.
      # @param args [*Object] The arguments to be output if the condition is true.
      # @return [Boolean] Returns true if the message was sent, false otherwise.
      # @example Sending a message conditionally
      #   socket.puts_if('Hello, World!') { true }
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
      # @param args [*Object] The data to be written.
      # @param block [Proc] An optional block to be executed.
      # @return [nil] Returns nil after writing.
      # @example Writing data to the socket
      #   socket.write('Data to send')
      def write(*args, &block)
        @mutex.synchronize {
          @delegate.write(*args, &block)
        }
      end

      # Handles calls to methods that are not defined in this class.
      # @param method [Symbol] The name of the method being called.
      # @param args [*Object] The arguments passed to the method.
      # @param block [Proc] An optional block to be executed.
      # @return [Object] The result of the method call on the delegate.
      # @example Calling an undefined method
      #   socket.some_undefined_method(arg1, arg2)
      def method_missing(method, *args, &block)
        @delegate.__send__ method, *args, &block
      end
    end
  end
end
