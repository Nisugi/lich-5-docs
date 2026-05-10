module Lich
  module Gemstone
    # Represents a list of items that can be stowed.
    #
    # This class manages the stow list entries and their states.
    class StowList
      @checked = false

      ORIGINAL_STOW_LIST = [:box, :gem, :herb, :skin, :wand, :scroll, :potion, :trinket, :reagent, :lockpick, :treasure, :forageable, :collectible, :default]

      @stow_list = {
        box: nil,
        gem: nil,
        herb: nil,
        skin: nil,
        wand: nil,
        scroll: nil,
        potion: nil,
        trinket: nil,
        reagent: nil,
        lockpick: nil,
        treasure: nil,
        forageable: nil,
        collectible: nil,
        default: nil
      }

      # Define class-level accessors for stow list entries
      @stow_list.each_key do |type|
        define_singleton_method(type) { @stow_list[type] }
        define_singleton_method("#{type}=") { |value| @stow_list[type] = value }
      end

      class << self
        # Returns the current stow list.
        # @return [Hash] a hash representing the stow list entries and their values.
        def stow_list
          @stow_list
        end

        # Checks if the stow list has been validated.
        # @return [Boolean] true if the stow list is checked, false otherwise.
        def checked?
          @checked
        end

        # Sets the checked state of the stow list.
        # @param value [Boolean] the new checked state.
        def checked=(value)
          @checked = value
        end

        # Validates the stow list entries against existing containers.
        #
        # @param all [Boolean] whether to validate all entries or only those in the original stow list.
        # @return [Boolean] true if all relevant entries are valid, false otherwise.
        def valid?(all: false)
          # check if existing containers are valid or not
          return false unless checked?
          @stow_list.each do |key, value|
            next unless all || ORIGINAL_STOW_LIST.include?(key)
            unless value.nil? || GameObj.inv.map(&:id).include?(value.id)
              @checked = false
              return false
            end
          end
          return true
        end

        # Resets the stow list entries to nil.
        #
        # @param all [Boolean] whether to reset all entries or only those in the original stow list.
        def reset(all: false)
          @checked = false
          @stow_list.each do |key, _value|
            next unless all || ORIGINAL_STOW_LIST.include?(key)
            @stow_list[key] = nil
          end
        end

        # Checks the current stow list against the game state.
        #
        # @param silent [Boolean] whether to suppress output during the check.
        # @param quiet [Boolean] whether to suppress all output.
        # @return [void]
        def check(silent: false, quiet: false)
          if quiet
            start_pattern = /<output class="mono"\/>|^You are a ghost!/
          else
            start_pattern = /You have the following containers set as stow targets:|^You are a ghost!/
          end
          waitrt?
          results = Lich::Util.issue_command("stow list", start_pattern, silent: silent, quiet: quiet)
          @checked = results.any? { |line| line.match?(/You have the following containers set as stow targets/) }
        end
      end
    end
  end
end
