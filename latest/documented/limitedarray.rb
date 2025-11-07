# Carve out from lich.rbw
# class LimitedArray 2024-06-13

module Lich
  module Common
    # Represents an array with a limited maximum size.
    # This class extends the standard Array class to enforce a maximum size.
    # @example Creating a LimitedArray
    #   limited_array = LimitedArray.new(5)
    class LimitedArray < Array
      attr_accessor :max_size

      # Initializes a new LimitedArray.
      # @param size [Integer] The initial size of the array (default is 0).
      # @param obj [Object] The object to initialize the array with (default is nil).
      # @return [LimitedArray] The newly created LimitedArray.
      def initialize(size = 0, obj = nil)
        @max_size = 200
        super
      end

      # Adds an element to the end of the array.
      # If the array exceeds the maximum size, elements are removed from the front.
      # @param line [Object] The element to add to the array.
      # @return [Object] The element that was added.
      # @example Adding an element
      #   limited_array.push('new_item')
      def push(line)
        self.shift while self.length >= @max_size
        super
      end

      # Adds an element to the end of the array (alias for push).
      # @param line [Object] The element to add to the array.
      # @return [Object] The element that was added.
      # @example Shoving an element
      #   limited_array.shove('another_item')
      def shove(line)
        push(line)
      end

      # Returns an empty array representing the history.
      # @return [Array] An empty array.
      def history
        Array.new
      end
    end
  end
end
