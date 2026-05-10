# frozen_string_literal: true

require "openssl"
require "socket"

module Lich
  module Common
    module Authentication
      module EAccess
        # Represents an error during authentication
        # @example Raising an authentication error
        #   raise Lich::Common::Authentication::EAccess::AuthenticationError.new(404)
        class AuthenticationError < StandardError
          attr_reader :error_code

          # Initializes a new AuthenticationError
          # @param error_code [Integer] The error code associated with the authentication error
          # @return [AuthenticationError]
          def initialize(error_code)
            @error_code = error_code
            super("Error(#{error_code})")
          end
        end

        # The size of the packet used for communication
        PACKET_SIZE = 8192

        # Returns the path to the PEM file
        # @return [String] The path to the PEM file
        def self.pem
          @pem ||= File.join(DATA_DIR, "simu.pem")
        end

        # Checks if the PEM file exists
        # @return [Boolean] True if the PEM file exists, false otherwise
        def self.pem_exist?
          File.exist? pem
        end

        # Downloads the PEM file from the specified hostname and port
        # @param hostname [String] The hostname to connect to (default: "eaccess.play.net")
        # @param port [Integer] The port to connect to (default: 7910)
        # @return [void]
        def self.download_pem(hostname = "eaccess.play.net", port = 7910)
          # Create an OpenSSL context
          ctx = OpenSSL::SSL::SSLContext.new
          # Get remote TCP socket
          sock = TCPSocket.new(hostname, port)
          # pass that socket to OpenSSL
          ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
          # establish connection, if possible
          ssl.connect
          # write the .pem to disk
          File.write(pem, ssl.peer_cert)
        end

        # Verifies the PEM certificate against the connection
        # @param conn [OpenSSL::SSL::SSLSocket] The SSL connection to verify
        # @return [Boolean] True if the PEM is valid, false otherwise
        # @raise [StandardError] If the PEM verification fails
        def self.verify_pem(conn)
          # return if conn.peer_cert.to_s = File.read(pem)
          if !(conn.peer_cert.to_s == File.read(pem))
            Lich.log "Exception, \nssl peer certificate did not match #{pem}\nwas:\n#{conn.peer_cert}"
            download_pem
          else
            return true
          end
          #     fail Exception, "\nssl peer certificate did not match #{pem}\nwas:\n#{conn.peer_cert}"
        end

        # Establishes a secure socket connection
        # @param hostname [String] The hostname to connect to (default: "eaccess.play.net")
        # @param port [Integer] The port to connect to (default: 7910)
        # @return [OpenSSL::SSL::SSLSocket] The established SSL socket
        def self.socket(hostname = "eaccess.play.net", port = 7910)
          download_pem unless pem_exist?
          socket = TCPSocket.open(hostname, port)
          cert_store              = OpenSSL::X509::Store.new
          ssl_context             = OpenSSL::SSL::SSLContext.new
          ssl_context.cert_store  = cert_store
          ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
          cert_store.add_file(pem) if pem_exist?
          ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
          ssl_socket.sync_close = true
          EAccess.verify_pem(ssl_socket.connect)
          return ssl_socket
        end

        # Authenticates a user with the provided credentials
        # @param password [String] The user's password
        # @param account [String] The user's account name
        # @param character [String, nil] The character name (optional)
        # @param game_code [String, nil] The game code (optional)
        # @param legacy [Boolean] Indicates if legacy authentication is used (default: false)
        # @return [Array<Hash>] The login information
        # @raise [AuthenticationError] If authentication fails
        # @raise [StandardError] For other errors during authentication
        def self.auth(password:, account:, character: nil, game_code: nil, legacy: false)
          # Set Account module state
          if defined?(Lich::Common::Account)
            Lich::Common::Account.name = account
            Lich::Common::Account.game_code = game_code
            Lich::Common::Account.character = character
          end

          conn = EAccess.socket()
          begin
            # it is vitally important to verify self-signed certs
            # because there is no chain-of-trust for them
            EAccess.verify_pem(conn)
            conn.puts "K\n"
            hashkey = EAccess.read(conn)
            # pp "hash=%s" % hashkey
            password = password.split('').map { |c| c.getbyte(0) }
            hashkey = hashkey.split('').map { |c| c.getbyte(0) }
            password.each_index { |i| password[i] = ((password[i] - 32) ^ hashkey[i]) + 32 }
            password = password.map { |c| c.chr }.join
            conn.puts "A\t#{account}\t#{password}\n"
            response = EAccess.read(conn)
            unless /KEY\t(?<key>.*)\t/.match(response)
              error_code = response.split(/\s+/).last
              raise AuthenticationError, error_code
            end
            # pp "A:response=%s" % response
            conn.puts "M\n"
            response = EAccess.read(conn)
            raise StandardError, response unless response =~ /^M\t/
            # pp "M:response=%s" % response

            unless legacy
              conn.puts "F\t#{game_code}\n"
              response = EAccess.read(conn)
              raise StandardError, response unless response =~ /NORMAL|PREMIUM|TRIAL|INTERNAL|FREE/
              if defined?(Lich::Common::Account)
                Lich::Common::Account.subscription = response
              end
              # pp "F:response=%s" % response
              conn.puts "G\t#{game_code}\n"
              EAccess.read(conn)
              # pp "G:response=%s" % response
              conn.puts "P\t#{game_code}\n"
              EAccess.read(conn)
              # pp "P:response=%s" % response
              conn.puts "C\n"
              response = EAccess.read(conn)
              # pp "C:response=%s" % response
              if defined?(Lich::Common::Account)
                Lich::Common::Account.members = response
              end
              char_entry = response.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '')
                                   .scan(/[^\t]+\t[^\t^\n]+/)
                                   .find { |c| c.split("\t")[1] == character }
              unless char_entry
                raise AuthenticationError, "CHARACTER_NOT_FOUND"
              end
              char_code = char_entry.split("\t")[0]
              conn.puts "L\t#{char_code}\tSTORM\n"
              response = EAccess.read(conn)
              raise StandardError, response unless response =~ /^L\t/
              # pp "L:response=%s" % response
              login_info = response.sub(/^L\tOK\t/, '')
                                   .split("\t")
                                   .map { |kv|
                                     k, v = kv.split("=")
                                     [k.downcase, v]
                                   }.to_h
            else
              login_info = Array.new
              for game in response.sub(/^M\t/, '').scan(/[^\t]+\t[^\t^\n]+/)
                game_code, game_name = game.split("\t")
                # pp "M:response = %s" % response
                conn.puts "N\t#{game_code}\n"
                response = EAccess.read(conn)
                if response =~ /STORM/
                  conn.puts "F\t#{game_code}\n"
                  response = EAccess.read(conn)
                  if response =~ /NORMAL|PREMIUM|TRIAL|INTERNAL|FREE/
                    if defined?(Lich::Common::Account)
                      Lich::Common::Account.subscription = response
                    end
                    conn.puts "G\t#{game_code}\n"
                    EAccess.read(conn)
                    conn.puts "P\t#{game_code}\n"
                    EAccess.read(conn)
                    conn.puts "C\n"
                    response = EAccess.read(conn)
                    if defined?(Lich::Common::Account)
                      Lich::Common::Account.members = response
                    end
                    for code_name in response.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
                      char_code, char_name = code_name.split("\t")
                      hash = { :game_code => "#{game_code}", :game_name => "#{game_name}",
                              :char_code => "#{char_code}", :char_name => "#{char_name}" }
                      login_info.push(hash)
                    end
                  end
                end
              end
            end
            return login_info
          ensure
            conn&.close unless conn&.closed?
          end
        end

        # Reads data from the connection
        # @param conn [TCPSocket] The connection to read from
        # @return [String] The data read from the connection
        def self.read(conn)
          conn.sysread(PACKET_SIZE)
        end
      end
    end
  end
end
