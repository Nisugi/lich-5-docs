module Lich
  module Gemstone
    module Currency
      # Returns the amount of silver currency.
      # @return [Integer] The amount of silver.
      # @example
      #   amount = Lich::Gemstone::Currency.silver
      def self.silver
        Lich::Gemstone::Infomon.get('currency.silver')
      end

      # Returns the silver container currency.
      # @return [Integer] The amount of silver container.
      # @example
      #   amount = Lich::Gemstone::Currency.silver_container
      def self.silver_container
        Lich::Gemstone::Infomon.get('currency.silver_container')
      end

      # Returns the amount of redsteel marks currency.
      # @return [Integer] The amount of redsteel marks.
      # @example
      #   amount = Lich::Gemstone::Currency.redsteel_marks
      def self.redsteel_marks
        Lich::Gemstone::Infomon.get('currency.redsteel_marks')
      end

      # Returns the amount of tickets currency.
      # @return [Integer] The amount of tickets.
      # @example
      #   amount = Lich::Gemstone::Currency.tickets
      def self.tickets
        Lich::Gemstone::Infomon.get('currency.tickets')
      end

      # Returns the amount of blackscrip currency.
      # @return [Integer] The amount of blackscrip.
      # @example
      #   amount = Lich::Gemstone::Currency.blackscrip
      def self.blackscrip
        Lich::Gemstone::Infomon.get('currency.blackscrip')
      end

      # Returns the amount of bloodscrip currency.
      # @return [Integer] The amount of bloodscrip.
      # @example
      #   amount = Lich::Gemstone::Currency.bloodscrip
      def self.bloodscrip
        Lich::Gemstone::Infomon.get('currency.bloodscrip')
      end

      # Returns the amount of ethereal scrip currency.
      # @return [Integer] The amount of ethereal scrip.
      # @example
      #   amount = Lich::Gemstone::Currency.ethereal_scrip
      def self.ethereal_scrip
        Lich::Gemstone::Infomon.get('currency.ethereal_scrip')
      end

      # Returns the amount of raikhen currency.
      # @return [Integer] The amount of raikhen.
      # @example
      #   amount = Lich::Gemstone::Currency.raikhen
      def self.raikhen
        Lich::Gemstone::Infomon.get('currency.raikhen')
      end

      # Returns the amount of elans currency.
      # @return [Integer] The amount of elans.
      # @example
      #   amount = Lich::Gemstone::Currency.elans
      def self.elans
        Lich::Gemstone::Infomon.get('currency.elans')
      end

      # Returns the amount of soul shards currency.
      # @return [Integer] The amount of soul shards.
      # @example
      #   amount = Lich::Gemstone::Currency.soul_shards
      def self.soul_shards
        Lich::Gemstone::Infomon.get('currency.soul_shards')
      end

      # Returns the amount of gold currency.
      # @return [Integer] The amount of gold.
      # @example
      #   amount = Lich::Gemstone::Currency.gold
      def self.gold
        Lich::Gemstone::Infomon.get('currency.gold')
      end

      # Returns the amount of gigas artifact fragments currency.
      # @return [Integer] The amount of gigas artifact fragments.
      # @example
      #   amount = Lich::Gemstone::Currency.gigas_artifact_fragments
      def self.gigas_artifact_fragments
        Lich::Gemstone::Infomon.get('currency.gigas_artifact_fragments')
      end

      # Returns the amount of gemstone dust currency.
      # @return [Integer] The amount of gemstone dust.
      # @example
      #   amount = Lich::Gemstone::Currency.gemstone_dust
      def self.gemstone_dust
        Lich::Gemstone::Infomon.get('currency.gemstone_dust')
      end
    end
  end
end
