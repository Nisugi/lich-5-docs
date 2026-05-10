##
## contextual logging
##

module Lich
  # Provides common logging functionality for the Lich module.
  #
  # @see Lich
  module Common
    module Log
      @@log_enabled = nil
      @@log_filter  = nil

      # Enables logging with an optional filter.
      # @param filter [Regexp] a regular expression to filter log messages
      # @return [nil] This method does not return a meaningful value.
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

      # Disables logging and resets the filter.
      # @return [nil] This method does not return a meaningful value.
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
      # @return [Boolean] true if logging is enabled, false otherwise.
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
      # @return [Regexp] the current log filter as a regular expression.
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
      # @param msg [String] the message to log
      # @param label [Symbol] the label for the log message (default: :debug)
      # @return [void]
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

      # Writes a line to the output based on the current environment settings.
      # @param line [String] the line to write
      # @return [void]
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
      # @param msg [String] the message to format
      # @param label [Symbol] the label to include in the formatted message
      # @return [String] the formatted message.
      def self._view(msg, label)
        label = [Script.current.name, label].flatten.compact.join(".")
        safe = msg.inspect
        # safe = safe.gsub("<", "&lt;").gsub(">", "&gt;") if safe.include?("<") and safe.include?(">")
        "[#{label}] #{safe}"
      end

      # Outputs a formatted log message using the respond method.
      # @param msg [String] the message to log
      # @param label [Symbol] the label for the log message (default: :debug)
      # @return [void]
      def self.pp(msg, label = :debug)
        respond _view(msg, label)
      end

      # Outputs a log message, alias for pp.
      # @param args [Array] the arguments to log
      # @return [void]
      def self.dump(*args)
        pp(*args)
      end

      # Provides preset formatting for log messages.
      module Preset
        # Formats a message as a preset log entry.
        # @param kind [String] the type of preset
        # @param body [String] the message body
        # @return [String] the formatted preset message.
        def self.as(kind, body)
          %[<preset id="#{kind}">#{body}</preset>]
        end
      end
    end
  end
end
