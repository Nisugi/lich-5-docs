module Lich
  module Gemstone
    module Currency
      # Retrieves the amount of silver currency.
      #
      # @return [Integer] the amount of silver
      def self.silver
        Lich::Gemstone::Infomon.get('currency.silver')
      end

      # Retrieves the silver container currency.
      #
      # @return [Integer] the amount of silver container
      def self.silver_container
        Lich::Gemstone::Infomon.get('currency.silver_container')
      end

      # Retrieves the amount of redsteel marks currency.
      #
      # @return [Integer] the amount of redsteel marks
      def self.redsteel_marks
        Lich::Gemstone::Infomon.get('currency.redsteel_marks')
      end

      # Retrieves the amount of tickets currency.
      #
      # @return [Integer] the amount of tickets
      def self.tickets
        Lich::Gemstone::Infomon.get('currency.tickets')
      end

      # Retrieves the amount of blackscrip currency.
      #
      # @return [Integer] the amount of blackscrip
      def self.blackscrip
        Lich::Gemstone::Infomon.get('currency.blackscrip')
      end

      # Retrieves the amount of bloodscrip currency.
      #
      # @return [Integer] the amount of bloodscrip
      def self.bloodscrip
        Lich::Gemstone::Infomon.get('currency.bloodscrip')
      end

      # Retrieves the amount of ethereal scrip currency.
      #
      # @return [Integer] the amount of ethereal scrip
      def self.ethereal_scrip
        Lich::Gemstone::Infomon.get('currency.ethereal_scrip')
      end

      # Retrieves the amount of raikhen currency.
      #
      # @return [Integer] the amount of raikhen
      def self.raikhen
        Lich::Gemstone::Infomon.get('currency.raikhen')
      end

      # Retrieves the amount of elans currency.
      #
      # @return [Integer] the amount of elans
      def self.elans
        Lich::Gemstone::Infomon.get('currency.elans')
      end

      # Retrieves the amount of soul shards currency.
      #
      # @return [Integer] the amount of soul shards
      def self.soul_shards
        Lich::Gemstone::Infomon.get('currency.soul_shards')
      end

      # Retrieves the amount of gold currency.
      #
      # @return [Integer] the amount of gold
      def self.gold
        Lich::Gemstone::Infomon.get('currency.gold')
      end

      # Retrieves the amount of gigas artifact fragments currency.
      #
      # @return [Integer] the amount of gigas artifact fragments
      def self.gigas_artifact_fragments
        Lich::Gemstone::Infomon.get('currency.gigas_artifact_fragments')
      end

      # Retrieves the amount of gemstone dust currency.
      #
      # @return [Integer] the amount of gemstone dust
      def self.gemstone_dust
        Lich::Gemstone::Infomon.get('currency.gemstone_dust')
      end
    end
  end
end
