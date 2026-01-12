require "ostruct"

# Contains the Lich module and its related functionalities
# @example Including the Lich module
#   include Lich
module Lich
  module Gemstone
    # Provides methods to access experience-related data
    # @example Accessing experience data
    #   Lich::Gemstone::Experience.fame
    module Experience
      # Retrieves the current fame value
      # @return [Integer] The current fame value
      # @example
      #   Lich::Gemstone::Experience.fame
      def self.fame
        Infomon.get("experience.fame")
      end

      # Retrieves the current field experience
      # @return [Integer] The current field experience
      # @example
      #   Lich::Gemstone::Experience.fxp_current
      def self.fxp_current
        Infomon.get("experience.field_experience_current")
      end

      # Retrieves the maximum field experience
      # @return [Integer] The maximum field experience
      # @example
      #   Lich::Gemstone::Experience.fxp_max
      def self.fxp_max
        Infomon.get("experience.field_experience_max")
      end

      # Retrieves the current experience
      # @return [Integer] The current experience
      # @example
      #   Lich::Gemstone::Experience.exp
      def self.exp
        Stats.exp
      end

      # Retrieves the current ascension experience
      # @return [Integer] The current ascension experience
      # @example
      #   Lich::Gemstone::Experience.axp
      def self.axp
        Infomon.get("experience.ascension_experience")
      end

      # Retrieves the total experience
      # @return [Integer] The total experience
      # @example
      #   Lich::Gemstone::Experience.txp
      def self.txp
        Infomon.get("experience.total_experience")
      end

      # Calculates the percentage of current field experience to maximum field experience
      # @return [Float] The percentage of current field experience
      # @example
      #   Lich::Gemstone::Experience.percent_fxp
      def self.percent_fxp
        (fxp_current.to_f / fxp_max.to_f) * 100
      end

      # Calculates the percentage of ascension experience to total experience
      # @return [Float] The percentage of ascension experience
      # @example
      #   Lich::Gemstone::Experience.percent_axp
      def self.percent_axp
        (axp.to_f / txp.to_f) * 100
      end

      # Calculates the percentage of current experience to total experience
      # @return [Float] The percentage of current experience
      # @example
      #   Lich::Gemstone::Experience.percent_exp
      def self.percent_exp
        (exp.to_f / txp.to_f) * 100
      end

      # Retrieves the long-term experience
      # @return [Integer] The long-term experience
      # @example
      #   Lich::Gemstone::Experience.lte
      def self.lte
        Infomon.get("experience.long_term_experience")
      end

      # Retrieves the number of deeds
      # @return [Integer] The number of deeds
      # @example
      #   Lich::Gemstone::Experience.deeds
      def self.deeds
        Infomon.get("experience.deeds")
      end

      # Retrieves the deaths sting value
      # @return [Integer] The deaths sting value
      # @example
      #   Lich::Gemstone::Experience.deaths_sting
      def self.deaths_sting
        Infomon.get("experience.deaths_sting")
      end

      # Retrieves the last updated timestamp for total experience
      # @return [Time, nil] The last updated time or nil if not available
      # @example
      #   Lich::Gemstone::Experience.updated_at
      def self.updated_at
        timestamp = Infomon.get_updated_at("experience.total_experience")
        timestamp ? Time.at(timestamp) : nil
      end

      # Checks if the experience data is stale based on a given threshold
      # @param threshold [ActiveSupport::Duration] The duration threshold to check against
      # @return [Boolean] True if stale, false otherwise
      # @example
      #   Lich::Gemstone::Experience.stale?(24.hours)
      def self.stale?(threshold: 24.hours)
        return true unless updated_at
        updated_at < threshold.ago
      end

      # Checks if the experience data was recently updated based on a given threshold
      # @param threshold [ActiveSupport::Duration] The duration threshold to check against
      # @return [Boolean] True if recently updated, false otherwise
      # @example
      #   Lich::Gemstone::Experience.recently_updated?(5.minutes)
      def self.recently_updated?(threshold: 5.minutes)
        return false unless updated_at
        updated_at >= threshold.ago
      end
    end
  end
end
