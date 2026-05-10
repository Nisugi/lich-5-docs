require 'socket'

module Lich
  # Common module for Lich project
  # This module contains shared functionality for the Lich project.
  module Common
    # A module for creating reusable TCP servers
    # This module provides a method to create a TCP server that can reuse the address.
    # @example Creating a reusable TCP server
    #   server = Lich::Common::ReusableTCPServer.create("localhost", 8080)
    module ReusableTCPServer
      # Creates a reusable TCP server
      # @param host [String] The hostname or IP address to bind the server to
      # @param port [Integer] The port number to bind the server to
      # @param backlog [Integer] The maximum length of the queue for pending connections (default is 1)
      # @return [Socket] The created TCP server socket
      # @raise [StandardError] Raises an error if the server cannot be created
      # @example Creating a server
      #   server = Lich::Common::ReusableTCPServer.create("localhost", 8080)
      def self.create(host, port, backlog: 1)
        server = Socket.new(:INET, :STREAM)
        begin
          server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
          server.bind(Addrinfo.tcp(host, port))
          server.listen(backlog)
          server
        rescue
          server.close rescue nil
          raise
        end
      end
    end
  end
end
