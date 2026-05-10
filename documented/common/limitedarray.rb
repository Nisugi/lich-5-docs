
module Lich
  module Common
    # Represents an array with a maximum size limit.
    #
    # This class extends the standard Array to enforce a maximum size,
    # automatically removing the oldest elements when the limit is reached.
    #
    # @see Array
    class LimitedArray < Array
      attr_accessor :max_size

      # Initializes a new LimitedArray instance.
      #
      # @param size [Integer] the initial size of the array (default is 0)
      # @param obj [Object, nil] an optional object to initialize the array with
      # @return [LimitedArray] the newly created LimitedArray instance
      def initialize(size = 0, obj = nil)
        @max_size = 200
        super
      end

      # Adds an element to the LimitedArray.
      #
      # If the array has reached its maximum size, the oldest elements are removed
      # to make space for the new element.
      #
      # @param line [Object] the element to add to the array
      # @return [Object] the element that was added
      def push(line)
        self.shift while self.length >= @max_size
        super
      end

      # Adds an element to the LimitedArray (alias for #push).
      #
      # @param line [Object] the element to add to the array
      # @return [Object] the element that was added
      # @api private
      def shove(line)
        push(line)
      end

      # Returns an empty array representing the history.
      #
      # This method is a placeholder and does not currently store any history.
      #
      # @return [Array] an empty array
      def history
        Array.new
      end
    end
  end
end
