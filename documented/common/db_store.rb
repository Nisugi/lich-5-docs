# frozen_string_literal: true

# Recreating / bridging the design for CharSettings to lift in scripts into lib
# as with infomon rewrite
# Also tuning slightly, to improve / reduce db calls made by CharSettings
# 20240801 - updated to include vars (uservars) settings to support renaming characters

require 'English'

module Lich
  # Provides common database storage functionality for the Lich project.
  #
  # @see Lich::Common::DB_Store
  module Common
    module DB_Store
      # Reads data from the database based on the provided scope and script name.
      #
      # @param scope [String] the scope for the data retrieval, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param script [String] the name of the script to read data for
      # @return [Hash] the retrieved data as a hash
      # @example
      #   data = Lich::Common::DB_Store.read("game:character", "vars")
      #   puts data
      def self.read(scope = "#{XMLData.game}:#{XMLData.name}", script)
        case script
        when 'vars', 'uservars'
          get_vars(scope)
        else
          get_data(scope, script)
        end
      end

      # Saves data to the database for the specified scope and script name.
      #
      # @param scope [String] the scope for the data storage, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param script [String] the name of the script to save data for
      # @param val [Hash] the data to be saved
      # @return [String] a message indicating success or failure
      # @example
      #   result = Lich::Common::DB_Store.save("game:character", "vars", {name: "Hero"})
      #   puts result
      def self.save(scope = "#{XMLData.game}:#{XMLData.name}", script, val)
        case script
        when 'vars', 'uservars'
          store_vars(scope, val)
        else
          store_data(scope, script, val)
        end
      end

      # Retrieves data from the database for a specific script and scope.
      #
      # @param scope [String] the scope for the data retrieval, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param script [String] the name of the script to retrieve data for
      # @return [Hash] the retrieved data as a hash, or an empty hash if no data is found
      # @example
      #   data = Lich::Common::DB_Store.get_data("game:character", "settings")
      #   puts data
      def self.get_data(scope = "#{XMLData.game}:#{XMLData.name}", script)
        hash = Lich.db.get_first_value('SELECT hash FROM script_auto_settings WHERE script=? AND scope=?;', [script.encode('UTF-8'), scope.encode('UTF-8')])
        return {} unless hash
        Marshal.load(hash)
      end

      # Retrieves user variables from the database for a specific scope.
      #
      # @param scope [String] the scope for the user variables retrieval, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @return [Hash] the retrieved user variables as a hash, or an empty hash if no data is found
      # @example
      #   user_vars = Lich::Common::DB_Store.get_vars("game:character")
      #   puts user_vars
      def self.get_vars(scope = "#{XMLData.game}:#{XMLData.name}")
        hash = Lich.db.get_first_value('SELECT hash FROM uservars WHERE scope=?;', scope.encode('UTF-8'))
        return {} unless hash
        Marshal.load(hash)
      end

      # Stores data in the database for a specific script and scope.
      #
      # @param scope [String] the scope for the data storage, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param script [String] the name of the script to store data for
      # @param val [Hash] the data to be stored
      # @return [String] a message indicating success or failure
      # @example
      #   result = Lich::Common::DB_Store.store_data("game:character", "settings", {level: 10})
      #   puts result
      def self.store_data(scope = "#{XMLData.game}:#{XMLData.name}", script, val)
        blob = SQLite3::Blob.new(Marshal.dump(val))
        return 'Error: No data to store.' unless blob

        Lich.db_mutex.synchronize do
          begin
            Lich.db.execute('INSERT OR REPLACE INTO script_auto_settings(script,scope,hash) VALUES(?,?,?);', [script.encode('UTF-8'), scope.encode('UTF-8'), blob])
          rescue SQLite3::BusyException
            sleep 0.05
            retry
          rescue StandardError
            respond "--- Lich: error: #{$ERROR_INFO}"
            respond $ERROR_INFO.backtrace[0..1]
          end
        end
      end

      # Stores user variables in the database for a specific scope.
      #
      # @param scope [String] the scope for the user variables storage, defaults to "#{XMLData.game}:#{XMLData.name}"
      # @param val [Hash] the user variables to be stored
      # @return [String] a message indicating success or failure
      # @example
      #   result = Lich::Common::DB_Store.store_vars("game:character", {name: "Hero"})
      #   puts result
      def self.store_vars(scope = "#{XMLData.game}:#{XMLData.name}", val)
        blob = SQLite3::Blob.new(Marshal.dump(val))
        return 'Error: No data to store.' unless blob

        Lich.db_mutex.synchronize do
          begin
            Lich.db.execute('INSERT OR REPLACE INTO uservars(scope,hash) VALUES(?,?);', [scope.encode('UTF-8'), blob])
          rescue SQLite3::BusyException
            sleep 0.05
            retry
          rescue StandardError
            respond "--- Lich: error: #{$ERROR_INFO}"
            respond $ERROR_INFO.backtrace[0..1]
          end
        end
      end
    end
  end
end
