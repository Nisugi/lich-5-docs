# frozen_string_literal: true

require 'terminal-table'

module Lich
  # Provides common functionality for the Lich CLI.
  #
  # @see Lich::CLI
  module Common
    module CLI
      module ActiveSessionsQuery
        # Executes the active sessions query if requested.
        # @return [Integer] exit status code
        # @api private
        def self.execute
          return unless query_requested?

          exit run
        end

        # Runs the active sessions query logic.
        # @return [Integer] exit status code
        def self.run
          if ARGV.include?('--active-sessions')
            print_snapshot(query_snapshot)
            return 0
          end

          session_name = requested_session_name
          if session_name.nil? || session_name.empty?
            print_session_info_usage
            return 1
          end

          print_session_info(query_snapshot, session_name)
        end

        # Checks if an active sessions query has been requested.
        # @return [Boolean] true if a query is requested, false otherwise
        def self.query_requested?
          ARGV.include?('--active-sessions') || !requested_session_name.nil?
        end

        # Retrieves the requested session name from command line arguments.
        # @return [String, nil] the requested session name or nil if not provided
        def self.requested_session_name
          inline_arg = ARGV.find { |arg| arg.start_with?('--session-info=') }
          return inline_arg.split('=', 2).last if inline_arg

          idx = ARGV.index('--session-info')
          return nil unless idx

          ARGV[idx + 1]
        end

        # Retrieves the current snapshot of active sessions.
        # @return [Hash] a snapshot of active sessions or an unavailable snapshot
        def self.query_snapshot
          return unavailable_snapshot unless defined?(Lich::InternalAPI::ActiveSessions)

          Lich::InternalAPI::ActiveSessions.query_snapshot
        end

        # Prints the snapshot of active sessions to standard output.
        # @param snapshot [Hash] the snapshot data to print
        # @return [void]
        def self.print_snapshot(snapshot)
          if snapshot[:error]
            $stdout.puts "No active sessions service available (#{snapshot[:error]})."
            return
          end

          sessions = Array(snapshot[:sessions])
          if sessions.empty?
            $stdout.puts 'No active sessions found.'
            return
          end

          rows = sessions.sort_by { |session| session[:session_name].to_s.downcase }.map do |session|
            [
              session[:session_name] || '(unnamed)',
              session[:pid],
              session[:role] || 'session',
              yes_no(session[:connected]),
              session[:listener] ? yes_no(true) : yes_no(false),
              listener_display(session[:listener]),
              format_uptime(session[:uptime_seconds])
            ]
          end

          table = Terminal::Table.new(
            title: 'Active Sessions',
            headings: ['Session', 'PID', 'Role', 'Connected', 'Detachable', 'Listener', 'Uptime'],
            rows: rows
          )
          $stdout.puts table
        end

        # Prints detailed information about a specific active session.
        # @param snapshot [Hash] the snapshot data containing session information
        # @param session_name [String] the name of the session to display
        # @return [Integer] exit status code
        def self.print_session_info(snapshot, session_name)
          if snapshot[:error]
            $stdout.puts "No active sessions service available (#{snapshot[:error]})."
            return 1
          end

          session = Array(snapshot[:sessions]).find do |entry|
            entry[:session_name].to_s.casecmp?(session_name)
          end

          unless session
            $stdout.puts "No active session found for #{session_name}."
            return 1
          end

          listener = session[:listener]
          $stdout.puts "Session: #{session[:session_name]}"
          $stdout.puts "PID: #{session[:pid]}"
          $stdout.puts "Role: #{session[:role] || 'session'}"
          $stdout.puts "Connected: #{yes_no(session[:connected])}"
          $stdout.puts "Detachable listener: #{listener_display(listener)}"
          $stdout.puts "Uptime: #{format_uptime(session[:uptime_seconds])}"
          0
        end

        # Prints usage information for the session info command.
        # @return [void]
        def self.print_session_info_usage
          lich_script = File.join(LICH_DIR, 'lich.rbw')
          $stdout.puts 'error: Missing session name'
          $stdout.puts "Usage: ruby #{lich_script} --session-info NAME"
          $stdout.puts "   or: ruby #{lich_script} --session-info=NAME"
        end

        # Provides a snapshot indicating that the active sessions service is unavailable.
        # @return [Hash] a hash representing an unavailable snapshot
        # @api private
        def self.unavailable_snapshot
          {
            source: 'ActiveSessionsAPI',
            total: 0,
            connected: 0,
            detachable: 0,
            sessions: [],
            error: 'active sessions service unavailable'
          }
        end
        private_class_method :unavailable_snapshot

        # Formats the listener information for display.
        # @param listener [Hash, nil] the listener data to format
        # @return [String] formatted listener information or 'none'
        # @api private
        def self.listener_display(listener)
          return 'none' unless listener

          "#{listener[:host]}:#{listener[:port]}"
        end
        private_class_method :listener_display

        # Formats uptime in seconds into a human-readable string.
        # @param uptime_seconds [Integer] uptime in seconds
        # @return [String] formatted uptime string
        # @api private
        def self.format_uptime(uptime_seconds)
          total = uptime_seconds.to_i
          hours = total / 3600
          minutes = (total % 3600) / 60
          seconds = total % 60
          format('%<hours>02d:%<minutes>02d:%<seconds>02d', hours: hours, minutes: minutes, seconds: seconds)
        end
        private_class_method :format_uptime

        # Converts a boolean value to a 'yes' or 'no' string.
        # @param value [Boolean] the boolean value to convert
        # @return [String] 'yes' if true, 'no' if false
        # @api private
        def self.yes_no(value)
          value ? 'yes' : 'no'
        end
        private_class_method :yes_no
      end
    end
  end
end
