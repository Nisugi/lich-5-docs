module Lich
  module Gemstone
    # Represents a list of ready items and their storage in the game.
    #
    # This class manages the items that a player can have ready for use,
    # including weapons and shields, and provides methods to check their
    # validity and reset the lists.
    #
    # @see Lich::Gemstone::ReadyList#ready_list
    # @see Lich::Gemstone::ReadyList#store_list
    class ReadyList
      @checked = false

      ORIGINAL_READY_LIST = [:shield, :weapon, :secondary_weapon, :ranged_weapon, :ammo_bundle, :ammo2_bundle, :sheath, :secondary_sheath, :wand]
      ORIGINAL_STORE_LIST = [:shield, :weapon, :secondary_weapon, :ranged_weapon, :ammo_bundle, :wand]

      @ready_list = {
        shield: nil,
        weapon: nil,
        secondary_weapon: nil,
        ranged_weapon: nil,
        ammo_bundle: nil,
        ammo2_bundle: nil,
        sheath: nil,
        secondary_sheath: nil,
        wand: nil,
      }
      @store_list = {
        shield: nil,
        weapon: nil,
        secondary_weapon: nil,
        ranged_weapon: nil,
        ammo_bundle: nil,
        wand: nil,
      }

      # Define class-level accessors for ready list entries
      @ready_list.each_key do |type|
        define_singleton_method("#{type}") { @ready_list[type] }
        define_singleton_method("#{type}=") { |value| @ready_list[type] = value }
      end

      # Define class-level accessors for store list entries
      @store_list.each_key do |type|
        define_singleton_method("store_#{type}") { @store_list[type] }
        define_singleton_method("store_#{type}=") { |value| @store_list[type] = value }
      end

      class << self
        def ready_list
          @ready_list
        end

        def store_list
          @store_list
        end

        def checked?
          @checked
        end

        def checked=(value)
          @checked = value
        end

        # Checks if the current ready items are valid.
        #
        # @param all [Boolean] if true, checks all items regardless of original list
        # @return [Boolean] true if all checked items are valid, false otherwise
        # @example Check validity of ready items
        #   ready_list.valid?
        # @note This method relies on the checked state being true.
        def valid?(all: false)
          # check if existing ready items are valid or not
          return false unless checked?
          @ready_list.each do |key, value|
            next unless all || ORIGINAL_READY_LIST.include?(key)
            unless key.eql?(:wand) || value.nil? || GameObj.inv.map(&:id).include?(value.id) || GameObj.containers.values.flatten.map(&:id).include?(value.id) || GameObj.right_hand.id.include?(value.id) || GameObj.left_hand.id.include?(value.id)
              @checked = false
              return false
            end
          end
          return true
        end

        # Resets the ready and store lists to nil.
        #
        # @param all [Boolean] if true, resets all items regardless of original list
        # @return [void]
        def reset(all: false)
          @checked = false
          @ready_list.each do |key, _value|
            next unless all || ORIGINAL_READY_LIST.include?(key)
            @ready_list[key] = nil
          end
          @store_list.each do |key, _value|
            next unless all || ORIGINAL_STORE_LIST.include?(key)
            @store_list[key] = nil
          end
        end

        # Checks the current settings of the ready list in the game.
        #
        # @param silent [Boolean] if true, suppresses output
        # @param quiet [Boolean] if true, uses a quieter output pattern
        # @return [void]
        # @note This method updates the checked state based on the results.
        def check(silent: false, quiet: false)
          if quiet
            start_pattern = /<output class="mono"\/>|^You are a ghost!/
          else
            start_pattern = /Your current settings are:|^You are a ghost!/
          end
          waitrt?
          results = Lich::Util.issue_command("ready list", start_pattern, silent: silent, quiet: quiet)
          @checked = results.any? { |line| line.match?(/Your current settings are:/) }
        end
      end
    end
  end
end
