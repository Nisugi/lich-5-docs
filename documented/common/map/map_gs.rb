# frozen_string_literal: true

require_relative 'map_base'

module Lich
  # Common module for Lich project
  # This module contains the Map class and related functionality.
  # @example Including the Common module
  #   include Lich::Common
  module Common
    # Represents a map in the Lich project.
    # This class includes methods for managing rooms and their properties.
    # @example Creating a new map
    #   map = Lich::Common::Map.new(1, "Room Title", "Room Description", [])
    class Map
      include Enumerable
      include MapBase

      @@loaded                   = false
      @@load_mutex               = Mutex.new
      @@list                   ||= []
      @@images                 ||= []
      @@locations              ||= []
      @@tags                   ||= []
      @@current_room_mutex       = Mutex.new
      @@current_room_id        ||= nil
      @@current_room_count     ||= -1
      @@fuzzy_room_mutex         = Mutex.new
      @@fuzzy_room_id          ||= nil
      @@fuzzy_room_count       ||= -1
      @@current_location       ||= nil
      @@current_location_count ||= -1
      @@previous_room_id       ||= nil
      @@uids                     = {}

      # The unique identifier for the map.
      # @return [Integer] The ID of the map.
      attr_reader :id
      # The title of the map.
      # @return [String] The title of the map.
      attr_accessor :title, :description, :paths, :uid, :location, :climate, :terrain,
                    :wayto, :timeto, :image, :image_coords, :tags, :check_location, :unique_loot

      # Initializes a new map instance.
      # @param id [Integer] The unique identifier for the map.
      # @param title [String] The title of the map.
      # @param description [String] A description of the map.
      # @param paths [Array] The paths available from this map.
      # @param uid [Array] Unique identifiers for the map.
      # @param location [String, nil] The location of the map.
      # @param climate [String, nil] The climate of the map.
      # @param terrain [String, nil] The terrain type of the map.
      # @param wayto [Hash] Directions to other maps.
      # @param timeto [Hash] Time taken to reach other maps.
      # @param image [String, nil] The image associated with the map.
      # @param image_coords [Array, nil] Coordinates for the image.
      # @param tags [Array] Tags associated with the map.
      # @param check_location [String, nil] Location check for the map.
      # @param unique_loot [Array, nil] Unique loot available in the map.
      # @return [Map] The newly created map instance.
      def initialize(id, title, description, paths, uid = [], location = nil,
                     climate = nil, terrain = nil, wayto = {}, timeto = {},
                     image = nil, image_coords = nil, tags = [], check_location = nil,
                     unique_loot = nil)
        @id = id
        @title = title
        @description = description
        @paths = paths
        @uid = uid
        @location = location
        @climate = climate
        @terrain = terrain
        @wayto = wayto
        @timeto = timeto
        @image = image
        @image_coords = image_coords
        @tags = tags
        @check_location = check_location
        @unique_loot = unique_loot
        @@list[@id] = self
      end

      # Class methods for the Map class.
      class << self
        # Returns the current room ID.
        # @return [Integer] The ID of the current room.
        def current_room_id
          @@current_room_id
        end

        def current_room_id=(id)
          @@current_room_id = id
        end

        # Checks if the map is loaded.
        # @return [Boolean] True if the map is loaded, false otherwise.
        def loaded
          @@loaded
        end

        # Checks if the map is loaded.
        # @return [Boolean] True if the map is loaded, false otherwise.
        def loaded?
          @@loaded
        end

        def previous_room_id
          @@previous_room_id
        end

        def previous_room_id=(id)
          @@previous_room_id = id
        end

        # Returns the list of maps.
        # @return [Array] The list of loaded maps.
        def list
          self.load unless @@loaded
          @@list
        end

        def list=(value)
          @@list = value
        end

        # Returns the unique identifiers for the maps.
        # @return [Hash] The hash of unique identifiers.
        def uids
          @@uids
        end

        def clear_tags_cache
          @@tags.clear
        end

        def mark_loaded
          @@loaded = true
        end

        # Synchronizes the loading of maps.
        # @param block [Proc] The block to execute during synchronization.
        def synchronize_load(&block)
          @@load_mutex.synchronize(&block)
        end
      end

      # Returns the fuzzy room ID.
      # @return [Integer] The fuzzy room ID.
      def fuzzy_room_id
        @@current_room_id
      end

      # Returns a string representation of the map.
      # @return [String] The string representation of the map.
      def to_s
        "##{@id} (u#{@uid[-1]}):\n#{@title[-1]} (#{@location})\n#{@description[-1]}\n#{@paths[-1]}"
      end

      def self.fuzzy_room_id
        @@fuzzy_room_id
      end

      # Gets a free ID for a new map.
      # @return [Integer] A free ID for the map.
      def self.get_free_id
        self.load unless @@loaded
        @@list.compact.max_by(&:id).id + 1
      end

      def self.[](val)
        self.load unless @@loaded
        if val.is_a?(Integer) || val =~ /^[0-9]+$/
          @@list[val.to_i]
        elsif val =~ /^u(-?\d+)$/i
          uid_request = ::Regexp.last_match(1).dup.to_i
          @@list[(ids_from_uid(uid_request)[0]).to_i]
        else
          chkre = /#{val.strip.sub(/\.$/, '').gsub(/\.(?:\.\.)?/, '|')}/i
          chk = /#{Regexp.escape(val.strip)}/i
          @@list.find { |room| room.title.find { |title| title =~ chk } } ||
            @@list.find { |room| room.description.find { |desc| desc =~ chk } } ||
            @@list.find { |room| room.description.find { |desc| desc =~ chkre } }
        end
      end

      # Retrieves the current location.
      # @return [String, nil] The current location or nil if not found.
      def self.get_location
        unless XMLData.room_count == @@current_location_count
          if (script = Script.current)
            save_want_downstream = script.want_downstream
            script.want_downstream = true
            waitrt?
            location_result = dothistimeout(
              'location', 15,
              /^You carefully survey your surroundings and guess that your current location is .*? or somewhere close to it\.$|^You can't do that while submerged under water\.$|^You can't do that\.$|^It would be rude not to give your full attention to the performance\.$|^You can't do that while hanging around up here!$|^You are too distracted by the difficulty of staying alive in these treacherous waters to do that\.$|^You carefully survey your surroundings but are unable to guess your current location\.$|^Not in pitch darkness you don't\.$|^That is too difficult to consider here\.$/
            )
            script.want_downstream = save_want_downstream
            @@current_location_count = XMLData.room_count
            if location_result =~ /^You can't do that while submerged under water\.$|^You can't do that\.$|^It would be rude not to give your full attention to the performance\.$|^You can't do that while hanging around up here!$|^You are too distracted by the difficulty of staying alive in these treacherous waters to do that\.$|^You carefully survey your surroundings but are unable to guess your current location\.$|^Not in pitch darkness you don't\.$|^That is too difficult to consider here\.$/
              @@current_location = false
            else
              @@current_location = /^You carefully survey your surroundings and guess that your current location is (.*?) or somewhere close to it\.$/.match(location_result).captures.first
            end
          else
            return nil
          end
        end
        @@current_location
      end

      # Returns the previous room based on the previous room ID.
      # @return [Room, nil] The previous room or nil if not found.
      def self.previous
        return nil if @@previous_room_id.nil?

        @@list[@@previous_room_id]
      end

      def self.previous_uid
        XMLData.previous_nav_rm
      end

      # Returns the current room based on the current room ID.
      # @return [Room, nil] The current room or nil if not found.
      def self.current
        self.load unless @@loaded
        if Script.current
          return @@list[@@current_room_id] if XMLData.room_count == @@current_room_count && !@@current_room_id.nil?
        elsif XMLData.room_count == @@fuzzy_room_count && !@@current_room_id.nil?
          return @@list[@@current_room_id]
        end
        # GS uses large UID check instead of zero check
        ids = XMLData.room_id > 4_294_967_296 ? [] : ids_from_uid(XMLData.room_id)
        return set_current(ids[0]) if ids.size == 1

        if ids.size > 1 && !@@current_room_id.nil? && (id = match_multi_ids(ids))
          return set_current(id)
        end
        match_no_uid
      end

      # Sets the current room based on the provided ID.
      # @param id [Integer] The ID of the room to set as current.
      # @return [Room, nil] The current room or nil if not found.
      def self.set_current(id)
        @@previous_room_id = @@current_room_id if id != @@current_room_id
        @@current_room_id = id
        return nil if id.nil?

        @@list[id]
      end

      # Sets the fuzzy room based on the provided ID.
      # @param id [Integer] The ID of the room to set as fuzzy.
      # @return [Room, nil] The fuzzy room or nil if not found.
      def self.set_fuzzy(id)
        @@previous_room_id = @@current_room_id if !id.nil? && id != @@current_room_id
        @@current_room_id = id
        return nil if id.nil?

        @@list[id]
      end

      # Matches multiple IDs to find a valid room.
      # @param ids [Array] The array of IDs to match.
      # @return [Integer, nil] The matched ID or nil if not found.
      def self.match_multi_ids(ids)
        matches = ids.find_all { |s| @@list[@@current_room_id].wayto.keys.include?(s.to_s) }
        return matches[0] if matches.size == 1

        nil
      end

      # Matches a room without a UID.
      # @return [Integer, nil] The matched room ID or nil if not found.
      def self.match_no_uid
        if (script = Script.current)
          set_current(match_current(script))
        else
          set_fuzzy(match_fuzzy)
        end
      end

      # Matches the current room based on the provided script.
      # @param script [Script] The current script context.
      # @return [Integer, nil] The matched room ID or nil if not found.
      def self.match_current(script)
        @@current_room_mutex.synchronize do
          peer_history = {}
          need_set_desc_off = false

          check_peer_tag = proc do |r|
            begin
              script.ignore_pause = true
              peer_room_count = XMLData.room_count
              peer_tag = r.tags.find { |tag| tag =~ %r{^(set desc on; )?peer [a-z]+ =~ /.+/$} }
              if peer_tag
                need_desc, peer_direction, peer_requirement = %r{^(set desc on; )?peer ([a-z]+) =~ /(.+)/$}.match(peer_tag).captures
                need_desc = need_desc ? true : false
                peer_history[peer_room_count] ||= {}
                peer_history[peer_room_count][peer_direction] ||= {}

                if peer_history[peer_room_count][peer_direction][need_desc].nil?
                  if need_desc
                    last_roomdesc = $_SERVERBUFFER_.reverse.find { |line| line =~ /<style id="roomDesc"\/>/ }
                    unless last_roomdesc && last_roomdesc =~ %r{<style id="roomDesc"/>[^<]}
                      put 'set description on'
                      need_set_desc_off = true
                    end
                  end
                  save_want_downstream = script.want_downstream
                  script.want_downstream = true
                  squelch_started = false
                  squelch_proc = proc do |server_string|
                    if squelch_started
                      DownstreamHook.remove('squelch-peer') if server_string =~ /<prompt/
                      nil
                    elsif server_string =~ /^You peer/
                      squelch_started = true
                      nil
                    else
                      server_string
                    end
                  end
                  DownstreamHook.add('squelch-peer', squelch_proc)
                  result = dothistimeout "peer #{peer_direction}", 3, /^You peer|^\[Usage: PEER/
                  if result =~ /^You peer/
                    peer_results = []
                    5.times do
                      line = get?
                      if line
                        peer_results.push line
                        break if line =~ /^Obvious/
                      end
                    end
                    if XMLData.room_count == peer_room_count
                      if need_desc
                        peer_history[peer_room_count][peer_direction][true] = peer_results
                        peer_history[peer_room_count][peer_direction][false] = peer_results
                      else
                        peer_history[peer_room_count][peer_direction][false] = peer_results
                      end
                    end
                  end
                  script.want_downstream = save_want_downstream
                end
                good = peer_history[peer_room_count][peer_direction][need_desc].any? { |line| line =~ /#{peer_requirement}/ }
              else
                good = true
              end
            ensure
              script.ignore_pause = false
            end
            good
          end

          begin
            loop do
              @@current_room_count = XMLData.room_count
              foggy_exits = XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/
              room = @@list.find do |r|
                r.title.include?(XMLData.room_title) &&
                  r.description.include?(XMLData.room_description.strip) &&
                  (r.unique_loot.nil? || (r.unique_loot.to_a - GameObj.loot.to_a.collect(&:name)).empty?) &&
                  (foggy_exits || r.paths.include?(XMLData.room_exits_string.strip) || r.tags.include?('random-paths')) &&
                  (!r.check_location || r.location == get_location) && check_peer_tag.call(r)
              end

              if room
                redo unless @@current_room_count == XMLData.room_count
                return room.id
              else
                redo unless @@current_room_count == XMLData.room_count
                desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
                room = @@list.find do |r|
                  r.title.include?(XMLData.room_title) &&
                    (foggy_exits || r.paths.include?(XMLData.room_exits_string.strip) || r.tags.include?('random-paths')) &&
                    (XMLData.room_window_disabled || r.description.any? { |desc| desc =~ desc_regex }) &&
                    (r.unique_loot.nil? || (r.unique_loot.to_a - GameObj.loot.to_a.collect(&:name)).empty?) &&
                    (!r.check_location || r.location == get_location) && check_peer_tag.call(r)
                end

                if room
                  redo unless @@current_room_count == XMLData.room_count
                  return room.id
                else
                  redo unless @@current_room_count == XMLData.room_count
                  return nil
                end
              end
            end
          ensure
            put 'set description off' if need_set_desc_off
          end
        end
      end

      # Matches a fuzzy room based on the current context.
      # @return [Integer, nil] The matched fuzzy room ID or nil if not found.
      def self.match_fuzzy
        @@fuzzy_room_mutex.synchronize do
          @@fuzzy_room_count = XMLData.room_count
          loop do
            foggy_exits = XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/
            room = @@list.find do |r|
              r.title.include?(XMLData.room_title) &&
                r.description.include?(XMLData.room_description.strip) &&
                (r.unique_loot.nil? || (r.unique_loot.to_a - GameObj.loot.to_a.collect(&:name)).empty?) &&
                (foggy_exits || r.paths.include?(XMLData.room_exits_string.strip) || r.tags.include?('random-paths')) &&
                (!r.check_location || r.location == get_location)
            end

            if room
              redo unless @@fuzzy_room_count == XMLData.room_count
              if room.tags.any? { |tag| tag =~ %r{^(set desc on; )?peer [a-z]+ =~ /.+/$} }
                return nil
              else
                return room.id
              end
            else
              redo unless @@fuzzy_room_count == XMLData.room_count
              desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
              room = @@list.find do |r|
                r.title.include?(XMLData.room_title) &&
                  (foggy_exits || r.paths.include?(XMLData.room_exits_string.strip) || r.tags.include?('random-paths')) &&
                  (XMLData.room_window_disabled || r.description.any? { |desc| desc =~ desc_regex }) &&
                  (r.unique_loot.nil? || (r.unique_loot.to_a - GameObj.loot.to_a.collect(&:name)).empty?) &&
                  (!r.check_location || r.location == get_location)
              end

              if room
                redo unless @@fuzzy_room_count == XMLData.room_count
                if room.tags.any? { |tag| tag =~ %r{^(set desc on; )?peer [a-z]+ =~ /.+/$} }
                  return nil
                else
                  return room.id
                end
              else
                redo unless @@fuzzy_room_count == XMLData.room_count
                return nil
              end
            end
          end
        end
      end

      # Retrieves the current room or creates a new one if it doesn't exist.
      # @return [Room, nil] The current room or nil if not found.
      def self.current_or_new
        return nil unless Script.current

        self.load unless @@loaded
        ids = XMLData.room_id > 4_294_967_296 ? [] : ids_from_uid(XMLData.room_id)
        room = nil
        id = ids[0] if ids.size == 1
        id = match_multi_ids(ids) if ids.size > 1

        if id.nil?
          id = match_current(Script.current)
          # prevent loading uids into existing rooms with a single id unless tagged meta:map:multi-uid
          if !id.nil? && self[id].uid.size == 1 && !self[id].tags.include?('meta:map:multi-uid')
            id = nil
          end
        end

        if !id.nil?
          room = self[id]
          unless XMLData.room_id > 4_294_967_296 || room.uid.include?(XMLData.room_id)
            room.uid << XMLData.room_id
            uids_add(XMLData.room_id, room.id)
            echo "Map: Adding new uid for #{room.id}: #{XMLData.room_id}"
          end

          if (room.tags & %w[meta:map:latest-only meta:playershop]).empty?
            # update room if not meta:playershop or meta:map:latest-only
            unless room.title.include?(XMLData.room_title)
              room.title.unshift(XMLData.room_title)
              echo "Map: Adding new title for #{room.id}: '#{XMLData.room_title}'"
            end
            unless room.description.include?(XMLData.room_description.strip)
              room.description.unshift(XMLData.room_description.strip)
              echo "Map: Adding new description for #{room.id} : #{XMLData.room_description.strip.inspect}"
            end
            unless room.paths.include?(XMLData.room_exits_string.strip)
              room.paths.unshift(XMLData.room_exits_string.strip)
              echo "Map: Adding new path for #{room.id}: #{XMLData.room_exits_string.strip.inspect}"
            end
            if room.location.nil? || room.location == false || room.location == ''
              current_location = get_location
              room.location = current_location
              echo "Map: Updating location for #{room.id}: #{current_location.inspect}"
            end
          elsif !(room.tags & %w[meta:map:latest-only meta:playershop]).empty?
            # update rooms tagged meta:playershop or meta:map:latest-only
            if room.title != [XMLData.room_title]
              room.title = [XMLData.room_title]
              echo "Map: Updating title for #{room.id}: #{XMLData.room_title.inspect}"
            end
            if room.description != [XMLData.room_description.strip]
              room.description = [XMLData.room_description.strip]
              echo "Map: Updating description for #{room.id}: #{XMLData.room_description.strip.inspect}"
            end
            if room.paths != [XMLData.room_exits_string.strip]
              room.paths = [XMLData.room_exits_string.strip]
              echo "Map: Updating path for #{room.id}: #{XMLData.room_exits_string.strip.inspect}"
            end
            if room.location.nil? || room.location == false || room.location == ''
              current_location = get_location
              room.location = current_location
              echo "Map: Updating location for #{room.id}: #{current_location.inspect}"
            end
          end
          return set_current(room.id)
        end

        # new room
        id = get_free_id
        title = [XMLData.room_title]
        description = [XMLData.room_description.strip]
        paths = [XMLData.room_exits_string.strip]
        uid = XMLData.room_id > 4_294_967_296 ? [] : [XMLData.room_id]
        current_location = get_location
        room = new(id, title, description, paths, uid, current_location)
        uids_add(XMLData.room_id, room.id) unless XMLData.room_id > 4_294_967_296

        # flag identical rooms with different locations
        identical_rooms = @@list.find_all do |r|
          r.location != current_location &&
            r.title.include?(XMLData.room_title) &&
            r.description.include?(XMLData.room_description.strip) &&
            (r.unique_loot.nil? || (r.unique_loot.to_a - GameObj.loot.to_a.collect(&:name)).empty?) &&
            (r.paths.include?(XMLData.room_exits_string.strip) || r.tags.include?('random-paths')) &&
            !r.uid.include?(XMLData.room_id)
        end

        if identical_rooms.length.positive?
          room.check_location = true
          identical_rooms.each { |r| r.check_location = true }
        end

        echo "mapped new room, set current room to #{room.id}"
        set_current(id)
      end

      # Retrieves the unique locations from the map.
      # @return [Array] The unique locations.
      def self.locations
        self.load unless @@loaded
        @@locations = @@list.each_with_object({}) { |r, h| h[r.location] = nil unless h.key?(r.location) }.keys if @@locations.empty?
        @@locations.dup
      end

      # Retrieves the unique images from the map.
      # @return [Array] The unique images.
      def self.images
        self.load unless @@loaded
        @@images = @@list.each_with_object({}) { |r, h| h[r.image] = nil unless h.key?(r.image) }.keys if @@images.empty?
        @@images.dup
      end

      # Retrieves the unique tags from the map.
      # @return [Array] The unique tags.
      def self.tags
        self.load unless @@loaded
        @@tags = @@list.compact.each_with_object({}) { |r, h| r.tags.each { |t| h[t] = nil unless h.key?(t) } }.keys if @@tags.empty?
        @@tags.dup
      end

      # Clears the unique identifiers for the maps.
      def self.uids_clear
        @@uids.clear
      end

      # Retrieves IDs associated with a given UID.
      # @param n [Integer] The UID to look up.
      # @return [Array] The array of IDs associated with the UID.
      def self.ids_from_uid(n)
        @@uids[n].nil? ? [] : @@uids[n]
      end

      # Loads unique identifiers from the map.
      def self.load_uids
        self.load unless @@loaded
        @@uids.clear
        @@list.each do |r|
          r.uid.each { |u| uids_add(u, r.id) }
        end
      end

      # Clears the map data and resets the state.
      def self.clear
        @@load_mutex.synchronize do
          @@list.clear
          @@tags.clear
          @@locations.clear
          @@images.clear
          @@loaded = false
          GC.start
        end
        true
      end

      # Loads the map data from a file.
      # @param filename [String, nil] The name of the file to load.
      # @return [Boolean] True if the load was successful, false otherwise.
      def self.load(filename = nil)
        file_list = if filename.nil?
                      Dir.entries(File.join(DATA_DIR, XMLData.game))
                         .find_all { |fn| fn =~ /^map-[0-9]+\.(?:dat|xml|json)$/i }
                         .collect { |fn| File.join(DATA_DIR, XMLData.game, fn) }
                         .sort
                         .reverse
                    else
                      [filename]
                    end

        if file_list.empty?
          respond '--- Lich: error: no map database found'
          return false
        end

        while (filename = file_list.shift)
          if filename =~ /\.json$/i
            return true if load_json(filename)
          elsif filename =~ /\.xml$/
            return true if load_xml(filename)
          elsif load_dat(filename)
            return true
          end
        end
        false
      end

      # Loads map data from a JSON file.
      # @param filename [String, nil] The name of the JSON file to load.
      # @return [Boolean] True if the load was successful, false otherwise.
      def self.load_json(filename = nil)
        @@load_mutex.synchronize do
          return true if @@loaded

          file_list = if filename
                        [filename]
                      else
                        Dir.entries(File.join(DATA_DIR, XMLData.game))
                           .find_all { |fn| fn =~ /^map-[0-9]+\.json$/i }
                           .collect { |fn| File.join(DATA_DIR, XMLData.game, fn) }
                           .sort
                           .reverse
                      end

          if file_list.empty?
            respond '--- Lich: error: no map database found'
            return false
          end

          while (filename = file_list.shift)
            next unless File.exist?(filename)

            File.open(filename) do |f|
              JSON.parse(f.read).each do |room|
                room['wayto'].keys.each do |k|
                  if room['wayto'][k][0..2] == ';e '
                    room['wayto'][k] = StringProc.new(room['wayto'][k][3..])
                  end
                end
                room['timeto'].keys.each do |k|
                  if room['timeto'][k].is_a?(String) && room['timeto'][k][0..2] == ';e '
                    room['timeto'][k] = StringProc.new(room['timeto'][k][3..])
                  end
                end
                room['wayto'] ||= {}
                room['timeto'] ||= {}
                room['title'] ||= []
                room['description'] ||= []
                room['tags'] ||= []
                room['uid'] ||= []
                new(
                  room['id'], room['title'], room['description'], room['paths'],
                  room['uid'], room['location'], room['climate'], room['terrain'],
                  room['wayto'], room['timeto'], room['image'], room['image_coords'],
                  room['tags'], room['check_location'], room['unique_loot']
                )
              end
            end
            @@tags.clear
            respond "--- #{Script.current.name} Map loaded #{filename}"
            @@loaded = true
            load_uids
            return true
          end
        end
      end

      # Loads map data from an XML file.
      # @param filename [String] The name of the XML file to load.
      # @return [Boolean] True if the load was successful, false otherwise.
      def self.load_xml(filename = File.join(DATA_DIR, XMLData.game, 'map.xml'))
        respond '--- WARNING: Map.load_xml is deprecated. Use Map.load_json instead.'
        @@load_mutex.synchronize do
          return true if @@loaded

          unless File.exist?(filename)
            raise Exception.exception('MapDatabaseError'), "Fatal error: file `#{filename}' does not exist!"
          end

          missing_end = false
          current_tag = nil
          current_attributes = nil
          room = nil
          buffer = String.new
          unescape = { 'lt' => '<', 'gt' => '>', 'quot' => '"', 'apos' => "'", 'amp' => '&' }

          tag_start = proc do |element, attributes|
            current_tag = element
            current_attributes = attributes
            if element == 'room'
              room = {}
              room['id'] = attributes['id'].to_i
              room['location'] = attributes['location']
              room['climate'] = attributes['climate']
              room['terrain'] = attributes['terrain']
              room['wayto'] = {}
              room['timeto'] = {}
              room['title'] = []
              room['description'] = []
              room['paths'] = []
              room['tags'] = []
              room['unique_loot'] = []
              room['uid'] = []
            elsif element =~ /^(?:image|tsoran)$/ && attributes['name'] && attributes['x'] && attributes['y'] && attributes['size']
              room['image'] = attributes['name']
              room['image_coords'] = [
                (attributes['x'].to_i - (attributes['size'] / 2.0).round),
                (attributes['y'].to_i - (attributes['size'] / 2.0).round),
                (attributes['x'].to_i + (attributes['size'] / 2.0).round),
                (attributes['y'].to_i + (attributes['size'] / 2.0).round)
              ]
            elsif element == 'image' && attributes['name'] && attributes['coords'] && attributes['coords'] =~ /[0-9]+,[0-9]+,[0-9]+,[0-9]+/
              room['image'] = attributes['name']
              room['image_coords'] = attributes['coords'].split(',').collect(&:to_i)
            elsif element == 'map'
              missing_end = true
            end
          end

          text = proc do |text_string|
            if current_tag == 'tag'
              room['tags'].push(text_string)
            elsif current_tag =~ /^(?:title|description|paths|unique_loot)$/
              room[current_tag].push(text_string)
            elsif current_tag =~ /^(?:uid)$/
              room[current_tag].push(text_string.to_i)
            elsif current_tag == 'exit' && current_attributes['target']
              room['wayto'][current_attributes['target']] = if current_attributes['type'].downcase == 'string'
                                                              text_string
                                                            else
                                                              StringProc.new(text_string)
                                                            end
              room['timeto'][current_attributes['target']] = if current_attributes['cost'] =~ /^[0-9.]+$/
                                                               current_attributes['cost'].to_f
                                                             elsif current_attributes['cost'].length.positive?
                                                               StringProc.new(current_attributes['cost'])
                                                             else
                                                               0.2
                                                             end
            end
          end

          tag_end = proc do |element|
            if element == 'room'
              room['unique_loot'] = nil if room['unique_loot'].empty?
              new(
                room['id'], room['title'], room['description'], room['paths'],
                room['uid'], room['location'], room['climate'], room['terrain'],
                room['wayto'], room['timeto'], room['image'], room['image_coords'],
                room['tags'], room['check_location'], room['unique_loot']
              )
            elsif element == 'map'
              missing_end = false
            end
            current_tag = nil
          end

          begin
            File.open(filename) do |file|
              while (line = file.gets)
                buffer.concat(line)
                while (str = buffer.slice!(/^<([^>]+)><\/\1>|^[^<]+(?=<)|^<[^<]+>/))
                  if str[0, 1] == '<'
                    if str[1, 1] == '/'
                      element = %r{^</([^\s>/]+)}.match(str).captures.first
                      tag_end.call(element)
                    elsif str =~ %r{^<([^>]+)></\1>}
                      element = ::Regexp.last_match(1)
                      tag_start.call(element)
                      text.call('')
                      tag_end.call(element)
                    else
                      element = %r{^<([^\s>/]+)}.match(str).captures.first
                      attributes = {}
                      str.scan(/([A-z][A-z0-9_-]*)=(["'])(.*?)\2/).each do |attr|
                        attributes[attr[0]] = attr[2].gsub(/&(#{unescape.keys.join('|')});/) { unescape[::Regexp.last_match(1)] }
                      end
                      tag_start.call(element, attributes)
                      tag_end.call(element) if str[-2, 1] == '/'
                    end
                  else
                    text.call(str.gsub(/&(#{unescape.keys.join('|')});/) { unescape[::Regexp.last_match(1)] })
                  end
                end
              end
            end

            if missing_end
              respond "--- Lich: error: failed to load #{filename}: unexpected end of file"
              return false
            end

            @@tags.clear
            load_uids
            @@loaded = true
            true
          rescue StandardError => e
            respond "--- Lich: error: failed to load #{filename}: #{e}"
            false
          end
        end
      end

      # Saves the map data to an XML file.
      # @param _filename [String, nil] The name of the XML file to save to.
      # @return [Boolean] True if the save was successful, false otherwise.
      def self.save_xml(_filename = nil)
        respond '--- WARNING: Map.save_xml is deprecated. Use Map.save_json instead.'
      end
    end

    # Represents a room in the map.
    # This class inherits from Map and can be extended with additional functionality.
    class Room < Map
      def self.method_missing(*args)
        super
      end

      def self.respond_to_missing?(*args)
        super
      end
    end
  end
end
