
module Lich
  module DragonRealms
    # Manages a set of flags and their associated matchers.
    #
    # This class provides methods to add, reset, delete, and access flags.
    #
    # @see Lich::DragonRealms::Flags#add
    # @see Lich::DragonRealms::Flags#reset
    # @see Lich::DragonRealms::Flags#delete
    class Flags
      @@flags = {}
      @@matchers = {}

      # Retrieves the value of a flag by its key.
      # @param key [String] the key of the flag to retrieve
      # @return [Boolean, nil] the value of the flag or nil if not set
      def self.[](key)
        @@flags[key]
      end

      # Sets the value of a flag by its key.
      # @param key [String] the key of the flag to set
      # @param value [Boolean] the value to assign to the flag
      # @return [void]
      def self.[]=(key, value)
        @@flags[key] = value
      end

      # Adds a new flag with the specified key and matchers.
      # @param key [String] the key for the new flag
      # @param matchers [Array<Regexp, String>] one or more matchers associated with the flag
      # @return [void]
      def self.add(key, *matchers)
        @@flags[key] = false
        @@matchers[key] = matchers.map { |item| item.is_a?(Regexp) ? item : /#{item}/i }
      end

      # Resets the specified flag to false.
      # @param key [String] the key of the flag to reset
      # @return [void]
      def self.reset(key)
        @@flags[key] = false
      end

      # Deletes the specified flag and its associated matchers.
      # @param key [String] the key of the flag to delete
      # @return [void]
      def self.delete(key)
        @@matchers.delete key
        @@flags.delete key
      end

      # Returns a hash of all flags.
      # @return [Hash<String, Boolean>] a hash containing all flags and their values
      def self.flags
        @@flags
      end

      # Returns a hash of all matchers associated with flags.
      # @return [Hash<String, Array<Regexp>>] a hash containing all matchers for each flag
      def self.matchers
        @@matchers
      end
    end
  end
end
