require "ostruct"

# The Lich module contains functionality related to the Lich game.
#
# @see Lich::Gemstone
module Lich
  module Gemstone
    # The Experience module provides methods to access and calculate experience-related data.
    #
    # @see Lich::Gemstone
    module Experience
      # Retrieves the current fame value.
      # @return [Integer] the current fame value.
      # @example Get current fame
      #   Lich::Gemstone::Experience.fame
      def self.fame
        Infomon.get("experience.fame")
      end

      # Retrieves the current field experience value.
      # @return [Integer] the current field experience value.
      # @example Get current field experience
      #   Lich::Gemstone::Experience.fxp_current
      def self.fxp_current
        Infomon.get("experience.field_experience_current")
      end

      # Retrieves the maximum field experience value.
      # @return [Integer] the maximum field experience value.
      # @example Get maximum field experience
      #   Lich::Gemstone::Experience.fxp_max
      def self.fxp_max
        Infomon.get("experience.field_experience_max")
      end

      # Retrieves the current experience value.
      # @return [Integer] the current experience value.
      # @example Get current experience
      #   Lich::Gemstone::Experience.exp
      def self.exp
        Stats.exp
      end

      # Retrieves the current ascension experience value.
      # @return [Integer] the current ascension experience value.
      # @example Get current ascension experience
      #   Lich::Gemstone::Experience.axp
      def self.axp
        Infomon.get("experience.ascension_experience")
      end

      # Retrieves the total experience value.
      # @return [Integer] the total experience value.
      # @example Get total experience
      #   Lich::Gemstone::Experience.txp
      def self.txp
        Infomon.get("experience.total_experience")
      end

      # Calculates the percentage of current field experience relative to maximum field experience.
      # @return [Float] the percentage of current field experience.
      # @example Get percentage of current field experience
      #   Lich::Gemstone::Experience.percent_fxp
      def self.percent_fxp
        (fxp_current.to_f / fxp_max.to_f) * 100
      end

      # Calculates the percentage of ascension experience relative to total experience.
      # @return [Float] the percentage of ascension experience.
      # @example Get percentage of ascension experience
      #   Lich::Gemstone::Experience.percent_axp
      def self.percent_axp
        (axp.to_f / txp.to_f) * 100
      end

      # Calculates the percentage of current experience relative to total experience.
      # @return [Float] the percentage of current experience.
      # @example Get percentage of current experience
      #   Lich::Gemstone::Experience.percent_exp
      def self.percent_exp
        (exp.to_f / txp.to_f) * 100
      end

      # Retrieves the long-term experience value.
      # @return [Integer] the long-term experience value.
      # @example Get long-term experience
      #   Lich::Gemstone::Experience.lte
      def self.lte
        Infomon.get("experience.long_term_experience")
      end

      # Retrieves the deeds value.
      # @return [Integer] the deeds value.
      # @example Get deeds
      #   Lich::Gemstone::Experience.deeds
      def self.deeds
        Infomon.get("experience.deeds")
      end

      # Retrieves the deaths sting value.
      # @return [Integer] the deaths sting value.
      # @example Get deaths sting
      #   Lich::Gemstone::Experience.deaths_sting
      def self.deaths_sting
        Infomon.get("experience.deaths_sting")
      end

      # Retrieves the timestamp of the last update for total experience.
      # @return [Time, nil] the last updated timestamp or nil if not available.
      # @example Get last updated timestamp
      #   Lich::Gemstone::Experience.updated_at
      def self.updated_at
        timestamp = Infomon.get_updated_at("experience.total_experience")
        timestamp ? Time.at(timestamp) : nil
      end

      # Checks if the experience data is stale based on the given threshold.
      # @param threshold [Integer] the time threshold to check against in hours.
      # @return [Boolean] true if stale, false otherwise.
      # @example Check if experience data is stale
      #   Lich::Gemstone::Experience.stale?(24)
      def self.stale?(threshold: 24.hours)
        return true unless updated_at
        updated_at < threshold.ago
      end

      # Checks if the experience data was updated recently based on the given threshold.
      # @param threshold [Integer] the time threshold to check against in minutes.
      # @return [Boolean] true if recently updated, false otherwise.
      # @example Check if experience data was recently updated
      #   Lich::Gemstone::Experience.recently_updated?(5)
      def self.recently_updated?(threshold: 5.minutes)
        return false unless updated_at
        updated_at >= threshold.ago
      end
    end
  end
end
