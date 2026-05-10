module Lich
  module Gemstone
    module Infomon
      # Represents a cache for storing key-value pairs.
      #
      # This class provides methods to put, get, delete, and check for keys in the cache.
      #
      # @see Lich::Gemstone::Infomon
      class Cache
        attr_reader :records

        # Initializes a new Cache instance.
        # @return [Cache] the new Cache instance
        def initialize()
          @records = {}
        end

        # Stores a value in the cache associated with the given key.
        # @param key [String] the key to store the value under
        # @param value [Object] the value to store
        # @return [Cache] the Cache instance for method chaining
        def put(key, value)
          @records[key] = value
          self
        end

        # Checks if the cache includes the given key.
        # @param key [String] the key to check
        # @return [Boolean] true if the key exists in the cache, false otherwise
        def include?(key)
          @records.include?(key)
        end

        # Clears all records from the cache.
        # @return [void]
        def flush!
          @records.clear
        end

        # Deletes the value associated with the given key from the cache.
        # @param key [String] the key to delete
        # @return [Object, nil] the deleted value, or nil if the key was not found
        def delete(key)
          @records.delete(key)
        end

        # Retrieves the value associated with the given key from the cache.
        # If the key does not exist, it yields to a block if given.
        # @param key [String] the key to retrieve the value for
        # @return [Object, nil] the value associated with the key, or nil if not found and no block is given
        # @yieldparam key [String] the key that was not found in the cache
        def get(key)
          return @records[key] if self.include?(key)
          miss = nil
          miss = yield(key) if block_given?
          # don't cache nils
          return miss if miss.nil?
          @records[key] = miss
        end

        # Merges the given hash into the cache.
        # @param h [Hash] a hash of key-value pairs to merge into the cache
        # @return [Hash] the updated records in the cache
        def merge!(h)
          @records.merge!(h)
        end

        # Converts the cache records to an array of key-value pairs.
        # @return [Array<Array>] an array of key-value pairs
        def to_a()
          @records.to_a
        end

        # Returns the cache records as a hash.
        # @return [Hash] the records in the cache
        def to_h()
          @records
        end

        alias :clear :flush!
        alias :key? :include?
      end
    end
  end
end
