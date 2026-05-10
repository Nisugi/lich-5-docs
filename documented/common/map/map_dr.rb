# frozen_string_literal: true

require_relative 'map_base'

module Lich
  module Common
    # Represents a map in the Lich game.
    # This class includes methods for managing rooms and their properties.
    # @example Creating a new map
    #   map = Lich::Common::Map.new(1, "Room Title", "Room Description", [])
    class Map
      include Enumerable
      include MapBase

      @@loaded                   = false
      @@load_mutex               = Mutex.new
      @@list                   ||= []
      @@tags                   ||= []
      @@current_room_mutex       = Mutex.new
      @@current_room_id        ||= -1
      @@current_room_count     ||= -1
      @@fuzzy_room_mutex         = Mutex.new
      @@fuzzy_room_count       ||= -1
      @@current_location       ||= nil
      @@current_location_count ||= -1
      @@current_room_uid       ||= -1
      @@previous_room_id       ||= -1
      @@uids                     = {}

      attr_reader :id
      attr_accessor :title, :description, :paths, :location, :climate, :terrain,
                    :wayto, :timeto, :image, :image_coords, :tags, :check_location,
                    :unique_loot, :uid, :room_objects,
                    :genie_id, :genie_zone, :genie_pos

      # Initializes a new Map instance.
      # @param id [Integer] The unique identifier for the map.
      # @param title [String] The title of the map.
      # @param description [String] A description of the map.
      # @param paths [Array] The paths available from this map.
      # @param uid [Array] (optional) Unique identifiers for the map.
      # @param location [String, nil] (optional) The location of the map.
      # @param climate [String, nil] (optional) The climate of the map.
      # @param terrain [String, nil] (optional) The terrain type of the map.
      # @param wayto [Hash] (optional) A hash mapping paths to their destinations.
      # @param timeto [Hash] (optional) A hash mapping paths to their travel times.
      # @param image [String, nil] (optional) The image associated with the map.
      # @param image_coords [Array, nil] (optional) Coordinates for the image.
      # @param tags [Array] (optional) Tags associated with the map.
      # @param check_location [String, nil] (optional) A check for the location.
      # @param unique_loot [String, nil] (optional) Unique loot available in the map.
      # @param _room_objects [nil] (optional) Room objects associated with the map.
      # @param genie_id [String, nil] (optional) The ID of the genie associated with the map.
      # @param genie_zone [String, nil] (optional) The zone of the genie.
      # @param genie_pos [String, nil] (optional) The position of the genie.
      def initialize(id, title, description, paths, uid = [], location = nil,
                     climate = nil, terrain = nil, wayto = {}, timeto = {},
                     image = nil, image_coords = nil, tags = [], check_location = nil,
                     unique_loot = nil, _room_objects = nil,
                     genie_id = nil, genie_zone = nil, genie_pos = nil)
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
        @genie_id = genie_id
        @genie_zone = genie_zone
        @genie_pos = genie_pos
        @@list[@id] = self
      end

      # Returns a string representation of the map.
      # @return [String] A formatted string containing the map's ID, title, description, and paths.
      # @example
      #   puts map.to_s
      def to_s
        "##{@id} (#{@uid[-1]}):\n#{@title[-1]}\n#{@description[-1]}\n#{@paths[-1]}"
      end

      # Returns additional fields for JSON representation.
      # @return [Hash] A hash containing extra fields like genie_id, genie_zone, and genie_pos.
      def json_extra_fields
        { genie_id: @genie_id, genie_zone: @genie_zone, genie_pos: @genie_pos }
      end

      class << self
        # Checks if the map has been loaded.
        # @return [Boolean] True if the map is loaded, false otherwise.
        def loaded?
          @@loaded
        end

        # Returns the list of maps.
        # @return [Array] An array of loaded maps.
        # @example
        #   maps = Lich::Common::Map.list
        def list
          self.load unless @@loaded
          @@list
        end

        def list=(value)
          @@list = value
        end

        # Returns the unique identifiers for the maps.
        # @return [Hash] A hash mapping unique IDs to map IDs.
        def uids
          @@uids
        end

        # Clears the tags cache.
        def clear_tags_cache
          @@tags.clear
        end

        # Marks the map as loaded.
        def mark_loaded
          @@loaded = true
        end

        def synchronize_load(&block)
          @@load_mutex.synchronize(&block)
        end
      end

      # Finds a map by genie reference.
      # @param zone_id [String] The zone ID of the genie.
      # @param node_id [String] The node ID of the genie.
      # @return [Map, nil] The map associated with the genie reference, or nil if not found.
      def self.by_genie_ref(zone_id, node_id)
        self.load unless @@loaded
        @@list.find { |r| r&.genie_zone == zone_id.to_s && r&.genie_id == node_id.to_s }
      end

      # Gets a free ID for a new map.
      # @return [Integer] A unique ID for a new map.
      def self.get_free_id
        self.load unless @@loaded
        @@list.compact.max_by(&:id).id + 1
      end

      # Retrieves a map by its ID or UID.
      # @param val [Integer, String] The ID or UID of the map.
      # @return [Map, nil] The map associated with the given ID or UID, or nil if not found.
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
          @@list.find { |room| room&.title&.find { |title| title =~ chk } } ||
            @@list.find { |room| room&.description&.find { |desc| desc =~ chk } } ||
            @@list.find { |room| room&.description&.find { |desc| desc =~ chkre } }
        end
      end

      # Retrieves the previous map.
      # @return [Map, nil] The previous map, or nil if none exists.
      def self.previous
        @@list[@@previous_room_id]
      end

      # Retrieves the previous UID.
      # @return [String, nil] The previous UID, or nil if none exists.
      def self.previous_uid
        XMLData.previous_nav_rm
      end

      # Retrieves the current map.
      # @return [Map, nil] The current map, or nil if none exists.
      def self.current
        self.load unless @@loaded
        if Script.current
          return @@list[@@current_room_id] if XMLData.room_count == @@current_room_count && !@@current_room_id.nil?
        elsif XMLData.room_count == @@fuzzy_room_count && !@@current_room_id.nil?
          return @@list[@@current_room_id]
        end
        ids = XMLData.room_id.zero? ? [] : ids_from_uid(XMLData.room_id)
        return set_current(ids[0]) if ids.size == 1

        if ids.size > 1 && !@@current_room_id.nil? && (id = match_multi_ids(ids))
          return set_current(id)
        end
        match_no_uid
      end

      def self.match_no_uid
        if (script = Script.current)
          set_current(match_current(script))
        else
          set_fuzzy(match_fuzzy)
        end
      end

      def self.set_fuzzy(id)
        @@previous_room_id = @@current_room_id if !id.nil? && id != @@current_room_id
        @@current_room_id = id
        return nil if id.nil?

        @@list[id]
      end

      def self.match_current(_script)
        @@current_room_mutex.synchronize do
          need_set_desc_off = false
          begin
            loop do
              @@current_room_count = XMLData.room_count
              foggy_exits = XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/
              room = @@list.find do |r|
                r.title.include?(XMLData.room_title) &&
                  r.description.include?(XMLData.room_description.strip) &&
                  (foggy_exits || r.paths.include?(XMLData.room_exits_string.strip))
              end

              if room
                redo unless @@current_room_count == XMLData.room_count
                if room.uid.any?
                  return room.uid.include?(XMLData.room_id) ? room.id : nil
                else
                  return room.id
                end
              else
                redo unless @@current_room_count == XMLData.room_count
                desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
                room = @@list.find do |r|
                  r.title.include?(XMLData.room_title) &&
                    (foggy_exits || r.paths.include?(XMLData.room_exits_string.strip)) &&
                    (XMLData.room_window_disabled || r.description.any? { |desc| desc =~ desc_regex })
                end

                if room
                  redo unless @@current_room_count == XMLData.room_count
                  if room.uid.any?
                    return room.uid.include?(XMLData.room_id) ? room.id : nil
                  else
                    return room.id
                  end
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

      def self.match_fuzzy
        @@fuzzy_room_mutex.synchronize do
          @@fuzzy_room_count = XMLData.room_count
          loop do
            foggy_exits = XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/
            room = @@list.find do |r|
              r.title.include?(XMLData.room_title) &&
                r.description.include?(XMLData.room_description.strip) &&
                (foggy_exits || r.paths.include?(XMLData.room_exits_string.strip))
            end

            if room
              redo unless @@fuzzy_room_count == XMLData.room_count

              if room.uid.any?
                return room.uid.include?(XMLData.room_id) ? room.id : nil
              elsif room.tags.any? { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
                return nil
              else
                return room.id
              end
            else
              redo unless @@fuzzy_room_count == XMLData.room_count
              desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
              room = @@list.find do |r|
                r.title.include?(XMLData.room_title) &&
                  (foggy_exits || r.paths.include?(XMLData.room_exits_string.strip)) &&
                  (XMLData.room_window_disabled || r.description.any? { |desc| desc =~ desc_regex })
              end

              if room
                redo unless @@fuzzy_room_count == XMLData.room_count

                if room.uid.any?
                  return room.uid.include?(XMLData.room_id) ? room.id : nil
                elsif room.tags.any? { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
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

      # Retrieves the current map or creates a new one if none exists.
      # @return [Map, nil] The current map or a new map if created.
      def self.current_or_new
        return nil unless Script.current

        @@current_room_count = -1
        @@fuzzy_room_count = -1

        self.load unless @@loaded

        id = current&.id

        echo("Map: current room id is #{id.inspect}")
        unless id.nil?
          room = self[id]
          unless XMLData.room_id.zero? || room.uid.include?(XMLData.room_id)
            room.uid << XMLData.room_id
            uids_add(XMLData.room_id, room.id)
            echo "Map: Adding new uid for #{room.id}: #{XMLData.room_id}"
          end
          return set_current(room.id)
        end

        id = get_free_id
        title = [XMLData.room_title]
        description = [XMLData.room_description.strip]
        paths = [XMLData.room_exits_string.strip]
        uid = XMLData.room_id.zero? ? [] : [XMLData.room_id]
        room = new(id, title, description, paths, uid)
        uids_add(XMLData.room_id, room.id) unless XMLData.room_id.zero?
        echo "mapped new room, set current room to #{room.id}"
        set_current(id)
      end

      # Sets the current map.
      # @param id [Integer] The ID of the map to set as current.
      # @return [Map, nil] The newly set current map, or nil if the ID is invalid.
      def self.set_current(id)
        @@previous_room_id = @@current_room_id if id != @@current_room_id
        @@current_room_id = id
        return nil if id.nil?

        @@list[id]
      end

      # Matches multiple IDs against the current map's wayto.
      # @param ids [Array] An array of IDs to match.
      # @return [Integer, nil] The matched ID if exactly one match is found, or nil.
      def self.match_multi_ids(ids)
        matches = ids.find_all { |s| @@list[@@current_room_id].wayto.keys.include?(s.to_s) }
        return matches[0] if matches.size == 1

        nil
      end

      # Loads unique IDs from the maps.
      def self.load_uids
        self.load unless @@loaded
        @@uids.clear
        @@list.each do |r|
          r.uid.each do |u|
            if @@uids[u].nil?
              @@uids[u] = [r.id]
            elsif !@@uids[u].include?(r.id)
              @@uids[u] << r.id
            end
          end
        end
      end

      # Retrieves the tags associated with the maps.
      # @return [Array] An array of unique tags.
      def self.tags
        self.load unless @@loaded
        @@tags = @@list.compact.each_with_object({}) { |r, h| r.tags.each { |t| h[t] = nil unless h.key?(t) } }.keys if @@tags.empty?
        @@tags.dup
      end

      # Retrieves map IDs associated with a given UID.
      # @param n [Integer] The UID to look up.
      # @return [Array] An array of map IDs associated with the UID.
      def self.ids_from_uid(n)
        @@uids[n].nil? || n.zero? ? [] : @@uids[n]
      end

      # Clears the map data and resets the state.
      def self.clear
        @@load_mutex.synchronize do
          @@list.clear
          @@tags.clear
          @@loaded = false
          GC.start
        end
        true
      end

      # Loads map data from files.
      # @param filename [String, nil] (optional) The filename to load from. If nil, loads all map files.
      # @return [Boolean] True if loading was successful, false otherwise.
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
      # @param filename [String, nil] (optional) The filename to load from. If nil, loads all JSON map files.
      # @return [Boolean] True if loading was successful, false otherwise.
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
                room['tags'] ||= []
                room['uid'] ||= []
                new(
                  room['id'], room['title'], room['description'], room['paths'],
                  room['uid'], room['location'], room['climate'], room['terrain'],
                  room['wayto'], room['timeto'], room['image'], room['image_coords'],
                  room['tags'], room['check_location'], room['unique_loot'],
                  nil, # _room_objects
                  room['genie_id'], room['genie_zone'], room['genie_pos']
                )
              end
            end
            @@tags.clear
            respond "--- Map loaded #{filename}"
            @@loaded = true
            load_uids
            return true
          end
        end
      end

      # Loads map data from an XML file.
      # @param filename [String] The filename to load from.
      # @return [Boolean] True if loading was successful, false otherwise.
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
              room['room_objects'] = []
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
            elsif current_tag =~ /^(?:title|description|paths|unique_loot|tag|room_objects)$/
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
              room['room_objects'] = nil if room['room_objects'].empty?
              new(
                room['id'], room['title'], room['description'], room['paths'],
                room['uid'], room['location'], room['climate'], room['terrain'],
                room['wayto'], room['timeto'], room['image'], room['image_coords'],
                room['tags'], room['check_location'], room['unique_loot'], room['room_objects']
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

      def self.save_xml(_filename = nil)
        respond '--- WARNING: Map.save_xml is deprecated. Use Map.save_json instead.'
      end
    end

    # Represents a room in the map.
    # This class inherits from Map and can be extended with additional functionality.
    # @example Creating a room
    #   room = Lich::Common::Room.new(1, "Room Title", "Room Description", [])
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
