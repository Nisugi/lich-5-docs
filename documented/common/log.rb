##
## contextual logging
##

module Lich
  module Common
    # Provides contextual logging functionality.
    # This module allows enabling and disabling logging,
    # setting filters, and outputting log messages.
    # @example Enabling logging with a filter
    #   Lich::Common::Log.on(/error/) 
    # @example Disabling logging
    #   Lich::Common::Log.off
    module Log
      @@log_enabled = nil
      @@log_filter  = nil

      # Enables logging with an optional filter.
      # @param filter [Regexp] The filter to apply to log messages.
      # @return [nil]
      # @raise [SQLite3::BusyException] If the database is busy.
      # @example Enabling logging
      #   Lich::Common::Log.on(/info/)
      def self.on(filter = //)
        @@log_enabled = true
        @@log_filter = filter
        begin
          Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('log_enabled',?);", [@@log_enabled.to_s.encode('UTF-8')])
          Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('log_filter',?);", [@@log_filter.to_s.encode('UTF-8')])
        rescue SQLite3::BusyException
          sleep 0.1
          retry
        end
        return nil
      end

      # Disables logging.
      # @return [nil]
      # @raise [SQLite3::BusyException] If the database is busy.
      # @example Disabling logging
      #   Lich::Common::Log.off
      def self.off
        @@log_enabled = false
        @@log_filter = //
        begin
          Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('log_enabled',?);", [@@log_enabled.to_s.encode('UTF-8')])
          Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('log_filter',?);", [@@log_filter.to_s.encode('UTF-8')])
        rescue SQLite3::BusyException
          sleep 0.1
          retry
        end
        return nil
      end

      # Checks if logging is enabled.
      # @return [Boolean] True if logging is enabled, false otherwise.
      # @raise [SQLite3::BusyException] If the database is busy.
      # @example Checking logging status
      #   Lich::Common::Log.on?
      def self.on?
        if @@log_enabled.nil?
          begin
            val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='log_enabled';")
          rescue SQLite3::BusyException
            sleep 0.1
            retry
          end
          val = false if val.nil?
          @@log_enabled = (val.to_s =~ /on|true|yes/ ? true : false) if !val.nil?
        end
        return @@log_enabled
      end

      # Retrieves the current log filter.
      # @return [Regexp] The current log filter.
      # @raise [SQLite3::BusyException] If the database is busy.
      # @example Getting the log filter
      #   Lich::Common::Log.filter
      def self.filter
        if @@log_filter.nil?
          begin
            val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='log_filter';")
          rescue SQLite3::BusyException
            sleep 0.1
            retry
          end
          val = // if val.nil?
          @@log_filter = Regexp.new(val)
        end
        return @@log_filter
      end

      # Outputs a log message if logging is enabled and the message matches the filter.
      # @param msg [String, Exception] The message or exception to log.
      # @param label [Symbol] The label for the log message (default: :debug).
      # @return [nil]
      # @example Outputting a log message
      #   Lich::Common::Log.out("This is a log message", label: :info)
      def self.out(msg, label: :debug)
        return unless Script.current.vars.include?("--debug") || Log.on?
        return if msg.to_s !~ Log.filter
        if msg.is_a?(Exception)
          ## pretty-print exception
          _write _view(msg.message, label)
          msg.backtrace.to_a.slice(0..5).each do |frame| _write _view(frame, label) end
        else
          self._write _view(msg, label) # if Script.current.vars.include?("--debug")
        end
      end

      # Writes a line to the output based on the current context.
      # @param line [String] The line to write to the output.
      # @return [nil]
      def self._write(line)
        if Script.current.vars.include?("--headless") or not defined?(:_respond)
          $stdout.write(line + "\n")
        elsif line.include?("<") and line.include?(">")
          respond(line)
        else
          _respond Preset.as(:debug, line)
        end
      end

      # Formats a message with a label for logging.
      # @param msg [String] The message to format.
      # @param label [Symbol] The label to include in the formatted message.
      # @return [String] The formatted message.
      def self._view(msg, label)
        label = [Script.current.name, label].flatten.compact.join(".")
        safe = msg.inspect
        # safe = safe.gsub("<", "&lt;").gsub(">", "&gt;") if safe.include?("<") and safe.include?(">")
        "[#{label}] #{safe}"
      end

      # Outputs a formatted log message using respond.
      # @param msg [String] The message to log.
      # @param label [Symbol] The label for the log message (default: :debug).
      # @return [nil]
      # @example Pretty printing a log message
      #   Lich::Common::Log.pp("This is a pretty log message")
      def self.pp(msg, label = :debug)
        respond _view(msg, label)
      end

      # Dumps a log message using pretty print.
      # @param args [Array] The messages to log.
      # @return [nil]
      # @example Dumping a log message
      #   Lich::Common::Log.dump("This is a dump log message")
      def self.dump(*args)
        pp(*args)
      end

      # Provides preset formatting for log messages.
      module Preset
        # Formats a message as a preset.
        # @param kind [Symbol] The kind of preset.
        # @param body [String] The body of the message.
        # @return [String] The formatted preset message.
        def self.as(kind, body)
          %[<preset id="#{kind}">#{body}</preset>]
        end
      end
    end
  end
end
