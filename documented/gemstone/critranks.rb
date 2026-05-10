# frozen_string_literal: true


module Lich
  module Gemstone
    # Provides functionality for managing critical ranks in the Gemstone module.
    # @example Usage
    #   Lich::Gemstone::CritRanks.init
    module CritRanks
      @critical_table ||= {}
      @types           = []
      @locations       = []
      @ranks           = []

      # Initializes the critical ranks data by loading necessary files.
      # @return [void]
      # @note This method will only run if the critical table is empty.
      # @example Initializing critical ranks
      #   Lich::Gemstone::CritRanks.init
      def self.init
        return unless @critical_table.empty?
        Dir.glob("#{File.join(LIB_DIR, "gemstone", "critranks", "*critical_table.rb")}").each do |file|
          require file
        end
        create_indices
      end

      # Returns the critical table.
      # @return [Hash] The critical table containing rank data.
      # @example Accessing the critical table
      #   critical_table = Lich::Gemstone::CritRanks.table
      def self.table
        @critical_table
      end

      # Reloads the critical ranks data, clearing the existing table first.
      # @return [void]
      # @example Reloading critical ranks
      #   Lich::Gemstone::CritRanks.reload!
      def self.reload!
        @critical_table = {}
        init
      end

      # Returns an array of table names derived from the types.
      # @return [Array<String>] The list of table names.
      # @example Getting table names
      #   table_names = Lich::Gemstone::CritRanks.tables
      def self.tables
        @tables = []
        @types.each do |type|
          @tables.push(type.to_s.gsub(':', ''))
        end
        @tables
      end

      # Returns the types of critical ranks.
      # @return [Array<Symbol>] The array of types.
      # @example Accessing types
      #   types = Lich::Gemstone::CritRanks.types
      def self.types
        @types
      end

      # Returns the locations associated with critical ranks.
      # @return [Array<String>] The array of locations.
      # @example Accessing locations
      #   locations = Lich::Gemstone::CritRanks.locations
      def self.locations
        @locations
      end

      # Returns the ranks associated with critical ranks.
      # @return [Array<String>] The array of ranks.
      # @example Accessing ranks
      #   ranks = Lich::Gemstone::CritRanks.ranks
      def self.ranks
        @ranks
      end

      # Cleans and normalizes the provided key for consistency.
      # @param key [String, Symbol, Integer] The key to clean.
      # @return [String, Integer] The cleaned key.
      # @example Cleaning a key
      #   cleaned_key = Lich::Gemstone::CritRanks.clean_key(:Example)
      #   # => "example"
      def self.clean_key(key)
        return key.to_i if key.is_a?(Integer) || key =~ (/^\d+$/)
        return key.downcase if key.is_a?(Symbol)

        key.strip.downcase.gsub(/[ -]/, '_')
      end

      # Validates the provided key against a list of valid options.
      # @param key [String, Symbol, Integer] The key to validate.
      # @param valid [Array<String>] The array of valid keys.
      # @return [String] The cleaned key if valid.
      # @raise [RuntimeError] If the key is invalid.
      # @example Validating a key
      #   valid_key = Lich::Gemstone::CritRanks.validate(:example, [:example, :test])
      def self.validate(key, valid)
        clean = clean_key(key)
        raise "Invalid key '#{key}', expecting one of #{valid.join(',')}" unless valid.include?(clean)

        clean
      end

      # Creates indices for types, locations, and ranks from the critical table.
      # @return [void]
      # @note This method is called internally to set up the indices.
      def self.create_indices
        @index_rx ||= {}
        @critical_table.each do |type, typedata|
          @types.append(type)
          typedata.each do |loc, locdata|
            @locations.append(loc) unless @locations.include?(loc)
            locdata.each do |rank, record|
              @ranks.append(rank) unless @ranks.include?(rank)
              @index_rx[record[:regex]] = record
            end
          end
        end
      end

      # Parses a line against the defined regex indices to find matches.
      # @param line [String] The line to parse.
      # @return [Array] An array of matches found.
      # @example Parsing a line
      #   matches = Lich::Gemstone::CritRanks.parse("Some input line")
      def self.parse(line)
        @index_rx.filter do |rx, _data|
          rx =~ line.strip # need to strip spaces to support anchored regex in tables
        end
      end

      # Fetches data from the critical table based on type, location, and rank.
      # @param type [Symbol] The type of critical rank.
      # @param location [String] The location associated with the rank.
      # @param rank [String] The rank to fetch.
      # @return [Hash, nil] The data associated with the specified type, location, and rank, or nil if not found.
      # @raise [RuntimeError] If any of the parameters are invalid.
      # @example Fetching data
      #   data = Lich::Gemstone::CritRanks.fetch(:type, "location", "rank")
      def self.fetch(type, location, rank)
        table.dig(
          validate(type, types),
          validate(location, locations),
          validate(rank, ranks)
        )
      rescue StandardError => e
        Lich::Messaging.msg('error', "Error! #{e}")
      end
      # startup
      init
    end
  end
end
