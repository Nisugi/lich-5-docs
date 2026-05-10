
module Lich
  module DragonRealms
    # Manages the equipment for the player character in the game.
    #
    # This class handles the retrieval, wearing, and stowing of items.
    # It also manages gear sets and combat items.
    #
    # @see Lich::DragonRealms::Item for item details.
    class EquipmentManager
      # Recovery patterns handled by stow_helper's retry logic.
      # These are automatically appended to every stow_helper call
      # so callers only need to pass success/failure patterns.
      #
      STOW_RECOVERY_PATTERNS = [
        /unload/,
        /close the fan/,
        /You are a little too busy/,
        /You don't seem to be able to move/,
        /is too small to hold that/,
        /Your wounds hinder your ability to do that/,
        /Sheath your .* where/
      ].freeze

      # Maximum retry attempts for stow_helper before giving up.
      STOW_HELPER_MAX_RETRIES = 10

      # Initializes a new EquipmentManager instance.
      # @param settings [OpenStruct, nil] configuration settings for the equipment manager
      # @return [void]
      def initialize(settings = nil)
        items(settings)
      end

      # Retrieves the list of items managed by the EquipmentManager.
      # If settings are not provided, it fetches them from the game.
      # @param settings [OpenStruct, nil] configuration settings for the equipment manager
      # @return [Array<Lich::DragonRealms::Item>] list of items
      def items(settings = nil)
        return @items if @items

        settings ||= get_settings
        @gear_sets = {}
        settings.gear_sets.each { |set_name, gear_list| @gear_sets[set_name] = gear_list.flatten.uniq }
        @sort_head = settings.sort_auto_head
        @items = settings.gear.map { |item| DRC::Item.new(name: item[:name], leather: item[:is_leather], hinders_locks: item[:hinders_lockpicking], worn: item[:is_worn], swappable: item[:swappable], tie_to: item[:tie_to], adjective: item[:adjective], bound: item[:bound], wield: item[:wield], transforms_to: item[:transforms_to], transform_verb: item[:transform_verb], transform_text: item[:transform_text], lodges: item[:lodges], ranged: item[:ranged], needs_unloading: item[:needs_unloading], skip_repair: item[:skip_repair], container: item[:container]) }
      end

      # Removes gear based on a given condition defined in the block.
      # @param block [Proc] a block that defines the condition for removing gear
      # @return [Array<Lich::DragonRealms::Item>] list of removed items
      def remove_gear_by(&_block)
        combat_items = get_combat_items
        gear = desc_to_items(combat_items).select { |item| yield(item) }
        gear.each { |item| remove_item(item) }
        gear
      end

      # Wears the specified items from the list.
      # @param items_list [Array<String>] list of item names to wear
      # @return [void]
      def wear_items(items_list)
        items_list.each { |item| wear_item?(item) }

        DRC.bput('sort auto head', /^Your inventory is now arranged/) if @sort_head
      end

      # Wears an entire equipment set if it exists.
      # @param set_name [String] the name of the gear set to wear
      # @return [Boolean] true if all items were successfully worn, false otherwise
      def wear_equipment_set?(set_name)
        return false unless set_name

        unless @gear_sets[set_name]
          Lich::Messaging.msg("bold", "EquipmentManager: Could not find gear set '#{set_name}'")
          return false
        end

        gear_set_items = desc_to_items(@gear_sets[set_name])
        Lich::Messaging.msg("plain", "EquipmentManager: expected worn items: #{gear_set_items.map(&:short_name).join(',')}") if UserVars.equipmanager_debug

        combat_items = get_combat_items

        remove_unmatched_items(combat_items, gear_set_items)

        lost_items = wear_missing_items(gear_set_items, combat_items)
        notify_missing(lost_items)

        DRC.bput('sort auto head', /^Your inventory is now arranged/) if @sort_head

        lost_items.empty?
      end

      # Converts a list of descriptions to corresponding items.
      # @param descs [Array<String>] list of item descriptions
      # @return [Array<Lich::DragonRealms::Item>] list of items matching the descriptions
      def desc_to_items(descs)
        descs.map { |description| item_by_desc(description) }.compact
      end

      # Finds an item by its description.
      # @param description [String] the description to match against items
      # @return [Lich::DragonRealms::Item, nil] the matching item or nil if not found
      def item_by_desc(description)
        items.find { |item| item.short_regex =~ description }
      end

      # Notifies the user about missing items.
      # @param lost_items [Array<Lich::DragonRealms::Item>] list of items that are missing
      # @return [void]
      def notify_missing(lost_items)
        return unless lost_items && !lost_items.empty?

        DRC.beep
        Lich::Messaging.msg("bold", "EquipmentManager: MISSING EQUIPMENT - Please verify these items are in a closed container and not lost:")
        Lich::Messaging.msg("bold", "EquipmentManager: #{lost_items.map(&:short_name).join(', ')}")
        pause
        DRC.beep
      end

      # Wears items that are missing from the combat items list.
      # @param target_items [Array<Lich::DragonRealms::Item>] items that should be worn
      # @param combat_items [Array<Lich::DragonRealms::Item>] currently worn combat items
      # @return [Array<Lich::DragonRealms::Item>] list of items that could not be worn
      def wear_missing_items(target_items, combat_items)
        if UserVars.equipmanager_debug
          Lich::Messaging.msg("plain", "EquipmentManager: wearing missing items between these two sets")
          Lich::Messaging.msg("plain", "EquipmentManager: combat: #{combat_items.join(',')}")
          Lich::Messaging.msg("plain", "EquipmentManager: target: #{target_items.map(&:short_name).join(',')}")
        end

        missing_items = target_items
                        .reject { |item| combat_items.find { |c_item| item.short_regex =~ c_item } }
                        .reject { |item| [DRC.right_hand, DRC.left_hand].grep(item.short_regex).any? ? (stow_weapon(item.short_name) || true) : false }

        Lich::Messaging.msg("plain", "EquipmentManager: wear missing items #{missing_items}") if !missing_items.empty? && UserVars.equipmanager_debug
        missing_items.reject { |item| wear_item?(item) }
      end

      # Removes items from combat that do not match the target items.
      # @param combat_items [Array<String>] currently worn combat items
      # @param target_items [Array<Lich::DragonRealms::Item>] items that should be worn
      # @return [Array<Lich::DragonRealms::Item>] list of removed items
      def remove_unmatched_items(combat_items, target_items)
        if UserVars.equipmanager_debug
          Lich::Messaging.msg("plain", "EquipmentManager: removing unmatched items between these two sets")
          Lich::Messaging.msg("plain", "EquipmentManager: combat: #{combat_items.join(',')}")
          Lich::Messaging.msg("plain", "EquipmentManager: target: #{target_items.map(&:short_name).join(',')}")
        end
        combat_items
          .reject { |description| target_items.find { |item| item.short_regex =~ description } }
          .map { |description| items.find { |item| item.short_regex =~ description } }
          .compact
          .each { |item| remove_item(item) }
      end

      # Retrieves the list of combat items currently worn.
      # @return [Array<String>] list of combat item descriptions
      def get_combat_items
        snapshot = Lich::Util.issue_command("inv combat", /All of your worn combat|You aren't wearing anything like that/, /Use INVENTORY HELP for more options/, usexml: false, include_end: false)
        return [] unless snapshot

        snapshot.map(&:strip) - ["All of your worn combat equipment:", "You aren't wearing anything like that."]
      end

      # Filters combat items based on a provided list.
      # @param list [Array<String>] list of item descriptions to filter by
      # @return [Array<Lich::DragonRealms::Item>] list of matching combat items
      def matching_combat_items(list)
        filter_gear = desc_to_items(list)
        gear = desc_to_items(get_combat_items)
        gear.select { |x| filter_gear.include?(x) }
      end

      alias_method :worn_items, :matching_combat_items

      # Removes a specified item from the player's inventory.
      # @param item [Lich::DragonRealms::Item] the item to remove
      # @param retries [Integer] number of retries before giving up (default: 2)
      # @return [Boolean] true if the item was successfully removed, false otherwise
      def remove_item(item, retries: 2)
        if retries <= 0
          Lich::Messaging.msg("bold", "EquipmentManager: remove_item exceeded max retries for #{item.short_name}")
          return false
        end

        result = DRC.bput("remove my #{item.short_name}", *DRCI::REMOVE_ITEM_SUCCESS_PATTERNS, *DRCI::REMOVE_ITEM_FAILURE_PATTERNS, "then constricts tighter around your")
        waitrt?
        case result
        when /then constricts tighter around your/
          # Items that auto-repair, like exoskeletal armor,
          # may have a timer on them that prevents you removing them.
          Lich::Messaging.msg("bold", "EquipmentManager: The #{item.short_name} is not ready to be removed yet. Try again later.")
          return false
        when *DRCI::REMOVE_ITEM_FAILURE_PATTERNS
          # We may need to empty our hands to remove the item.
          # For example, exoskeletal armor requires two hands.
          temp_left_item = DRC.left_hand
          temp_right_item = DRC.right_hand
          # Lower the items because that preserves loaded bows.
          # Stowing them in a container would require unloading.
          did_lower = [temp_left_item, temp_right_item].compact.all? { |item_in_hand| DRCI.lower_item?(item_in_hand) }
          if did_lower
            remove_item(item, retries: retries - 1)
          else
            Lich::Messaging.msg("bold", "EquipmentManager: Unable to empty your hands to remove #{item.short_name}")
          end
          # Pick up the items in reverse order you lowered them
          # so that they end up in the correct hands again.
          DRCI.get_item_if_not_held?(temp_right_item) if temp_right_item
          DRCI.get_item_if_not_held?(temp_left_item) if temp_left_item
          # In case they end up in different hands, swap.
          if DRC.left_hand != temp_left_item || DRC.right_hand != temp_right_item
            swap_result = DRC.bput('swap', *DRCI::SWAP_HANDS_SUCCESS_PATTERNS, *DRCI::SWAP_HANDS_FAILURE_PATTERNS)
            unless DRCI::SWAP_HANDS_SUCCESS_PATTERNS.any? { |p| p.match?(swap_result) }
              Lich::Messaging.msg("bold", "EquipmentManager: Unable to restore hand order after removing #{item.short_name}")
            end
          end
        when *DRCI::REMOVE_ITEM_SUCCESS_PATTERNS
          # If removing item transforms it (e.g. exoskeletal armor => orb) then continue with the transformed item.
          if item.transforms_to && DRCI.in_hands?(item.transforms_to)
            transform_desc = item.transforms_to
            item = item_by_desc(transform_desc)
            unless item
              Lich::Messaging.msg("bold", "EquipmentManager: Could not find transformed item matching '#{transform_desc}' in gear list")
              return false
            end
          end
          if item.tie_to || item.wield || item.container
            stow_by_type(item)
          elsif /more room|too long to fit/ =~ DRC.bput("stow my #{item.short_name}", *DRCI::PUT_AWAY_ITEM_SUCCESS_PATTERNS, 'There isn\'t any more room', 'straps have all been used', 'is too long to fit')
            wear_item?(item)
          end
        end
        waitrt?
      end

      # Wears a specified item if it is available.
      # @param item [Lich::DragonRealms::Item] the item to wear
      # @return [Boolean] true if the item was successfully worn, false otherwise
      def wear_item?(item)
        if item.nil?
          Lich::Messaging.msg("bold", "EquipmentManager: Failed to match an item, try turning on debugging with #{$clean_lich_char}e UserVars.equipmanager_debug = true")
          return false
        end
        if get_item?(item)
          return DRCI.wear_item?(item.short_name)
        end
        return false
      end

      # Wields a weapon in the offhand if it exists.
      # @param description [String] the description of the weapon to wield
      # @param skill [String, nil] optional skill to use for wielding
      # @return [Boolean] true if the weapon was successfully wielded, false otherwise
      def wield_weapon_offhand?(description, skill = nil)
        return unless description && !description.empty?

        weapon = item_by_desc(description)
        unless weapon
          Lich::Messaging.msg("bold", "EquipmentManager: Failed to match a weapon for #{description}:#{skill}")
          return false
        end

        if get_item?(weapon)
          swap_to_skill?(weapon.name, skill) if skill && weapon.swappable
          if DRCI.in_right_hand?(weapon)
            case DRC.bput('swap', *DRCI::SWAP_HANDS_SUCCESS_PATTERNS, *DRCI::SWAP_HANDS_FAILURE_PATTERNS)
            when *DRCI::SWAP_HANDS_SUCCESS_PATTERNS
              return true
            else
              return false
            end
          end
        end

        return false
      end

      alias_method :wield_weapon_offhand, :wield_weapon_offhand?

      # Wields a specified weapon.
      # @param description [String] the description of the weapon to wield
      # @param skill [String, nil] optional skill to use for wielding
      # @return [Boolean] true if the weapon was successfully wielded, false otherwise
      def wield_weapon?(description, skill = nil)
        return unless description && !description.empty?

        offhand = skill == 'Offhand Weapon'
        weapon = item_by_desc(description)
        unless weapon
          Lich::Messaging.msg("bold", "EquipmentManager: Failed to match a weapon for #{description}:#{skill}")
          return false
        end

        if [DRC.left_hand, DRC.right_hand].grep(weapon.short_regex).any?
          stow_weapon
        end

        if get_item?(weapon)
          swap_to_skill?(weapon.name, skill) if skill && weapon.swappable

          if offhand && DRC.right_hand
            case DRC.bput('swap', *DRCI::SWAP_HANDS_SUCCESS_PATTERNS, *DRCI::SWAP_HANDS_FAILURE_PATTERNS)
            when *DRCI::SWAP_HANDS_SUCCESS_PATTERNS
              return true
            else
              return false
            end
          end

          return true
        end

        return false
      end

      alias_method :wield_weapon, :wield_weapon?

      # Retrieves an item from the inventory if it is available.
      # @param item [Lich::DragonRealms::Item] the item to retrieve
      # @return [Boolean] true if the item was successfully retrieved, false otherwise
      def get_item?(item)
        return true if DRCI.in_hands?(item)

        if item.wield
          case DRC.bput("wield my #{item.short_name}", *DRCI::WIELD_ITEM_SUCCESS_PATTERNS, *DRCI::WIELD_ITEM_FAILURE_PATTERNS)
          when *DRCI::WIELD_ITEM_SUCCESS_PATTERNS
            return true
          else
            Lich::Messaging.msg("bold", "EquipmentManager: Unable to wield #{item.short_name}")
            return false
          end
        elsif item.transforms_to
          transform_item = item_by_desc(item.transforms_to)
          unless transform_item
            Lich::Messaging.msg("bold", "EquipmentManager: Could not find transformed item matching '#{item.transforms_to}' in gear list")
            return false
          end
          unless transform_item.worn ? get_item_helper(transform_item, :worn) : get_item_helper(transform_item, :stowed)
            Lich::Messaging.msg("bold", "EquipmentManager: Unable to retrieve #{transform_item.short_name} for transform")
            return false
          end
          get_item_helper(transform_item, :transform)
        elsif (item.tie_to && get_item_helper(item, :tied)) || (item.worn && get_item_helper(item, :worn)) || (item.container && DRCI.get_item(item.short_name, item.container)) || get_item_helper(item, :stowed)
          true
        else
          Lich::Messaging.msg("bold", "EquipmentManager: Could not find #{item.short_name} anywhere")
          false
        end
      end

      def listed_item?(desc)
        items.find { |item| item.short_regex =~ desc }
      end

      alias_method :is_listed_item?, :listed_item?

      # Returns held gear to the specified gear set.
      # @param gear_set [String] the name of the gear set to return to (default: 'standard')
      # @return [void]
      def return_held_gear(gear_set = 'standard')
        return unless DRC.right_hand || DRC.left_hand

        todo = [DRC.left_hand, DRC.right_hand].compact

        gear_set_items = desc_to_items(@gear_sets[gear_set] || [])

        todo.all? do |held_item|
          if (info = gear_set_items.find { |item| item.short_regex =~ held_item })
            unload_weapon(info.short_name) if info.needs_unloading
            stow_helper("wear my #{info.short_name}", info.short_name, *DRCI::WEAR_ITEM_SUCCESS_PATTERNS, failure_patterns: DRCI::WEAR_ITEM_FAILURE_PATTERNS)
          elsif (info = items.find { |item| item.short_regex =~ held_item })
            unload_weapon(info.short_name) if info.needs_unloading
            stow_by_type(info)
          else
            false
          end
        end
      end

      # Empties the player's hands by returning held gear.
      # @return [void]
      def empty_hands
        return_held_gear || DRCI.stow_hands
      end

      # Non-recoverable untie failure patterns that should return false
      # immediately in {#get_item_helper}. Contains every entry from
      # {DRCI::UNTIE_ITEM_FAILURE_PATTERNS} EXCEPT the "too busy" patterns
      # which are recoverable (retreat / stop playing) and live in the
      # +:failures+ array instead.
      #
      # For +:worn+ and +:stowed+/+:transform+, exhausted is set directly to
      # the full DRCI failure constant because their +:failures+ entries don't
      # overlap. +:tied+ is the exception -- "too busy" appears in both DRCI
      # failures and the recoverable +:failures+ array, so this curated subset
      # excludes them to prevent the exhausted branch from swallowing recovery.
      #
      # If a new pattern is added to {DRCI::UNTIE_ITEM_FAILURE_PATTERNS},
      # it must be categorized here or in +:failures+ -- the coverage spec
      # enforces that no DRCI failure falls through to the timeout branch.
      # Non-recoverable untie failure patterns that should return false immediately.
      #
      # @example
      # Matches:
      # - "You don't seem to be able to move"
      # - "You fumble with the ties"
      # - "Untie what"
      # - "What were you referring"
      # @see DRCI::UNTIE_ITEM_FAILURE_PATTERNS for related patterns.
      UNTIE_EXHAUSTED_PATTERNS = [
        /^You don't seem to be able to move/,
        /^You fumble with the ties/,
        /^Untie what/,
        /^What were you referring/
      ].freeze

      # Builds a hash of verb configurations for retrieving an item by type.
      #
      # Each type (+:worn+, +:tied+, +:stowed+, +:transform+) maps to a hash
      # with the game verb, match patterns, failure patterns, and recovery procs.
      # Match patterns reference DRCI constants so that new game messages added
      # Builds a hash of verb configurations for retrieving an item by type.
      # @param item [Lich::DragonRealms::Item] the item to build verb data for
      # @return [Hash] hash containing verb configurations for the item
      def verb_data(item)
        {
          worn: {
            verb: 'remove',
            matches: [
              /^You .*#{item.short_regex}/,
              /^You (get|sling|pull|work|loosen|slide|remove|yank|unbuckle).*#{item.name}/,
              *DRCI::REMOVE_ITEM_SUCCESS_PATTERNS,
              *DRCI::REMOVE_ITEM_FAILURE_PATTERNS
            ],
            failures: [/^You (get|sling|pull|work|slide|remove|yank|unbuckle) $/],
            failure_recovery: proc { |noun| DRC.bput("wear my #{noun}", '^You ') },
            exhausted: DRCI::REMOVE_ITEM_FAILURE_PATTERNS
          },
          tied: {
            verb: 'untie',
            matches: [
              /^You .*#{item.short_regex}/,
              /^You remove.*#{item.name}/,
              /^.*you untie your .*#{item.short_regex} from it./,
              *DRCI::UNTIE_ITEM_SUCCESS_PATTERNS,
              *DRCI::UNTIE_ITEM_FAILURE_PATTERNS
            ],
            # NOTE: /^You remove$/ (with end anchor) prevents matching successful
            # untie responses like "You remove a sword from your belt" -- only
            # matches the bare "You remove" edge case.
            failures: [/^You remove$/, /^You are a little too busy/, /^You are a bit too busy/],
            # NOTE: response is accepted as a single String (not *splat) so that
            # case/when uses Regexp#=== for proper pattern matching. The original
            # *matches splat wrapped the response in an Array, making Regexp-based
            # when clauses silently fall through to else.
            failure_recovery: proc { |_noun, item_to_recover, response|
                                case response
                                when /You are a little too busy/
                                  DRC.retreat
                                  get_item?(item_to_recover)
                                when /You are a bit too busy/
                                  DRC.stop_playing
                                  get_item?(item_to_recover)
                                else
                                  stow_weapon
                                end
                              },
            exhausted: UNTIE_EXHAUSTED_PATTERNS
          },
          stowed: {
            verb: 'get',
            matches: [
              /^You .*#{item.short_regex}/,
              /^You .*#{item.name}/,
              *DRCI::GET_ITEM_SUCCESS_PATTERNS,
              *DRCI::GET_ITEM_FAILURE_PATTERNS,
              /^The.* slides easily out/,
              /But that is already/
            ],
            failures: [/^You get$/, /But that is already/],
            failure_recovery: proc { |noun| DRC.bput("stow my #{noun}", 'You put', 'But that is already in') },
            exhausted: DRCI::GET_ITEM_FAILURE_PATTERNS
          },
          transform: {
            verb: item.transform_verb,
            matches: [
              item.transform_text,
              /You'll need a free hand to do that!/,
              /You don't seem to be holding/,
              *DRCI::GET_ITEM_FAILURE_PATTERNS
            ],
            failures: [/You'll need a free hand to do that!/, /You don't seem to be holding/],
            failure_recovery: proc do |noun|
                                DRCI.stow_hand('left') if DRC.left_hand && DRC.left_hand !~ /#{noun}/i
                                DRCI.stow_hand('right') if DRC.right_hand && DRC.right_hand !~ /#{noun}/i
                                if (DRC.left_hand && DRC.left_hand !~ /#{noun}/i) || (DRC.right_hand && DRC.right_hand !~ /#{noun}/i)
                                  Lich::Messaging.msg("bold", "EquipmentManager: Unable to free hands for transform")
                                  next
                                end
                                item.worn ? DRC.bput("remove my #{noun}", '^You') : DRC.bput("get my #{noun}", '^You')
                                DRC.bput("#{item.transform_verb} my #{item.short_name}", *verb_data(item)[:transform][:matches])
                              end,
            exhausted: DRCI::GET_ITEM_FAILURE_PATTERNS
          }
        }
      end

      def get_item_helper(item, type)
        return false unless item

        data = verb_data(item)[type]
        snapshot = [DRC.left_hand, DRC.right_hand]
        waitrt?
        response = DRC.bput("#{data[:verb]} my #{item.short_name}", *data[:matches])
        waitrt?

        # Handle empty/nil response (bput timeout) as failure
        if response.nil? || response.empty?
          Lich::Messaging.msg("bold", "EquipmentManager: No response from game for '#{data[:verb]} my #{item.short_name}' - command may have been lost")
          return false
        end

        # For non-transform types, verify success via the XML game-object
        # feed rather than trusting bput's text match. This prevents false
        # positives where an unrelated game message (e.g., "You get the
        # feeling...") matches /^You get/ in GET_ITEM_SUCCESS_PATTERNS,
        # causing bput to return "You get" which then triggers the failure
        # recovery proc and stows the item that was just retrieved.
        # See elanthia-online/lich-5#1286 for the same approach in
        # DRCI.get_item_unsafe.
        # Transform is excluded because the item changes identity (e.g.,
        # orb -> armor) so noun verification against the original item
        # would fail.
        if type != :transform
          noun = DRC.get_noun(item.short_name)
          10.times do
            break if item_noun_in_hands?(noun)
            pause 0.05
          end
          return true if item_noun_in_hands?(noun)
        end

        case response
        when 'You are already holding'
          return true
        when *data[:exhausted]
          return false
        when *data[:failures]
          data[:failure_recovery].call(item.name, item, response)
          # Check if hands changed from pre-command snapshot, consistent with
          # the success (else) branch. Using in_hands?(item) here would fail
          # for :transform where the item changes identity (e.g., orb -> armor).
          return snapshot != [DRC.left_hand, DRC.right_hand]
        else
          # Wait for hands to change with a timeout to prevent infinite loop
          timeout = Time.now + 5
          pause 0.05 while snapshot == [DRC.left_hand, DRC.right_hand] && Time.now < timeout
          if snapshot == [DRC.left_hand, DRC.right_hand]
            Lich::Messaging.msg("bold", "EquipmentManager: Hands did not change after '#{data[:verb]} my #{item.short_name}' - item may not have been retrieved")
            return false
          end
          return true
        end
      end

      def item_noun_in_hands?(noun)
        [DRC.left_hand_noun, DRC.right_hand_noun].compact.include?(noun)
      end

      def turn_to_weapon?(old_noun, new_noun)
        return true if old_noun == new_noun

        result = DRC.bput("turn my #{old_noun} to #{new_noun}", /^Turn what?/i, /^Which weapon did you want to pull out/i, /^Your .*\b#{old_noun}.* shifts .*/i)
        waitrt? # turning may incur roundtime
        case result
        when /^Your .*\b#{old_noun}.* shifts .* before resolving itself into .*\b#{new_noun}/i
          true
        else
          false
        end
      end

      def swap_to_skill?(noun, skill)
        if noun =~ /\bfan\b/i
          command = skill =~ /edged/i ? 'open' : 'close'
          DRC.bput("#{command} my fan", 'you snap', 'already')
          return true
        end
        proper_skill = case skill
                       when /^he$|heavy edge|large edge|one-handed/i
                         'heavy edged'
                       when /^2he$|^the$|twohanded edge|two-handed edge/i
                         'two-handed edged'
                       when /^hb$|heavy blunt|large blunt/i
                         'heavy blunt'
                       when /^2hb$|^thb$|twohanded blunt|two-handed blunt/i
                         'two-handed blunt'
                       when /^se$|small edged|light edge|medium edge/i
                         '(light edged|medium edged)'
                       when /^sb$|small blunt|light blunt|medium blunt/i
                         '(light blunt|medium blunt)'
                       when /^lt$|light thrown/i
                         'light thrown'
                       when /^ht$|heavy thrown/i
                         'heavy thrown'
                       when /stave/i
                         '(short|quarter) staff'
                       when /polearms/i
                         '(halberd|pike)'
                       when /^ow$|offhand weapon/i
                         return true # just use weapon in your left hand
                       else
                         Lich::Messaging.msg("bold", "EquipmentManager: Unsupported weapon swap: #{noun} to #{skill}. Please report this to https://github.com/elanthia-online/lich-5/issues")
                         return false
                       end
        # All possible weapon skills to swap into.
        weapon_skills = [
          'light edged',
          'medium edged',
          'heavy edged',
          'two-handed edged',
          'light blunt',
          'medium blunt',
          'heavy blunt',
          'two-handed blunt',
          'light thrown',
          'heavy thrown',
          'short staff',
          'quarter staff',
          'halberd',
          'pike'
        ]
        failure_matches = [
          /You have nothing to swap/,
          /Your (left|right) hand is too injured/,
          /Will alone cannot conquer the paralysis that has wracked your body/,
          /^You move a .* to your (left|right) hand/
        ]
        # The spaces in the regex are deliberate
        skill_match = / #{proper_skill} /i
        swapped_count = 0
        loop do
          pause 0.25
          # Avoid infinite loop where weapon can't swap to desired skill.
          return false if swapped_count > weapon_skills.length

          swapped_count += 1

          # Try to swap weapon to desired skill.
          case DRC.bput("swap my #{noun}", skill_match, /\b#{noun}\b.*(#{weapon_skills.join('|')})/, "You must have two free hands", *failure_matches)
          when /You must have two free hands/
            DRCI.stow_hand('left') if DRC.left_hand && DRC.left_hand !~ /#{noun}/i
            DRCI.stow_hand('right') if DRC.right_hand && DRC.right_hand !~ /#{noun}/i
            hands_free = [DRC.left_hand, DRC.right_hand].compact.all? { |h| h =~ /#{noun}/i }
            unless hands_free
              Lich::Messaging.msg("bold", "EquipmentManager: Unable to free hands for weapon swap")
              return false
            end
          when *failure_matches
            return false
          when skill_match
            return true
          end
        end
      end

      def unload_weapon(name)
        result = DRC.bput("unload my #{name}", *DRCI::UNLOAD_WEAPON_SUCCESS_PATTERNS, *DRCI::UNLOAD_WEAPON_FAILURE_PATTERNS)
        ammo_match = result&.match(/^(?:Your .*?\b(?<ammo>[\w]+)\b fall.* from your .* to your feet\.)$/)
        if ammo_match
          # Ammo fell to ground because hands are full.
          # Lower weapon, stow ammo, then pick it back up.
          ammo = ammo_match[:ammo]
          unless DRCI.lower_item?(name)
            Lich::Messaging.msg("bold", "EquipmentManager: Unable to lower #{name} to pick up ammo")
            return
          end
          DRCI.put_away_item?(ammo)
          unless DRCI.get_item?(name)
            Lich::Messaging.msg("bold", "EquipmentManager: Unable to pick #{name} back up after unloading")
          end
        elsif result&.match?(/As you release the string/)
          # Ammo tumbled to the ground (e.g., "As you release the string, the arrow tumbles to the ground.")
          # Same recovery as ammo falling to feet: lower weapon, stow ammo, pick weapon back up.
          ammo_ground_match = result.match(/the (?<ammo>\w+) tumbles/)
          if ammo_ground_match
            ammo = ammo_ground_match[:ammo]
            unless DRCI.lower_item?(name)
              Lich::Messaging.msg("bold", "EquipmentManager: Unable to lower #{name} to pick up ammo")
              return
            end
            DRCI.put_away_item?(ammo)
            unless DRCI.get_item?(name)
              Lich::Messaging.msg("bold", "EquipmentManager: Unable to pick #{name} back up after unloading")
            end
          end
        elsif result&.match?(/^(?:You unload|You .* unloading)/)
          # Ammo is in hand, stow whichever hand isn't holding the weapon.
          unless DRCI.in_left_hand?(name)
            Lich::Messaging.msg("bold", "EquipmentManager: Unable to stow ammo from left hand") unless DRCI.stow_hand('left')
          end
          unless DRCI.in_right_hand?(name)
            Lich::Messaging.msg("bold", "EquipmentManager: Unable to stow ammo from right hand") unless DRCI.stow_hand('right')
          end
        end
        waitrt?
      end

      def stow_weapon(description = nil, transform_depth: 3)
        unless description
          return unless DRC.right_hand || DRC.left_hand

          stow_weapon(DRC.right_hand) if DRC.right_hand
          stow_weapon(DRC.left_hand)  if DRC.left_hand
          return
        end
        weapon = item_by_desc(description)
        return unless weapon

        # Is this a weapon that needs to be unloaded before it is put away?
        # This is an optimization attempt so that the script
        # isn't trying to unload every weapon that gets put away.
        # Would be silly to try "unload my scimitar" wouldn't it? :grins:
        unload_weapon(weapon.short_name) if weapon.needs_unloading
        if weapon.worn
          stow_helper("wear my #{weapon.short_name}", weapon.short_name, *DRCI::WEAR_ITEM_SUCCESS_PATTERNS, failure_patterns: DRCI::WEAR_ITEM_FAILURE_PATTERNS)
        elsif weapon.transforms_to
          if transform_depth <= 0
            Lich::Messaging.msg("bold", "EquipmentManager: stow_weapon exceeded max transform depth for #{weapon.short_name}")
            return
          end
          stow_helper("#{weapon.transform_verb} my #{weapon.short_name}", weapon.short_name, weapon.transform_text)
          stow_weapon(weapon.transforms_to, transform_depth: transform_depth - 1)
        else
          stow_by_type(weapon)
        end
      end

      def stow_by_type(item)
        if item.tie_to
          stow_helper("tie my #{item.short_name} to my #{item.tie_to}", item.short_name, *DRCI::TIE_ITEM_SUCCESS_PATTERNS, failure_patterns: DRCI::TIE_ITEM_FAILURE_PATTERNS)
        elsif item.wield
          stow_helper("sheath my #{item.short_name}", item.short_name, *DRCI::SHEATH_ITEM_SUCCESS_PATTERNS, failure_patterns: DRCI::SHEATH_ITEM_FAILURE_PATTERNS)
        elsif item.container
          stow_helper("put my #{item.short_name} in my #{item.container}", item.short_name, *DRCI::PUT_AWAY_ITEM_SUCCESS_PATTERNS, failure_patterns: DRCI::PUT_AWAY_ITEM_FAILURE_PATTERNS)
        else
          stow_helper("stow my #{item.short_name}", item.short_name, *DRCI::PUT_AWAY_ITEM_SUCCESS_PATTERNS, failure_patterns: DRCI::PUT_AWAY_ITEM_FAILURE_PATTERNS)
        end
      end

      def stow_helper(action, weapon_name, *accept_strings, failure_patterns: [], retries: STOW_HELPER_MAX_RETRIES)
        if retries <= 0
          Lich::Messaging.msg("bold", "EquipmentManager: stow_helper exceeded max retries for '#{action}'")
          return false
        end

        result = DRC.bput(action, *accept_strings, *failure_patterns, *STOW_RECOVERY_PATTERNS)
        if result.nil? || result.empty?
          Lich::Messaging.msg("bold", "EquipmentManager: stow_helper got no response for '#{action}'")
          return false
        end

        case result
        when /unload/
          unload_weapon(weapon_name)
          return stow_helper(action, weapon_name, *accept_strings, failure_patterns: failure_patterns, retries: retries - 1)
        when /close the fan/
          fput("close my #{weapon_name}")
          return stow_helper(action, weapon_name, *accept_strings, failure_patterns: failure_patterns, retries: retries - 1)
        when /You are a little too busy/
          DRC.retreat
          return stow_helper(action, weapon_name, *accept_strings, failure_patterns: failure_patterns, retries: retries - 1)
        when /You don't seem to be able to move/
          pause 1
          return stow_helper(action, weapon_name, *accept_strings, failure_patterns: failure_patterns, retries: retries - 1)
        when /is too small to hold that/
          fput("swap my #{weapon_name}")
          return stow_helper(action, weapon_name, *accept_strings, failure_patterns: failure_patterns, retries: retries - 1)
        when /Your wounds hinder your ability to do that/, /Sheath your .* where/
          return stow_helper("stow my #{weapon_name}", weapon_name, *DRCI::PUT_AWAY_ITEM_SUCCESS_PATTERNS, failure_patterns: DRCI::PUT_AWAY_ITEM_FAILURE_PATTERNS, retries: retries - 1)
        when *STOW_RECOVERY_PATTERNS
          # Catch-all for any recovery pattern not explicitly handled above
          Lich::Messaging.msg("bold", "EquipmentManager: stow_helper unhandled recovery for '#{action}': #{result}")
          return false
        end
        # Check if the result matched an explicit failure pattern
        if failure_patterns.any? { |p| p.match?(result) }
          Lich::Messaging.msg("bold", "EquipmentManager: stow_helper failed for '#{action}': #{result}")
          return false
        end
        true
      end
    end
  end
end
