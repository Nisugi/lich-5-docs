# frozen_string_literal: true

#
# Module CritRanks used to resolve critical hits into their mechanical results
#
# This module queries against crit_tables files in lib/crit_tables/
#
# @example Initializing critical ranks
#   Lich::Gemstone::CritRanks.init
# module CritRanks used to resolve critical hits into their mechanical results
# queries against crit_tables files in lib/crit_tables/
# 20240625
#

#
# See generic_critical_table.rb for the general template used
#
module Lich
  module Gemstone
    module CritRanks
      @critical_table ||= {}
      @types           = []
      @locations       = []
      @ranks           = []

      # Initializes the critical table by loading critical_table.rb files
      # @return [void]
      # @note This method will only load files if the critical table is empty.
      # @example Initializing the critical table
      #   Lich::Gemstone::CritRanks.init
      def self.init
        return unless @critical_table.empty?
        Dir.glob("#{File.join(LIB_DIR, "gemstone", "critranks", "*critical_table.rb")}").each do |file|
          require file
        end
        create_indices
      end

      # Returns the current critical table
      # @return [Hash] The critical table containing critical hit data
      # @example Accessing the critical table
      #   critical_data = Lich::Gemstone::CritRanks.table
      def self.table
        @critical_table
      end

      # Reloads the critical table by clearing and reinitializing it
      # @return [void]
      # @example Reloading the critical table
      #   Lich::Gemstone::CritRanks.reload!
      def self.reload!
        @critical_table = {}
        init
      end

      # Returns an array of table names from the critical table
      # @return [Array<String>] The names of the critical tables
      # @example Getting the list of critical tables
      #   table_names = Lich::Gemstone::CritRanks.tables
      def self.tables
        @tables = []
        @types.each do |type|
          @tables.push(type.to_s.gsub(':', ''))
        end
        @tables
      end

      # Returns an array of types defined in the critical table
      # @return [Array<Symbol>] The types of critical hits
      # @example Getting the types of critical hits
      #   crit_types = Lich::Gemstone::CritRanks.types
      def self.types
        @types
      end

      # Returns an array of locations defined in the critical table
      # @return [Array<Symbol>] The locations for critical hits
      # @example Getting the locations for critical hits
      #   crit_locations = Lich::Gemstone::CritRanks.locations
      def self.locations
        @locations
      end

      # Returns an array of ranks defined in the critical table
      # @return [Array<Symbol>] The ranks of critical hits
      # @example Getting the ranks of critical hits
      #   crit_ranks = Lich::Gemstone::CritRanks.ranks
      def self.ranks
        @ranks
      end

      # Cleans and normalizes a key for validation
      # @param key [String, Symbol, Integer] The key to clean
      # @return [String, Integer] The cleaned key
      # @example Cleaning a key
      #   cleaned_key = Lich::Gemstone::CritRanks.clean_key('Some Key')
      def self.clean_key(key)
        return key.to_i if key.is_a?(Integer) || key =~ (/^\d+$/)
        return key.downcase if key.is_a?(Symbol)

        key.strip.downcase.gsub(/[ -]/, '_')
      end

      # Validates a key against a list of valid keys
      # @param key [String, Symbol, Integer] The key to validate
      # @param valid [Array<String>] The array of valid keys
      # @return [String] The cleaned key if valid
      # @raise [RuntimeError] If the key is invalid
      # @example Validating a key
      #   valid_key = Lich::Gemstone::CritRanks.validate(:some_key, Lich::Gemstone::CritRanks.types)
      def self.validate(key, valid)
        clean = clean_key(key)
        raise "Invalid key '#{key}', expecting one of #{valid.join(',')}" unless valid.include?(clean)

        clean
      end

      # Creates indices for types, locations, and ranks from the critical table
      # @return [void]
      # @example Creating indices for critical hits
      #   Lich::Gemstone::CritRanks.create_indices
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

      # Parses a line against the regex indices to find matches
      # @param line [String] The line to parse
      # @return [Hash] A hash of matched regex and associated data
      # @example Parsing a line for critical hits
      #   matches = Lich::Gemstone::CritRanks.parse('some input line')
      def self.parse(line)
        @index_rx.filter do |rx, _data|
          rx =~ line.strip # need to strip spaces to support anchored regex in tables
        end
      end

      # Fetches data from the critical table based on type, location, and rank
      # @param type [Symbol] The type of critical hit
      # @param location [Symbol] The location of the critical hit
      # @param rank [Symbol] The rank of the critical hit
      # @return [Hash, nil] The data for the specified critical hit or nil if not found
      # @raise [StandardError] If an error occurs during fetching
      # @example Fetching critical hit data
      #   data = Lich::Gemstone::CritRanks.fetch(:type, :location, :rank)
      def self.fetch(type, location, rank)
        table.dig(
          validate(type, types),
          validate(location, locations),
          validate(rank, ranks)
        )
      rescue StandardError => e
        Lich::Messaging.msg('error', "Error! #{e}")
      end
      # Initializes the critical ranks on startup
      # @example Automatically initializing on load
      #   Lich::Gemstone::CritRanks.init
      # startup
      init
    end
  end
end
