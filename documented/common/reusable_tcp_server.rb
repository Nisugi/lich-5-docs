require 'socket'

module Lich
  module Common
    module ReusableTCPServer
      # Creates a reusable TCP server socket.
      #
      # @param host [String] the hostname or IP address to bind the server to
      # @param port [Integer] the port number to bind the server to
      # @param backlog [Integer] the maximum length of the queue for pending connections (default is 1)
      # @return [Socket] the created TCP server socket
      # @raise [StandardError] raises an error if the server cannot be created
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
