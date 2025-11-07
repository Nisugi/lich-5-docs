module Lich
  module Gemstone
    module Infomon
      # in-memory cache with db read fallbacks
      # In-memory cache with database read fallbacks
      # This class provides a simple caching mechanism that stores records in memory.
      # @example Creating a cache and using it
      #   cache = Lich::Gemstone::Infomon::Cache.new
      class Cache
        attr_reader :records

        # Initializes a new Cache instance.
        # @return [Cache] A new instance of Cache.
        def initialize()
          @records = {}
        end

        # Stores a value in the cache with the given key.
        # @param key [Object] The key to store the value under.
        # @param value [Object] The value to be cached.
        # @return [Cache] The Cache instance for method chaining.
        # @example Adding a value to the cache
        #   cache.put(:my_key, 'my_value')
        def put(key, value)
          @records[key] = value
          self
        end

        # Checks if the cache includes a given key.
        # @param key [Object] The key to check for existence.
        # @return [Boolean] True if the key exists in the cache, false otherwise.
        # @example Checking for a key in the cache
        #   cache.include?(:my_key)
        def include?(key)
          @records.include?(key)
        end

        # Clears all records from the cache.
        # @return [void]
        # @example Flushing the cache
        #   cache.flush!
        def flush!
          @records.clear
        end

        # Deletes a value from the cache by its key.
        # @param key [Object] The key of the value to delete.
        # @return [Object, nil] The deleted value, or nil if the key was not found.
        # @example Deleting a value from the cache
        #   cache.delete(:my_key)
        def delete(key)
          @records.delete(key)
        end

        # Retrieves a value from the cache by its key, or fetches it using a block if not found.
        # @param key [Object] The key of the value to retrieve.
        # @return [Object, nil] The cached value, or the result of the block if the key was not found.
        # @example Getting a value from the cache
        #   value = cache.get(:my_key) { 'default_value' }
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
        # @example Merging a hash into the cache
        #   cache.merge!({ new_key: 'new_value' })
        def merge!(h)
          @records.merge!(h)
        end

        # Converts the cache records to an array of key-value pairs.
        # @return [Array] An array representation of the cache records.
        # @example Converting cache records to an array
        #   array = cache.to_a
        def to_a()
          @records.to_a
        end

        # Returns the cache records as a hash.
        # @return [Hash] The hash representation of the cache records.
        # @example Getting the cache records as a hash
        #   hash = cache.to_h
        def to_h()
          @records
        end

        # Alias for flush! method.
        alias :clear :flush!
        # Alias for include? method.
        alias :key? :include?
      end
    end
  end
end
