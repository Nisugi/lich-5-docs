# frozen_string_literal: true


# Provides functionality related to the Lich project.
#
# @see Lich::Gemstone
module Lich
  module Gemstone
    # Handles critical ranks for the Gemstone game.
    #
    # This module manages critical hit tables and related data.
    module CritRanks
      @critical_table ||= {}
      @types           = []
      @locations       = []
      @ranks           = []

      # Initializes the critical ranks module by loading critical tables.
      # @return [void]
      def self.init
        return unless @critical_table.empty?
        Dir.glob("#{File.join(LIB_DIR, "gemstone", "critranks", "*critical_table.rb")}").each do |file|
          require file
        end
        create_indices
      end

      # Returns the critical table data.
      # @return [Hash] the critical table
      def self.table
        @critical_table
      end

      # Reloads the critical table data.
      # @return [void]
      def self.reload!
        @critical_table = {}
        init
      end

      # Returns an array of table names derived from types.
      # @return [Array<String>] the list of table names
      def self.tables
        @tables = []
        @types.each do |type|
          @tables.push(type.to_s.gsub(':', ''))
        end
        @tables
      end

      # Returns the types of critical ranks available.
      # @return [Array<String>] the types of critical ranks
      def self.types
        @types
      end

      # Returns the locations associated with critical ranks.
      # @return [Array<String>] the locations
      def self.locations
        @locations
      end

      # Returns the ranks associated with critical hits.
      # @return [Array<String>] the ranks
      def self.ranks
        @ranks
      end

      # Cleans and normalizes the provided key for consistency.
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
      # @return [String] the cleaned key
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

      # Parses a line of text and matches it against the critical rank indices.
      # @param line [String] the line to parse
      # @return [Hash] matched indices
      def self.parse(line)
        @index_rx.filter do |rx, _data|
          rx =~ line.strip # need to strip spaces to support anchored regex in tables
        end
      end

      # Fetches the critical rank data for the specified type, location, and rank.
      # @param type [String] the type of critical rank
      # @param location [String] the location of the critical rank
      # @param rank [String] the rank to fetch
      # @return [Hash, nil] the critical rank data or nil if not found
      # @raise [RuntimeError] if any of the parameters are invalid
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
