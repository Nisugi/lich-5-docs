

module Lich
  module Common
    # Indicates whether core map overrides are enabled
    CORE_MAP_OVERRIDES = true

    # A class representing a minimum heap data structure.
    # Provides methods to push and pop elements based on priority.
    # @example Creating a MinHeap and using it
    #   heap = MinHeap.new
    #   heap.push(1, "low priority")
    #   heap.push(0, "high priority")
    #   heap.pop # => [0, "high priority"]
    class MinHeap
      def initialize
        @heap = []
      end

      # Pushes a value onto the heap with a given priority.
      # @param priority [Integer] The priority of the value to be pushed.
      # @param value [Object] The value to be pushed onto the heap.
      # @return [void]
      # @example
      #   heap.push(1, "low priority")
      def push(priority, value)
        @heap << [priority, value]
        bubble_up(@heap.size - 1)
      end

      # Pops the minimum value from the heap.
      # @return [Array, nil] The minimum value and its priority, or nil if the heap is empty.
      # @example
      #   heap.pop # => [0, "high priority"]
      def pop
        return nil if @heap.empty?

        swap(0, @heap.size - 1)
        min = @heap.pop
        bubble_down(0) unless @heap.empty?
        min
      end

      # Checks if the heap is empty.
      # @return [Boolean] True if the heap is empty, false otherwise.
      # @example
      #   heap.empty? # => false
      def empty?
        @heap.empty?
      end

      private

      def bubble_up(index)
        while index.positive?
          parent_index = (index - 1) / 2
          break if @heap[index][0] >= @heap[parent_index][0]

          swap(index, parent_index)
          index = parent_index
        end
      end

      def bubble_down(index)
        loop do
          left_child = (2 * index) + 1
          right_child = (2 * index) + 2
          break if left_child >= @heap.size

          min_child = if right_child >= @heap.size || @heap[left_child][0] < @heap[right_child][0]
                        left_child
                      else
                        right_child
                      end

          break if @heap[index][0] <= @heap[min_child][0]

          swap(index, min_child)
          index = min_child
        end
      end

      def swap(i, j)
        @heap[i], @heap[j] = @heap[j], @heap[i]
      end
    end

    # A module that provides map-related functionality.
    # This module can be included in classes to add map capabilities.
    # @example Including MapBase in a class
    #   class MyMap
    #     include MapBase
    #   end
    module MapBase
      def self.included(base)
        base.extend(ClassMethods)
        base.include(InstanceMethods)
      end

      module ClassMethods
        # Retrieves the next available ID for a map entry.
        # @return [Integer] The next available ID.
        # @example
        #   free_id = MyMap.get_free_id
        def get_free_id
          self.load unless loaded?
          list.compact.max_by(&:id).id + 1
        end

        # Estimates the time required to traverse a given array of rooms.
        # @param array [Array] An array of room identifiers.
        # @return [Float] The estimated time to traverse the rooms.
        # @raise [Exception] If the provided array is not an Array.
        # @example
        #   time = MyMap.estimate_time(["room1", "room2"])
        def estimate_time(array)
          self.load unless loaded?
          unless array.is_a?(Array)
            raise Exception.exception('MapError'), 'Map.estimate_time was given something not an array!'
          end

          time = 0.0
          until array.length < 2
            room = array.shift
            t = self[room].timeto[array.first.to_s]
            if t
              time += t.is_a?(StringProc) ? t.call.to_f : t.to_f
            else
              time += 0.2
            end
          end
          time
        end

        def dijkstra(source, destination = nil)
          if source.is_a?(self)
            source.dijkstra(destination)
          elsif (room = self[source])
            room.dijkstra(destination)
          else
            echo 'Map.dijkstra: error: invalid source room'
            nil
          end
        end

        # Finds the path from a source to a destination room.
        # @param source [Object] The source room or identifier.
        # @param destination [Object] The destination room or identifier.
        # @return [Array, nil] An array representing the path, or nil if no path is found.
        # @example
        #   path = MyMap.findpath(source_room, destination_room)
        def findpath(source, destination)
          if source.is_a?(self)
            source.path_to(destination)
          elsif (room = self[source])
            room.path_to(destination)
          else
            echo 'Map.findpath: error: invalid source room'
            nil
          end
        end

        # Reloads the map data from the source.
        # @return [void]
        # @example
        #   MyMap.reload
        def reload
          clear
          load
        end

        # Adds a unique identifier to the list of IDs for a given UID.
        # @param uid [String] The unique identifier.
        # @param id [Integer] The ID to associate with the UID.
        # @return [void]
        # @example
        #   MyMap.uids_add("user1", 42)
        def uids_add(uid, id)
          uids[uid] ||= []
          uids[uid] << id unless uids[uid].include?(id)
        end

        # Retrieves the list of IDs associated with a given UID.
        # @param uid [String] The unique identifier.
        # @return [Array] An array of IDs associated with the UID.
        # @example
        #   ids = MyMap.ids_from_uid("user1")
        def ids_from_uid(uid)
          uids[uid] || []
        end

        def to_json(*args)
          list.delete_if(&:nil?)
          list.sort_by(&:id).to_json(args)
        end

        # Saves the map data to a JSON file.
        # @param filename [String, nil] The name of the file to save to (optional).
        # @return [void]
        # @example
        #   MyMap.save_json("map.json")
        def save_json(filename = nil)
          filename ||= File.join(DATA_DIR, XMLData.game, "map-#{Time.now.to_i}.json")
          if File.exist?(filename)
            respond 'File exists!  Backing it up before proceeding...'
            begin
              File.open(filename, 'rb') do |infile|
                File.open("#{filename}.bak", 'wb:UTF-8') do |outfile|
                  outfile.write(infile.read)
                end
              end
            rescue StandardError => e
              respond "--- Lich: error: #{e}\n\t#{e.backtrace[0..1].join("\n\t")}"
              Lich.log "error: #{e}\n\t#{e.backtrace.join("\n\t")}"
            end
          end
          File.open(filename, 'wb:UTF-8') { |file| file.write(to_json) }
          respond "#{filename} saved"
          # Reload if map index appears corrupted
          reload if self[-1].id != self[self[-1].id].id
        end

        alias_method :save, :save_json

        # Loads map data from a .dat file.
        # @param filename [String, nil] The name of the file to load from (optional).
        # @return [Boolean] True if loading was successful, false otherwise.
        # @raise [StandardError] If an error occurs during loading.
        # @example
        #   success = MyMap.load_dat("map.dat")
        def load_dat(filename = nil)
          respond '--- WARNING: Map.load_dat (Marshal .dat format) is deprecated. Use Map.load_json instead.'
          synchronize_load do
            return true if loaded?

            file_list = if filename.nil?
                          Dir.entries(File.join(DATA_DIR, XMLData.game))
                             .find_all { |fn| fn =~ /^map-[0-9]+\.dat$/ }
                             .collect { |fn| File.join(DATA_DIR, XMLData.game, fn) }
                             .sort
                             .reverse
                        else
                          respond "--- file_list = #{filename.inspect}"
                          [filename]
                        end

            if file_list.empty?
              respond '--- Lich: error: no map database found'
              return false
            end

            while (filename = file_list.shift)
              begin
                self.list = File.open(filename, 'rb') { |f| Marshal.load(f.read) }
                respond "--- Map loaded #{filename}"
                mark_loaded
                load_uids
                return true
              rescue StandardError => e
                if file_list.empty?
                  respond "--- Lich: error: failed to load #{filename}: #{e}"
                else
                  respond "--- warning: failed to load #{filename}: #{e}"
                end
              end
            end
            false
          end
        end

        # Applies overrides for wayto settings based on user preferences.
        # @return [void]
        # @example
        #   MyMap.apply_wayto_overrides
        def apply_wayto_overrides
          self.load unless loaded?
          settings = get_settings
          base_overrides = settings.base_wayto_overrides || {}
          personal_overrides = settings.personal_wayto_overrides || {}
          wayto_overrides = base_overrides.merge(personal_overrides)

          wayto_overrides.each do |_key, values|
            next unless values.is_a?(Hash) && values['start_room'] && values['end_room']

            start_room_id = values['start_room'].to_i
            end_room_id = values['end_room'].to_s
            start_room = list[start_room_id]
            next unless start_room

            if values['str_proc']
              start_room.wayto[end_room_id] = StringProc.new(values['str_proc'].to_s)
            end
            if values['travel_time']
              new_timeto = Float(values['travel_time'], exception: false)
              new_timeto ||= StringProc.new(values['travel_time'].to_s)
              start_room.timeto[end_room_id] = new_timeto
            end
          end

          personal_map_targets = settings.personal_map_targets
          if personal_map_targets.is_a?(Hash)
            custom_targets = (GameSettings['custom targets'] || {})
            custom_targets.merge!(personal_map_targets)
            GameSettings['custom targets'] = custom_targets
          end
        end
      end

      module InstanceMethods
        # Converts the map instance to an integer ID.
        # @return [Integer] The ID of the map instance.
        # @example
        #   id = map_instance.to_i
        def to_i
          @id
        end

        # Checks if the map instance is outside.
        # @return [Boolean] True if the instance is outside, false otherwise.
        # @example
        #   is_outside = map_instance.outside?
        def outside?
          return false if @paths.nil? || @paths.empty?

          @paths.last =~ /^Obvious paths:/ ? true : false
        end

        # Checks if the map instance is inside.
        # @return [Boolean] True if the instance is inside, false otherwise.
        # @example
        #   is_inside = map_instance.inside?
        def inside?
          !outside?
        end

        # Returns a string representation of the map instance.
        # @return [String] The string representation of the instance.
        # @example
        #   puts map_instance.inspect
        def inspect
          instance_variables.collect do |var|
            "#{var}=#{instance_variable_get(var).inspect}"
          end.join("\n")
        end

        # Returns additional fields for JSON representation.
        # @return [Hash] A hash of extra fields.
        # @example
        #   extra_fields = map_instance.json_extra_fields
        def json_extra_fields
          {}
        end

        # Converts the map instance to JSON format.
        # @param args [Array] Additional arguments for JSON generation.
        # @return [String] The JSON representation of the map instance.
        # @example
        #   json_data = map_instance.to_json
        def to_json(*_args)
          mapjson = {
            id: @id,
            title: @title,
            description: @description,
            paths: @paths,
            location: @location,
            climate: @climate,
            terrain: @terrain,
            wayto: @wayto&.sort_by { |k, _v| k.to_i }&.to_h,
            timeto: @timeto&.sort_by { |k, _v| k.to_i }&.to_h,
            image: @image,
            image_coords: @image_coords,
            tags: @tags&.sort_by(&:downcase),
            check_location: @check_location,
            unique_loot: @unique_loot,
            uid: @uid
          }
          mapjson.merge!(json_extra_fields)
          mapjson.delete_if { |_a, b| b.nil? || (b.is_a?(Array) && b.empty?) }
          JSON.pretty_generate(mapjson)
        end

        # Performs Dijkstra's algorithm to find the shortest path to a destination.
        # @param destination [Object, nil] The destination room or identifier (optional).
        # @return [Array, nil] An array containing the previous nodes and shortest distances, or nil on error.
        # @raise [StandardError] If an error occurs during processing.
        # @example
        #   path = map_instance.dijkstra(destination_room)
        def dijkstra(destination = nil)
          self.class.load unless self.class.loaded?
          source = @id
          visited = {}
          shortest_distances_hash = {}
          previous_hash = {}

          pq = MinHeap.new
          pq.push(0, source)
          shortest_distances_hash[source] = 0

          check_destination = proc do |v, dist|
            case destination
            when Integer
              v == destination
            when Array
              destination.include?(v) && dist < 20
            else
              false
            end
          end

          until pq.empty?
            current_dist, v = pq.pop

            next if visited[v]
            break if check_destination.call(v, current_dist)

            visited[v] = true

            self.class.list[v].wayto.keys.each do |adj_room|
              adj_room_i = adj_room.to_i
              next if visited[adj_room_i]

              edge_weight = if self.class.list[v].timeto[adj_room].is_a?(StringProc)
                              self.class.list[v].timeto[adj_room].call
                            else
                              self.class.list[v].timeto[adj_room]
                            end

              next unless edge_weight

              new_distance = current_dist + edge_weight

              if !shortest_distances_hash[adj_room_i] || shortest_distances_hash[adj_room_i] > new_distance
                shortest_distances_hash[adj_room_i] = new_distance
                previous_hash[adj_room_i] = v
                pq.push(new_distance, adj_room_i)
              end
            end
          end

          # Convert hashes back to arrays for backward compatibility
          max_room_id = [previous_hash.keys.max, shortest_distances_hash.keys.max].compact.max || 0
          previous = Array.new(max_room_id + 1)
          shortest_distances = Array.new(max_room_id + 1)

          previous_hash.each { |key, value| previous[key] = value }
          shortest_distances_hash.each { |key, value| shortest_distances[key] = value }

          [previous, shortest_distances]
        rescue StandardError => e
          echo "Map.dijkstra: error: #{e}"
          respond e.backtrace
          nil
        end

        # Finds the path to a specified destination room.
        # @param destination [Object] The destination room or identifier.
        # @return [Array, nil] An array representing the path, or nil if no path is found.
        # @example
        #   path = map_instance.path_to(destination_room)
        def path_to(destination)
          self.class.load unless self.class.loaded?
          destination = destination.to_i
          previous, = dijkstra(destination)
          return nil unless previous[destination]

          path = [destination]
          path.push(previous[path[-1]]) until previous[path[-1]] == @id
          path.reverse
        end

        # Finds the nearest room with a specified tag.
        # @param tag_name [String] The name of the tag to search for.
        # @return [Integer, nil] The ID of the nearest room with the tag, or nil if none found.
        # @example
        #   nearest_room_id = map_instance.find_nearest_by_tag("treasure")
        def find_nearest_by_tag(tag_name)
          target_list = []
          self.class.list.each { |room| target_list.push(room.id) if room.tags.include?(tag_name) }
          _, shortest_distances = self.class.dijkstra(@id, target_list)
          if target_list.include?(@id)
            @id
          else
            target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
            target_list.sort { |a, b| shortest_distances[a] <=> shortest_distances[b] }.first
          end
        end

        # Finds all nearest rooms with a specified tag.
        # @param tag_name [String] The name of the tag to search for.
        # @return [Array] An array of IDs of the nearest rooms with the tag.
        # @example
        #   nearest_rooms = map_instance.find_all_nearest_by_tag("treasure")
        def find_all_nearest_by_tag(tag_name)
          target_list = []
          self.class.list.each { |room| target_list.push(room.id) if room.tags.include?(tag_name) }
          _, shortest_distances = self.class.dijkstra(@id)
          target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
          target_list.sort { |a, b| shortest_distances[a] <=> shortest_distances[b] }
        end

        # Finds the nearest room from a list of target rooms.
        # @param target_list [Array] An array of room identifiers to search from.
        # @return [Integer, nil] The ID of the nearest room, or nil if none found.
        # @example
        #   nearest_room_id = map_instance.find_nearest([1, 2, 3])
        def find_nearest(target_list)
          target_list = target_list.collect(&:to_i)
          if target_list.include?(@id)
            @id
          else
            _, shortest_distances = self.class.dijkstra(@id, target_list)
            valid_rooms = target_list.select { |room_num| shortest_distances[room_num].is_a?(Numeric) }
            valid_rooms.min_by { |room_num| shortest_distances[room_num] }
          end
        end

        # Returns the description of the map instance.
        # @return [String] The description of the map.
        # @example
        #   description = map_instance.desc
        def desc
          @description
        end

        # Returns the name of the map image.
        # @return [String] The name of the map image.
        # @example
        #   image_name = map_instance.map_name
        def map_name
          @image
        end

        # Returns the X coordinate of the map image.
        # @return [Integer, nil] The X coordinate, or nil if not available.
        # @example
        #   x_coord = map_instance.map_x
        def map_x
          return nil if @image_coords.nil?

          ((image_coords[0] + image_coords[2]) / 2.0).round
        end

        # Returns the Y coordinate of the map image.
        # @return [Integer, nil] The Y coordinate, or nil if not available.
        # @example
        #   y_coord = map_instance.map_y
        def map_y
          return nil if @image_coords.nil?

          ((image_coords[1] + image_coords[3]) / 2.0).round
        end

        # Returns the size of the map room.
        # @return [Integer, nil] The size of the room, or nil if not available.
        # @example
        #   room_size = map_instance.map_roomsize
        def map_roomsize
          return nil if @image_coords.nil?

          image_coords[2] - image_coords[0]
        end

        # Returns geographical information for the map.
        # @return [nil] Always returns nil.
        # @example
        #   geo_info = map_instance.geo
        def geo
          nil
        end
      end
    end
  end
end
