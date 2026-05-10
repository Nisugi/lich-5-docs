# The Lich module
# This module serves as a namespace for the Lich project.
module Lich
  # The Gemstone module
  # This module contains functionality related to gemstones in the Lich project.
  module Gemstone
    # The Currency module
    # This module provides methods to retrieve various types of currency in the Lich project.
    # @example Retrieving silver
    #   silver_amount = Lich::Gemstone::Currency.silver
    module Currency
      # Retrieves the amount of silver currency.
      # @return [Integer] The amount of silver.
      # @example Getting silver amount
      #   silver_amount = Lich::Gemstone::Currency.silver
      def self.silver
        Lich::Gemstone::Infomon.get('currency.silver')
      end

      # Retrieves the silver container currency.
      # @return [Integer] The amount of silver container.
      # @example Getting silver container amount
      #   silver_container_amount = Lich::Gemstone::Currency.silver_container
      def self.silver_container
        Lich::Gemstone::Infomon.get('currency.silver_container')
      end

      # Retrieves the amount of redsteel marks currency.
      # @return [Integer] The amount of redsteel marks.
      # @example Getting redsteel marks amount
      #   redsteel_marks_amount = Lich::Gemstone::Currency.redsteel_marks
      def self.redsteel_marks
        Lich::Gemstone::Infomon.get('currency.redsteel_marks')
      end

      # Retrieves the amount of tickets currency.
      # @return [Integer] The amount of tickets.
      # @example Getting tickets amount
      #   tickets_amount = Lich::Gemstone::Currency.tickets
      def self.tickets
        Lich::Gemstone::Infomon.get('currency.tickets')
      end

      # Retrieves the amount of blackscrip currency.
      # @return [Integer] The amount of blackscrip.
      # @example Getting blackscrip amount
      #   blackscrip_amount = Lich::Gemstone::Currency.blackscrip
      def self.blackscrip
        Lich::Gemstone::Infomon.get('currency.blackscrip')
      end

      # Retrieves the amount of bloodscrip currency.
      # @return [Integer] The amount of bloodscrip.
      # @example Getting bloodscrip amount
      #   bloodscrip_amount = Lich::Gemstone::Currency.bloodscrip
      def self.bloodscrip
        Lich::Gemstone::Infomon.get('currency.bloodscrip')
      end

      # Retrieves the amount of ethereal scrip currency.
      # @return [Integer] The amount of ethereal scrip.
      # @example Getting ethereal scrip amount
      #   ethereal_scrip_amount = Lich::Gemstone::Currency.ethereal_scrip
      def self.ethereal_scrip
        Lich::Gemstone::Infomon.get('currency.ethereal_scrip')
      end

      # Retrieves the amount of raikhen currency.
      # @return [Integer] The amount of raikhen.
      # @example Getting raikhen amount
      #   raikhen_amount = Lich::Gemstone::Currency.raikhen
      def self.raikhen
        Lich::Gemstone::Infomon.get('currency.raikhen')
      end

      # Retrieves the amount of elans currency.
      # @return [Integer] The amount of elans.
      # @example Getting elans amount
      #   elans_amount = Lich::Gemstone::Currency.elans
      def self.elans
        Lich::Gemstone::Infomon.get('currency.elans')
      end

      # Retrieves the amount of soul shards currency.
      # @return [Integer] The amount of soul shards.
      # @example Getting soul shards amount
      #   soul_shards_amount = Lich::Gemstone::Currency.soul_shards
      def self.soul_shards
        Lich::Gemstone::Infomon.get('currency.soul_shards')
      end

      # Retrieves the amount of gold currency.
      # @return [Integer] The amount of gold.
      # @example Getting gold amount
      #   gold_amount = Lich::Gemstone::Currency.gold
      def self.gold
        Lich::Gemstone::Infomon.get('currency.gold')
      end

      # Retrieves the amount of gigas artifact fragments currency.
      # @return [Integer] The amount of gigas artifact fragments.
      # @example Getting gigas artifact fragments amount
      #   gigas_artifact_fragments_amount = Lich::Gemstone::Currency.gigas_artifact_fragments
      def self.gigas_artifact_fragments
        Lich::Gemstone::Infomon.get('currency.gigas_artifact_fragments')
      end

      # Retrieves the amount of gemstone dust currency.
      # @return [Integer] The amount of gemstone dust.
      # @example Getting gemstone dust amount
      #   gemstone_dust_amount = Lich::Gemstone::Currency.gemstone_dust
      def self.gemstone_dust
        Lich::Gemstone::Infomon.get('currency.gemstone_dust')
      end
    end
  end
end
