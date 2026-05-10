# frozen_string_literal: true


# Provides functionality related to the Lich game framework.
#
# @see Lich::Gemstone
module Lich
  module Gemstone
    # Handles critical ranks and related data for the game.
    #
    # This module manages critical hit tables, types, locations, and ranks.
    module CritRanks
      @critical_table ||= {}
      @types           = []
      @locations       = []
      @ranks           = []

      # Initializes the critical table by loading necessary files.
      # @return [void]
      # @note This method should be called to set up the critical ranks.
      def self.init
        return unless @critical_table.empty?
        Dir.glob("#{File.join(LIB_DIR, "gemstone", "critranks", "*critical_table.rb")}").each do |file|
          require file
        end
        create_indices
      end

      # Returns the current critical table.
      # @return [Hash] the critical table containing rank data.
      def self.table
        @critical_table
      end

      # Reloads the critical table, clearing existing data.
      # @return [void]
      # @api private
      def self.reload!
        @critical_table = {}
        init
      end

      # Returns an array of table names derived from types.
      # @return [Array<String>] the list of table names.
      def self.tables
        @tables = []
        @types.each do |type|
          @tables.push(type.to_s.gsub(':', ''))
        end
        @tables
      end

      # Returns an array of types defined in the critical ranks.
      # @return [Array<String>] the list of types.
      def self.types
        @types
      end

      # Returns an array of locations defined in the critical ranks.
      # @return [Array<String>] the list of locations.
      def self.locations
        @locations
      end

      # Returns an array of ranks defined in the critical ranks.
      # @return [Array<String>] the list of ranks.
      def self.ranks
        @ranks
      end

      # Cleans and normalizes the provided key for validation.
      # @param key [String, Symbol, Integer] the key to clean
      # @return [String, Integer] the cleaned key
      def self.clean_key(key)
        return key.to_i if key.is_a?(Integer) || key =~ (/^\d+$/)
        return key.downcase if key.is_a?(Symbol)

        key.strip.downcase.gsub(/[ -]/, '_')
      end

      # Validates the provided key against a list of valid options.
      # @param key [String, Symbol, Integer] the key to validate
      # @param valid [Array<String>] the list of valid keys
      # @return [String] the cleaned key if valid
      # @raise [RuntimeError] if the key is invalid
      def self.validate(key, valid)
        clean = clean_key(key)
        raise "Invalid key '#{key}', expecting one of #{valid.join(',')}" unless valid.include?(clean)

        clean
      end

      # Creates indices for types, locations, and ranks from the critical table.
      # @return [void]
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

      # Parses a line and filters indices based on regex matches.
      # @param line [String] the line to parse
      # @return [Hash] filtered indices matching the line
      def self.parse(line)
        @index_rx.filter do |rx, _data|
          rx =~ line.strip # need to strip spaces to support anchored regex in tables
        end
      end

      # Fetches data from the critical table based on type, location, and rank.
      # @param type [String] the type to fetch
      # @param location [String] the location to fetch
      # @param rank [String] the rank to fetch
      # @return [Hash, nil] the fetched data or nil if not found
      # @raise [StandardError] if an error occurs during fetching
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
