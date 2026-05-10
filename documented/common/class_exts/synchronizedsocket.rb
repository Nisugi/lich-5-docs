
module Lich
  module Common
    # A class that wraps a socket to provide synchronized access.
    # This is useful in multi-threaded environments where multiple threads
    # may attempt to read from or write to the socket simultaneously.
    # @example Creating a synchronized socket
    #   socket = SynchronizedSocket.new(delegate_socket)
    class SynchronizedSocket
      # Initializes a new SynchronizedSocket instance.
      # @param o [Object] The delegate object that the socket will wrap.
      # @return [SynchronizedSocket]
      def initialize(o)
        @delegate = o
        @mutex = Mutex.new
        # self # removed by robocop, needs broad testing
      end

      # Writes a line to the socket.
      # @param args [Array] The arguments to be written to the socket.
      # @param block [Proc] An optional block to be executed.
      # @return [nil]
      # @example Writing to the socket
      #   socket.puts("Hello, World!")
      def puts(*args, &block)
        @mutex.synchronize {
          @delegate.puts(*args, &block)
        }
      end

      # Conditionally writes a line to the socket based on the given block.
      # @param args [Array] The arguments to be written to the socket if the block returns true.
      # @return [Boolean] Returns true if the line was written, false otherwise.
      # @example Conditionally writing to the socket
      #   socket.puts_if { some_condition }
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
      # @param args [Array] The data to be written to the socket.
      # @param block [Proc] An optional block to be executed.
      # @return [nil]
      # @example Writing data to the socket
      #   socket.write("Data to send")
      def write(*args, &block)
        @mutex.synchronize {
          @delegate.write(*args, &block)
        }
      end

      # Handles calls to methods that are not defined in this class.
      # This delegates the call to the wrapped delegate object.
      # @param method [Symbol] The name of the method being called.
      # @param args [Array] The arguments to pass to the method.
      # @param block [Proc] An optional block to be executed.
      # @return [Object] The result of the method call on the delegate.
      def method_missing(method, *args, &block)
        @delegate.__send__ method, *args, &block
      end
    end
  end
end
