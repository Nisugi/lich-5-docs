module Lich
  module DragonRealms
    # Manages flags and matchers for the DragonRealms module.
    # This class allows for the addition, retrieval, and management of flags and their associated matchers.
    # @example Adding a flag
    #   Flags.add(:example_flag, 'example')
    class Flags
      @@flags = {}
      @@matchers = {}

      # Retrieves the value of a flag by its key.
      # @param key [Symbol] The key of the flag to retrieve.
      # @return [Boolean, nil] The value of the flag or nil if not found.
      # @example Retrieving a flag
      #   value = Flags[:example_flag]
      def self.[](key)
        @@flags[key]
      end

      # Sets the value of a flag by its key.
      # @param key [Symbol] The key of the flag to set.
      # @param value [Boolean] The value to assign to the flag.
      # @return [Boolean] The value that was set.
      # @example Setting a flag
      #   Flags[:example_flag] = true
      def self.[]=(key, value)
        @@flags[key] = value
      end

      # Adds a new flag with associated matchers.
      # @param key [Symbol] The key for the new flag.
      # @param matchers [Array<String, Regexp>] The matchers associated with the flag.
      # @return [void]
      # @example Adding a flag with matchers
      #   Flags.add(:example_flag, 'example', /test/i)
      def self.add(key, *matchers)
        @@flags[key] = false
        @@matchers[key] = matchers.map { |item| item.is_a?(Regexp) ? item : /#{item}/i }
      end

      # Resets the value of a flag to false.
      # @param key [Symbol] The key of the flag to reset.
      # @return [void]
      # @example Resetting a flag
      #   Flags.reset(:example_flag)
      def self.reset(key)
        @@flags[key] = false
      end

      # Deletes a flag and its associated matchers.
      # @param key [Symbol] The key of the flag to delete.
      # @return [void]
      # @example Deleting a flag
      #   Flags.delete(:example_flag)
      def self.delete(key)
        @@matchers.delete key
        @@flags.delete key
      end

      # Returns all flags as a hash.
      # @return [Hash<Symbol, Boolean>] A hash of all flags and their values.
      # @example Getting all flags
      #   all_flags = Flags.flags
      def self.flags
        @@flags
      end

      # Returns all matchers as a hash.
      # @return [Hash<Symbol, Array<Regexp>] A hash of all matchers associated with flags.
      # @example Getting all matchers
      #   all_matchers = Flags.matchers
      def self.matchers
        @@matchers
      end
    end
  end
end
