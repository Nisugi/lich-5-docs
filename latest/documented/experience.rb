require "ostruct"

# Provides functionality related to the Lich game.
# @example
#   module Lich
#     # Your code here
#   end
module Lich
  # Contains methods related to gemstones in the Lich game.
  # @example
  #   module Gemstone
  #     # Your code here
  #   end
  module Gemstone
    # Provides methods to retrieve and calculate experience-related data.
    # @example
    #   Lich::Gemstone::Experience.fame
    module Experience
      # Retrieves the player's fame.
      # @return [Integer] The player's fame value.
      # @example
      #   fame_value = Lich::Gemstone::Experience.fame
      def self.fame
        Infomon.get("experience.fame")
      end

      # Retrieves the current field experience.
      # @return [Integer] The current field experience value.
      # @example
      #   current_fxp = Lich::Gemstone::Experience.fxp_current
      def self.fxp_current
        Infomon.get("experience.field_experience_current")
      end

      # Retrieves the maximum field experience.
      # @return [Integer] The maximum field experience value.
      # @example
      #   max_fxp = Lich::Gemstone::Experience.fxp_max
      def self.fxp_max
        Infomon.get("experience.field_experience_max")
      end

      # Retrieves the player's experience.
      # @return [Integer] The player's experience value.
      # @example
      #   player_exp = Lich::Gemstone::Experience.exp
      def self.exp
        Stats.exp
      end

      # Retrieves the ascension experience.
      # @return [Integer] The ascension experience value.
      # @example
      #   ascension_exp = Lich::Gemstone::Experience.axp
      def self.axp
        Infomon.get("experience.ascension_experience")
      end

      # Retrieves the total experience.
      # @return [Integer] The total experience value.
      # @example
      #   total_exp = Lich::Gemstone::Experience.txp
      def self.txp
        Infomon.get("experience.total_experience")
      end

      # Calculates the percentage of current field experience to maximum field experience.
      # @return [Float] The percentage of current field experience.
      # @example
      #   percent = Lich::Gemstone::Experience.percent_fxp
      def self.percent_fxp
        (fxp_current.to_f / fxp_max.to_f) * 100
      end

      # Calculates the percentage of ascension experience to total experience.
      # @return [Float] The percentage of ascension experience.
      # @example
      #   percent = Lich::Gemstone::Experience.percent_axp
      def self.percent_axp
        (axp.to_f / txp.to_f) * 100
      end

      # Calculates the percentage of player's experience to total experience.
      # @return [Float] The percentage of player's experience.
      # @example
      #   percent = Lich::Gemstone::Experience.percent_exp
      def self.percent_exp
        (exp.to_f / txp.to_f) * 100
      end

      # Retrieves the long-term experience.
      # @return [Integer] The long-term experience value.
      # @example
      #   long_term_exp = Lich::Gemstone::Experience.lte
      def self.lte
        Infomon.get("experience.long_term_experience")
      end

      # Retrieves the number of deeds.
      # @return [Integer] The number of deeds.
      # @example
      #   deeds_count = Lich::Gemstone::Experience.deeds
      def self.deeds
        Infomon.get("experience.deeds")
      end

      # Retrieves the deaths sting value.
      # @return [Integer] The deaths sting value.
      # @example
      #   deaths_value = Lich::Gemstone::Experience.deaths_sting
      def self.deaths_sting
        Infomon.get("experience.deaths_sting")
      end
    end
  end
end
