# frozen_string_literal: true

require 'json'
require 'socket'

module Lich
  module InternalAPI
    module ActiveSessions
      # Represents a client for interacting with the Lich internal API.
      # This class handles requests and responses to the API.
      # @example Creating a new client
      #   client = Lich::InternalAPI::ActiveSessions::Client.new(host: "localhost", port: 1234, auth_token: "token")
      class Client
        # The timeout duration for reading responses from the API, in seconds.
        READ_TIMEOUT = 1

        # Initializes a new Client instance.
        # @param host [String] The hostname of the API server.
        # @param port [Integer] The port number of the API server.
        # @param auth_token [String] The authentication token for the API.
        # @param socket_factory [Proc] Optional factory for creating sockets.
        # @return [Client] The initialized Client instance.
        def initialize(host:, port:, auth_token:, socket_factory: nil)
          @host = host
          @port = port
          @auth_token = auth_token
          @socket_factory = socket_factory || ->(connect_host, connect_port) { TCPSocket.new(connect_host, connect_port) }
        end

        # Sends a request to the API with the given command and payload.
        # @param command [String] The command to send to the API.
        # @param payload [Hash] The payload to include with the command.
        # @return [Hash] The response from the API.
        # @raise [StandardError] If an error occurs during the request.
        # @example Sending a request
        #   response = client.request("ping")
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
        # @return [Boolean] True if the ping was successful, false otherwise.
        # @example Checking connectivity
        #   is_alive = client.ping
        def ping
          request('ping').fetch(:ok, false)
        end

        # Sends an upsert request to the API with the given payload.
        # @param payload [Hash] The data to upsert.
        # @return [Hash] The response from the API.
        # @example Upserting data
        #   response = client.upsert(data)
        def upsert(payload)
          request('upsert', payload)
        end

        # Sends a remove request to the API for the specified process ID.
        # @param pid [String] The process ID to remove.
        # @return [Hash] The response from the API.
        # @example Removing a process
        #   response = client.remove("1234")
        def remove(pid)
          request('remove', pid: pid)
        end

        # Sends a snapshot request to the API.
        # @return [Hash] The response from the API containing the snapshot data.
        # @example Getting a snapshot
        #   snapshot_data = client.snapshot
        def snapshot
          request('snapshot')
        end

        private

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
