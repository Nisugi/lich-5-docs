
module Lich
  module DragonRealms
    module DRCMM
      module_function

      # Moon weapon detection regex. Matches summoned moon weapons in hand.
      # Colors: black (Katamba), red-hot (Yavash), blue-white (Xibar).
      # Moon weapon detection regex. Matches summoned moon weapons in hand.
      #
      # @example
      # Matches:
      # - "black moonblade"
      # - "red-hot moonstaff"
      # - "blue-white moonblade"
      MOON_WEAPON_REGEX = /^(?:black|red-hot|blue-white) moon(?:blade|staff)$/i.freeze

      # Canonical moon weapon base names for glance/hold operations.
      # Canonical moon weapon base names for glance/hold operations.
      #
      # @example
      # Names:
      # - "moonblade"
      # - "moonstaff"
      MOON_WEAPON_NAMES = ['moonblade', 'moonstaff'].freeze

      # Expected game messages when wearing a summoned moon weapon.
      # Expected game messages when wearing a summoned moon weapon.
      #
      # @example
      # Messages:
      # - "You're already"
      # - "You can't wear"
      # - "Wear what"
      MOON_WEAR_MESSAGES = ["You're already", "You can't wear", "Wear what", "telekinetic"].freeze

      # Expected game messages when dropping a summoned moon weapon.
      # Expected game messages when dropping a summoned moon weapon.
      #
      # @example
      # Messages:
      # - "As you open your hand"
      # - "What were you referring to"
      MOON_DROP_MESSAGES = ["As you open your hand", "What were you referring to"].freeze

      # Maps moon weapon color adjective to moon name.
      # Maps moon weapon color adjective to moon name.
      #
      # @example
      # - "black" => "katamba"
      # - "red-hot" => "yavash"
      # - "blue-white" => "xibar"
      MOON_COLOR_TO_NAME = {
        'black'      => 'katamba',
        'red-hot'    => 'yavash',
        'blue-white' => 'xibar'
      }.freeze

      # Regex for extracting moon color from glance output.
      # Regex for extracting moon color from glance output.
      #
      # @example
      # Matches:
      # - "You glance at a black moonblade"
      # - "You glance at a red-hot moonstaff"
      MOON_GLANCE_REGEX = /You glance at a .* (?<color>black|red-hot|blue-white) moon(?:blade|staff)/i.freeze

      # Maps divination tool keywords to their use verb.
      # Maps divination tool keywords to their use verb.
      #
      # @example
      # - "charts" => "review"
      # - "bones" => "roll"
      DIV_TOOL_VERBS = {
        'charts' => 'review',
        'bones'  => 'roll',
        'mirror' => 'gaze',
        'bowl'   => 'gaze',
        'prism'  => 'raise'
      }.freeze

      # Minimum minutes remaining before a celestial body sets to be considered "visible."
      # Minimum minutes remaining before a celestial body sets to be considered "visible."
      MOON_VISIBILITY_TIMER_THRESHOLD = 4

      # Expected game responses when centering a telescope on a target.
      CENTER_TELESCOPE_MESSAGES = [
        'Center what',
        'You put your eye',
        'open it to make any use of it',
        'The pain is too much',
        "That's a bit tough to do when you can't see the sky",
        "You would probably need a periscope to do that",
        'Your search for',
        'Your vision is too fuzzy',
        "You'll need to open it to make any use of it",
        'You must have both hands free'
      ].freeze

      # Expected game responses when observing celestial bodies.
      # Used by `observe` method to match bput responses.
      # Patterns validated via in-game testing with test_observe_comprehensive.lic
      # Note: Roundtime is intentionally NOT included - every observation that produces
      # a Roundtime also produces a more specific pattern that matches first.
      # Expected game responses when observing celestial bodies.
      #
      # @example
      # Messages:
      # - "Your search for"
      # - "You see nothing regarding the future"
      OBSERVE_MESSAGES = [
        'Your search for',                           # Covers: fruitless, foiled by daylight/darkness
        'You see nothing regarding the future',      # No vision available
        'Clouds obscure',                            # Weather blocking
        'The following heavenly bodies are visible:', # Observe heavens listing
        "That's a bit hard to do while inside",      # Indoor blocking
        'too close to the sun',                      # Planet visibility (solar conjunction)
        'too faint for you to pick out',             # Requires telescope
        'You learn nothing of the future',           # Circle too low for body
        'below the horizon',                         # Body not visible
        'You have not pondered',                     # Observation cooldown
        'You are unable to make use',                # Cooldown followup
        'While the sighting',                        # Partial success
        'You learned something useful'               # Full success
      ].freeze

      # Observes a specified thing in the heavens.
      #
      # @param thing [String] the item to observe
      # @return [void]
      def observe(thing)
        output = "observe #{thing} in heavens"
        output = 'observe heavens' if thing.eql?('heavens')
        DRC.bput(output.to_s, *OBSERVE_MESSAGES)
      end

      # Predicts the future regarding a specified thing.
      #
      # @param thing [String] the item to predict
      # @return [void]
      def predict(thing)
        output = "predict #{thing}"
        output = 'predict state all' if thing.eql?('all')
        DRC.bput(output.to_s, 'You predict that', 'You are far too', 'you lack the skill to grasp them fully', /(R|r)oundtime/i, 'You focus inwardly')
      end

      # Studies the sky for celestial information.
      #
      # @return [void]
      def study_sky
        DRC.bput('study sky', 'You feel a lingering sense', 'You feel it is too soon', 'Roundtime', 'You are unable to sense additional information', 'detect any portents')
      end

      # Attempts to retrieve a telescope from storage or hands.
      #
      # @param telescope_name [String] the name of the telescope
      # @param storage [Hash] the storage information
      # @return [Boolean] true if the telescope is successfully retrieved
      def get_telescope?(telescope_name = 'telescope', storage)
        return true if DRCI.in_hands?(telescope_name)

        if storage['tied']
          DRCI.untie_item?(telescope_name, storage['tied'])
        elsif storage['container']
          unless DRCI.get_item?(telescope_name, storage['container'])
            Lich::Messaging.msg("plain", "DRCMM: Telescope not found in container. Trying to get it from anywhere we can.")
            return DRCI.get_item?(telescope_name)
          end
          true
        else
          DRCI.get_item?(telescope_name)
        end
      end

      # Attempts to store a telescope in the specified storage.
      #
      # @param telescope_name [String] the name of the telescope
      # @param storage [Hash] the storage information
      # @return [Boolean] true if the telescope is successfully stored
      def store_telescope?(telescope_name = "telescope", storage)
        return true unless DRCI.in_hands?(telescope_name)

        if storage['tied']
          DRCI.tie_item?(telescope_name, storage['tied'])
        elsif storage['container']
          DRCI.put_away_item?(telescope_name, storage['container'])
        else
          DRCI.put_away_item?(telescope_name)
        end
      end

      # Retrieves a telescope and sends a message if it fails.
      #
      # @param storage [Hash] the storage information
      # @return [void]
      def get_telescope(storage)
        return if get_telescope?('telescope', storage)

        Lich::Messaging.msg('bold', 'DRCMM: Failed to get telescope.')
      end

      # Stores a telescope and sends a message if it fails.
      #
      # @param storage [Hash] the storage information
      # @return [void]
      def store_telescope(storage)
        return if store_telescope?('telescope', storage)

        Lich::Messaging.msg('bold', 'DRCMM: Failed to store telescope.')
      end

      # Peers through the telescope to observe celestial bodies.
      #
      # @return [void]
      def peer_telescope
        telescope_regex_patterns = Regexp.union(
          /The pain is too much/,
          /You see nothing regarding the future/,
          /You believe you've learned all that you can about/,
          Regexp.union(get_data('constellations').observe_finished_messages),
          /open it/,
          /Your vision is too fuzzy/,
        )
        Lich::Util.issue_command("peer my telescope", telescope_regex_patterns, /Roundtime: /, usexml: false)
      end

      # Centers the telescope on a specified target.
      #
      # @param target [String] the celestial body to center on
      # @return [void]
      def center_telescope(target)
        case DRC.bput("center telescope on #{target}", *CENTER_TELESCOPE_MESSAGES)
        when 'The pain is too much', "That's a bit tough to do when you can't see the sky"
          Lich::Messaging.msg("bold", "DRCMM: Planet #{target} not visible. Are you indoors perhaps?")
        when "You'll need to open it to make any use of it"
          fput("open my telescope")
          fput("center telescope on #{target}")
        end
      end

      # Aligns the telescope based on the specified skill.
      #
      # @param skill [String] the skill to align with
      # @return [void]
      def align(skill)
        DRC.bput("align #{skill}", 'You focus internally')
      end

      # Attempts to retrieve bones from storage.
      #
      # @param storage [Hash] the storage information
      # @return [Boolean] true if the bones are successfully retrieved
      def get_bones?(storage)
        if storage['tied']
          DRCI.untie_item?("bones", storage['tied'])
        elsif storage['container']
          DRCI.get_item?("bones", storage['container'])
        else
          DRCI.get_item?("bones")
        end
      end

      # Attempts to store bones in the specified storage.
      #
      # @param storage [Hash] the storage information
      # @return [Boolean] true if the bones are successfully stored
      def store_bones?(storage)
        if storage['tied']
          DRCI.tie_item?("bones", storage['tied'])
        elsif storage['container']
          DRCI.put_away_item?("bones", storage['container'])
        else
          DRCI.put_away_item?("bones")
        end
      end

      # Retrieves bones and sends a message if it fails.
      #
      # @param storage [Hash] the storage information
      # @return [void]
      def get_bones(storage)
        return if get_bones?(storage)

        Lich::Messaging.msg('bold', 'DRCMM: Failed to get bones.')
      end

      # Stores bones and sends a message if it fails.
      #
      # @param storage [Hash] the storage information
      # @return [void]
      def store_bones(storage)
        return if store_bones?(storage)

        Lich::Messaging.msg('bold', 'DRCMM: Failed to store bones.')
      end

      # Rolls the bones and manages the storage of bones afterward.
      #
      # @param storage [Hash] the storage information
      # @return [void]
      def roll_bones(storage)
        unless get_bones?(storage)
          Lich::Messaging.msg('bold', 'DRCMM: Failed to get bones, aborting roll_bones.')
          return
        end

        DRC.bput('roll my bones', 'roundtime')
        waitrt?

        Lich::Messaging.msg('bold', 'DRCMM: Failed to store bones after rolling.') unless store_bones?(storage)
      end

      # Attempts to retrieve a divination tool from storage.
      #
      # @param tool [Hash] the divination tool information
      # @return [Boolean] true if the tool is successfully retrieved
      def get_div_tool?(tool)
        if tool['tied']
          DRCI.untie_item?(tool['name'], tool['container'])
        elsif tool['worn']
          DRCI.remove_item?(tool['name'])
        else
          DRCI.get_item?(tool['name'], tool['container'])
        end
      end

      # Attempts to store a divination tool in the specified storage.
      #
      # @param tool [Hash] the divination tool information
      # @return [Boolean] true if the tool is successfully stored
      def store_div_tool?(tool)
        if tool['tied']
          DRCI.tie_item?(tool['name'], tool['container'])
        elsif tool['worn']
          DRCI.wear_item?(tool['name'])
        else
          DRCI.put_away_item?(tool['name'], tool['container'])
        end
      end

      # Retrieves a divination tool and sends a message if it fails.
      #
      # @param tool [Hash] the divination tool information
      # @return [void]
      def get_div_tool(tool)
        return if get_div_tool?(tool)

        Lich::Messaging.msg('bold', "DRCMM: Failed to get divination tool '#{tool['name']}'.")
      end

      # Stores a divination tool and sends a message if it fails.
      #
      # @param tool [Hash] the divination tool information
      # @return [void]
      def store_div_tool(tool)
        return if store_div_tool?(tool)

        Lich::Messaging.msg('bold', "DRCMM: Failed to store divination tool '#{tool['name']}'.")
      end

      # Uses a divination tool for its intended purpose.
      #
      # @param tool_storage [Hash] the storage information for the tool
      # @return [void]
      def use_div_tool(tool_storage)
        unless get_div_tool?(tool_storage)
          Lich::Messaging.msg('bold', "DRCMM: Failed to get divination tool '#{tool_storage['name']}', aborting use_div_tool.")
          return
        end

        DIV_TOOL_VERBS
          .select { |tool, _| tool_storage['name'].include?(tool) }
          .each   { |tool, verb| DRC.bput("#{verb} my #{tool}", 'roundtime'); waitrt? }

        unless store_div_tool?(tool_storage)
          Lich::Messaging.msg('bold', "DRCMM: Failed to store divination tool '#{tool_storage['name']}'.")
        end
      end

      # Attempts to wear a moon weapon if one is held.
      #
      # @return [Boolean] true if a moon weapon was successfully worn
      def wear_moon_weapon?
        wore_it = false
        if is_moon_weapon?(DRC.left_hand)
          wore_it = wore_it || DRC.bput("wear #{DRC.left_hand}", *MOON_WEAR_MESSAGES) == "telekinetic"
        end
        if is_moon_weapon?(DRC.right_hand)
          wore_it = wore_it || DRC.bput("wear #{DRC.right_hand}", *MOON_WEAR_MESSAGES) == "telekinetic"
        end
        wore_it
      end

      # Attempts to drop a moon weapon if one is held.
      #
      # @return [Boolean] true if a moon weapon was successfully dropped
      def drop_moon_weapon?
        dropped_it = false
        if is_moon_weapon?(DRC.left_hand)
          dropped_it = dropped_it || DRC.bput("drop #{DRC.left_hand}", *MOON_DROP_MESSAGES) == "As you open your hand"
        end
        if is_moon_weapon?(DRC.right_hand)
          dropped_it = dropped_it || DRC.bput("drop #{DRC.right_hand}", *MOON_DROP_MESSAGES) == "As you open your hand"
        end
        dropped_it
      end

      # Checks if a moon weapon is currently being held.
      #
      # @return [Boolean] true if a moon weapon is held
      def holding_moon_weapon?
        is_moon_weapon?(DRC.left_hand) || is_moon_weapon?(DRC.right_hand)
      end

      # Attempts to hold a moon weapon if no other weapons are held.
      #
      # @return [Boolean] true if a moon weapon was successfully held
      def hold_moon_weapon?
        return true if holding_moon_weapon?
        return false if [DRC.left_hand, DRC.right_hand].compact.length >= 2

        MOON_WEAPON_NAMES.each do |weapon|
          glance = DRC.bput("glance my #{weapon}", "You glance at a .* #{weapon}", "I could not find")
          case glance
          when /You glance/
            return DRC.bput("hold my #{weapon}", "You grab", "You aren't wearing", "Hold hands with whom?", "You need a free hand") == "You grab"
          end
        end
        false
      end

      # Checks if the specified item is a moon weapon.
      #
      # @param item [String] the item to check
      # @return [Boolean] true if the item is a moon weapon
      def is_moon_weapon?(item)
        return false unless item

        MOON_WEAPON_REGEX.match?(item)
      end

      # Determines which moon was used to summon a weapon.
      #
      # @return [String, nil] the name of the moon or nil if none found
      def moon_used_to_summon_weapon
        # Note, if you have more than one weapon summoned at a time
        # then the results of this method are non-deterministic.
        # For example, if you have 2+ moonblades/staffs cast on different moons.
        MOON_WEAPON_NAMES.each do |weapon|
          glance = DRC.bput("glance my #{weapon}", MOON_GLANCE_REGEX, "I could not find")
          match = glance&.match(MOON_GLANCE_REGEX)
          return MOON_COLOR_TO_NAME[match[:color]] if match
        end
        nil
      end

      # Updates the astral data based on the provided information.
      #
      # @param data [Hash] the data to update
      # @param settings [OpenStruct, nil] optional settings for the update
      # @return [Hash] the updated data
      def update_astral_data(data, settings = nil)
        if data['moon']
          data = set_moon_data(data)
        elsif data['stats']
          data = set_planet_data(data, settings)
        end
        data
      end

      # Finds visible planets based on the provided settings.
      #
      # @param planets [Array<String>] the list of planets to check
      # @param settings [OpenStruct, nil] optional settings for the search
      # @return [Array<String>] the visible planets found
      def find_visible_planets(planets, settings = nil)
        unless get_telescope?(settings.telescope_name, settings.telescope_storage)
          Lich::Messaging.msg("bold", "DRCMM: Could not get telescope to find visible planets.")
          return
        end

        Flags.add('planet-not-visible', 'turns up fruitless')
        observed_planets = []

        begin
          planets.each do |planet|
            center_telescope(planet)
            observed_planets << planet unless Flags['planet-not-visible']
            Flags.reset('planet-not-visible')
          end
        ensure
          Flags.delete('planet-not-visible')
        end

        Lich::Messaging.msg("bold", "DRCMM: Could not store telescope after finding visible planets.") unless store_telescope?(settings.telescope_name, settings.telescope_storage)
        observed_planets
      end

      # Sets the planet data based on the provided information.
      #
      # @param data [Hash] the data to set
      # @param settings [OpenStruct, nil] optional settings for the update
      # @return [Hash] the updated data
      def set_planet_data(data, settings = nil)
        return data unless data['stats']

        planets = get_data('constellations')[:constellations].select { |planet| planet['stats'] }
        planet_names = planets.map { |planet| planet['name'] }
        visible_planets = find_visible_planets(planet_names, settings)
        data['stats'].each do |stat|
          cast_on = planets.map { |planet| planet['name'] if planet['stats'].include?(stat) && visible_planets.include?(planet['name']) }.compact.first
          next unless cast_on

          data['cast'] = "cast #{cast_on}"
          return data
        end
        Lich::Messaging.msg("bold", "DRCMM: Could not set planet data. Cannot cast #{data['abbrev']}.")
      end

      # Sets the moon data based on the provided information.
      #
      # @param data [Hash] the data to set
      # @return [Hash, nil] the updated data or nil if no moon is available
      def set_moon_data(data)
        return data unless data['moon']

        moon = visible_moons.first
        if moon
          data['cast'] = "cast #{moon}"
        elsif data['name'].downcase == 'cage of light'
          data['cast'] = "cast ambient"
        else
          Lich::Messaging.msg("bold", "DRCMM: No moon available to cast #{data['name']}.")
          data = nil
        end
        data
      end

      # Checks if a bright celestial object is currently visible.
      #
      # @return [Boolean] true if a bright celestial object is visible
      def bright_celestial_object?
        check_moonwatch
        (UserVars.sun['day'] && UserVars.sun['timer'] >= MOON_VISIBILITY_TIMER_THRESHOLD) || moon_visible?('xibar') || moon_visible?('yavash')
      end

      # Checks if any celestial object is currently visible.
      #
      # @return [Boolean] true if any celestial object is visible
      def any_celestial_object?
        check_moonwatch
        (UserVars.sun['day'] && UserVars.sun['timer'] >= MOON_VISIBILITY_TIMER_THRESHOLD) || moons_visible?
      end

      # Checks if any moons are currently visible.
      #
      # @return [Boolean] true if any moons are visible
      def moons_visible?
        !visible_moons.empty?
      end

      # Checks if a specific moon is currently visible.
      #
      # @param moon_name [String] the name of the moon to check
      # @return [Boolean] true if the moon is visible
      def moon_visible?(moon_name)
        visible_moons.include?(moon_name)
      end

      # Retrieves a list of currently visible moons.
      #
      # @return [Array<String>] the names of visible moons
      def visible_moons
        check_moonwatch
        UserVars.moons.select { |moon_name, moon_data| UserVars.moons['visible'].include?(moon_name) && moon_data['timer'] >= MOON_VISIBILITY_TIMER_THRESHOLD }
                      .map { |moon_name, _moon_data| moon_name }
      end

      # Checks if the moonwatch script is running and starts it if not.
      #
      # @return [void]
      def check_moonwatch
        return if Script.running?('moonwatch')

        Lich::Messaging.msg("bold", "DRCMM: moonwatch is not running. Starting it now.")
        UserVars.moons = {}
        start_script('moonwatch')
        Lich::Messaging.msg("plain", "DRCMM: Run `#{$clean_lich_char}e autostart('moonwatch')` to avoid this in the future.")
        pause 0.5 while UserVars.moons.empty?
      end
    end
  end
end
