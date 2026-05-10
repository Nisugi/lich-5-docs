# frozen_string_literal: true

require 'json'
require 'socket'

module Lich
  module InternalAPI
    module ActiveSessions
      # Client for interacting with the Lich internal API.
      #
      # This class manages the connection to the API and handles requests.
      #
      # @see Lich::InternalAPI
      class Client
        READ_TIMEOUT = 1

        # Initializes a new Client instance.
        #
        # @param host [String] the hostname of the API server
        # @param port [Integer] the port number of the API server
        # @param auth_token [String] the authentication token for API access
        # @param socket_factory [Proc, nil] a factory for creating sockets (defaults to TCPSocket)
        # @return [void]
        def initialize(host:, port:, auth_token:, socket_factory: nil)
          @host = host
          @port = port
          @auth_token = auth_token
          @socket_factory = socket_factory || ->(connect_host, connect_port) { TCPSocket.new(connect_host, connect_port) }
        end

        # Sends a request to the API with the specified command and payload.
        #
        # @param command [String] the command to send to the API
        # @param payload [Hash] the payload data to include with the request
        # @return [Hash] the response from the API, including success status and data
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

        # Sends a ping request to the API to check connectivity.
        #
        # @return [Boolean] true if the API is reachable, false otherwise
        def ping
          request('ping').fetch(:ok, false)
        end

        # Sends an upsert request to the API with the given payload.
        #
        # @param payload [Hash] the data to upsert
        # @return [Hash] the response from the API
        def upsert(payload)
          request('upsert', payload)
        end

        # Sends a remove request to the API for the specified process ID.
        #
        # @param pid [String] the process ID to remove
        # @return [Hash] the response from the API
        def remove(pid)
          request('remove', pid: pid)
        end

        # Requests a snapshot from the API.
        #
        # @return [Hash] the snapshot data from the API
        def snapshot
          request('snapshot')
        end

        private

        # Reads the response from the socket with a timeout.
        #
        # @param socket [TCPSocket] the socket to read from
        # @return [String, nil] the response data or nil if a timeout occurs
        # @api private
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
