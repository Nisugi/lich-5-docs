# frozen_string_literal: true

require "ostruct"

module Lich
  module Gemstone
    # Provides access to enhancive item bonuses tracked via the INVENTORY ENHANCIVE TOTALS command.
    #
    # Enhancive items in GemStone IV provide temporary stat, skill, resource, and spell bonuses.
    # This module parses and exposes those bonuses through a clean API, allowing scripts to
    # query current enhancive values, detect over-cap situations, and manage enhancive state.
    #
    # Data is populated by the {Infomon::Parser} when processing game output from:
    # - `INVENTORY ENHANCIVE TOTALS` - Full enhancive breakdown
    # - `INVENTORY ENHANCIVE` - Active state and pause count
    #
    # @example Check enhancive strength bonus
    #   Enhancive.strength.value  # => 41
    #   Enhancive.strength.cap    # => 40
    #   Enhancive.str             # => 41 (shorthand)
    #
    # @example Check skill bonuses
    #   Enhancive.edged_weapons.bonus  # => 50
    #   Enhancive.edged_weapons.ranks  # => 10
    #   Enhancive.ambush.bonus         # => 52
    #
    # @example Check resource bonuses
    #   Enhancive.max_mana.value       # => 18
    #   Enhancive.mana_recovery.value  # => 30
    #
    # @example Check for over-cap stats
    #   Enhancive.stat_over_cap?(:strength)  # => true (if > 40)
    #   Enhancive.over_cap_stats             # => [:strength, :agility]
    #
    # @example Check enhancive-granted spells
    #   Enhancive.spells              # => [215, 506, 1109]
    #   Enhancive.knows_spell?(215)   # => true
    #
    # @example Check active state
    #   Enhancive.active?   # => true/false
    #   Enhancive.pauses    # => 1233
    #
    # @example Refresh data from game
    #   Enhancive.refresh         # Full refresh (status + totals)
    #   Enhancive.refresh_status  # Lightweight (just active state + pauses)
    #
    # @see Lich::Gemstone::Infomon::Parser Parses INVENTORY ENHANCIVE output
    # @see Lich::Gemstone::Stats Base character stats module
    # @see Lich::Gemstone::Skills Base character skills module
    #
    module Enhancive
      # @!group Constants

      # List of stat symbols tracked by enhancives.
      # @note Influence is not included as enhancives don't provide influence bonuses.
      # @return [Array<Symbol>] Stat symbols
      STATS = %i[strength constitution dexterity agility discipline aura logic intuition wisdom].freeze

      # Maps 3-letter stat abbreviations to full stat symbols.
      # Used by the parser to convert game output.
      # @return [Hash<String, Symbol>] Abbreviation to symbol mapping
      STAT_ABBREV = {
        'STR' => :strength, 'CON' => :constitution, 'DEX' => :dexterity,
        'AGI' => :agility, 'DIS' => :discipline, 'AUR' => :aura,
        'LOG' => :logic, 'INT' => :intuition, 'WIS' => :wisdom
      }.freeze

      # Maximum enhancive bonus for any single stat.
      # @return [Integer] Cap value (40)
      STAT_CAP = 40

      # List of skill symbols that can receive enhancive bonuses.
      # Skills can have both rank bonuses and skill bonus bonuses.
      # @return [Array<Symbol>] Skill symbols
      BONUS_SKILLS = %i[
        two_weapon_combat armor_use shield_use combat_maneuvers edged_weapons
        blunt_weapons two_handed_weapons ranged_weapons thrown_weapons polearm_weapons
        brawling ambush multi_opponent_combat physical_fitness dodging arcane_symbols
        magic_item_use spell_aiming harness_power elemental_mana_control mental_mana_control
        spirit_mana_control elemental_lore_air elemental_lore_earth elemental_lore_fire
        elemental_lore_water spiritual_lore_blessings spiritual_lore_religion
        spiritual_lore_summoning sorcerous_lore_demonology sorcerous_lore_necromancy
        mental_lore_divination mental_lore_manipulation mental_lore_telepathy
        mental_lore_transference mental_lore_transformation survival disarming_traps
        picking_locks stalking_and_hiding perception climbing swimming first_aid
        trading pickpocketing
      ].freeze

      # Maximum enhancive bonus for any single skill.
      # @return [Integer] Cap value (50)
      SKILL_CAP = 50

      # List of resource symbols that can receive enhancive bonuses.
      # @return [Array<Symbol>] Resource symbols
      RESOURCES = %i[max_mana max_health max_stamina mana_recovery stamina_recovery].freeze

      # Maximum enhancive bonus for each resource type.
      # Different resources have different caps.
      # @return [Hash<Symbol, Integer>] Resource to cap mapping
      RESOURCE_CAPS = {
        max_mana: 600, max_health: 300, max_stamina: 300,
        mana_recovery: 50, stamina_recovery: 50
      }.freeze

      # Maps game output skill names to internal symbol names.
      # Used by the parser to normalize skill names from INVENTORY ENHANCIVE TOTALS.
      # @return [Hash<String, Symbol>] Display name to symbol mapping
      SKILL_NAME_MAP = {
        'Two Weapon Combat'            => :two_weapon_combat,
        'Armor Use'                    => :armor_use,
        'Shield Use'                   => :shield_use,
        'Combat Maneuvers'             => :combat_maneuvers,
        'Edged Weapons'                => :edged_weapons,
        'Blunt Weapons'                => :blunt_weapons,
        'Two-Handed Weapons'           => :two_handed_weapons,
        'Ranged Weapons'               => :ranged_weapons,
        'Thrown Weapons'               => :thrown_weapons,
        'Polearm Weapons'              => :polearm_weapons,
        'Brawling'                     => :brawling,
        'Ambush'                       => :ambush,
        'Multi Opponent Combat'        => :multi_opponent_combat,
        'Physical Fitness'             => :physical_fitness,
        'Dodging'                      => :dodging,
        'Arcane Symbols'               => :arcane_symbols,
        'Magic Item Use'               => :magic_item_use,
        'Spell Aiming'                 => :spell_aiming,
        'Harness Power'                => :harness_power,
        'Elemental Mana Control'       => :elemental_mana_control,
        'Mental Mana Control'          => :mental_mana_control,
        'Spirit Mana Control'          => :spirit_mana_control,
        'Elemental Lore - Air'         => :elemental_lore_air,
        'Elemental Lore - Earth'       => :elemental_lore_earth,
        'Elemental Lore - Fire'        => :elemental_lore_fire,
        'Elemental Lore - Water'       => :elemental_lore_water,
        'Spiritual Lore - Blessings'   => :spiritual_lore_blessings,
        'Spiritual Lore - Religion'    => :spiritual_lore_religion,
        'Spiritual Lore - Summoning'   => :spiritual_lore_summoning,
        'Sorcerous Lore - Demonology'  => :sorcerous_lore_demonology,
        'Sorcerous Lore - Necromancy'  => :sorcerous_lore_necromancy,
        'Mental Lore - Divination'     => :mental_lore_divination,
        'Mental Lore - Manipulation'   => :mental_lore_manipulation,
        'Mental Lore - Telepathy'      => :mental_lore_telepathy,
        'Mental Lore - Transference'   => :mental_lore_transference,
        'Mental Lore - Transformation' => :mental_lore_transformation,
        'Survival'                     => :survival,
        'Disarming Traps'              => :disarming_traps,
        'Picking Locks'                => :picking_locks,
        'Stalking and Hiding'          => :stalking_and_hiding,
        'Perception'                   => :perception,
        'Climbing'                     => :climbing,
        'Swimming'                     => :swimming,
        'First Aid'                    => :first_aid,
        'Trading'                      => :trading,
        'Pickpocketing'                => :pickpocketing
      }.freeze

      # Maps game output resource names to internal symbol names.
      # Used by the parser to normalize resource names from INVENTORY ENHANCIVE TOTALS.
      # @return [Hash<String, Symbol>] Display name to symbol mapping
      RESOURCE_NAME_MAP = {
        'Max Mana'         => :max_mana,
        'Max Health'       => :max_health,
        'Max Stamina'      => :max_stamina,
        'Mana Recovery'    => :mana_recovery,
        'Stamina Recovery' => :stamina_recovery
      }.freeze

      # @!endgroup

      # @!group Stat Accessors

      # Dynamically defines stat accessor methods for each stat in {STATS}.
      # Each method returns an OpenStruct with :value and :cap.
      #
      # @!method strength
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (Integer)
      # @!method constitution
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (Integer)
      # @!method dexterity
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (Integer)
      # @!method agility
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (Integer)
      # @!method discipline
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (Integer)
      # @!method aura
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (Integer)
      # @!method logic
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (Integer)
      # @!method intuition
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (Integer)
      # @!method wisdom
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (Integer)
      STATS.each do |stat|
        define_singleton_method(stat) do
          OpenStruct.new(
            value: Infomon.get("enhancive.stat.#{stat}").to_i,
            cap: STAT_CAP
          )
        end
      end

      # Shorthand stat accessors that return just the value (not OpenStruct).
      # @!method str
      #   @return [Integer] Enhancive strength bonus value
      # @!method con
      #   @return [Integer] Enhancive constitution bonus value
      # @!method dex
      #   @return [Integer] Enhancive dexterity bonus value
      # @!method agi
      #   @return [Integer] Enhancive agility bonus value
      # @!method dis
      #   @return [Integer] Enhancive discipline bonus value
      # @!method aur
      #   @return [Integer] Enhancive aura bonus value
      # @!method log
      #   @return [Integer] Enhancive logic bonus value
      # @!method int
      #   @return [Integer] Enhancive intuition bonus value
      # @!method wis
      #   @return [Integer] Enhancive wisdom bonus value
      %i[str con dex agi dis aur log int wis].each do |shorthand|
        long_hand = STATS.find { |s| s.to_s.start_with?(shorthand.to_s) }
        define_singleton_method(shorthand) do
          send(long_hand).value
        end
      end

      # @!endgroup

      # @!group Skill Accessors

      # Dynamically defines skill accessor methods for each skill in {BONUS_SKILLS}.
      # Each method returns an OpenStruct with :ranks, :bonus, :value (combined), and :cap.
      #
      # @example
      #   Enhancive.edged_weapons.ranks  # => 10
      #   Enhancive.edged_weapons.bonus  # => 50
      #   Enhancive.edged_weapons.value  # => 60 (ranks + bonus)
      #   Enhancive.edged_weapons.cap    # => 50
      BONUS_SKILLS.each do |skill|
        define_singleton_method(skill) do
          ranks = Infomon.get("enhancive.skill.#{skill}.ranks").to_i
          bonus = Infomon.get("enhancive.skill.#{skill}.bonus").to_i
          OpenStruct.new(
            ranks: ranks,
            bonus: bonus,
            value: ranks + bonus,
            cap: SKILL_CAP
          )
        end
      end

      # Shorthand skill aliases matching the Skills module naming conventions.
      # @example
      #   Enhancive.edgedweapons  # Same as Enhancive.edged_weapons
      #   Enhancive.smc           # Same as Enhancive.spirit_mana_control
      {
        twoweaponcombat: :two_weapon_combat,
        armoruse: :armor_use,
        shielduse: :shield_use,
        combatmaneuvers: :combat_maneuvers,
        edgedweapons: :edged_weapons,
        bluntweapons: :blunt_weapons,
        twohandedweapons: :two_handed_weapons,
        rangedweapons: :ranged_weapons,
        thrownweapons: :thrown_weapons,
        polearmweapons: :polearm_weapons,
        multiopponentcombat: :multi_opponent_combat,
        physicalfitness: :physical_fitness,
        arcanesymbols: :arcane_symbols,
        magicitemuse: :magic_item_use,
        spellaiming: :spell_aiming,
        harnesspower: :harness_power,
        disarmingtraps: :disarming_traps,
        pickinglocks: :picking_locks,
        stalkingandhiding: :stalking_and_hiding,
        firstaid: :first_aid,
        emc: :elemental_mana_control,
        mmc: :mental_mana_control,
        smc: :spirit_mana_control,
        elair: :elemental_lore_air,
        elearth: :elemental_lore_earth,
        elfire: :elemental_lore_fire,
        elwater: :elemental_lore_water,
        slblessings: :spiritual_lore_blessings,
        slreligion: :spiritual_lore_religion,
        slsummoning: :spiritual_lore_summoning,
        sldemonology: :sorcerous_lore_demonology,
        slnecromancy: :sorcerous_lore_necromancy,
        mldivination: :mental_lore_divination,
        mlmanipulation: :mental_lore_manipulation,
        mltelepathy: :mental_lore_telepathy,
        mltransference: :mental_lore_transference,
        mltransformation: :mental_lore_transformation
      }.each do |shorthand, long_hand|
        define_singleton_method(shorthand) do
          send(long_hand)
        end
      end

      # @!endgroup

      # @!group Resource Accessors

      # Dynamically defines resource accessor methods for each resource in {RESOURCES}.
      # Each method returns an OpenStruct with :value and :cap.
      #
      # @!method max_mana
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (600)
      # @!method max_health
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (300)
      # @!method max_stamina
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (300)
      # @!method mana_recovery
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (50)
      # @!method stamina_recovery
      #   @return [OpenStruct] Struct with :value (Integer) and :cap (50)
      RESOURCES.each do |resource|
        define_singleton_method(resource) do
          OpenStruct.new(
            value: Infomon.get("enhancive.resource.#{resource}").to_i,
            cap: RESOURCE_CAPS[resource]
          )
        end
      end

      # Convenience alias for {max_mana}.
      # @return [OpenStruct] Same as max_mana
      def self.mana
        max_mana
      end

      # Convenience alias for {max_health}.
      # @return [OpenStruct] Same as max_health
      def self.health
        max_health
      end

      # Convenience alias for {max_stamina}.
      # @return [OpenStruct] Same as max_stamina
      def self.stamina
        max_stamina
      end

      # @!endgroup

      # @!group Spell Accessors

      # Returns array of spell numbers that enhancives grant self-knowledge of.
      # These are spells the character can cast due to enhancive items, not trained spells.
      #
      # @return [Array<Integer>] Array of spell numbers, or empty array if none
      # @example
      #   Enhancive.spells  # => [215, 506, 1109]
      def self.spells
        raw = Infomon.get("enhancive.spells")
        return [] if raw.nil? || raw.empty?

        raw.to_s.split(',').map(&:to_i)
      end

      # Check if enhancives grant knowledge of a specific spell.
      #
      # @param spell_num [Integer, String] Spell number to check
      # @return [Boolean] true if enhancives grant this spell
      # @example
      #   Enhancive.knows_spell?(215)   # => true
      #   Enhancive.knows_spell?(101)   # => false
      def self.knows_spell?(spell_num)
        spells.include?(spell_num.to_i)
      end

      # @!endgroup

      # @!group Statistics Accessors

      # Returns the total number of enhancive items contributing bonuses.
      #
      # @return [Integer] Number of enhancive items
      def self.item_count
        Infomon.get("enhancive.stats.item_count").to_i
      end

      # Returns the total number of enhancive properties across all items.
      # A single item can have multiple enhancive properties.
      #
      # @return [Integer] Number of enhancive properties
      def self.property_count
        Infomon.get("enhancive.stats.property_count").to_i
      end

      # Returns the sum of all enhancive bonus amounts.
      #
      # @return [Integer] Total enhancive amount
      def self.total_amount
        Infomon.get("enhancive.stats.total_amount").to_i
      end

      # @!endgroup

      # @!group Active State

      # Returns whether enhancives are currently active (toggled on).
      # Players can toggle enhancives on/off with INVENTORY ENHANCIVE ON/OFF.
      #
      # @return [Boolean] true if enhancives are active
      def self.active?
        Infomon.get("enhancive.active") == true
      end

      # Returns the Time when active state was last updated.
      #
      # @return [Time, nil] Time of last update, or nil if never updated
      def self.active_last_updated
        timestamp = Infomon.get_updated_at("enhancive.active")
        timestamp ? Time.at(timestamp) : nil
      end

      # Returns the number of enhancive pauses available.
      # Pauses allow temporarily disabling enhancive drain.
      #
      # @return [Integer] Number of pauses available
      def self.pauses
        Infomon.get("enhancive.pauses").to_i
      end

      # @!endgroup

      # @!group Metadata

      # Returns the Time when enhancive data was last refreshed.
      # Based on when item_count was last updated.
      #
      # @return [Time, nil] Time of last refresh, or nil if never refreshed
      def self.last_updated
        timestamp = Infomon.get_updated_at("enhancive.stats.item_count")
        timestamp ? Time.at(timestamp) : nil
      end

      # @!endgroup

      # @!group Utility Methods

      # Check if a specific stat's enhancive bonus exceeds the cap.
      #
      # @param stat [Symbol] Stat symbol (e.g., :strength, :agility)
      # @return [Boolean] true if the stat bonus exceeds {STAT_CAP}
      # @example
      #   Enhancive.stat_over_cap?(:strength)  # => true (if > 40)
      def self.stat_over_cap?(stat)
        send(stat).value > STAT_CAP
      end

      # Check if a specific skill's enhancive bonus exceeds the cap.
      #
      # @param skill [Symbol] Skill symbol (e.g., :ambush, :edged_weapons)
      # @return [Boolean] true if the skill bonus exceeds {SKILL_CAP}
      # @example
      #   Enhancive.skill_over_cap?(:ambush)  # => true (if bonus > 50)
      def self.skill_over_cap?(skill)
        s = send(skill)
        s.bonus > SKILL_CAP
      end

      # Returns all stats that are currently over their enhancive cap.
      #
      # @return [Array<Symbol>] Array of stat symbols that are over cap
      # @example
      #   Enhancive.over_cap_stats  # => [:strength, :agility]
      def self.over_cap_stats
        STATS.select { |s| stat_over_cap?(s) }
      end

      # Returns all skills that are currently over their enhancive cap.
      #
      # @return [Array<Symbol>] Array of skill symbols that are over cap
      # @example
      #   Enhancive.over_cap_skills  # => [:ambush, :stalking_and_hiding]
      def self.over_cap_skills
        BONUS_SKILLS.select { |s| skill_over_cap?(s) rescue false }
      end

      # @!endgroup

      # @!group Refresh Methods

      # Triggers a full refresh of enhancive data from the game.
      # Issues INVENTORY ENHANCIVE and INVENTORY ENHANCIVE TOTALS commands.
      # Blocks until complete.
      #
      # @return [void]
      # @note Output is hidden from the user via quiet mode
      def self.refresh
        respond "Refreshing enhancive data..."
        # First get status (active state + pauses)
        Lich::Util.issue_command(
          "invento enh",
          /^You are (?:currently|not currently|now|already|no longer)/,
          /<prompt/,
          include_end: true, timeout: 5, silent: false, usexml: true, quiet: true
        )
        # Then get full totals
        # TODO: Update start pattern once GM adds proper start message to invento enhancive totals
        # Current pattern is fragile - if player has no stat enhancives, output starts with Skills/Resources
        Lich::Util.issue_command(
          "invento enhancive totals",
          /^<pushBold\/>(?:Stats:|Skills:|Resources:)|^No enhancive item bonuses found\./,
          /<prompt/,
          include_end: true, timeout: 5, silent: false, usexml: true, quiet: true
        )
        respond "Enhancive data refreshed."
      end

      # Triggers a lightweight refresh of just the active state and pause count.
      # Issues only INVENTORY ENHANCIVE command.
      # Blocks until complete.
      #
      # @return [void]
      # @note Faster than {refresh} when you only need active state
      def self.refresh_status
        Lich::Util.issue_command(
          "invento enh",
          /^You are (?:currently|not currently|now|already|no longer)/,
          /<prompt/,
          include_end: true, timeout: 5, silent: false, usexml: true, quiet: true
        )
      end

      # @!endgroup

      # @!group Internal Methods

      # Resets all enhancive values to 0/empty.
      # Called by the parser before populating new data to ensure stale values are cleared.
      # This is critical because game output only shows non-zero values.
      #
      # @return [void]
      # @api private
      def self.reset_all
        batch = []

        # Reset all stats to 0
        STATS.each do |stat|
          batch.push(["enhancive.stat.#{stat}", 0])
        end

        # Reset all skills to 0
        BONUS_SKILLS.each do |skill|
          batch.push(["enhancive.skill.#{skill}.ranks", 0])
          batch.push(["enhancive.skill.#{skill}.bonus", 0])
        end

        # Reset all resources to 0
        RESOURCES.each do |resource|
          batch.push(["enhancive.resource.#{resource}", 0])
        end

        # Reset spells to empty array
        batch.push(["enhancive.spells", ""])

        # Reset statistics to 0
        batch.push(["enhancive.stats.item_count", 0])
        batch.push(["enhancive.stats.property_count", 0])
        batch.push(["enhancive.stats.total_amount", 0])

        Infomon.upsert_batch(batch)
      end

      # @!endgroup
    end
  end
end
