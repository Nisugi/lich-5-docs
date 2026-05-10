
module Lich
  module DragonRealms
    module DRDefsPattern
      # Pattern to extract the final "and X" portion of room player lists
      # Pattern to extract the final "and X" portion of room player lists.
      #
      # @see DRDefsPattern::PLAYER_NAME
      # @see DRDefsPattern::COMMA_OR_AND
      TRAILING_AND = / and (?<last>.*)$/.freeze
      # Pattern to match player status descriptions
      # Pattern to match player status descriptions.
      #
      # @example Matches:
      #   "who is glowing"
      #   "whose body appears dead"
      PLAYER_STATUS = / (who|whose body)? ?(has|is|appears|glows) .+/.freeze
      # Pattern to match parenthetical info after player names
      # Pattern to match parenthetical info after player names.
      #
      # @example Matches:
      #   "(injured)"
      #   "(asleep)"
      PARENTHETICAL = / \(.+\)/.freeze
      # Pattern to extract player name (word characters at end)
      # Pattern to extract player name (word characters at end).
      #
      # @example Matches:
      #   "John"
      #   "Doe"
      PLAYER_NAME = /\w+$/.freeze
      # Pattern for lying down players
      # Pattern for lying down players.
      #
      # @example Matches:
      #   "who is lying down"
      LYING_DOWN = /who is lying down/i.freeze
      # Pattern for sitting players
      # Pattern for sitting players.
      #
      # @example Matches:
      #   "who is sitting"
      SITTING = /who is sitting/i.freeze
      # Pattern for "You also see" prefix
      # Pattern for "You also see" prefix.
      #
      # @example Matches:
      #   "You also see a dragon"
      YOU_ALSO_SEE = /You also see/.freeze
      # Pattern for mount descriptions
      # Pattern for mount descriptions.
      #
      # @example Matches:
      #   "with a horse sitting astride its back"
      MOUNT_DESCRIPTION = / with a [\w\s]+ sitting astride its back/.freeze
      # Pattern to find NPCs in room objects (bold tags indicate creatures)
      # Pattern to find NPCs in room objects (bold tags indicate creatures).
      #
      # @example Matches:
      #   "<pushBold/>Goblin<popBold/> which appears dead"
      NPC_SCAN = %r{<pushBold/>[^<>]*<popBold/> which appears dead|<pushBold/>[^<>]*<popBold/> \(dead\)|<pushBold/>[^<>]*<popBold/>}.freeze
      # Pattern for dead NPCs
      # Pattern for dead NPCs.
      #
      # @example Matches:
      #   "which appears dead"
      #   "(dead)"
      DEAD_NPC = /which appears dead|\(dead\)/.freeze
      # Pattern for pushBold tags (indicates creature, not object)
      # Pattern for pushBold tags (indicates creature, not object).
      #
      # @example Matches:
      #   "pushBold"
      PUSH_BOLD = /pushBold/.freeze
      # Pattern for leading articles
      # Pattern for leading articles.
      #
      # @example Matches:
      #   "a dragon"
      #   "some goblins"
      LEADING_ARTICLE = /^(a|some) /.freeze
      # Pattern for trailing period
      # Pattern for trailing period.
      #
      # @example Matches:
      #   "This is a test."
      TRAILING_PERIOD = /\.$/.freeze
      # Pattern for splitting on comma or "and"
      # Pattern for splitting on comma or "and".
      #
      # @example Matches:
      #   "a, b, and c"
      COMMA_OR_AND = /,|\sand\s/.freeze
      # Pattern for extracting creature name (letters, hyphens, apostrophes only)
      # Note: Using [A-Za-z] instead of [A-z] to avoid matching [\]^_` characters
      # Pattern for extracting creature name (letters, hyphens, apostrophes only).
      #
      # @example Matches:
      #   "dragon"
      #   "elf-king"
      CREATURE_NAME = /[A-Za-z'-]+$/.freeze
      # Pattern for "who has/is" descriptions
      # Pattern for "who has/is" descriptions.
      #
      # @example Matches:
      #   "who has a sword"
      #   "who is glowing"
      WHO_STATUS = / who (has|is) .+/.freeze
      # Pattern for "glowing with" modifiers
      # Pattern for "glowing with" modifiers.
      #
      # @example Matches:
      #   "glowing with magic"
      GLOWING_WITH = /(?:\sglowing)?\swith\s.*/.freeze
      # Gelapod replacement pattern
      # Gelapod replacement pattern.
      #
      # @example Matches:
      #   "<pushBold/>a domesticated gelapod<popBold/>"
      GELAPOD = "<pushBold/>a domesticated gelapod<popBold/>".freeze
      GELAPOD_REPLACEMENT = 'domesticated gelapod'.freeze
      # Creature name normalization patterns (creatures with variant descriptions)
      # Creature name normalization patterns (creatures with variant descriptions).
      #
      # @example Matches:
      #   "alfar warrior"
      ALFAR_WARRIOR_PATTERN = /.*alfar warrior.*/.freeze
      # Creature name normalization patterns (creatures with variant descriptions).
      #
      # @example Matches:
      #   "sinewy leopard"
      SINEWY_LEOPARD_PATTERN = /.*sinewy leopard.*/.freeze
      # Creature name normalization patterns (creatures with variant descriptions).
      #
      # @example Matches:
      #   "lesser naga"
      LESSER_NAGA_PATTERN = /.*lesser naga.*/.freeze
    end

    # Converts a given amount of currency to copper.
    #
    # @param amt [Integer] the amount to convert
    # @param denomination [String] the currency denomination (e.g., "gold")
    # @return [Integer] the equivalent amount in copper
    def convert2copper(amt, denomination)
      if denomination =~ /platinum/
        (amt.to_i * 10_000)
      elsif denomination =~ /gold/
        (amt.to_i * 1000)
      elsif denomination =~ /silver/
        (amt.to_i * 100)
      elsif denomination =~ /bronze/
        (amt.to_i * 10)
      else
        amt
      end
    end

    # Checks for experience modifiers in the game.
    #
    # @return [void]
    def check_exp_mods
      Lich::Util.issue_command("exp mods", /The following skills are currently under the influence of a modifier/, /^<output class=""/, quiet: true, include_end: false, usexml: false)
    end

    # Converts a given amount of copper to various denominations.
    #
    # @param copper [Integer] the amount of copper to convert
    # @return [String] a string representation of the denominations
    def convert2plats(copper)
      denominations = [[10_000, 'platinum'], [1000, 'gold'], [100, 'silver'], [10, 'bronze'], [1, 'copper']]
      denominations.inject([copper, []]) do |result, denomination|
        remaining = result.first
        display = result.last
        if remaining / denomination.first > 0
          display << "#{remaining / denomination.first} #{denomination.last}"
        end
        [remaining % denomination.first, display]
      end.last.join(', ')
    end

    # Cleans and splits room objects into an array.
    #
    # @param room_objs [String] the room objects string
    # @return [Array<String>] an array of cleaned room objects
    def clean_and_split(room_objs)
      room_objs.sub(DRDefsPattern::YOU_ALSO_SEE, '')
               .sub(DRDefsPattern::MOUNT_DESCRIPTION, '')
               .strip
               .split(DRDefsPattern::COMMA_OR_AND)
    end

    # Normalizes the trailing "and" in a string.
    #
    # @param text [String] the input text
    # @return [String] the normalized text
    def normalize_trailing_and(text)
      if (match = text.match(DRDefsPattern::TRAILING_AND))
        text.sub(DRDefsPattern::TRAILING_AND, ", #{match[:last]}")
      else
        text
      end
    end

    # Extracts player characters from a room player string.
    #
    # @param room_players [String] the room players string
    # @param filter_pattern [Regexp, nil] optional pattern to filter players
    # @param status_pattern [Regexp] the pattern to match player status
    # @return [Array<String>] an array of extracted player character names
    def extract_pcs(room_players, filter_pattern: nil, status_pattern: DRDefsPattern::PLAYER_STATUS)
      return [] if room_players.nil? || room_players.empty?

      players = normalize_trailing_and(room_players).split(', ')
      players = players.select { |obj| filter_pattern.match?(obj) } if filter_pattern

      players
        .map { |obj| obj.sub(status_pattern, '').sub(DRDefsPattern::PARENTHETICAL, '') }
        .map { |obj| obj.strip.scan(DRDefsPattern::PLAYER_NAME).first }
        .compact
    end

    # Finds player characters in a room.
    #
    # @param room_players [String] the room players string
    # @return [Array<String>] an array of player character names
    def find_pcs(room_players)
      extract_pcs(room_players)
    end

    # Finds player characters that are lying down in a room.
    #
    # @param room_players [String] the room players string
    # @return [Array<String>] an array of prone player character names
    def find_pcs_prone(room_players)
      extract_pcs(room_players, filter_pattern: DRDefsPattern::LYING_DOWN, status_pattern: DRDefsPattern::WHO_STATUS)
    end

    # Finds player characters that are sitting in a room.
    #
    # @param room_players [String] the room players string
    # @return [Array<String>] an array of sitting player character names
    def find_pcs_sitting(room_players)
      extract_pcs(room_players, filter_pattern: DRDefsPattern::SITTING, status_pattern: DRDefsPattern::WHO_STATUS)
    end

    # Finds all non-player characters in a room.
    #
    # @param room_objs [String] the room objects string
    # @return [Array<String>] an array of non-player character descriptions
    def find_all_npcs(room_objs)
      room_objs.sub(DRDefsPattern::YOU_ALSO_SEE, '')
               .sub(DRDefsPattern::MOUNT_DESCRIPTION, '')
               .strip
               .scan(DRDefsPattern::NPC_SCAN)
    end

    # Cleans and normalizes a string of NPC names.
    #
    # @param npc_string [Array<String>] the array of NPC strings
    # @return [Array<String>] an array of cleaned NPC names
    def clean_npc_string(npc_string)
      # Normalize NPC names
      normalized_npcs = npc_string
                        .map { |obj| normalize_creature_names(obj) }
                        .map { |obj| remove_html_tags(obj) }
                        .map { |obj| extract_last_creature(obj) }
                        .map { |obj| extract_final_name(obj) }
                        .compact
                        .sort

      # Count occurrences and add ordinals
      add_ordinals_to_duplicates(normalized_npcs)
    end

    # Normalizes creature names based on specific patterns.
    #
    # @param text [String] the input text
    # @return [String] the normalized text
    def normalize_creature_names(text)
      text
        .sub(DRDefsPattern::ALFAR_WARRIOR_PATTERN, 'alfar warrior')
        .sub(DRDefsPattern::SINEWY_LEOPARD_PATTERN, 'sinewy leopard')
        .sub(DRDefsPattern::LESSER_NAGA_PATTERN, 'lesser naga')
    end

    # Removes HTML tags from a string.
    #
    # @param text [String] the input text
    # @return [String] the text without HTML tags
    def remove_html_tags(text)
      text
        .sub('<pushBold/>', '')
        .sub(%r{<popBold/>.*}, '')
    end

    # Extracts the last creature name from a string, removing modifiers.
    #
    # @param text [String] the input text
    # @return [String] the last creature name
    def extract_last_creature(text)
      # Get the last creature name after "and", removing modifiers like "glowing with"
      text.split(/\sand\s/).last.sub(DRDefsPattern::GLOWING_WITH, '')
    end

    # Extracts just the creature name from a string.
    #
    # @param text [String] the input text
    # @return [String] the extracted creature name
    def extract_final_name(text)
      # Extract just the creature name (letters, hyphens, apostrophes)
      text.strip.scan(DRDefsPattern::CREATURE_NAME).first
    end

    # Adds ordinal numbers to duplicate NPC names in a list.
    #
    # @param npc_list [Array<String>] the list of NPC names
    # @return [Array<String>] the list with ordinals added
    def add_ordinals_to_duplicates(npc_list)
      flat_npcs = []

      npc_list.uniq.each do |npc|
        # Count how many times this NPC appears
        count = npc_list.count(npc)

        # Create entries with ordinals for duplicates
        count.times do |index|
          if index.zero?
            flat_npcs << npc
          else
            # Use ordinal from $ORDINALS if available, otherwise generate one
            ordinal = $ORDINALS[index] || "#{index + 1}th"
            flat_npcs << "#{ordinal} #{npc}"
          end
        end
      end

      flat_npcs
    end

    # Extracts non-player characters from room objects.
    #
    # @param room_objs [String] the room objects string
    # @param select_dead [Boolean] whether to include dead NPCs
    # @return [Array<String>] an array of extracted NPC names
    def extract_npcs(room_objs, select_dead: false)
      all_npcs = find_all_npcs(room_objs)
      filtered = if select_dead
                   all_npcs.select { |obj| DRDefsPattern::DEAD_NPC.match?(obj) }
                 else
                   all_npcs.reject { |obj| DRDefsPattern::DEAD_NPC.match?(obj) }
                 end
      clean_npc_string(filtered)
    end

    # Finds non-player characters in a room.
    #
    # @param room_objs [String] the room objects string
    # @return [Array<String>] an array of non-player character names
    def find_npcs(room_objs)
      extract_npcs(room_objs, select_dead: false)
    end

    # Finds dead non-player characters in a room.
    #
    # @param room_objs [String] the room objects string
    # @return [Array<String>] an array of dead non-player character names
    def find_dead_npcs(room_objs)
      extract_npcs(room_objs, select_dead: true)
    end

    # Finds objects in a room, excluding certain patterns.
    #
    # @param room_objs [String] the room objects string
    # @return [Array<String>] an array of found objects
    def find_objects(room_objs)
      # Use sub instead of sub! to avoid mutating frozen strings
      processed_objs = room_objs.sub(DRDefsPattern::GELAPOD, DRDefsPattern::GELAPOD_REPLACEMENT)
      clean_and_split(processed_objs)
        .reject { |obj| DRDefsPattern::PUSH_BOLD.match?(obj) }
        .map { |obj| obj.sub(DRDefsPattern::TRAILING_PERIOD, '').strip.sub(DRDefsPattern::LEADING_ARTICLE, '').strip }
    end
  end
end
