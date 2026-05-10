module Lich
  module Common
    # Handles database interactions for Lich.
    #
    # This class is responsible for setting up the database and managing
    # settings related to scripts and their scopes.
    #
    # @see Lich::Common
    class DatabaseAdapter
      # Initializes a new DatabaseAdapter instance.
      # @param data_dir [String] the directory where the database file is located
      # @param table_name [String] the name of the table to use
      # @return [void]
      def initialize(data_dir, table_name)
        @file = File.join(data_dir, "lich.db3")
        @db = Sequel.sqlite(@file)
        @table_name = table_name
        setup!
      end

      # Sets up the database table if it does not exist.
      # @return [void]
      def setup!
        @db.create_table?(@table_name) do
          text :script
          text :scope
          blob :hash
        end
        @table = @db[@table_name]
      end

      # Returns the database table object.
      # @return [Sequel::Dataset] the dataset representing the table
      def table
        @table
      end

      # Retrieves settings for a given script and scope.
      # @param script_name [String] the name of the script to retrieve settings for
      # @param scope [String] the scope of the settings (default is ":")
      # @return [Hash] the settings for the script, or an empty hash if none found
      def get_settings(script_name, scope = ":")
        entry = @table.first(script: script_name, scope: scope)
        entry.nil? ? {} : Marshal.load(entry[:hash])
      end

      # Saves settings for a given script and scope.
      # @param script_name [String] the name of the script to save settings for
      # @param settings [Hash] the settings to save
      # @param scope [String] the scope of the settings (default is ":")
      # @return [Boolean] true if settings were saved successfully, false otherwise
      # @example Save settings for a script
      #   adapter.save_settings("my_script", { key: "value" })
      def save_settings(script_name, settings, scope = ":")
        unless settings.is_a?(Hash)
          Lich::Messaging.msg("error", "--- Error: Report this - settings must be a Hash, got #{settings.class} ---")
          Lich.log("--- Error: settings must be a Hash, got #{settings.class} from call initiated by #{script_name} ---")
          Lich.log(settings.inspect)
          return false
        end

        begin
          blob = Sequel::SQL::Blob.new(Marshal.dump(settings))
        rescue => e
          Lich::Messaging.msg("error", "--- Error: failed to serialize settings ---")
          Lich.log("--- Error: failed to serialize settings ---")
          Lich.log("#{e.message}\n#{e.backtrace.join("\n")}")
          return false
        end

        begin
          @table
            .insert_conflict(target: [:script, :scope], update: { hash: blob })
            .insert(script: script_name, scope: scope, hash: blob)
          return true
        rescue Sequel::DatabaseError => db_err
          Lich::Messaging.msg("error", "--- Database error while saving settings ---")
          Lich.log("--- Database error while saving settings ---")
          Lich.log("#{db_err.message}\n#{db_err.backtrace.join("\n")}")
        rescue => e
          Lich::Messaging.msg("error", "--- Unexpected error while saving settings ---")
          Lich.log("--- Unexpected error while saving settings ---")
          Lich.log("#{e.message}\n#{e.backtrace.join("\n")}")
        end

        false
      end
    end
  end
end
