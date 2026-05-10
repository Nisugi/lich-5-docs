# frozen_string_literal: true

require 'sqlite3'

module Lich
  module Common
    # Handles database interactions for session management.
    #
    # This class provides methods to upsert, find, delete, and query sessions.
    #
    # @see Lich::Common
    class SessionDatabaseAdapter
      DEFAULT_TABLE_NAME = 'session_summary_state'

      # Initializes a new SessionDatabaseAdapter instance.
      # @param db [SQLite3::Database, nil] the database connection (optional)
      # @param data_dir [String] the directory where the database file is located
      # @param table_name [String] the name of the table to use for sessions
      # @return [SessionDatabaseAdapter]
      def initialize(db: nil, data_dir: DATA_DIR, table_name: DEFAULT_TABLE_NAME)
        @db = db || SQLite3::Database.new(File.join(data_dir, 'lich.db3'))
        @table_name = table_name
      end

      # Inserts or updates a session in the database.
      #
      # This method will insert a new session or update an existing one based on the provided payload.
      # @param payload [Hash] the session data to upsert
      # @return [void]
      def upsert_session(payload)
        with_retry do
          @db.execute(<<~SQL, bind_params(payload))
            INSERT INTO #{@table_name} (
              pid, session_name, role, state, frontend, game_code, hidden,
              started_at, last_heartbeat_at, os_seen_at, os_seen, os_name, last_utilization_at, metadata_json
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(pid) DO UPDATE SET
              session_name = COALESCE(excluded.session_name, #{@table_name}.session_name),
              role = COALESCE(excluded.role, #{@table_name}.role),
              state = COALESCE(excluded.state, #{@table_name}.state),
              frontend = COALESCE(excluded.frontend, #{@table_name}.frontend),
              game_code = COALESCE(excluded.game_code, #{@table_name}.game_code),
              hidden = COALESCE(excluded.hidden, #{@table_name}.hidden),
              started_at = COALESCE(excluded.started_at, #{@table_name}.started_at),
              last_heartbeat_at = COALESCE(excluded.last_heartbeat_at, #{@table_name}.last_heartbeat_at),
              os_seen_at = COALESCE(excluded.os_seen_at, #{@table_name}.os_seen_at),
              os_seen = COALESCE(excluded.os_seen, #{@table_name}.os_seen),
              os_name = COALESCE(excluded.os_name, #{@table_name}.os_name),
              last_utilization_at = COALESCE(excluded.last_utilization_at, #{@table_name}.last_utilization_at),
              metadata_json = COALESCE(excluded.metadata_json, #{@table_name}.metadata_json);
          SQL
        end
      end

      # Retrieves all active sessions from the database.
      # @return [Array<Hash>] an array of hashes representing active sessions
      def active_sessions
        with_retry do
          rows_as_hashes("SELECT * FROM #{@table_name} ORDER BY pid ASC;")
        end
      end

      # Deletes a session from the database by its process ID.
      # @param pid [Integer] the process ID of the session to delete
      # @return [void]
      def delete_session(pid:)
        with_retry do
          @db.execute("DELETE FROM #{@table_name} WHERE pid = ?;", [pid])
        end
      end

      # Finds a session by its process ID.
      # @param pid [Integer] the process ID of the session to find
      # @return [Hash, nil] the session data as a hash, or nil if not found
      def find_session(pid:)
        with_retry do
          rows_as_hashes("SELECT * FROM #{@table_name} WHERE pid = ? LIMIT 1;", [pid.to_i]).first
        end
      end

      # Retrieves session names that have duplicates in the active sessions.
      # @return [Array<Hash>] an array of hashes containing session names and their duplicate counts
      def duplicate_active_session_names
        with_retry do
          rows_as_hashes(<<~SQL)
            SELECT session_name, COUNT(*) AS duplicate_count
            FROM #{@table_name}
            WHERE session_name IS NOT NULL
              AND session_name != ''
              AND COALESCE(state, '') != 'exited'
            GROUP BY session_name
            HAVING COUNT(*) > 1
            ORDER BY session_name ASC;
          SQL
        end
      end

      # Retrieves sessions that are currently tracked and not exited.
      # @return [Array<Hash>] an array of hashes representing tracked live candidates
      def tracked_live_candidates
        with_retry do
          rows_as_hashes(<<~SQL)
            SELECT * FROM #{@table_name}
            WHERE COALESCE(state, '') != 'exited'
            ORDER BY pid ASC;
          SQL
        end
      end

      private

      def bind_params(payload)
        [
          payload[:pid],
          payload[:session_name],
          payload[:role],
          payload[:state],
          payload[:frontend],
          payload[:game_code],
          payload.key?(:hidden) ? payload[:hidden] : nil,
          payload[:started_at],
          payload[:last_heartbeat_at],
          payload[:os_seen_at],
          payload.key?(:os_seen) ? payload[:os_seen] : nil,
          payload.key?(:os_name) ? payload[:os_name] : nil,
          payload[:last_utilization_at],
          payload[:metadata_json]
        ]
      end

      def rows_as_hashes(sql, binds = [])
        rows_with_headers = @db.execute2(sql, binds)
        headers = rows_with_headers.shift || []
        rows_with_headers.map do |row|
          if row.is_a?(Array)
            headers.each_with_index.with_object({}) do |(column, idx), cleaned|
              cleaned[column] = row[idx]
            end
          else
            headers.each_with_object({}) do |column, cleaned|
              cleaned[column] = row[column]
            end
          end
        end
      end

      def with_retry(max_attempts = 5)
        attempts = 0
        begin
          attempts += 1
          yield
        rescue SQLite3::BusyException
          raise if attempts >= max_attempts

          sleep(0.05 * attempts)
          retry
        end
      end
    end
  end
end
