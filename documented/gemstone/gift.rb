
module Lich
  module Gemstone
    # Represents a gift in the Lich Gemstone module.
    # This class manages the state of a gift including its start time and pulse count.
    # @example Creating and using a gift
    #   Lich::Gemstone::Gift.init_gift
    #   Lich::Gemstone::Gift.pulse
    class Gift
      class << self
        attr_reader :gift_start, :pulse_count

        # Initializes the gift state.
        # Sets the gift start time to the current time and resets the pulse count.
        # @return [void]
        # @example Initializing a gift
        #   Lich::Gemstone::Gift.init_gift
        def init_gift
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Marks the gift as started.
        # Resets the pulse count and updates the gift start time to the current time.
        # @return [void]
        # @example Starting a gift
        #   Lich::Gemstone::Gift.started
        def started
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Increments the pulse count by one.
        # @return [void]
        # @example Incrementing pulse count
        #   Lich::Gemstone::Gift.pulse
        def pulse
          @pulse_count += 1
        end

        # Calculates the remaining time for the gift in seconds.
        # @return [Float] The remaining time in seconds.
        # @example Getting remaining time
        #   remaining_time = Lich::Gemstone::Gift.remaining
        def remaining
          ([360 - @pulse_count, 0].max * 60).to_f
        end

        # Calculates the time when the gift will restart.
        # @return [Time] The time when the gift restarts.
        # @example Getting restart time
        #   restart_time = Lich::Gemstone::Gift.restarts_on
        def restarts_on
          @gift_start + 594000
        end

        # Serializes the gift state into an array.
        # @return [Array] An array containing the gift start time and pulse count.
        # @example Serializing a gift
        #   serialized_data = Lich::Gemstone::Gift.serialize
        def serialize
          [@gift_start, @pulse_count]
        end

        # Loads the gift state from a serialized array.
        # @param array [Array] An array containing the gift start time and pulse count.
        # @return [void]
        # @example Loading serialized data
        #   Lich::Gemstone::Gift.load_serialized = [Time.now, 5]
        def load_serialized=(array)
          @gift_start = array[0]
          @pulse_count = array[1].to_i
        end

        # Marks the gift as ended by setting the pulse count to 360.
        # @return [void]
        # @example Ending a gift
        #   Lich::Gemstone::Gift.ended
        def ended
          @pulse_count = 360
        end

        # Placeholder method for a stopwatch feature.
        # @return [nil]
        # @example Using stopwatch
        #   Lich::Gemstone::Gift.stopwatch
        def stopwatch
          nil
        end
      end

      # Initialize the class
      init_gift
    end
  end
end
