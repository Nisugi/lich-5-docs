module Lich
  module Gemstone
    # Represents a spellsong in the Lich game.
    #
    # This class manages the duration and effects of bard spells.
    #
    # @see Lich::Gemstone::Effects
    class Spellsong
      @@renewed ||= 0.to_f
      @@song_duration ||= 120.to_f
      @@duration_calcs ||= []

      # Synchronizes the spellsong duration based on active bard spells.
      #
      # @return [String] message indicating the status of the synchronization
      def self.sync
        timed_spell = Effects::Spells.to_h.keys.find { |k| k.to_s.match(/10[0-9][0-9]/) }
        return 'No active bard spells' if timed_spell.nil?
        @@renewed = Time.at(Time.now.to_f - self.timeleft.to_f + (Effects::Spells.time_left(timed_spell) * 60.to_f)) # duration
      end

      # Updates the timestamp of when the spellsong was last renewed.
      #
      # @return [void]
      def self.renewed
        @@renewed = Time.now
      end

      # Sets the timestamp of when the spellsong was last renewed.
      #
      # @param val [Time] the new renewed time
      # @return [void]
      def self.renewed=(val)
        @@renewed = val
      end

      # Returns the timestamp of when the spellsong was last renewed.
      #
      # @return [Time] the last renewed time
      def self.renewed_at
        @@renewed
      end

      # Calculates the remaining time left for the spellsong.
      #
      # @return [Float] remaining time in minutes
      def self.timeleft
        return 0.0 if Stats.prof != 'Bard'
        (self.duration - ((Time.now.to_f - @@renewed.to_f) % self.duration)) / 60.to_f
      end

      # Serializes the current state of the spellsong.
      #
      # @return [Float] the time left for the spellsong
      def self.serialize
        self.timeleft
      end

      # Calculates the total duration of the spellsong based on various factors.
      #
      # @return [Float] the total duration in seconds
      def self.duration
        return @@song_duration if @@duration_calcs == [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy]
        return @@song_duration if [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy].include?(nil)
        @@duration_calcs = [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy]
        total = self.duration_base_level(Stats.level)
        return (@@song_duration = total + Stats.log[1] + (Stats.inf[1] * 3) + (Skills.mltelepathy * 2))
      end

      # Calculates the base duration of the spellsong based on the bard's level.
      #
      # @param level [Integer] the bard's level
      # @return [Integer] the base duration in seconds
      def self.duration_base_level(level = Stats.level)
        total = 120
        case level
        when (0..25)
          total += level * 4
        when (26..50)
          total += 100 + (level - 25) * 3
        when (51..75)
          total += 175 + (level - 50) * 2
        when (76..100)
          total += 225 + (level - 75)
        else
          Lich.log("unhandled case in Spellsong.duration level=#{level}")
        end
        return total
      end

      # Calculates the total cost to renew active bard spells.
      #
      # @return [Integer] total renewal cost
      def self.renew_cost
        # fixme: multi-spell penalty?
        total = num_active = 0
        [1003, 1006, 1009, 1010, 1012, 1014, 1018, 1019, 1025].each { |song_num|
          if (song = Spell[song_num])
            if song.active?
              total += song.renew_cost
              num_active += 1
            end
          else
            echo "self.renew_cost: warning: can't find song number #{song_num}"
          end
        }
        return total
      end

      # Calculates the durability of the sonic armor.
      #
      # @return [Integer] durability value
      def self.sonicarmordurability
        210 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Calculates the durability of the sonic blade.
      #
      # @return [Integer] durability value
      def self.sonicbladedurability
        160 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Returns the durability of the sonic weapon.
      #
      # @return [Integer] durability value
      def self.sonicweapondurability
        self.sonicbladedurability
      end

      # Calculates the durability of the sonic shield.
      #
      # @return [Integer] durability value
      def self.sonicshielddurability
        125 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Calculates the haste bonus for the tonis spell.
      #
      # @return [Integer] haste bonus value
      def self.tonishastebonus
        bonus = -1
        thresholds = [30, 75]
        thresholds.each { |val| if Skills.elair >= val then bonus -= 1 end }
        bonus
      end

      # Calculates the push down effect of the depression spell.
      #
      # @return [Integer] push down value
      def self.depressionpushdown
        20 + Skills.mltelepathy
      end

      # Calculates the slow effect of the depression spell.
      #
      # @return [Integer] slow bonus value
      def self.depressionslow
        thresholds = [10, 25, 45, 70, 100]
        bonus = -2
        thresholds.each { |val| if Skills.mltelepathy >= val then bonus -= 1 end }
        bonus
      end

      # Calculates the number of targets that can be held by the bard.
      #
      # @return [Integer] number of holding targets
      def self.holdingtargets
        1 + ((Spells.bard - 1) / 7).truncate
      end

      # Returns the cost associated with renewing spells.
      #
      # @return [Integer] the renewal cost
      def self.cost
        self.renew_cost
      end

      # Calculates the dodge bonus for the tonis spell.
      #
      # @return [Integer] dodge bonus value
      def self.tonisdodgebonus
        thresholds = [1, 2, 3, 5, 8, 10, 14, 17, 21, 26, 31, 36, 42, 49, 55, 63, 70, 78, 87, 96]
        bonus = 20
        thresholds.each { |val| if Skills.elair >= val then bonus += 1 end }
        bonus
      end

      # Calculates the dodge bonus for the mirrors spell.
      #
      # @return [Integer] dodge bonus value
      def self.mirrorsdodgebonus
        20 + ((Spells.bard - 19) / 2).round
      end

      # Calculates the cost associated with the mirrors spell.
      #
      # @return [Array<Integer>] array containing cost values
      def self.mirrorscost
        [19 + ((Spells.bard - 19) / 5).truncate, 8 + ((Spells.bard - 19) / 10).truncate]
      end

      # Calculates the sonic bonus based on bard level.
      #
      # @return [Integer] sonic bonus value
      def self.sonicbonus
        (Spells.bard / 2).round
      end

      # Calculates the sonic armor bonus.
      #
      # @return [Integer] sonic armor bonus value
      def self.sonicarmorbonus
        self.sonicbonus + 15
      end

      # Calculates the sonic blade bonus.
      #
      # @return [Integer] sonic blade bonus value
      def self.sonicbladebonus
        self.sonicbonus + 10
      end

      # Returns the sonic weapon bonus.
      #
      # @return [Integer] sonic weapon bonus value
      def self.sonicweaponbonus
        self.sonicbladebonus
      end

      # Calculates the sonic shield bonus.
      #
      # @return [Integer] sonic shield bonus value
      def self.sonicshieldbonus
        self.sonicbonus + 10
      end

      # Calculates the valor bonus based on bard level.
      #
      # @return [Integer] valor bonus value
      def self.valorbonus
        10 + (([Spells.bard, Stats.level].min - 10) / 2).round
      end

      # Calculates the cost associated with the valor spell.
      #
      # @return [Array<Integer>] array containing cost values
      def self.valorcost
        [10 + (self.valorbonus / 2), 3 + (self.valorbonus / 5)]
      end

      # Calculates the cost associated with the luck spell.
      #
      # @return [Array<Integer>] array containing cost values
      def self.luckcost
        [6 + ((Spells.bard - 6) / 4), (6 + ((Spells.bard - 6) / 4) / 2).round]
      end

      # Returns the mana cost associated with spells.
      #
      # @return [Array<Integer>] array containing mana cost values
      def self.manacost
        [18, 15]
      end

      # Returns the fortitude cost associated with spells.
      #
      # @return [Array<Integer>] array containing fortitude cost values
      def self.fortcost
        [3, 1]
      end

      # Returns the shield cost associated with spells.
      #
      # @return [Array<Integer>] array containing shield cost values
      def self.shieldcost
        [9, 4]
      end

      # Returns the weapon cost associated with spells.
      #
      # @return [Array<Integer>] array containing weapon cost values
      def self.weaponcost
        [12, 4]
      end

      # Returns the armor cost associated with spells.
      #
      # @return [Array<Integer>] array containing armor cost values
      def self.armorcost
        [14, 5]
      end

      # Returns the sword cost associated with spells.
      #
      # @return [Array<Integer>] array containing sword cost values
      def self.swordcost
        [25, 15]
      end
    end
  end
end
