# frozen_string_literal: true

module Lich
  module Gemstone
    # Gift class for tracking gift box status
    # Gift class for tracking gift box status
    #
    # This class manages the state of a gift box, including tracking the start time, pulse count, and remaining time.
    # @example Initializing a gift
    #   Lich::Gemstone::Gift.init_gift
    class Gift
      class << self
        attr_reader :gift_start, :pulse_count

        # Initializes the gift tracking system.
        # @return [void]
        # @example Initializing the gift system
        #   Lich::Gemstone::Gift.init_gift
        def init_gift
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Marks the start of a new gift session.
        # @return [void]
        # @example Starting a new gift session
        #   Lich::Gemstone::Gift.started
        def started
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Increments the pulse count by one.
        # @return [void]
        # @example Incrementing the pulse count
        #   Lich::Gemstone::Gift.pulse
        def pulse
          @pulse_count += 1
        end

        # Calculates the remaining time in seconds until the gift ends.
        # @return [Float] The remaining time in seconds
        # @example Getting remaining time
        #   remaining_time = Lich::Gemstone::Gift.remaining
        def remaining
          ([360 - @pulse_count, 0].max * 60).to_f
        end

        # Calculates the time when the gift will restart.
        # @return [Time] The restart time of the gift
        # @example Getting the restart time
        #   restart_time = Lich::Gemstone::Gift.restarts_on
        def restarts_on
          @gift_start + 594000
        end

        # Serializes the current state of the gift.
        # @return [Array] An array containing the gift start time and pulse count
        # @example Serializing the gift state
        #   serialized_data = Lich::Gemstone::Gift.serialize
        def serialize
          [@gift_start, @pulse_count]
        end

        # Loads the gift state from a serialized array.
        # @param array [Array] An array containing the gift start time and pulse count
        # @return [void]
        # @example Loading serialized data
        #   Lich::Gemstone::Gift.load_serialized = [Time.now, 5]
        def load_serialized=(array)
          @gift_start = array[0]
          @pulse_count = array[1].to_i
        end

        # Marks the gift as ended by setting the pulse count to 360.
        # @return [void]
        # @example Ending the gift session
        #   Lich::Gemstone::Gift.ended
        def ended
          @pulse_count = 360
        end

        # Placeholder method for a stopwatch feature.
        # @return [nil]
        # @example Using the stopwatch (currently does nothing)
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
