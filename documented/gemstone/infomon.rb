# frozen_string_literal: true

# Replacement for the venerable infomon.lic script used in Lich4 and Lich5 (03/01/23)
# Supports Ruby 3.X builds
#
#     maintainer: elanthia-online
#   contributors: Tillmen, Shaelun, Athias
#           game: Gemstone
#           tags: core
#       required: Lich > 5.6.2
#        version: 2.0
#         Source: https://github.com/elanthia-online/scripts

require 'sequel'
require 'tmpdir'
require 'logger'
require 'timeout'
require_relative 'infomon/cache'
require_relative '../common/watchable'

module Lich
  module Gemstone
    # Module for Infomon functionality
    # This module provides methods to manage and interact with the Infomon database.
    # @example Using Infomon
    #   Infomon.set("key", "value")
    module Infomon
      extend Lich::Common::Watchable
      $infomon_debug = ENV["DEBUG"]
      # use temp dir in ci context
      @root = defined?(DATA_DIR) ? DATA_DIR : Dir.tmpdir
      @file = File.join(@root, "infomon.db")
      @db   = Sequel.sqlite(@file)
      @cache ||= Infomon::Cache.new
      @cache_loaded = false
      @db.loggers << Logger.new($stdout) if ENV["DEBUG"]
      @sql_queue ||= Queue.new
      @sql_mutex ||= Mutex.new

      # Returns the cache object
      # @return [Cache] The cache instance used by Infomon.
      def self.cache
        @cache
      end

      # Returns the file path for the database
      # @return [String] The path to the database file.
      def self.file
        @file
      end

      # Returns the database connection
      # @return [Sequel::Database] The Sequel database connection.
      def self.db
        @db
      end

      # Returns the mutex for thread safety
      # @return [Mutex] The mutex used for synchronizing access.
      def self.mutex
        @sql_mutex
      end

      # Locks the mutex to ensure thread safety
      # @raise [StandardError] If an error occurs while locking the mutex.
      def self.mutex_lock
        begin
          self.mutex.lock unless self.mutex.owned?
        rescue StandardError
          respond "--- Lich: error: Infomon.mutex_lock: #{$!}"
          Lich.log "error: Infomon.mutex_lock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Unlocks the mutex to allow other threads access
      # @raise [StandardError] If an error occurs while unlocking the mutex.
      def self.mutex_unlock
        begin
          self.mutex.unlock if self.mutex.owned?
        rescue StandardError
          respond "--- Lich: error: Infomon.mutex_unlock: #{$!}"
          Lich.log "error: Infomon.mutex_unlock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Returns the SQL queue
      # @return [Queue] The queue for SQL statements.
      def self.queue
        @sql_queue
      end

      # Returns the current UTC timestamp
      # @return [Float] The current timestamp in UTC.
      def self.current_timestamp
        Time.now.utc.to_f
      end

      # Checks if the context is valid before accessing Infomon
      # @raise [RuntimeError] If XMLData.name is not loaded.
      def self.context!
        return unless XMLData.name.empty? or XMLData.name.nil?
        puts Exception.new.backtrace
        fail "cannot access Infomon before XMLData.name is loaded"
      end

      # Returns the table name based on game and character name
      # @return [Symbol] The table name for the current context.
      def self.table_name
        self.context!
        ("%s_%s" % [XMLData.game, XMLData.name]).to_sym
      end

      # Resets the Infomon state by dropping the table and clearing the cache
      # @return [void]
      def self.reset!
        self.mutex_lock
        Infomon.db.drop_table?(self.table_name)
        self.cache.clear
        @cache_loaded = false
        Infomon.setup!
      end

      # Returns the database table for Infomon
      # @return [Sequel::Dataset] The dataset for the Infomon table.
      def self.table
        @_table ||= self.setup!
      end

      # Sets up the Infomon database table if it doesn't exist
      # @return [Sequel::Dataset] The dataset for the Infomon table.
      def self.setup!
        self.mutex_lock

        # Check if table exists but missing updated_at column
        if @db.table_exists?(self.table_name)
          columns = @db.schema(self.table_name).map { |col| col[0] }
          unless columns.include?(:updated_at)
            self.mutex_unlock
            self.reset!
            return
          end
        end

        @db.create_table?(self.table_name) do
          text :key, primary_key: true
          any :value
          float :updated_at
        end
        self.mutex_unlock
        @_table = @db[self.table_name]
      end

      # Loads the cache from the database
      # @return [void]
      def self.cache_load
        sleep(0.01) if XMLData.name.empty?
        dataset = Infomon.table
        h = dataset.map(:key).zip(dataset.map(:value)).to_h
        self.cache.merge!(h)
        @cache_loaded = true
      end

      # Normalizes the key for storage
      # @param key [String, Symbol] The key to normalize
      # @return [String] The normalized key.
      def self._key(key)
        key.to_s.downcase.tr(' -', '_').gsub(/_+/, '_')
      end

      # Normalizes the value for storage
      # @param val [Object] The value to normalize
      # @return [Object] The normalized value.
      def self._value(val)
        return true if val.to_s == "true"
        return false if val.to_s == "false"
        return val
      end

      # Allowed types for values in Infomon
      # @constant [Array<Class>] List of allowed types.
      AllowedTypes = [Integer, String, NilClass, FalseClass, TrueClass]
      # Validates the key and value types
      # @param key [String] The key to validate
      # @param value [Object] The value to validate
      # @return [Object] The validated value.
      # @raise [RuntimeError] If the value type is not allowed.
      def self._validate!(key, value)
        return self._value(value) if AllowedTypes.include?(value.class)
        raise "infomon:insert(%s) was called with %s\nmust be %s\nvalue=%s" % [key, value.class, AllowedTypes.map(&:name).join("|"), value]
      end

      # Retrieves a value from the cache or database
      # @param key [String] The key to retrieve
      # @return [Object, nil] The value associated with the key, or nil if not found.
      def self.get(key)
        self.cache_load if !@cache_loaded
        key = self._key(key)
        val = self.cache.get(key) {
          # Flush queue before reading from DB to ensure we see latest writes
          self.flush
          begin
            self.mutex.synchronize do
              begin
                db_result = self.table[key: key]
                if db_result
                  db_result[:value]
                else
                  nil
                end
              rescue => exception
                pp(exception)
                nil
              end
            end
          rescue StandardError
            respond "--- Lich: error: Infomon.get(#{key}): #{$!}"
            Lich.log "error: Infomon.get(#{key}): #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        }
        return self._value(val)
      end

      # Retrieves a boolean value from the cache or database
      # @param key [String] The key to retrieve
      # @return [Boolean] The boolean value associated with the key.
      def self.get_bool(key)
        value = Infomon.get(key)
        if value.is_a?(TrueClass) || value.is_a?(FalseClass)
          return value
        elsif value == 1
          return true
        else
          return false
        end
      end

      # Retrieves the updated timestamp for a key
      # @param key [String] The key to retrieve the timestamp for
      # @return [Float, nil] The updated timestamp, or nil if not found.
      def self.get_updated_at(key)
        key = self._key(key)
        begin
          self.mutex.synchronize do
            db_result = self.table[key: key]
            if db_result
              db_result[:updated_at]
            else
              nil
            end
          end
        rescue StandardError
          respond "--- Lich: error: Infomon.get_updated_at(#{key}): #{$!}"
          Lich.log "error: Infomon.get_updated_at(#{key}): #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          nil
        end
      end

      # Inserts or replaces a key-value pair in the database
      # @param args [Array] The key-value pairs to insert
      # @return [void]
      def self.upsert(*args)
        self.table
            .insert_conflict(:replace)
            .insert(*args)
      end

      # Sets a key-value pair in the cache and database
      # @param key [String] The key to set
      # @param value [Object] The value to set
      # @return [Symbol] :noop if the value is unchanged, otherwise performs the operation.
      def self.set(key, value)
        key = self._key(key)
        value = self._validate!(key, value)
        return :noop if self.cache.get(key) == value
        self.cache.put(key, value)
        self.queue << "INSERT OR REPLACE INTO %s (`key`, `value`, `updated_at`) VALUES (%s, %s, %s)
      on conflict(`key`) do update set value = excluded.value, updated_at = excluded.updated_at;" % [self.db.literal(self.table_name), self.db.literal(key), self.db.literal(value), current_timestamp]
      end

      # Deletes a key from the cache and database
      # @param key [String] The key to delete
      # @return [void]
      def self.delete!(key)
        key = self._key(key)
        self.cache.delete(key)
        self.queue << "DELETE FROM %s WHERE key = (%s);" % [self.db.literal(self.table_name), self.db.literal(key)]
      end

      # Flushes the SQL queue, executing all queued statements
      # @param timeout_seconds [Integer] The timeout for flushing
      # @return [Boolean] True if flushed successfully, false if timed out.
      def self.flush(timeout_seconds: 5)
        return true if self.queue.empty?

        # Create a barrier token - a Queue that the worker will signal when reached
        barrier = ::Queue.new
        self.queue << barrier

        # Wait for the worker to signal completion (with timeout)
        begin
          ::Timeout.timeout(timeout_seconds) { barrier.pop }
          true
        rescue ::Timeout::Error
          Lich.log "warning: Infomon.flush timed out after #{timeout_seconds}s"
          false
        end
      end

      # Inserts or replaces multiple key-value pairs in the database
      # @param blob [Array] The key-value pairs to insert
      # @return [Symbol] :noop if no updates were made.
      def self.upsert_batch(*blob)
        updated = (blob.first.map { |k, v| [self._key(k), self._validate!(k, v)] } - self.cache.to_a)
        return :noop if updated.empty?
        now = current_timestamp
        pairs = updated.map { |key, value|
          (value.is_a?(Integer) or value.is_a?(String)) or fail "upsert_batch only works with Integer or String types"
          # add the value to the cache
          self.cache.put(key, value)
          %[(%s, %s, %s)] % [self.db.literal(key), self.db.literal(value), now]
        }.join(", ")
        # queue sql statement to run async
        self.queue << "INSERT OR REPLACE INTO %s (`key`, `value`, `updated_at`) VALUES %s
      on conflict(`key`) do update set value = excluded.value, updated_at = excluded.updated_at;" % [self.db.literal(self.table_name), pairs]
      end

      Thread.new do
        loop do
          item = Infomon.queue.pop
          begin
            # Handle flush barrier tokens - signal completion and continue
            if item.is_a?(Queue)
              item << :flushed
              next
            end

            # Normal SQL statement processing
            Infomon.mutex.synchronize do
              begin
                Infomon.db.run(item)
              rescue StandardError => e
                pp(e)
              end
            end
          rescue StandardError
            respond "--- Lich: error: Infomon ThreadQueue: #{$!}"
            Lich.log "error: Infomon ThreadQueue: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        end
      end

      # Starts a thread to watch for game state changes
      # @return [void]
      def self.watch!
        @init_thread ||= Thread.new do
          begin
            # Wait for character to be ready and dialogs to load
            sleep 0.1 until GameBase::Game.autostarted? && XMLData.name && !XMLData.name.empty? &&
                            !XMLData.dialogs.empty?

            # Run initial setup if needed (GS-specific only, skip for DR)
            if XMLData.game !~ /^DR/ && db_refresh_needed?
              ExecScript.start("Infomon.redo!", { quiet: true, name: "infomon_reset" })
            end

            PostLoad.game_loaded! if defined?(PostLoad)
          rescue StandardError => e
            respond 'Error in Infomon initialization thread'
            respond e.inspect
          end
        end
      end

      require_relative 'infomon/parser'
      require_relative 'infomon/xmlparser'
      require_relative 'infomon/cli'
    end
  end
end
