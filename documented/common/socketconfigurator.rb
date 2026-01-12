require 'socket'

module Lich
  # Common utilities for the Lich project
  # This module contains socket configuration utilities.
  # @example Using the SocketConfigurator
  #   Lich::Common::SocketConfigurator.configure(socket)
  module Common
    # Provides methods to configure socket options.
    # This module handles both Windows and Unix socket configurations.
    # @example Configuring a socket
    #   Lich::Common::SocketConfigurator.configure(socket, keepalive: { enable: true })
    module SocketConfigurator
      if Gem.win_platform?
        Lich::Util.install_gem_requirements({ "ffi" => true })

        module WinFFI
          extend FFI::Library
          ffi_lib 'Ws2_32', 'msvcrt'

          # WSAIoctl command code for setting TCP keep-alive parameters
          # WSAIoctl command code for setting TCP keep-alive parameters
          SIO_KEEPALIVE_VALS = 0x98000004

          # Socket option level for socket-level options
          # Socket option level for socket-level options
          SOL_SOCKET = 0xffff

          # Socket option to enable/disable keep-alive
          # Socket option to enable/disable keep-alive
          SO_KEEPALIVE = 0x0008

          # Socket option to control connection linger on close
          # Socket option to control connection linger on close
          SO_LINGER   = 0x0080

          # Socket option to set receive timeout
          # Socket option to set receive timeout
          SO_RCVTIMEO = 0x1006

          # Socket option to set send timeout
          # Socket option to set send timeout
          SO_SNDTIMEO = 0x1005

          # Socket option to set receive buffer size
          # Socket option to set receive buffer size
          SO_RCVBUF   = 0x1002

          # Socket option to set send buffer size
          # Socket option to set send buffer size
          SO_SNDBUF   = 0x1003

          # Protocol number for TCP
          # Protocol number for TCP
          IPPROTO_TCP = 6

          # TCP option to disable Nagle's algorithm
          # TCP option to disable Nagle's algorithm
          TCP_NODELAY = 0x0001

          # TCP option to set maximum retransmission time
          # TCP option to set maximum retransmission time
          TCP_MAXRT   = 5

          class TcpKeepalive < FFI::Struct
            layout :onoff, :ulong,
                   :keepalivetime, :ulong,
                   :keepaliveinterval, :ulong
          end

          class Linger < FFI::Struct
            layout :l_onoff, :ushort,
                   :l_linger, :ushort
          end

          class Timeval < FFI::Struct
            layout :tv_sec, :long,
                   :tv_usec, :long
          end

          attach_function :WSAIoctl, [:int, :ulong, :pointer, :ulong,
                                      :pointer, :ulong, :pointer,
                                      :pointer, :pointer], :int

          attach_function :setsockopt, [:int, :int, :int, :pointer, :int], :int

          attach_function :_get_osfhandle, [:int], :long
        end
      end


      # Configures the given socket with specified options.
      # @param sock [Socket] The socket to configure.
      # @param keepalive [Hash] Options for TCP keep-alive settings.
      # @param linger [Hash] Options for socket linger settings.
      # @param timeout [Hash] Options for receive and send timeouts.
      # @param buffer_size [Hash] Options for receive and send buffer sizes.
      # @param tcp_nodelay [Boolean] Whether to disable Nagle's algorithm.
      # @param tcp_maxrt [Integer] Maximum retransmission time.
      # @return [void]
      # @raise [StandardError] If socket configuration fails.
      # @example Configuring a socket with custom options
      #   Lich::Common::SocketConfigurator.configure(socket, keepalive: { enable: true, idle: 60 })
      def self.configure(sock,
                         keepalive: { enable: true, idle: 120, interval: 30 },
                         linger: { enable: true, timeout: 5 },
                         timeout: { recv: 30, send: 30 },
                         buffer_size: { recv: 32768, send: 32768 },
                         tcp_nodelay: true,
                         tcp_maxrt: 10)
        Lich.log("Configuring socket: keepalive=#{keepalive}, linger=#{linger}, timeout=#{timeout}, buffer_size=#{buffer_size}, tcp_nodelay=#{tcp_nodelay}, tcp_maxrt=#{tcp_maxrt}") if ARGV.include?("--debug")

        begin
          if Gem.win_platform?
            configure_windows(sock, keepalive, linger, timeout, buffer_size, tcp_nodelay, tcp_maxrt)
          else
            configure_unix(sock, keepalive, linger, timeout, buffer_size, tcp_nodelay)
          end
          Lich.log("Socket configuration successful") if ARGV.include?("--debug")
        rescue => e
          Lich.log("Socket configuration failed: #{e.class} - #{e.message}\n\t#{e.backtrace.join("\n\t")}") if ARGV.include?("--debug")
          raise
        end
      end


      # Configures socket options for Unix-based systems.
      # @param sock [Socket] The socket to configure.
      # @param keepalive [Hash] Options for TCP keep-alive settings.
      # @param linger [Hash] Options for socket linger settings.
      # @param timeout [Hash] Options for receive and send timeouts.
      # @param buffer_size [Hash] Options for receive and send buffer sizes.
      # @param tcp_nodelay [Boolean] Whether to disable Nagle's algorithm.
      # @return [void]
      # @raise [StandardError] If socket configuration fails.
      # @note This method is specific to Unix systems.
      def self.configure_unix(sock, keepalive, linger, timeout, buffer_size, tcp_nodelay)
        # Helper: error-checked setsockopt
        check_setsockopt = lambda do |level, option, value|
          begin
            sock.setsockopt(level, option, value)
            Lich.log("Unix setsockopt succeeded: level=#{level}, option=#{option}") if ARGV.include?("--debug")
          rescue => e
            Lich.log("Unix setsockopt failed: level=#{level}, option=#{option}, error=#{e.message}") if ARGV.include?("--debug")
            raise
          end
        end

        # Keepalive
        if keepalive[:enable]
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, [1].pack('i'))
          if Socket.const_defined?(:TCP_KEEPIDLE)
            check_setsockopt.call(Socket::IPPROTO_TCP, Socket::TCP_KEEPIDLE, [keepalive[:idle]].pack('i'))
          elsif Socket.const_defined?(:TCP_KEEPALIVE)
            check_setsockopt.call(Socket::IPPROTO_TCP, Socket::TCP_KEEPALIVE, [keepalive[:idle]].pack('i'))
          end
          check_setsockopt.call(Socket::IPPROTO_TCP, Socket::TCP_KEEPINTVL, [keepalive[:interval]].pack('i')) if Socket.const_defined?(:TCP_KEEPINTVL)
          check_setsockopt.call(Socket::IPPROTO_TCP, Socket::TCP_KEEPCNT, [5].pack('i')) if Socket.const_defined?(:TCP_KEEPCNT)
        end

        # Linger
        if linger
          linger_struct = [linger[:enable] ? 1 : 0, linger[:timeout]].pack("ii")
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_LINGER, linger_struct)
        end

        # Timeouts
        if timeout
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, [timeout[:recv], 0].pack("l!l!"))
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, [timeout[:send], 0].pack("l!l!"))
        end

        # Buffer sizes
        if buffer_size
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_RCVBUF, [buffer_size[:recv]].pack('i')) if buffer_size[:recv]
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_SNDBUF, [buffer_size[:send]].pack('i')) if buffer_size[:send]
        end

        # TCP_NODELAY
        check_setsockopt.call(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, [1].pack('i')) if tcp_nodelay

        # TCP_USER_TIMEOUT (Linux only - how long to retry before giving up)
        if Socket.const_defined?(:TCP_USER_TIMEOUT)
          user_timeout_ms = 120000 # 120 seconds
          check_setsockopt.call(Socket::IPPROTO_TCP, Socket::TCP_USER_TIMEOUT, [user_timeout_ms].pack('i'))
        end
      rescue => e
        Lich.log("Unix socket configuration error: #{e.class} - #{e.message}") if ARGV.include?("--debug")
        raise
      end

      # -------------------------

      # Configures socket options for Windows systems.
      # @param sock [Socket] The socket to configure.
      # @param keepalive [Hash] Options for TCP keep-alive settings.
      # @param linger [Hash] Options for socket linger settings.
      # @param timeout [Hash] Options for receive and send timeouts.
      # @param buffer_size [Hash] Options for receive and send buffer sizes.
      # @param tcp_nodelay [Boolean] Whether to disable Nagle's algorithm.
      # @param tcp_maxrt [Integer] Maximum retransmission time.
      # @return [void]
      # @raise [StandardError] If socket configuration fails.
      # @note This method is specific to Windows systems.
      def self.configure_windows(sock, keepalive, linger, timeout, buffer_size, tcp_nodelay, tcp_maxrt)
        # Helper: error-checked setsockopt using Ruby's Socket API
        check_setsockopt = lambda do |level, option, value|
          begin
            sock.setsockopt(level, option, value)
            Lich.log("Windows setsockopt succeeded: level=#{level}, option=#{option}") if ARGV.include?("--debug")
          rescue => e
            Lich.log("Windows setsockopt failed: level=#{level}, option=#{option}, error=#{e.class}: #{e.message}") if ARGV.include?("--debug")
            raise SystemCallError.new("setsockopt(level=#{level}, option=#{option})", 0)
          end
        end

        # Keepalive - Step 1: Enable SO_KEEPALIVE using Ruby's API
        if keepalive[:enable]
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, [1].pack('i'))

          # Step 2: Try to configure keep-alive parameters via WSAIoctl
          # This may fail on Ruby 3.x, so we'll catch and log but continue
          begin
            crt_fd = sock.fileno
            fd = WinFFI._get_osfhandle(crt_fd)

            if fd != -1
              ka = WinFFI::TcpKeepalive.new
              ka[:onoff] = 1
              ka[:keepalivetime] = keepalive[:idle] * 1000
              ka[:keepaliveinterval] = keepalive[:interval] * 1000
              bytes_returned = FFI::MemoryPointer.new(:ulong)

              ret = WinFFI.WSAIoctl(fd, WinFFI::SIO_KEEPALIVE_VALS, ka.to_ptr, ka.size,
                                    nil, 0, bytes_returned, nil, nil)
              if ret == 0
                Lich.log("WSAIoctl keepalive configuration succeeded") if ARGV.include?("--debug")
              else
                errno = FFI.errno
                Lich.log("WSAIoctl keepalive failed (errno=#{errno}), using default Windows keepalive settings") if ARGV.include?("--debug")
              end
            else
              Lich.log("Could not get OS handle for WSAIoctl, using default Windows keepalive settings") if ARGV.include?("--debug")
            end
          rescue => e
            Lich.log("WSAIoctl keepalive configuration failed: #{e.class} - #{e.message}") if ARGV.include?("--debug")
            Lich.log("Continuing with basic keepalive enabled (default Windows settings)") if ARGV.include?("--debug")
          end
        end

        # Linger - using Ruby's Socket API
        if linger
          linger_bytes = [linger[:enable] ? 1 : 0, linger[:timeout]].pack('SS')
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_LINGER, linger_bytes)
        end

        # Timeouts - using Ruby's Socket API
        if timeout
          # Windows expects timeout in milliseconds as a DWORD (4 bytes)
          recv_timeout_ms = timeout[:recv] * 1000
          send_timeout_ms = timeout[:send] * 1000
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, [recv_timeout_ms].pack('L'))
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, [send_timeout_ms].pack('L'))
        end

        # Buffer sizes - using Ruby's Socket API
        if buffer_size
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_RCVBUF, [buffer_size[:recv]].pack('i')) if buffer_size[:recv]
          check_setsockopt.call(Socket::SOL_SOCKET, Socket::SO_SNDBUF, [buffer_size[:send]].pack('i')) if buffer_size[:send]
        end

        # TCP_NODELAY - using Ruby's Socket API
        if tcp_nodelay
          check_setsockopt.call(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, [1].pack('i'))
        end

        # TCP_MAXRT - Windows-specific, may not be supported
        if tcp_maxrt
          begin
            # Try using Ruby's API first
            if defined?(Socket::TCP_MAXRT)
              check_setsockopt.call(Socket::IPPROTO_TCP, Socket::TCP_MAXRT, [tcp_maxrt].pack('i'))
            else
              Lich.log("TCP_MAXRT constant not available in Ruby's Socket API") if ARGV.include?("--debug")
            end
          rescue => e
            Lich.log("TCP_MAXRT not supported on this Windows version: #{e.message}") if ARGV.include?("--debug")
          end
        end

        Lich.log("Windows socket configuration completed successfully") if ARGV.include?("--debug")
      rescue => e
        Lich.log("Windows socket configuration error: #{e.class} - #{e.message}") if ARGV.include?("--debug")
        raise
      end
    end
  end
end
