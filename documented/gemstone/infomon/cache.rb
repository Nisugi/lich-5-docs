module Lich
  module Gemstone
    module Infomon
      # Represents a cache for storing records.
      # This class provides methods to put, get, delete, and check for records.
      # @example Creating a cache and using it
      #   cache = Lich::Gemstone::Infomon::Cache.new
      #   cache.put(:key, "value")
      class Cache
        attr_reader :records

        # Initializes a new Cache instance.
        # @return [Cache] The new Cache instance.
        def initialize()
          @records = {}
        end

        # Stores a value in the cache with the given key.
        # @param key [Object] The key to store the value under.
        # @param value [Object] The value to store in the cache.
        # @return [Cache] The Cache instance for method chaining.
        # @example Putting a value in the cache
        #   cache.put(:key, "value")
        def put(key, value)
          @records[key] = value
          self
        end

        # Checks if the cache includes a record with the given key.
        # @param key [Object] The key to check for existence.
        # @return [Boolean] True if the key exists, false otherwise.
        # @example Checking for a key in the cache
        #   cache.include?(:key)
        def include?(key)
          @records.include?(key)
        end

        # Clears all records from the cache.
        # @return [void]
        def flush!
          @records.clear
        end

        # Deletes a record from the cache by its key.
        # @param key [Object] The key of the record to delete.
        # @return [Object, nil] The deleted value, or nil if the key was not found.
        # @example Deleting a key from the cache
        #   cache.delete(:key)
        def delete(key)
          @records.delete(key)
        end

        # Retrieves a value from the cache by its key, or computes it if not present.
        # @param key [Object] The key of the record to retrieve.
        # @yield block to compute the value if the key is not found.
        # @return [Object, nil] The value associated with the key, or nil if not found and block returns nil.
        # @example Getting a value from the cache
        #   value = cache.get(:key) { "computed value" }
        def get(key)
          return @records[key] if self.include?(key)
          miss = nil
          miss = yield(key) if block_given?
          # don't cache nils
          return miss if miss.nil?
          @records[key] = miss
        end

        # Merges another hash into the cache.
        # @param h [Hash] The hash to merge into the cache.
        # @return [Hash] The updated records hash.
        def merge!(h)
          @records.merge!(h)
        end

        # Converts the cache records to an array of key-value pairs.
        # @return [Array] An array representation of the cache records.
        def to_a()
          @records.to_a
        end

        # Returns the records as a hash.
        # @return [Hash] The hash of records in the cache.
        def to_h()
          @records
        end

        alias :clear :flush!
        alias :key? :include?
      end
    end
  end
end
