# frozen_string_literal: true

require 'rexml/document'

module Lich
  module Common
    # Represents a game object in the world.
    #
    # @see Lich::Common::RoomObj for a specialized game object.
    class GameObj
      # ---------------------------------------------------------------------------
      # Class-level registries
      # ---------------------------------------------------------------------------

      @@loot          = []
      @@npcs          = []
      @@npc_status    = {}
      @@pcs           = []
      @@pc_status     = {}
      @@inv           = []
      @@reserve       = nil
      @@contents      = {}
      @@right_hand    = nil
      @@left_hand     = nil
      @@room_desc     = []
      @@fam_loot      = []
      @@fam_npcs      = []
      @@fam_pcs       = []
      @@fam_room_desc = []
      @@type_data     = {}
      @@type_cache    = {}
      @@sellable_data = {}

      # ---------------------------------------------------------------------------
      # Shared identity index — single persistent O(1) lookup pool with TTL.
      #
      # Maps composite key String <tt>"id|noun|name"</tt> to a two-element array
      # <tt>[GameObj, last_seen_at]</tt> where +last_seen_at+ is a Float timestamp
      # (from +Process.clock_gettime(Process::CLOCK_MONOTONIC)+) recording when
      # the entry was last accessed by +find_or_create+.
      #
      # All registries share this one index because a GameObj with the same
      # id, noun, and name is the same logical game entity regardless of which
      # registry it belongs to.
      #
      # The index is intentionally *not* flushed when a registry is cleared.
      # Room transitions call multiple +clear_*+ methods in quick succession;
      # flushing on every clear would cause every re-encountered object to be
      # needlessly reallocated. Instead, stale index entries self-heal: when
      # +find_or_create+ finds an entry for an object that was cleared from
      # its registry, it simply re-adds that same instance to the target
      # registry and refreshes its +last_seen_at+ timestamp.
      #
      # Garbage collection is handled by +prune_index!+, which removes entries
      # whose +last_seen_at+ is older than a given TTL (default 15 minutes).
      # Call it at natural session breakpoints (e.g. after a room transition or
      # from a script's idle loop). It is safe to call frequently — entries that
      # were just accessed will never be pruned regardless of how often it runs.
      #
      # Use +index_stats+ to inspect the current state of the index at any time.
      #
      # For very long automated sessions an alternative +LruIndex+ drop-in is
      # also available — see +Lich::Common::LruIndex+ below.
      # ---------------------------------------------------------------------------

      @@index = {}


      attr_reader :id

      attr_accessor :noun

      attr_accessor :name

      attr_accessor :before_name

      attr_accessor :after_name

      # Initializes a new game object.
      # @param id [String] unique object ID
      # @param noun [String] object noun (e.g., "sword", "backpack")
      # @param name [String] object name
      # @param before [String, nil] optional prefix for the name
      # @param after [String, nil] optional suffix for the name
      # @return [GameObj]
      def initialize(id, noun, name, before = nil, after = nil)
        @id          = id.is_a?(Integer) ? id.to_s : id
        @noun        = normalize_noun(noun, name)
        @name        = name
        @before_name = before
        @after_name  = after
      end

      def to_s
        @noun
      end

      def GameObj
        @noun
      end

      def empty?
        false
      end

      def contents
        @@contents[@id]&.dup
      end

      def full_name
        parts = [@before_name, @name, @after_name]
        parts.compact.reject(&:empty?).join(' ')
      end


      # Retrieves the type of the game object based on its name.
      # @return [String, nil] a comma-separated list of types or nil if none found.
      def type
        GameObj.load_data if @@type_data.empty?
        return @@type_cache[@name] if @@type_cache.key?(@name)

        matches = matching_data_keys(@@type_data)
        @@type_cache[@name] = matches.empty? ? nil : matches.join(',')
      end

      def type?(type_to_check)
        type.to_s.split(',').include?(type_to_check)
      end

      # Retrieves the sellable types of the game object.
      # @return [String, nil] a comma-separated list of sellable types or nil if none found.
      def sellable
        GameObj.load_data if @@sellable_data.empty?
        matches = matching_data_keys(@@sellable_data)
        matches.empty? ? nil : matches.join(',')
      end


      def status
        return @@npc_status[@id] if @@npc_status.key?(@id)
        return @@pc_status[@id]  if @@pc_status.key?(@id)

        present_in_any_registry? ? nil : 'gone'
      end

      def status=(val)
        if @@npcs.any? { |npc| npc.id == @id }
          @@npc_status[@id] = val
        elsif @@pcs.any? { |pc| pc.id == @id }
          @@pc_status[@id] = val
        end
      end


      # Creates a new NPC game object and registers it.
      # @param id [String] unique NPC ID
      # @param noun [String] NPC noun
      # @param name [String] NPC name
      # @param status [String, nil] optional status of the NPC
      # @return [GameObj] the created NPC object.
      def self.new_npc(id, noun, name, status = nil)
        obj = find_or_create(@@npcs, id, noun, name)
        @@npc_status[obj.id] = status
        obj
      end

      def self.new_loot(id, noun, name)
        find_or_create(@@loot, id, noun, name)
      end

      # Creates a new player character game object and registers it.
      # @param id [String] unique PC ID
      # @param noun [String] PC noun
      # @param name [String] PC name
      # @param status [String, nil] optional status of the PC
      # @return [GameObj] the created PC object.
      def self.new_pc(id, noun, name, status = nil)
        obj = find_or_create(@@pcs, id, noun, name)
        @@pc_status[obj.id] = status
        obj
      end

      def self.new_inv(id, noun, name, container = nil, before = nil, after = nil)
        if container
          @@contents[container] ||= []
          find_or_create(@@contents[container], id, noun, name, before, after)
        else
          find_or_create(@@inv, id, noun, name, before, after)
        end
      end

      def self.new_reserve(id, noun, name)
        @@reserve ||= []
        find_or_create(@@reserve, id, noun, name)
      end

      def self.new_room_desc(id, noun, name)
        find_or_create(@@room_desc, id, noun, name)
      end

      def self.new_fam_room_desc(id, noun, name)
        find_or_create(@@fam_room_desc, id, noun, name)
      end

      def self.new_fam_loot(id, noun, name)
        find_or_create(@@fam_loot, id, noun, name)
      end

      def self.new_fam_npc(id, noun, name)
        find_or_create(@@fam_npcs, id, noun, name)
      end

      def self.new_fam_pc(id, noun, name)
        find_or_create(@@fam_pcs, id, noun, name)
      end

      def self.new_right_hand(id, noun, name)
        @@right_hand = index_or_create(id, noun, name)
      end

      def self.new_left_hand(id, noun, name)
        @@left_hand = index_or_create(id, noun, name)
      end

      # Looks up an existing +GameObj+ in the shared identity index by composite
      # key (+id+, +noun+, +name+), or creates and indexes a new one.
      #
      # Unlike +find_or_create+, this method does *not* push the object into any
      # Looks up an existing game object in the shared identity index by composite key (id, noun, name), or creates and indexes a new one.
      # @param id [String] unique object ID
      # @param noun [String] object noun
      # @param name [String] object name
      # @param before [String, nil] optional prefix for the name
      # @param after [String, nil] optional suffix for the name
      # @return [GameObj] the found or newly created game object.
      def self.index_or_create(id, noun, name, before = nil, after = nil)
        str_id = id.is_a?(Integer) ? id.to_s : id
        key    = "#{str_id}|#{noun}|#{name}"
        now    = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        if (entry = @@index[key])
          existing, _ts        = entry
          @@index[key]         = [existing, now]
          existing.before_name = before if existing.before_name.nil? && !before.nil?
          existing.after_name  = after  if existing.after_name.nil?  && !after.nil?
          return existing
        end

        obj          = GameObj.new(id, noun, name, before, after)
        @@index[key] = [obj, now]
        obj
      end


      def self.right_hand  = @@right_hand&.dup

      def self.left_hand   = @@left_hand&.dup

      def self.npcs        = registry_or_nil(@@npcs)

      def self.loot        = registry_or_nil(@@loot)

      def self.pcs         = registry_or_nil(@@pcs)

      def self.inv         = registry_or_nil(@@inv)

      def self.reserve     = @@reserve&.dup

      def self.room_desc   = registry_or_nil(@@room_desc)

      def self.fam_room_desc = registry_or_nil(@@fam_room_desc)

      def self.fam_loot    = registry_or_nil(@@fam_loot)

      def self.fam_npcs    = registry_or_nil(@@fam_npcs)

      def self.fam_pcs     = registry_or_nil(@@fam_pcs)

      def self.containers  = @@contents.dup


      def self.clear_loot          = @@loot.clear

      def self.clear_npcs          = (@@npcs.clear; @@npc_status.clear)

      def self.clear_pcs           = (@@pcs.clear; @@pc_status.clear)

      def self.clear_inv           = @@inv.clear

      def self.clear_reserve       = (@@reserve = [])

      def self.clear_room_desc     = @@room_desc.clear

      def self.clear_fam_room_desc = @@fam_room_desc.clear

      def self.clear_fam_loot      = @@fam_loot.clear

      def self.clear_fam_npcs      = @@fam_npcs.clear

      def self.clear_fam_pcs       = @@fam_pcs.clear

      def self.clear_all_containers = @@contents.clear

      def self.clear_container(container_id)
        @@contents[container_id] = []
      end

      def self.delete_container(container_id)
        @@contents.delete(container_id)
      end


      def self.[](val)
        unless val.is_a?(String) || val.is_a?(Regexp)
          respond "--- Lich: error: GameObj[] passed with #{val.class} #{val} via caller: #{caller[0]}"
          respond "--- Lich: error: GameObj[] supports String or Regexp only"
          Lich.log "--- Lich: error: GameObj[] passed with #{val.class} #{val} via caller: #{caller[0]}\n\t"
          Lich.log "--- Lich: error: GameObj[] supports String or Regexp only\n\t"

          if val.is_a?(Integer)
            respond "--- Lich: error: GameObj[] converted Integer #{val} to String to continue"
            val = val.to_s
          else
            return nil
          end
        end

        if val.is_a?(Regexp)
          return search_registries { |o| o.name =~ val }
        end

        if val =~ /^\-?[0-9]+$/
          # Numeric ID lookup (room_desc excluded from primary, appended last for completeness)
          search_registries { |o| o.id == val }
        elsif val.split(' ').length == 1
          # Single-word noun lookup
          search_registries { |o| o.noun == val }
        else
          # Name lookup — exact first, then suffix, then fuzzy suffix
          escaped     = Regexp.escape(val.strip)
          fuzzy       = Regexp.escape(val).sub(' ', ' .*')
          search_registries { |o| o.name == val } ||
            search_registries { |o| o.name =~ /\b#{escaped}$/i } ||
            search_registries { |o| o.name =~ /\b#{fuzzy}$/i }
        end
      end


      def self.targets
        XMLData.current_target_ids.filter_map do |id|
          npc = @@npcs.find { |n| n.id == id }
          next unless npc
          next if npc.status.to_s =~ /dead|gone/i
          next if npc.name  =~ /^animated\b/i && npc.name !~ /^animated slush/i
          next if npc.noun  =~ /^(?:arm|appendage|claw|limb|pincer|tentacle)s?$|^(?:palpus|palpi)$/i &&
                  npc.name !~ /(?:amaranthine|ghostly|grizzled|ancient) kraken tentacle/i
          npc
        end
      end

      def self.hidden_targets
        XMLData.current_target_ids.reject { |id| @@npcs.any? { |n| n.id == id } }
      end

      def self.target
        (@@npcs + @@pcs).find { |n| n.id == XMLData.current_target_id }
      end

      def self.dead
        dead_list = @@npcs.select { |obj| obj.status == 'dead' }
        dead_list.empty? ? nil : dead_list
      end

      # ---------------------------------------------------------------------------
      # Index lifecycle — pruning & diagnostics
      # ---------------------------------------------------------------------------

      # Removes entries from the shared identity index whose +last_seen_at+
      # timestamp is older than +ttl+ seconds ago **and** whose object is not
      # currently present in any active registry, then GC-hints Ruby.
      #
      # The live-registry check is the critical guard: an object that is still
      # held in +@@npcs+, +@@loot+, +@@inv+, or any other registry must never be
      # pruned regardless of how long ago it was last re-registered. Pruning a
      # live entry would cause the next +find_or_create+ call for that object to
      # allocate a brand-new instance, silently breaking the identity guarantee.
      #
      # An entry is only eligible for pruning when *both* conditions are true:
      #   1. +last_seen_at+ is older than +ttl+ seconds ago
      #   2. The object's ID is not present in any active registry
      #
      # Safe to call at any time and as frequently as desired. Entries that are
      # live in registries are always skipped. Entries accessed within the TTL
      # window are always skipped.
      # Removes entries from the shared identity index whose last_seen_at timestamp is older than ttl seconds ago and whose object is not currently present in any active registry.
      # @param ttl [Integer] the time-to-live in seconds for entries in the index
      # @param verbose [Boolean] whether to print detailed output
      # @return [Hash] a summary of the pruning operation.
      def self.prune_index!(ttl: 900, verbose: false)
        require 'objspace'
        t_start   = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        cutoff    = t_start - ttl

        # Build the live-ID set once before the sweep so we do not repeatedly
        # iterate all registries inside the delete_if block.
        live_ids = live_registry_ids

        obj_before  = gameobj_memory_bytes
        heap_before = ruby_heap_bytes

        pruned       = 0
        skipped_live = 0

        @@index.delete_if do |_key, (obj, last_seen)|
          if live_ids.include?(obj.id)
            # Object is currently held in a registry — never prune regardless of age.
            skipped_live += 1
            false
          elsif last_seen < cutoff
            pruned += 1
            true
          else
            false
          end
        end

        GC.start(full_mark: false, immediate_sweep: false) if pruned.positive?

        obj_after  = gameobj_memory_bytes
        heap_after = ruby_heap_bytes
        elapsed    = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t_start) * 1000

        result = {
          pruned: pruned,
          skipped_live: skipped_live,
          remaining: @@index.size,
          gameobj_bytes_before: obj_before,
          gameobj_bytes_after: obj_after,
          gameobj_bytes_freed: obj_before - obj_after,
          heap_bytes_before: heap_before,
          heap_bytes_after: heap_after,
          heap_bytes_freed: heap_before - heap_after,
          elapsed_ms: elapsed.round(3)
        }

        if verbose
          w = 28
          puts "=" * 52
          puts "  GameObj.prune_index! - TTL: #{ttl}s"
          puts "=" * 52
          puts format("  %-#{w}s %s -> %s  (%s)",
                      "GameObj object memory:",
                      format_bytes(obj_before),
                      format_bytes(obj_after),
                      format_delta(result[:gameobj_bytes_freed]))
          puts format("  %-#{w}s %s -> %s  (%s)",
                      "Ruby heap size:",
                      format_bytes(heap_before),
                      format_bytes(heap_after),
                      format_delta(result[:heap_bytes_freed]))
          puts format("  %-#{w}s %d removed, %d skipped (live), %d remaining",
                      "Index entries:",
                      pruned,
                      skipped_live,
                      @@index.size)
          puts format("  %-#{w}s %.3f ms", "Elapsed:", elapsed)
          puts "=" * 52
        end

        result
      end

      # Provides statistics about the current state of the index.
      # @param verbose [Boolean] whether to print detailed output
      # @return [Hash] a summary of index statistics.
      def self.index_stats(verbose: false)
        require 'objspace'
        return empty_index_stats if @@index.empty?

        now        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        live_ids   = live_registry_ids
        buckets    = { 'under5m' => 0, '5-15m' => 0,
                       '15-30m' => 0, '30-60m' => 0, 'over60m' => 0 }
        stale      = 0
        oldest_age = 0.0

        @@index.each_value do |obj, last_seen|
          age        = now - last_seen
          oldest_age = age if age > oldest_age
          stale     += 1 unless live_ids.include?(obj.id)

          buckets[case age
                  when 0...300    then 'under5m'
                  when 300...900  then '5-15m'
                  when 900...1800 then '15-30m'
                  when 1800...3600 then '30-60m'
                  else 'over60m'
                  end] += 1
        end

        obj_mem  = gameobj_memory_bytes
        heap_mem = ruby_heap_bytes

        result = {
          total_entries: @@index.size,
          live_in_registries: @@index.size - stale,
          stale_entries: stale,
          oldest_entry_seconds: oldest_age.round(1),
          age_buckets: buckets,
          gameobj_bytes: obj_mem,
          heap_bytes: heap_mem
        }

        if verbose
          oldest_fmt = if oldest_age < 60
                         "#{oldest_age.round(1)}s"
                       elsif oldest_age < 3600
                         "#{(oldest_age / 60).round(1)}m"
                       else
                         "#{(oldest_age / 3600).round(2)}h"
                       end

          w = 28
          puts "=" * 52
          puts "  GameObj.index_stats"
          puts "=" * 52
          puts format("  %-#{w}s %d", "Total index entries:",  @@index.size)
          puts format("  %-#{w}s %d", "Live in registries:",   result[:live_in_registries])
          puts format("  %-#{w}s %d", "Stale (index-only):",   stale)
          puts format("  %-#{w}s %s", "Oldest entry:",         oldest_fmt)
          puts "-" * 52
          puts "  Age distribution:"
          buckets.each do |label, count|
            bar = "#" * [count, 30].min
            puts format("  %-10s %4d  %s", label, count, bar)
          end
          puts "-" * 52
          puts format("  %-#{w}s %s", "GameObj object memory:", format_bytes(obj_mem))
          puts format("  %-#{w}s %s", "Ruby heap size:", format_bytes(heap_mem))
          puts "=" * 52
        end

        result
      end


      # Reloads the game object data from the specified file.
      # @param filename [String, nil] optional path to the data file
      # @return [Boolean] true if the reload was successful, false otherwise.
      def self.reload(filename = nil)
        load_data(filename)
      end

      def self.merge_data(existing, new_value)
        existing.is_a?(Regexp) ? Regexp.union(existing, new_value) : new_value
      end

      def self.load_data(filename = nil)
        primary = filename || File.join(DATA_DIR, 'gameobj-data.xml')

        unless File.exist?(primary)
          @@type_data = @@sellable_data = nil
          echo "error: GameObj.load_data: file does not exist: #{primary}"
          return false
        end

        begin
          @@type_data     = {}
          @@sellable_data = {}
          @@type_cache    = {}
          parse_data_file(primary)
        rescue => e
          @@type_data = @@sellable_data = nil
          echo "error: GameObj.load_data: #{e}"
          respond e.backtrace[0..1]
          return false
        end

        custom = File.join(DATA_DIR, 'gameobj-custom', 'gameobj-data.xml')
        if File.exist?(custom)
          begin
            parse_data_file(custom, merge: true)
          rescue => e
            echo "error: Custom GameObj.load_data: #{e}"
            respond e.backtrace[0..1]
            return false
          end
        end

        true
      end

      def self.type_data     = @@type_data

      def self.type_cache    = @@type_cache

      def self.sellable_data = @@sellable_data

      # ---------------------------------------------------------------------------
      private


      def normalize_noun(noun, name)
        case noun
        when 'lapis lazuli'   then 'lapis'
        when 'Hammer of Kai'  then 'hammer'
        when 'ball and chain' then 'ball'
        when 'pearl'
          (name =~ /mother\-of\-pearl/) ? 'mother-of-pearl' : noun
        else
          noun
        end
      end

      def matching_data_keys(data_hash)
        data_hash.keys.select do |t|
          entry = data_hash[t]
          matches = (@name =~ entry[:name] || @noun =~ entry[:noun])
          excluded = entry[:exclude] && @name =~ entry[:exclude]
          matches && !excluded
        end
      end

      def present_in_any_registry?
        all_flat_registries.any? { |obj| obj.id == @id } ||
          @@contents.values.any? { |list| list.any? { |obj| obj.id == @id } }
      end

      def all_flat_registries
        [*@@loot, *@@inv, *@@reserve, *@@room_desc,
         *@@fam_loot, *@@fam_npcs, *@@fam_pcs, *@@fam_room_desc,
         @@right_hand, @@left_hand].compact
      end


      class << self
        private

        # All ordered search registries for +[]+, hands wrapped in an array to
        # use the same +#find+ interface.
        SEARCH_ORDER = proc do
          [@@inv, Array(@@reserve), @@loot, @@npcs, @@pcs,
           [@@right_hand, @@left_hand].compact,
           @@room_desc,
           @@contents.values.flatten]
        end

        def search_registries(&block)
          SEARCH_ORDER.call.each do |registry|
            result = registry.find(&block)
            return result if result
          end
          nil
        end

        def registry_or_nil(registry)
          registry.empty? ? nil : registry.dup
        end

        # Finds an existing object matching the composite key (id + noun + name)
        # via an O(1) lookup in the shared +@@index+, or creates and registers
        # a new one.
        #
        # Each index entry stores a two-element array <tt>[GameObj, last_seen_at]</tt>.
        # +last_seen_at+ is refreshed on every hit using a monotonic clock, giving
        # +prune_index!+ an accurate staleness signal for garbage collection.
        #
        def find_or_create(registry, id, noun, name, before = nil, after = nil)
          str_id = id.is_a?(Integer) ? id.to_s : id
          key    = "#{str_id}|#{noun}|#{name}"
          now    = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          if (entry = @@index[key])
            existing, _ts      = entry
            @@index[key]       = [existing, now] # refresh last-seen timestamp
            existing.before_name = before if existing.before_name.nil? && !before.nil?
            existing.after_name  = after  if existing.after_name.nil?  && !after.nil?
            registry.push(existing) unless registry.include?(existing)
            return existing
          end

          obj          = GameObj.new(id, noun, name, before, after)
          @@index[key] = [obj, now]
          registry.push(obj)
          obj
        end

        def live_registry_ids
          ids = [
            *@@loot, *@@npcs, *@@pcs, *@@inv, *@@reserve,
            *@@room_desc, *@@fam_loot, *@@fam_npcs, *@@fam_pcs, *@@fam_room_desc,
            *@@contents.values.flatten,
            @@right_hand, @@left_hand
          ].compact.map(&:id)
          defined?(Set) ? Set.new(ids) : ids
        end

        def empty_index_stats
          {
            total_entries: 0,
            live_in_registries: 0,
            stale_entries: 0,
            oldest_entry_seconds: 0.0,
            age_buckets: { 'under5m' => 0, '5-15m' => 0,
                                    '15-30m' => 0, '30-60m' => 0, 'over60m' => 0 },
            gameobj_bytes: 0,
            heap_bytes: ruby_heap_bytes
          }
        end

        def gameobj_memory_bytes
          @@index.sum { |_key, (obj, _ts)| ObjectSpace.memsize_of(obj) }
        end

        def ruby_heap_bytes
          stat      = GC.stat
          slot_size = stat[:heap_slot_size] || 40 # 40 bytes is the MRI default
          (stat[:heap_live_slots] || 0) * slot_size
        end

        def format_bytes(bytes)
          abs = bytes.abs
          return "#{abs} B" if abs < 1024
          return format("%.2f KB", abs / 1024.0)        if abs < 1_048_576
          return format("%.2f MB", abs / 1_048_576.0)   if abs < 1_073_741_824
          format("%.2f GB", abs / 1_073_741_824.0)
        end

        def format_delta(delta)
          label = delta >= 0 ? 'freed' : 'allocated'
          "#{format_bytes(delta.abs)} #{label}"
        end

        def parse_data_file(filename, merge: false)
          File.open(filename) do |file|
            doc = REXML::Document.new(file.read)
            parse_data_section(doc, 'data/type',     @@type_data,     merge: merge)
            parse_data_section(doc, 'data/sellable', @@sellable_data, merge: merge)
          end
        end

        def parse_data_section(doc, xpath, target, merge: false)
          doc.elements.each(xpath) do |e|
            key = e.attributes['name']
            next unless key

            target[key] ||= {}
            %i[name noun exclude].each do |field|
              text = e.elements[field.to_s]&.text
              next if text.nil? || text.empty?

              regexp = Regexp.new(text)
              target[key][field] = merge ? GameObj.merge_data(target[key][field], regexp) : regexp
            end
          end
        end
      end
    end

    class RoomObj < GameObj; end

    # ---------------------------------------------------------------------------
    # Lich::Common::LruIndex — optional drop-in replacement for +@@index+
    #
    # A size-capped Least Recently Used (LRU) cache that stores the same
    # <tt>[GameObj, last_seen_at]</tt> tuple format as the default plain Hash,
    # making it a transparent drop-in replacement.
    #
    # Use when profiling shows +@@index+ growing too large in very long or
    # heavily automated sessions. Combines LRU eviction (by access recency)
    # with the same TTL-based +prune_older_than+ interface as +prune_index!+.
    #
    # Usage — swap the initializer inside GameObj:
    #
    #   @@index = Lich::Common::LruIndex.new(2000)
    #
    # How it works:
    #   Ruby Hashes preserve insertion order. On every read (+[]+) the accessed
    #   entry is moved to the end (most recently used). When the cap is reached
    #   on a write (+[]=+), the first entry (least recently used) is evicted.
    class LruIndex
      def initialize(capacity = 2000)
        @capacity = capacity
        @store    = {}
      end

      def [](key)
        return nil unless @store.key?(key)

        # Move to end (most recently used) by delete-and-reinsert
        value = @store.delete(key)
        @store[key] = value
        value
      end

      def []=(key, value)
        @store.delete(key) if @store.key?(key)
        @store.shift if @store.size >= @capacity
        @store[key] = value
      end

      def key?(key)
        @store.key?(key)
      end

      def prune_older_than(cutoff)
        pruned = 0
        @store.delete_if do |_key, (_obj, last_seen)|
          if last_seen < cutoff
            pruned += 1
            true
          else
            false
          end
        end
        pruned
      end

      def each_value(&block)
        @store.each_value(&block)
      end

      def clear
        @store.clear
      end

      def delete_if(&block)
        @store.delete_if(&block)
        self
      end

      def size
        @store.size
      end
    end
  end
end
