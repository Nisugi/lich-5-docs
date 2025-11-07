require 'tempfile'
require 'json'
require 'fileutils'

module Lich
  # Provides common functionality for the Lich project
  # This module contains methods related to session file management.
  # @example Including the module
  #   include Lich::Common
  module Common
    # Handles frontend session file operations
    # This module manages the creation, location, and cleanup of session files.
    # @example Using the Frontend module
    #   Lich::Common::Frontend.create_session_file('example', 'localhost', 3000)
    module Frontend
      @session_file = nil
      @tmp_session_dir = File.join Dir.tmpdir, "simutronics", "sessions"

      # Creates a session file with the given parameters
      # @param name [String] The name of the session
      # @param host [String] The host for the session
      # @param port [Integer] The port for the session
      # @param display_session [Boolean] Whether to display the session descriptor (default: true)
      # @return [nil]
      # @note If the name is nil, the method will return early without creating a session file.
      # @example Creating a session file
      #   Lich::Common::Frontend.create_session_file('example', 'localhost', 3000)
      def self.create_session_file(name, host, port, display_session: true)
        return if name.nil?
        FileUtils.mkdir_p @tmp_session_dir
        @session_file = File.join(@tmp_session_dir, "%s.session" % name.downcase.capitalize)
        session_descriptor = { name: name, host: host, port: port }.to_json
        puts "writing session descriptor to %s\n%s" % [@session_file, session_descriptor] if display_session
        File.open(@session_file, "w") do |fd|
          fd << session_descriptor
        end
      end

      # Returns the location of the current session file
      # @return [String, nil] The path to the session file or nil if not set
      # @example Retrieving the session file location
      #   location = Lich::Common::Frontend.session_file_location
      def self.session_file_location
        @session_file
      end

      # Cleans up (deletes) the current session file if it exists
      # @return [nil]
      # @note If the session file does not exist, the method will return early without performing any action.
      # @example Cleaning up the session file
      #   Lich::Common::Frontend.cleanup_session_file
      def self.cleanup_session_file
        return if @session_file.nil?
        File.delete(@session_file) if File.exist? @session_file
      end
    end
  end
end
