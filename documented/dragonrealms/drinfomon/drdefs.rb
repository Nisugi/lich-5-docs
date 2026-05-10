
module Lich
  module DragonRealms
    module DRDefsPattern
      # Pattern to extract the final "and X" portion of room player lists
      # Pattern to extract the final "and X" portion of room player lists
      TRAILING_AND = / and (?<last>.*)$/.freeze
      # Pattern to match player status descriptions
      # Pattern to match player status descriptions
      PLAYER_STATUS = / (who|whose body)? ?(has|is|appears|glows) .+/.freeze
      # Pattern to match parenthetical info after player names
      # Pattern to match parenthetical info after player names
      PARENTHETICAL = / \(.+\)/.freeze
      # Pattern to extract player name (word characters at end)
      # Pattern to extract player name (word characters at end)
      PLAYER_NAME = /\w+$/.freeze
      # Pattern for lying down players
      # Pattern for lying down players
      LYING_DOWN = /who is lying down/i.freeze
      # Pattern for sitting players
      # Pattern for sitting players
      SITTING = /who is sitting/i.freeze
      # Pattern for "You also see" prefix
      # Pattern for "You also see" prefix
      YOU_ALSO_SEE = /You also see/.freeze
      # Pattern for mount descriptions
      # Pattern for mount descriptions
      MOUNT_DESCRIPTION = / with a [\w\s]+ sitting astride its back/.freeze
      # Pattern to find NPCs in room objects (bold tags indicate creatures)
      # Pattern to find NPCs in room objects (bold tags indicate creatures)
      NPC_SCAN = %r{<pushBold/>[^<>]*<popBold/> which appears dead|<pushBold/>[^<>]*<popBold/> \(dead\)|<pushBold/>[^<>]*<popBold/>}.freeze
      # Pattern for dead NPCs
      # Pattern for dead NPCs
      DEAD_NPC = /which appears dead|\(dead\)/.freeze
      # Pattern for pushBold tags (indicates creature, not object)
      # Pattern for pushBold tags (indicates creature, not object)
      PUSH_BOLD = /pushBold/.freeze
      # Pattern for leading articles
      # Pattern for leading articles
      LEADING_ARTICLE = /^(a|some) /.freeze
      # Pattern for trailing period
      # Pattern for trailing period
      TRAILING_PERIOD = /\.$/.freeze
      # Pattern for splitting on comma or "and"
      # Pattern for splitting on comma or "and"
      COMMA_OR_AND = /,|\sand\s/.freeze
      # Pattern for extracting creature name (letters, hyphens, apostrophes only)
      # Note: Using [A-Za-z] instead of [A-z] to avoid matching [\]^_` characters
      # Pattern for extracting creature name (letters, hyphens, apostrophes only)
      # Note: Using [A-Za-z] instead of [A-z] to avoid matching [\]^_` characters
      CREATURE_NAME = /[A-Za-z'-]+$/.freeze
      # Pattern for "who has/is" descriptions
      # Pattern for "who has/is" descriptions
      WHO_STATUS = / who (has|is) .+/.freeze
      # Pattern for "glowing with" modifiers
      # Pattern for "glowing with" modifiers
      GLOWING_WITH = /(?:\sglowing)?\swith\s.*/.freeze
      # Gelapod replacement pattern
      # Gelapod replacement pattern
      GELAPOD = "<pushBold/>a domesticated gelapod<popBold/>".freeze
      # Gelapod replacement string
      GELAPOD_REPLACEMENT = 'domesticated gelapod'.freeze
      # Creature name normalization patterns (creatures with variant descriptions)
      # Creature name normalization patterns (creatures with variant descriptions)
      ALFAR_WARRIOR_PATTERN = /.*alfar warrior.*/.freeze
      # Pattern for sinewy leopards
      SINEWY_LEOPARD_PATTERN = /.*sinewy leopard.*/.freeze
      # Pattern for lesser nagas
      LESSER_NAGA_PATTERN = /.*lesser naga.*/.freeze
    end

    # Converts an amount of currency to copper.
    # @param amt [Numeric] The amount to convert.
    # @param denomination [String] The currency denomination (e.g., "platinum", "gold").
    # @return [Numeric] The equivalent amount in copper.
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

    # Checks for experience modifiers.
    # @return [Array] The list of experience modifiers.
    def check_exp_mods
      Lich::Util.issue_command("exp mods", /The following skills are currently under the influence of a modifier/, /^<output class=""/, quiet: true, include_end: false, usexml: false)
    end

    # Converts an amount of copper to various denominations.
    # @param copper [Numeric] The amount of copper to convert.
    # @return [String] A string representation of the amount in different denominations.
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
    # @param room_objs [String] The room objects string to clean and split.
    # @return [Array<String>] The cleaned and split room objects.
    def clean_and_split(room_objs)
      room_objs.sub(DRDefsPattern::YOU_ALSO_SEE, '')
               .sub(DRDefsPattern::MOUNT_DESCRIPTION, '')
               .strip
               .split(DRDefsPattern::COMMA_OR_AND)
    end

    # Normalizes the trailing "and" in a string.
    # @param text [String] The text to normalize.
    # @return [String] The normalized text.
    def normalize_trailing_and(text)
      if (match = text.match(DRDefsPattern::TRAILING_AND))
        text.sub(DRDefsPattern::TRAILING_AND, ", #{match[:last]}")
      else
        text
      end
    end

    # Extracts player characters from a room player string.
    # @param room_players [String] The string of room players.
    # @param filter_pattern [Regexp, nil] An optional pattern to filter players.
    # @param status_pattern [Regexp] The pattern to match player status descriptions.
    # @return [Array<String>] The list of extracted player character names.
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
    # @param room_players [String] The string of room players.
    # @return [Array<String>] The list of player characters.
    def find_pcs(room_players)
      extract_pcs(room_players)
    end

    # Finds prone player characters in a room.
    # @param room_players [String] The string of room players.
    # @return [Array<String>] The list of prone player characters.
    def find_pcs_prone(room_players)
      extract_pcs(room_players, filter_pattern: DRDefsPattern::LYING_DOWN, status_pattern: DRDefsPattern::WHO_STATUS)
    end

    # Finds sitting player characters in a room.
    # @param room_players [String] The string of room players.
    # @return [Array<String>] The list of sitting player characters.
    def find_pcs_sitting(room_players)
      extract_pcs(room_players, filter_pattern: DRDefsPattern::SITTING, status_pattern: DRDefsPattern::WHO_STATUS)
    end

    # Finds all non-player characters in a room.
    # @param room_objs [String] The string of room objects.
    # @return [Array<String>] The list of non-player characters.
    def find_all_npcs(room_objs)
      room_objs.sub(DRDefsPattern::YOU_ALSO_SEE, '')
               .sub(DRDefsPattern::MOUNT_DESCRIPTION, '')
               .strip
               .scan(DRDefsPattern::NPC_SCAN)
    end

    # Cleans and normalizes a string of NPC names.
    # @param npc_string [Array<String>] The array of NPC strings to clean.
    # @return [Array<String>] The cleaned and sorted NPC names.
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
    # @param text [String] The text containing creature names to normalize.
    # @return [String] The normalized text.
    def normalize_creature_names(text)
      text
        .sub(DRDefsPattern::ALFAR_WARRIOR_PATTERN, 'alfar warrior')
        .sub(DRDefsPattern::SINEWY_LEOPARD_PATTERN, 'sinewy leopard')
        .sub(DRDefsPattern::LESSER_NAGA_PATTERN, 'lesser naga')
    end

    # Removes HTML tags from a string.
    # @param text [String] The text to remove HTML tags from.
    # @return [String] The text without HTML tags.
    def remove_html_tags(text)
      text
        .sub('<pushBold/>', '')
        .sub(%r{<popBold/>.*}, '')
    end

    # Extracts the last creature name from a string.
    # @param text [String] The text containing creature names.
    # @return [String] The last creature name.
    def extract_last_creature(text)
      # Get the last creature name after "and", removing modifiers like "glowing with"
      text.split(/\sand\s/).last.sub(DRDefsPattern::GLOWING_WITH, '')
    end

    # Extracts the final creature name from a string.
    # @param text [String] The text containing the creature name.
    # @return [String] The extracted creature name.
    def extract_final_name(text)
      # Extract just the creature name (letters, hyphens, apostrophes)
      text.strip.scan(DRDefsPattern::CREATURE_NAME).first
    end

    # Adds ordinals to duplicate NPC names in a list.
    # @param npc_list [Array<String>] The list of NPC names.
    # @return [Array<String>] The list of NPC names with ordinals.
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
    # @param room_objs [String] The string of room objects.
    # @param select_dead [Boolean] Whether to include dead NPCs.
    # @return [Array<String>] The list of extracted NPCs.
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
    # @param room_objs [String] The string of room objects.
    # @return [Array<String>] The list of non-player characters.
    def find_npcs(room_objs)
      extract_npcs(room_objs, select_dead: false)
    end

    # Finds dead non-player characters in a room.
    # @param room_objs [String] The string of room objects.
    # @return [Array<String>] The list of dead non-player characters.
    def find_dead_npcs(room_objs)
      extract_npcs(room_objs, select_dead: true)
    end

    # Finds objects in a room, excluding certain patterns.
    # @param room_objs [String] The string of room objects.
    # @return [Array<String>] The list of found objects.
    def find_objects(room_objs)
      # Use sub instead of sub! to avoid mutating frozen strings
      processed_objs = room_objs.sub(DRDefsPattern::GELAPOD, DRDefsPattern::GELAPOD_REPLACEMENT)
      clean_and_split(processed_objs)
        .reject { |obj| DRDefsPattern::PUSH_BOLD.match?(obj) }
        .map { |obj| obj.sub(DRDefsPattern::TRAILING_PERIOD, '').strip.sub(DRDefsPattern::LEADING_ARTICLE, '').strip }
    end
  end
end
