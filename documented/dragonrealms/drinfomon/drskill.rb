
module Lich
  module DragonRealms
    # Represents a skill in the DragonRealms game.
    # This class manages skill data, including experience and rank.
    # @example Creating a new skill
    #   skill = Lich::DragonRealms::DRSkill.new("Evasion", 10, 100, 50)
    class DRSkill
      @@skills_data ||= DR_SKILLS_DATA
      @@gained_skills ||= []
      @@start_time ||= Time.now
      @@list ||= []
      @@exp_modifiers ||= {}
      # stored in seconds for easier manipulation with Time objects.  values will
      #   always be divisible by 60 as we don't get any further precision then that,
      #   and heuristically getting finer precision isn't worth the effort
      @@rexp_stored ||= 0
      @@rexp_usable ||= 0
      @@rexp_refresh ||= 0

      attr_reader :name, :skillset
      attr_accessor :rank, :exp, :percent, :current, :baseline

      # Initializes a new DRSkill instance.
      # @param name [String] The name of the skill.
      # @param rank [Integer] The earned rank in the skill.
      # @param exp [Integer] The experience points for the skill.
      # @param percent [Integer] The percentage to the next rank from 0 to 100.
      # @return [DRSkill]
      def initialize(name, rank, exp, percent)
        @name = name # skill name like 'Evasion'
        @rank = rank.to_i # earned ranks in the skill
        # Skill mindstate x/34
        # Hardcode caped skills to 34/34
        @exp = rank.to_i >= 1750 ? 34 : exp.to_i
        @percent = percent.to_i # percent to next rank from 0 to 100
        @baseline = rank.to_i + (percent.to_i / 100.0)
        @current = rank.to_i + (percent.to_i / 100.0)
        @skillset = lookup_skillset(@name)
        @@list.push(self) unless @@list.find { |skill| skill.name == @name }
      end

      # Resets the gained skills and start time.
      # @return [void]
      def self.reset
        @@gained_skills = []
        @@start_time = Time.now
        @@list.each { |skill| skill.baseline = skill.current }
      end

      # Returns the start time of the skill tracking.
      # @return [Time] The start time.
      def self.start_time
        @@start_time
      end

      # Returns the list of gained skills.
      # @return [Array<Hash>] An array of hashes containing skill names and changes.
      def self.gained_skills
        @@gained_skills
      end

      # Calculates the gained experience for a skill.
      # @param val [String] The name of the skill.
      # @return [Float] The amount of experience gained.
      def self.gained_exp(val)
        skill = find_skill(val)
        return 0.00 unless skill&.current

        (skill.current - skill.baseline).round(2)
      end

      # Handles the experience change for a skill.
      # @param name [String] The name of the skill.
      # @param new_exp [Integer] The new experience value.
      # @return [void]
      def self.handle_exp_change(name, new_exp)
        return unless Lich.display_expgains

        # Only track gains for skills that already exist
        # (skip initial skill discovery on login)
        skill = find_skill(name)
        return unless skill

        old_exp = skill.exp.to_i
        change = new_exp.to_i - old_exp
        if change > 0
          @@gained_skills << { skill: name, change: change }
        end
      end

      # Checks if a skill exists in the list.
      # @param val [String] The name of the skill.
      # @return [Boolean] True if the skill exists, false otherwise.
      def self.include?(val)
        !find_skill(val).nil?
      end

      # Updates the skill's rank, experience, and percentage.
      # @param name [String] The name of the skill.
      # @param rank [Integer] The new rank of the skill.
      # @param exp [Integer] The new experience points.
      # @param percent [Integer] The new percentage to the next rank.
      # @return [void]
      def self.update(name, rank, exp, percent)
        handle_exp_change(name, exp)
        skill = find_skill(name)
        if skill
          skill.rank = rank.to_i
          skill.exp = skill.rank.to_i >= 1750 ? 34 : exp.to_i
          skill.percent = percent.to_i
          skill.current = rank.to_i + (percent.to_i / 100.0)
        else
          DRSkill.new(name, rank, exp, percent)
        end
      end

      # Updates the experience modifiers for a skill.
      # @param name [String] The name of the skill.
      # @param rank [Integer] The new rank to set.
      # @return [void]
      def self.update_mods(name, rank)
        exp_modifiers[lookup_alias(name)] = rank.to_i
      end

      # Updates the rested experience values.
      # @param stored [String] The stored experience string.
      # @param usable [String] The usable experience string.
      # @param refresh [String] The refresh time string.
      # @return [void]
      def self.update_rested_exp(stored, usable, refresh)
        @@rexp_stored = convert_rexp_str_to_seconds(stored)
        @@rexp_usable = convert_rexp_str_to_seconds(usable)
        @@rexp_refresh = convert_rexp_str_to_seconds(refresh)
      end

      # Returns the experience modifiers for skills.
      # @return [Hash] A hash of skill names and their modifiers.
      def self.exp_modifiers
        @@exp_modifiers
      end

      # Returns the stored rested experience.
      # @return [Integer] The stored rested experience in seconds.
      def self.rested_exp_stored
        @@rexp_stored
      end

      # Returns the usable rested experience.
      # @return [Integer] The usable rested experience in seconds.
      def self.rested_exp_usable
        @@rexp_usable
      end

      # Returns the refresh time for rested experience.
      # @return [Integer] The refresh time in seconds.
      def self.rested_exp_refresh
        @@rexp_refresh
      end

      # Checks if there is any rested experience available.
      # @return [Boolean] True if there is rested experience, false otherwise.
      def self.rested_active?
        @@rexp_stored > 0 && @@rexp_usable > 0
      end

      # Clears the experience of a skill.
      # @param val [String] The name of the skill.
      # @return [void]
      def self.clear_mind(val)
        skill = find_skill(val)
        skill.exp = 0 if skill
      end

      # Gets the rank of a skill.
      # @param val [String] The name of the skill.
      # @return [Integer] The rank of the skill.
      def self.getrank(val)
        skill = find_skill(val)
        return 0 unless skill

        skill.rank.to_i
      end

      # Gets the modified rank of a skill including modifiers.
      # @param val [String] The name of the skill.
      # @return [Integer] The modified rank of the skill.
      def self.getmodrank(val)
        skill = find_skill(val)
        return 0 unless skill

        rank = skill.rank.to_i
        modifier = exp_modifiers[skill.name].to_i
        rank + modifier
      end

      # Gets the experience points of a skill.
      # @param val [String] The name of the skill.
      # @return [Integer] The experience points of the skill.
      def self.getxp(val)
        skill = find_skill(val)
        return 0 unless skill

        skill.exp.to_i
      end

      # Gets the percentage to the next rank of a skill.
      # @param val [String] The name of the skill.
      # @return [Integer] The percentage to the next rank.
      def self.getpercent(val)
        skill = find_skill(val)
        return 0 unless skill

        skill.percent.to_i
      end

      # Gets the skillset associated with a skill.
      # @param val [String] The name of the skill.
      # @return [String, nil] The skillset name or nil if not found.
      def self.getskillset(val)
        skill = find_skill(val)
        return nil unless skill

        skill.skillset
      end

      # Lists all skills with their details.
      # @return [void]
      def self.listall
        @@list.each do |i|
          Lich::Messaging.msg('plain', "DRSkill: #{i.name}: #{i.rank}.#{i.percent}% [#{i.exp}/34]")
        end
      end

      # Returns the list of all skills.
      # @return [Array<DRSkill>] An array of all DRSkill instances.
      def self.list
        @@list
      end

      # Finds a skill by its name.
      # @param val [String] The name of the skill.
      # @return [DRSkill, nil] The DRSkill instance or nil if not found.
      def self.find_skill(val)
        @@list.find { |data| data.name == lookup_alias(val) }
      end

      # Converts a rested experience string to seconds.
      # @param time_string [String] The rested experience time string.
      # @return [Integer] The total seconds represented by the string.
      def self.convert_rexp_str_to_seconds(time_string)
        # Handle empty, nil, or specific "zero" cases (less than a minute is zero because it can get stuck there)
        return 0 if time_string.nil? ||
                    time_string.to_s.strip.empty? ||
                    time_string.include?('none') ||
                    time_string.include?('less than a minute')

        total_seconds = 0

        # Extract hours and optional minutes (e.g., "4:38 hours" or "6 hour")
        # Ruby's match returns a MatchData object or nil
        if (hour_match = time_string.match(/(\d+):?(\d+)?\s*hour/))
          hours = hour_match[1].to_i
          total_seconds += hours * 60 * 60

          # Handle the minutes part of a "4:38" format
          if hour_match[2]
            total_seconds += hour_match[2].to_i * 60
            return total_seconds
          end
        end

        # Extract standalone minutes (e.g., "38 minutes")
        if (minute_match = time_string.match(/(\d+)\s*minute/))
          total_seconds += minute_match[1].to_i * 60
        end

        total_seconds
      end

      def self.lookup_alias(skill)
        @@skills_data.dig(:guild_skill_aliases, DRStats.guild, skill) || skill
      end

      # Looks up the skillset for a given skill.
      # @param skill [String] The name of the skill.
      # @return [String, nil] The skillset name or nil if not found.
      def lookup_skillset(skill)
        result = @@skills_data[:skillsets].find { |_skillset, skills| skills.include?(skill) }
        result&.first
      end
    end
  end
end
