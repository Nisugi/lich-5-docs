
module Lich
  module Gemstone
    # Represents a gift in the Lich game.
    #
    # This class manages the state of a gift, including its start time,
    # pulse count, and methods to manipulate and retrieve this data.
    #
    # @see Lich::Gemstone
    class Gift
      class << self
        attr_reader :gift_start, :pulse_count

        # Initializes the gift state.
        # Sets the start time to the current time and resets the pulse count.
        # @return [void]
        def init_gift
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Marks the gift as started.
        # Resets the pulse count and updates the start time to the current time.
        # @return [void]
        def started
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Increments the pulse count by one.
        # @return [void]
        def pulse
          @pulse_count += 1
        end

        # Calculates the remaining time for the gift in seconds.
        # @return [Float] the remaining time in seconds
        def remaining
          ([360 - @pulse_count, 0].max * 60).to_f
        end

        # Calculates the time when the gift will restart.
        # @return [Time] the time when the gift restarts
        def restarts_on
          @gift_start + 594000
        end

        # Serializes the gift state into an array.
        # @return [Array] an array containing the start time and pulse count
        def serialize
          [@gift_start, @pulse_count]
        end

        # Loads the gift state from a serialized array.
        # @param array [Array] an array containing the start time and pulse count
        # @return [void]
        def load_serialized=(array)
          @gift_start = array[0]
          @pulse_count = array[1].to_i
        end

        # Marks the gift as ended by setting the pulse count to 360.
        # @return [void]
        def ended
          @pulse_count = 360
        end

        # Placeholder method for a stopwatch functionality.
        # @return [nil]
        def stopwatch
          nil
        end
      end

      # Initialize the class
      init_gift
    end
  end
end
