
module Lich
  module Gemstone
    # Manages the tracking of hidden targets in the game.
    # This class provides methods to track, clear, and check for hidden targets.
    # @example Tracking hidden targets
    #   Overwatch.track_hidden_targets(room_id)
    class Overwatch
      @@hidden_targets ||= nil
      @@debug          ||= false

      # Clears the list of hidden targets.
      # @return [nil]
      def self.clear
        @@hidden_targets = nil
      end

      # Returns the room ID with hidden targets.
      # @return [Object, nil] The room ID or nil if no targets are hidden.
      def self.room_with_hiders
        @@hidden_targets
      end

      # Checks if there are any hidden targets in the current room.
      # @return [Boolean] True if there are hidden targets, false otherwise.
      def self.hiders?
        return false if @@hidden_targets.nil?
        @@hidden_targets.eql?(XMLData.room_id)
      end

      # Tracks hidden targets in the specified room.
      # @param room_id [Object] The ID of the room to track hidden targets.
      # @return [nil]
      def self.track_hidden_targets(room_id)
        @@hidden_targets = room_id
      end

      # Resets the room with hidden targets by clearing the list.
      # @return [nil]
      def self.room_with_hiders_reset
        clear
      end

      # Sets the debug mode on or off.
      # @param value [Boolean] True to enable debug mode, false to disable.
      # @return [nil]
      def self.debug=(value)
        @@debug = value
      end

      # Checks if debug mode is enabled.
      # @return [Boolean] True if debug mode is enabled, false otherwise.
      def self.debug?
        @@debug
      end

      # Pushes revealed targets into the tracking system.
      # @param target_id [Object] The ID of the target.
      # @param target_noun [String] The noun associated with the target.
      # @param target_name [String] The name of the target.
      # @param silent_strike [Boolean] Indicates if the strike was silent.
      # @return [nil]
      def self.push_revealed_targets(target_id, target_noun, target_name, silent_strike: false)
        @@hidden_targets = nil

        if silent_strike
          respond "Checking for silent strike against #{target_id} #{target_name}." if @@debug
          result = reget(10, /fades into the surroundings\./, /slips into the shadows\./, /botch an attempt at concealing\./, /The figure quickly disappears from view\./, core: true)
          respond result if @@debug

          unless result.empty?
            case result[0]
            when /With a (?:barely audible hiss|sibilant exhalation), <pushBold\/>\w+ <a exist="(\d+)" noun=" ?\w+">[^<]+<\/a><popBold\/> (?:fades into the surroundings|slips into the shadows)\./
              if target_id == Regexp.last_match[1]
                respond "Silent Strike Detected. Target #{target_id} #{target_name} is hidden." if @@debug
                return
              end
            when /The figure quickly disappears from view\./
              respond "Silent Strike Detected. Target is hidden." if @@debug
              return
            when /You notice <pushBold\/>\w+ <a exist="(\d+)" noun=" ?\w+">[^<]+<\/a><popBold\/> botch an attempt at concealing <pushBold\/><a exist="\d+" noun=" ?\w+">\w+<\/a><popBold\/>\./
              if target_id == Regexp.last_match[1]
                respond "Silent Strike Botched. Target #{target_id} #{target_name}." if @@debug
              end
            end
          end
        end

        respond "push_revealed_targets(#{target_id}, #{target_noun}, #{target_name}, silent_strike: #{silent_strike})" if @@debug

        # Add to GameObj.npcs if not already present
        unless GameObj.npcs.any? { |npc| npc.id == target_id }
          GameObj.new_npc(target_id, target_noun, target_name.gsub(/  /, " "))
          respond "#{target_id} added to GameObj.npcs." if @@debug
        end

        # Add to XMLData.current_target_ids if not already present
        unless XMLData.current_target_ids.include?(target_id)
          XMLData.current_target_ids.unshift(target_id)
          respond "#{target_id} added to XMLData.current_target_ids." if @@debug
        end
      end

      # Provides functionality for observing and handling events related to hidden targets.
      module Observer
        # Contains regular expressions for detecting hiding and revealing actions.
        module Term
          # Patterns for creatures entering hiding
          HIDING = Regexp.union(
            /<pushBold\/>\w+ <a exist="\d+" noun="\w+">[^<]+<\/a><popBold\/> slips into hiding\./,
            /flies out of the shadows toward you\!/,
            /A faint silvery light flickers from the shadows\./,
            /Suddenly, a tiny shard of jet black crystal flies from the shadows toward you!/,
            /With a barely audible hiss, <pushBold\/>\w+ <a exist="\d+" noun=" ?\w+">[^<]+<\/a><popBold\/> fades into the surroundings\./,
            /With a sibilant exhalation, <pushBold\/>\w+ <a exist="\d+" noun=" ?\w+">[^<]+<\/a><popBold\/> slips into the shadows\./,
            /flies out of the shadows toward <a exist="\-\d+" noun="\w+">[^<]+<\/a>\!/,
            /flies out of the shadows toward <pushBold\/>\w+ <a exist="\d+" noun="\w+">[^<]+<\/a><popBold\/>\!/,
            /<pushBold\/>\w+ <a exist="\d+" noun=" ?\w+">[^<]+<\/a><popBold\/> darts into the shadows\./,
            /As you move to attack <pushBold\/>\w+ <a exist="\d+" noun=" ?\w+">[^<]+<\/a><popBold\/>, <pushBold\/>\w+ <a exist="\d+" noun=" ?\w+">[^<]+<\/a><popBold\/> shrinks away from you, baring sharpened teeth as <pushBold\/><a exist="\d+" noun=" ?\w+">\w+<\/a><popBold\/> darts into the shadows!/,
            /As you move to attack <pushBold\/>\w+ <a exist="\d+" noun=" ?\w+">[^<]+<\/a><popBold\/>, <pushBold\/><a exist="\d+" noun=" ?\w+">\w+<\/a><popBold\/> disperses into roiling shadows!/,
            /Something stirs in the shadows\./,
            /The figure quickly disappears from view\./,
            /<pushBold\/>\w+ <a exist="\d+" noun=" ?\w+">[^<]+<\/a><popBold\/> blends with the shadows, moving too swiftly for the eye to follow\./,
            /You notice the hiding place of <pushBold\/>\w+ <a exist="\d+" noun=" ?\w+">[^<]+<\/a><popBold\/>, but do not reveal your hidden position./
          )

          # Patterns for creatures being revealed from hiding
          REVEALED_DISCOVERY = /<pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> is revealed from hiding\./
          REVEALED_FORCED = /<pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> is forced from hiding\!/
          REVEALED_COMES_OUT = /<pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> comes out of hiding\./
          REVEALED_LEAPS_OUT = /<pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> leaps out of <pushBold\/><a exist="\d+" noun="\w+">\w+<\/a><popBold\/> hiding place\!/
          REVEALED_SUDDENLY_LEAPS = /<pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> suddenly leaps from <pushBold\/><a exist="\d+" noun=" ?\w+">\w+<\/a><popBold\/> hiding place\!/
          REVEALED_SHADOWS_MELT = /The shadows melt away to reveal <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/>!/
          REVEALED_YOU_DISCOVER = /You discover the hiding place of <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/>\!/
          REVEALED_YOU_REVEAL = /You reveal <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> from hiding\!/
          REVEALED_WALL_THORNS = /The thorny barrier surrounding you blocks the attack from the <pushBold\/><a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/>\!/
          REVEALED_FLAMING_AURA = /The flaming aura surrounding you lashes out at <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/>, who is forced into view!/

          # Animal companion reveals
          REVEALED_AC_CAT = /<pushBold\/>\w+ <a exist="\d+" noun="\w+">[^<]+<\/a><popBold\/> leaps suddenly forward, uncovering <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/>, who was hidden\!/
          REVEALED_AC_CANINE = /<pushBold\/>\w+ <a exist="\d+" noun="\w+">[^<]+<\/a><popBold\/> takes a pointed step forward, revealing <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/>, who was hidden\!/
          REVEALED_AC_AVIAN = /<pushBold\/>\w+ <a exist="\d+" noun=" ?\w+">[^<]+<\/a><popBold\/> dives ahead while flapping <pushBold\/><a exist="\d+" noun="\w+">\w+<\/a><popBold\/> wings, exposing <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/>, who was hidden\!/

          # Kiramon stalker specific reveals
          REVEALED_STALKER_BITE = /Without warning, <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> glides from the shadows and aims a preternaturally swift bite at you\!/
          REVEALED_STALKER_STINGER = /<pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> twists fluidly to spear you with <pushBold\/><a exist="\d+" noun=" ?\w+">\w+<\/a><popBold\/> barbed stinger\!/
          REVEALED_STALKER_SLASH = /Without warning, <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> glides from the shadows and skitters mercilessly forward to slash at you with a razor-sharp foreleg\!/
          REVEALED_STALKER_INTERPOSE = /As you attempt to hide, <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> glides past you in a single fluid motion, interposing between you and the safety of the shadows\./
          REVEALED_STALKER_MISS = /Caught unaware, you can only stare in fascination as <pushBold\/><a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">\w+<\/a><popBold\/> manages to completely miss you while nearly dropping <pushBold\/><a exist="\d+" noun=" ?\w+">\w+<\/a><popBold\/>  in the process\./

          # Silent strike patterns - attacks that may result in immediate rehiding
          SILENT_CUTTHROAT = /<pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> springs upon you from behind and attempts to grasp you by the chin while bringing <pushBold\/><a exist="\d+" noun=" ?\w+">\w+<\/a><popBold\/> <a exist="\d+" noun="[^"]+">[^<]+<\/a> up to slit your throat\!/
          SILENT_CANNIBAL_SWING = /With an ululating shriek, <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> leaps from the shadows and hurtles at you, swinging wildly with a <a exist="\d+" noun="[^"]+">[^<]+<\/a>!/
          SILENT_CANNIBAL_GRAPPLE = /With an ululating shriek, <pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> leaps from the shadows and throws <pushBold\/><a exist="\d+" noun="[^"]+">(?:his|her)<\/a><popBold\/> wiry arms around you, fueled by panicked hunger!/
          SILENT_LEAP_ATTACK = /<pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> leaps from hiding to attack\!/
          SILENT_SUBDUE = /<pushBold\/>\w+ <a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">(?<name>[^<]+)<\/a><popBold\/> springs upon you from behind and aims a blow to your head\!/
          SILENT_STALKER_SAVAGE = /Catching you unaware, <pushBold\/><a exist="(?<id>\d+)" noun=" ?(?<noun>\w+)">\w+<\/a><popBold\/> carves into you with cruel and ruthless savagery\!/

          # Combined patterns for efficient matching
          ANY_REVEALED = Regexp.union(
            REVEALED_DISCOVERY,
            REVEALED_FORCED,
            REVEALED_COMES_OUT,
            REVEALED_LEAPS_OUT,
            REVEALED_SUDDENLY_LEAPS,
            REVEALED_SHADOWS_MELT,
            REVEALED_YOU_DISCOVER,
            REVEALED_YOU_REVEAL,
            REVEALED_WALL_THORNS,
            REVEALED_FLAMING_AURA,
            REVEALED_AC_CAT,
            REVEALED_AC_CANINE,
            REVEALED_AC_AVIAN,
            REVEALED_STALKER_BITE,
            REVEALED_STALKER_STINGER,
            REVEALED_STALKER_SLASH,
            REVEALED_STALKER_INTERPOSE,
            REVEALED_STALKER_MISS
          )

          ANY_SILENT_STRIKE = Regexp.union(
            SILENT_CUTTHROAT,
            SILENT_CANNIBAL_SWING,
            SILENT_CANNIBAL_GRAPPLE,
            SILENT_LEAP_ATTACK,
            SILENT_SUBDUE,
            SILENT_STALKER_SAVAGE
          )

          ANY = Regexp.union(HIDING, ANY_REVEALED, ANY_SILENT_STRIKE)
        end

        def self.wants?(line)
          line.match(Term::ANY)
        end

        def self.consume(line, match_data)
          case line
          when Term::HIDING
            Overwatch.track_hidden_targets(XMLData.room_id)
          when Term::ANY_REVEALED
            Overwatch.push_revealed_targets(
              match_data[:id],
              match_data[:noun],
              match_data[:name]
            )
          when Term::ANY_SILENT_STRIKE
            # Handle special case for unknown assailant
            name = match_data[:name] || "unknown assailant"
            Overwatch.push_revealed_targets(
              match_data[:id],
              match_data[:noun],
              name,
              silent_strike: true
            )
          end
        end
      end
    end
  end
end
