require "ostruct"

# Provides functionality related to the Lich game engine.
#
# @see Lich::Gemstone
module Lich
  module Gemstone
    # Module for managing experience-related data in the Lich game.
    #
    # @see Lich::Gemstone
    module Experience
      # Retrieves the current fame value.
      # @return [Integer] the current fame value
      # @see .fxp_current
      def self.fame
        Infomon.get("experience.fame")
      end

      # Retrieves the current field experience value.
      # @return [Integer] the current field experience value
      # @see .fxp_max
      def self.fxp_current
        Infomon.get("experience.field_experience_current")
      end

      # Retrieves the maximum field experience value.
      # @return [Integer] the maximum field experience value
      def self.fxp_max
        Infomon.get("experience.field_experience_max")
      end

      # Retrieves the current experience value.
      # @return [Integer] the current experience value
      def self.exp
        Stats.exp
      end

      # Retrieves the current ascension experience value.
      # @return [Integer] the current ascension experience value
      def self.axp
        Infomon.get("experience.ascension_experience")
      end

      # Retrieves the total experience value.
      # @return [Integer] the total experience value
      def self.txp
        Infomon.get("experience.total_experience")
      end

      # Calculates the percentage of current field experience relative to the maximum.
      # @return [Float] the percentage of current field experience
      def self.percent_fxp
        (fxp_current.to_f / fxp_max.to_f) * 100
      end

      # Calculates the percentage of ascension experience relative to total experience.
      # @return [Float] the percentage of ascension experience
      def self.percent_axp
        (axp.to_f / txp.to_f) * 100
      end

      # Calculates the percentage of current experience relative to total experience.
      # @return [Float] the percentage of current experience
      def self.percent_exp
        (exp.to_f / txp.to_f) * 100
      end

      # Retrieves the long-term experience value.
      # @return [Integer] the long-term experience value
      def self.lte
        Infomon.get("experience.long_term_experience")
      end

      # Retrieves the number of deeds.
      # @return [Integer] the number of deeds
      def self.deeds
        Infomon.get("experience.deeds")
      end

      # Retrieves the deaths sting value.
      # @return [Integer] the deaths sting value
      def self.deaths_sting
        Infomon.get("experience.deaths_sting")
      end

      # Retrieves the timestamp of the last update for total experience.
      # @return [Time, nil] the last updated time or nil if not available
      def self.updated_at
        timestamp = Infomon.get_updated_at("experience.total_experience")
        timestamp ? Time.at(timestamp) : nil
      end

      # Checks if the experience data is stale based on the given threshold.
      # @param threshold [Integer] the time threshold to check against in hours
      # @return [Boolean] true if stale, false otherwise
      def self.stale?(threshold: 24.hours)
        return true unless updated_at
        updated_at < threshold.ago
      end

      # Checks if the experience data was updated recently based on the given threshold.
      # @param threshold [Integer] the time threshold to check against in minutes
      # @return [Boolean] true if recently updated, false otherwise
      def self.recently_updated?(threshold: 5.minutes)
        return false unless updated_at
        updated_at >= threshold.ago
      end
    end
  end
end
