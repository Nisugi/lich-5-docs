
module Lich
  module Common
    # Represents an array with a maximum size limit.
    # This class extends the standard Array class to enforce a maximum size.
    # When the limit is reached, the oldest elements are removed.
    # @example Creating a LimitedArray
    #   limited_array = Lich::Common::LimitedArray.new(5)
    class LimitedArray < Array
      attr_accessor :max_size

      # Initializes a new LimitedArray instance.
      # @param size [Integer] The initial size of the array (default is 0).
      # @param obj [Object] The object to initialize the array with (default is nil).
      # @return [LimitedArray]
      def initialize(size = 0, obj = nil)
        @max_size = 200
        super
      end

      # Adds an element to the array, removing the oldest elements if the maximum size is exceeded.
      # @param line [Object] The element to add to the array.
      # @return [Object] The element that was added.
      def push(line)
        self.shift while self.length >= @max_size
        super
      end

      # Adds an element to the array, similar to push.
      # @param line [Object] The element to add to the array.
      # @return [Object] The element that was added.
      # @note This method is an alias for push.
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
