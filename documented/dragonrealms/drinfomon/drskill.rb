
module Lich
  module DragonRealms
    # Represents a skill in the DragonRealms game.
    #
    # This class manages skill data, including experience and rank.
    #
    # @see Lich::DragonRealms for related modules.
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
      # @param name [String] the name of the skill (e.g., "Evasion")
      # @param rank [Integer] the earned rank in the skill
      # @param exp [Integer] the experience points for the skill
      # @param percent [Integer] the percentage to the next rank from 0 to 100
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

      def self.start_time
        @@start_time
      end

      def self.gained_skills
        @@gained_skills
      end

      # Calculates the gained experience for a skill.
      # @param val [String] the name of the skill
      # @return [Float] the gained experience, rounded to two decimal places
      def self.gained_exp(val)
        skill = find_skill(val)
        return 0.00 unless skill&.current

        (skill.current - skill.baseline).round(2)
      end

      # Handles changes in experience for a skill.
      # @param name [String] the name of the skill
      # @param new_exp [Integer] the new experience value
      # @return [void]
      # @api private
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

      def self.include?(val)
        !find_skill(val).nil?
      end

      # Updates the skill's rank, experience, and percentage.
      # @param name [String] the name of the skill
      # @param rank [Integer] the new rank of the skill
      # @param exp [Integer] the new experience points for the skill
      # @param percent [Integer] the new percentage to the next rank
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
      # @param name [String] the name of the skill
      # @param rank [Integer] the new rank to set as a modifier
      # @return [void]
      # @api private
      def self.update_mods(name, rank)
        exp_modifiers[lookup_alias(name)] = rank.to_i
      end

      # Updates the stored, usable, and refresh rested experience values.
      # @param stored [String] the stored rested experience as a string
      # @param usable [String] the usable rested experience as a string
      # @param refresh [String] the refresh time for rested experience as a string
      # @return [void]
      # @api private
      def self.update_rested_exp(stored, usable, refresh)
        @@rexp_stored = convert_rexp_str_to_seconds(stored)
        @@rexp_usable = convert_rexp_str_to_seconds(usable)
        @@rexp_refresh = convert_rexp_str_to_seconds(refresh)
      end

      def self.exp_modifiers
        @@exp_modifiers
      end

      def self.rested_exp_stored
        @@rexp_stored
      end

      def self.rested_exp_usable
        @@rexp_usable
      end

      def self.rested_exp_refresh
        @@rexp_refresh
      end

      # Checks if there is any rested experience available.
      # @return [Boolean] true if there is rested experience, false otherwise
      def self.rested_active?
        @@rexp_stored > 0 && @@rexp_usable > 0
      end

      def self.clear_mind(val)
        skill = find_skill(val)
        skill.exp = 0 if skill
      end

      # Retrieves the rank of a specified skill.
      # @param val [String] the name of the skill
      # @return [Integer] the rank of the skill, or 0 if not found
      def self.getrank(val)
        skill = find_skill(val)
        return 0 unless skill

        skill.rank.to_i
      end

      # Retrieves the modified rank of a specified skill, including modifiers.
      # @param val [String] the name of the skill
      # @return [Integer] the modified rank of the skill, or 0 if not found
      def self.getmodrank(val)
        skill = find_skill(val)
        return 0 unless skill

        rank = skill.rank.to_i
        modifier = exp_modifiers[skill.name].to_i
        rank + modifier
      end

      # Retrieves the experience points of a specified skill.
      # @param val [String] the name of the skill
      # @return [Integer] the experience points of the skill, or 0 if not found
      def self.getxp(val)
        skill = find_skill(val)
        return 0 unless skill

        skill.exp.to_i
      end

      # Retrieves the percentage to the next rank of a specified skill.
      # @param val [String] the name of the skill
      # @return [Integer] the percentage to the next rank, or 0 if not found
      def self.getpercent(val)
        skill = find_skill(val)
        return 0 unless skill

        skill.percent.to_i
      end

      # Retrieves the skillset associated with a specified skill.
      # @param val [String] the name of the skill
      # @return [String, nil] the skillset name, or nil if not found
      def self.getskillset(val)
        skill = find_skill(val)
        return nil unless skill

        skill.skillset
      end

      # Lists all skills and their details to the messaging system.
      # @return [void]
      def self.listall
        @@list.each do |i|
          Lich::Messaging.msg('plain', "DRSkill: #{i.name}: #{i.rank}.#{i.percent}% [#{i.exp}/34]")
        end
      end

      def self.list
        @@list
      end

      # Finds a skill by its name or alias.
      # @param val [String] the name or alias of the skill
      # @return [DRSkill, nil] the found skill instance, or nil if not found
      def self.find_skill(val)
        @@list.find { |data| data.name == lookup_alias(val) }
      end

      # Converts a rested experience time string into seconds.
      # @param time_string [String] the time string to convert
      # @return [Integer] the total seconds represented by the time string
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
      # @param skill [String] the name of the skill
      # @return [String, nil] the skillset name, or nil if not found
      def lookup_skillset(skill)
        result = @@skills_data[:skillsets].find { |_skillset, skills| skills.include?(skill) }
        result&.first
      end
    end
  end
end
