# frozen_string_literal: true

require 'json'
require 'socket'

module Lich
  module InternalAPI
    module ActiveSessions
      # Represents a server for handling active sessions.
      #
      # This class manages client connections and processes requests.
      #
      # @see Lich::InternalAPI::ActiveSessions
      class Server
        READ_TIMEOUT = 1

        attr_reader :host, :port
        attr_reader :auth_token

        # Initializes a new Server instance.
        # @param host [String] the host address to bind the server to
        # @param port [Integer] the port number to listen on
        # @param registry [Object] the registry for managing session data
        # @param auth_token [String] the token used for authenticating requests
        # @param server_factory [Proc, nil] optional factory for creating the server
        # @param accept_thread_factory [Proc, nil] optional factory for creating accept threads
        # @param client_thread_factory [Proc, nil] optional factory for creating client threads
        # @return [void]
        def initialize(host:, port:, registry:, auth_token:, server_factory: nil, accept_thread_factory: nil, client_thread_factory: nil)
          @host = host
          @port = port
          @registry = registry
          @auth_token = auth_token
          @server_factory = server_factory || ->(bind_host, bind_port) { TCPServer.new(bind_host, bind_port) }
          @accept_thread_factory = accept_thread_factory || ->(&block) { Thread.new(&block) }
          @client_thread_factory = client_thread_factory || ->(socket, &block) { Thread.new(socket, &block) }
          @server = nil
          @thread = nil
          @mutex = Mutex.new
          @client_threads = []
        end

        # Starts the server to accept client connections.
        #
        # This method initializes the server and begins the accept loop.
        # @return [Boolean] true if the server started successfully, false otherwise
        # @raise [StandardError] if an error occurs during startup
        def start
          @mutex.synchronize do
            return true if running?

            @server = @server_factory.call(@host, @port)
            @server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1) rescue nil
            @port = @server.addr[1]
            @thread = @accept_thread_factory.call { accept_loop }
          end
          true
        rescue StandardError
          stop
          false
        end

        # Stops the server and cleans up resources.
        #
        # This method closes the server socket and joins any active client threads.
        # @return [void]
        def stop
          thread = nil
          server = nil
          client_threads = []
          @mutex.synchronize do
            thread = @thread
            server = @server
            client_threads = @client_threads.dup
            @client_threads.clear
            @thread = nil
            @server = nil
          end

          server&.close rescue nil
          if thread&.alive?
            thread.join(0.1)
            thread.kill if thread.alive?
          end
          client_threads.each do |client_thread|
            next unless client_thread.respond_to?(:join)

            client_thread.join(0.25)
            client_thread.kill if client_thread.respond_to?(:alive?) && client_thread.alive?
          end
        end

        # Checks if the server is currently running.
        # @return [Boolean] true if the server is running, false otherwise
        def running?
          @thread&.alive? || false
        end

        private

        # Accepts incoming client connections in a loop.
        #
        # This method runs in a separate thread and handles client connections.
        # @return [void]
        def accept_loop
          loop do
            server = @server
            break unless server

            socket = nil
            begin
              socket = server.accept
              client_thread = @client_thread_factory.call(socket) { |client| handle_tracked_client(client) }
              track_client_thread(client_thread)
            rescue IOError, Errno::EBADF
              # Server socket closed -- normal shutdown path.
              break
            rescue StandardError => e
              socket&.close rescue nil
              Lich.log("warning: ActiveSessions accept_loop error (continuing): #{e.class}: #{e.message}") if defined?(Lich) && Lich.respond_to?(:log)
            end
          end
        end

        def handle_tracked_client(socket)
          handle_client(socket)
        ensure
          untrack_current_thread
        end
        private :handle_tracked_client

        # Handles a connected client socket.
        #
        # This method reads the client's request and sends back a response.
        # @param socket [TCPSocket] the client socket to handle
        # @return [void]
        def handle_client(socket)
          raw = read_request(socket)
          unless raw
            Lich.log('warning: ActiveSessions client read timed out') if defined?(Lich) && Lich.respond_to?(:log)
            return
          end

          response = process_request(raw)
          socket.puts(JSON.dump(response))
        rescue StandardError => e
          socket.puts(JSON.dump(ok: false, error: e.message)) rescue nil
        ensure
          socket.close rescue nil
        end

        # Reads a request from the client socket with a timeout.
        #
        # This method waits for data to be available on the socket and reads it.
        # @param socket [TCPSocket] the client socket to read from
        # @return [String, nil] the raw request data or nil if timed out
        def read_request(socket)
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + READ_TIMEOUT
          buffer = +''

          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            return nil if remaining <= 0
            return nil unless IO.select([socket], nil, nil, remaining)

            chunk = socket.read_nonblock(1024, exception: false)
            case chunk
            when :wait_readable
              next
            when nil
              break
            else
              buffer << chunk
              break if buffer.include?("\n")
            end
          end

          buffer.empty? ? nil : buffer
        rescue IO::WaitReadable
          nil
        end
        private :read_request

        # Processes a raw request and returns a response.
        #
        # This method parses the request and executes the corresponding command.
        # @param raw [String] the raw request data
        # @return [Hash] the response data
        def process_request(raw)
          request = JSON.parse(raw.to_s, symbolize_names: true)
          return unauthorized_response unless authorized?(request)

          case request[:command]
          when 'ping'
            { ok: true, payload: { status: 'ok' } }
          when 'upsert'
            { ok: true, payload: @registry.upsert(request.fetch(:payload)) }
          when 'remove'
            remove_pid = request[:pid] || request.fetch(:payload, {})[:pid]
            return { ok: false, error: 'pid required' } if remove_pid.nil? || remove_pid.to_s.empty?

            { ok: true, payload: { removed: @registry.remove(remove_pid) } }
          when 'snapshot'
            { ok: true, payload: @registry.snapshot }
          else
            { ok: false, error: "unknown command: #{request[:command]}" }
          end
        rescue StandardError => e
          { ok: false, error: e.message }
        end

        # Checks if the request is authorized based on the auth token.
        # @param request [Hash] the request data containing authorization info
        # @return [Boolean] true if authorized, false otherwise
        # @api private
        def authorized?(request)
          request[:auth].to_s == @auth_token
        end
        private :authorized?

        # Returns a response indicating that the request is unauthorized.
        # @return [Hash] the unauthorized response data
        # @api private
        def unauthorized_response
          Lich.log('warning: ActiveSessions unauthorized local request rejected') if defined?(Lich) && Lich.respond_to?(:log)
          { ok: false, error: 'unauthorized' }
        end
        private :unauthorized_response

        # Tracks a client thread for cleanup purposes.
        # @param thread [Thread] the client thread to track
        # @return [void]
        # @api private
        def track_client_thread(thread)
          return unless thread

          @mutex.synchronize { @client_threads << thread }
        end
        private :track_client_thread

        # Untracks the current thread from the client threads list.
        # @return [void]
        # @api private
        def untrack_current_thread
          @mutex.synchronize { @client_threads.delete(Thread.current) }
        end
        private :untrack_current_thread
      end
    end
  end
end
