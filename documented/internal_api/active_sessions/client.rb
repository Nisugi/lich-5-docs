# frozen_string_literal: true

require 'json'
require 'socket'

module Lich
  module InternalAPI
    module ActiveSessions
      # Client for managing active sessions with the Lich internal API.
      #
      # This class handles communication with the server, including sending requests and receiving responses.
      #
      # @see Lich::InternalAPI::ActiveSessions
      class Client
        READ_TIMEOUT = 1

        # Initializes a new Client instance.
        # @param host [String] the hostname of the server
        # @param port [Integer] the port number of the server
        # @param auth_token [String] the authentication token for the session
        # @param socket_factory [Proc, nil] a factory for creating sockets (defaults to TCPSocket)
        # @return [void]
        def initialize(host:, port:, auth_token:, socket_factory: nil)
          @host = host
          @port = port
          @auth_token = auth_token
          @socket_factory = socket_factory || ->(connect_host, connect_port) { TCPSocket.new(connect_host, connect_port) }
        end

        # Sends a request to the server with the specified command and payload.
        # @param command [String] the command to send to the server
        # @param payload [Hash] the data to include with the command
        # @return [Hash] the server's response, including success status and any data or error messages
        # @raise [StandardError] if an error occurs during the request
        def request(command, payload = {})
          socket = @socket_factory.call(@host, @port)
          socket.write(JSON.dump(command: command, auth: @auth_token, payload: payload) + "\n")
          raw = read_response(socket)
          return { ok: false, error: 'read timeout' } unless raw

          response = JSON.parse(raw.to_s, symbolize_names: true)
          return { ok: false, error: 'invalid response type' } unless response.is_a?(Hash)

          response
        rescue StandardError => e
          { ok: false, error: e.message }
        ensure
          socket&.close rescue nil
        end

        # Sends a ping request to the server to check connectivity.
        # @return [Boolean] true if the server responds positively, false otherwise
        # @example Check server connectivity
        #   client = Lich::InternalAPI::ActiveSessions::Client.new(host: "localhost", port: 1234, auth_token: "token")
        #   client.ping
        def ping
          request('ping').fetch(:ok, false)
        end

        # Sends an upsert request to the server with the provided payload.
        # @param payload [Hash] the data to upsert
        # @return [Hash] the server's response to the upsert request
        def upsert(payload)
          request('upsert', payload)
        end

        # Sends a remove request to the server for the specified process ID.
        # @param pid [String] the process ID to remove
        # @return [Hash] the server's response to the remove request
        def remove(pid)
          request('remove', pid: pid)
        end

        # Sends a snapshot request to the server.
        # @return [Hash] the server's response containing the snapshot data
        def snapshot
          request('snapshot')
        end

        private

        # Reads the response from the server socket with a timeout.
        # @param socket [TCPSocket] the socket to read from
        # @return [String, nil] the response data or nil if a timeout occurs
        # @raise [IO::WaitReadable] if the socket is not ready for reading
        def read_response(socket)
          deadline = Time.now + READ_TIMEOUT
          buffer = +''

          loop do
            remaining = deadline - Time.now
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
      end
    end
  end
end
