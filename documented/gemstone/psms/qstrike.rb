
# Provides functionality for the Lich5 project.
#
# @see Lich::Gemstone for gemstone-related features.
module Lich
  module Gemstone
    # Module for handling QStrike combat mechanics.
    #
    # This module includes methods for calculating attack costs,
    # managing combat settings, and executing attacks.
    module QStrike
      # Speed multipliers by weapon category
      # Applied per-weapon to calculate Equipment Speed
      SPEED_MULTIPLIERS = {
        two_handed: 1.5,
        polearm: 1.5,
        ranged: 2.5,
        # All others default to 1.0
      }.freeze
      # Default speed multiplier for weapons not categorized.
      #
      # @example
      #   DEFAULT_MULTIPLIER # => 1.0
      DEFAULT_MULTIPLIER = 1.0

      # Striking Asp stance cost multipliers by rank
      # Rank 1 = 2/3 cost, Rank 2 = 1/2 cost, Rank 3 = 1/3 cost
      STRIKING_ASP_MULTIPLIERS = {
        1 => 2.0 / 3.0,  # 0.667
        2 => 1.0 / 2.0,  # 0.500
        3 => 1.0 / 3.0,  # 0.333
      }.freeze

      # Base cost constant from formula
      BASE_COST = 10

      # Maximum seconds of RT reduction (reasonable upper bound)
      MAX_REDUCTION = 8

      # Valid combat actions that can use QSTRIKE
      VALID_ACTIONS = %w[
        ascension ambush attack cheapshot cman cock disarm feat fire
        grapple hurl jab kill kick mstrike punch shield smite
        stunman subdue sweep tackle trip weapon wtricks
      ].freeze

      # Default settings
      # Default settings for QStrike module.
      #
      # @example
      #   DEFAULT_SETTINGS # => { reserve: 1, adaptive: false }
      DEFAULT_SETTINGS = {
        reserve: 1,
        adaptive: false
      }.freeze


      # Loads and returns the default settings for QStrike.
      #
      # @return [Hash] the current default settings.
      def self.defaults
        load_settings
        {
          reserve: @settings[:reserve],
          adaptive: @settings[:adaptive]
        }
      end

      # Updates the default settings with new values.
      #
      # @param new_defaults [Hash] new settings to apply.
      # @return [void]
      def self.defaults=(new_defaults)
        load_settings
        @settings.merge!(new_defaults)
        save_settings
      end

      # Sets a specific default setting to a new value.
      #
      # @param key [Symbol] the setting key to update.
      # @param value [Object] the new value for the setting.
      # @return [void]
      def self.set_default(key, value)
        load_settings
        @settings[key.to_sym] = value
        save_settings
      end

      # Retrieves the value of a specific default setting.
      #
      # @param key [Symbol] the setting key to retrieve.
      # @return [Object] the value of the specified setting.
      def self.default(key)
        load_settings
        @settings.fetch(key.to_sym, DEFAULT_SETTINGS[key.to_sym])
      end

      # Resets all default settings to their initial values.
      #
      # @return [void]
      def self.reset_defaults
        @settings = DEFAULT_SETTINGS.dup
        save_settings
      end

      def self.load_settings
        return if @settings_loaded

        if defined?(Lich::Common::DB_Store) && defined?(XMLData) && !XMLData.game.to_s.empty? && !XMLData.name.to_s.empty?
          scope = "#{XMLData.game}:#{XMLData.name}"
          stored = Lich::Common::DB_Store.read(scope, 'lich_qstrike')
          @settings = DEFAULT_SETTINGS.merge(stored || {})
          @settings_loaded = true
        else
          # Fallback to in-memory defaults
          @settings ||= DEFAULT_SETTINGS.dup
        end
      end

      def self.save_settings
        if defined?(Lich::Common::DB_Store) && defined?(XMLData) && !XMLData.game.to_s.empty? && !XMLData.name.to_s.empty?
          scope = "#{XMLData.game}:#{XMLData.name}"
          Lich::Common::DB_Store.save(scope, 'lich_qstrike', @settings)
        end
      end

      def self.reset_settings_cache
        @settings_loaded = false
        @settings = nil
      end


      # Calculates the QStrike reduction based on provided parameters.
      #
      # @param reserve [Integer, nil] the stamina reserve to consider.
      # @param attack_cost [Integer] the cost of the attack.
      # @param attack_name [String, nil] the name of the attack to look up.
      # @param attack_rt [Integer, nil] the current RT of the attack.
      # @return [Hash] a hash containing the calculated values.
      def self.calculate(reserve: nil, attack_cost: 0, attack_name: nil, attack_rt: nil)
        reserve ||= default(:reserve)
        # Look up attack cost if name provided
        if attack_name && attack_cost.zero?
          attack_cost = lookup_attack_cost(attack_name)
        end

        current_stamina = Char.stamina
        available = current_stamina - reserve - attack_cost

        if available <= 0
          return {
            seconds: 0,
            stamina_cost: 0,
            qstrike_cmd: nil,
            reason: :insufficient_stamina,
            current_stamina: current_stamina,
            available_stamina: available,
            attack_cost: attack_cost,
            reserve: reserve
          }
        end

        cost_per_second = cost_per_second_reduction
        max_seconds = find_max_seconds(available, cost_per_second)

        # Cap reduction based on attack's RT (can't reduce below 1 second)
        if attack_rt && attack_rt > 1
          max_useful = attack_rt - 1
          max_seconds = [max_seconds, max_useful].min
        end

        if max_seconds.positive?
          total_cost = cost_per_second * max_seconds
          {
            seconds: max_seconds,
            stamina_cost: total_cost,
            qstrike_cmd: "qstrike -#{max_seconds}",
            current_stamina: current_stamina,
            available_stamina: available,
            attack_cost: attack_cost,
            attack_rt: attack_rt,
            reserve: reserve,
            cost_per_second: cost_per_second,
            striking_asp_active: striking_asp_active?
          }
        else
          {
            seconds: 0,
            stamina_cost: 0,
            qstrike_cmd: nil,
            reason: :too_expensive,
            current_stamina: current_stamina,
            available_stamina: available,
            attack_cost: attack_cost,
            attack_rt: attack_rt,
            reserve: reserve,
            cost_per_second: cost_per_second
          }
        end
      end

      # Generates the QStrike command based on the current settings.
      #
      # @param reserve [Integer, nil] the stamina reserve to consider.
      # @param attack_cost [Integer] the cost of the attack.
      # @param attack_name [String, nil] the name of the attack to look up.
      # @param attack_rt [Integer, nil] the current RT of the attack.
      # @return [String, nil] the generated QStrike command.
      def self.command(reserve: nil, attack_cost: 0, attack_name: nil, attack_rt: nil)
        calculate(reserve: reserve, attack_cost: attack_cost, attack_name: attack_name, attack_rt: attack_rt)[:qstrike_cmd]
      end

      # Checks if the QStrike reduction can be afforded with current stamina.
      #
      # @param reserve [Integer, nil] the stamina reserve to consider.
      # @param attack_cost [Integer] the cost of the attack.
      # @param attack_name [String, nil] the name of the attack to look up.
      # @param attack_rt [Integer, nil] the current RT of the attack.
      # @return [Boolean] true if the reduction can be afforded, false otherwise.
      def self.affordable?(reserve: nil, attack_cost: 0, attack_name: nil, attack_rt: nil)
        result = calculate(reserve: reserve, attack_cost: attack_cost, attack_name: attack_name, attack_rt: attack_rt)
        result[:seconds].positive?
      end


      # Executes a QStrike reduction and attack.
      #
      # @param reduction [Integer] the amount of reduction to apply.
      # @param attack [String] the name of the attack to execute.
      # @param target [String, nil] the target of the attack.
      # @param reserve [Integer, nil] the stamina reserve to consider.
      # @param adaptive [Boolean, nil] whether to adaptively reduce the attack.
      # @return [Hash] a hash containing the result of the operation.
      def self.use(reduction:, attack:, target: nil, reserve: nil, adaptive: nil)
        reserve ||= default(:reserve)
        adaptive = default(:adaptive) if adaptive.nil?

        attack_name = normalize_attack_name(attack)
        attack_cost = lookup_attack_cost(attack_name)

        # Determine the actual reduction to attempt
        actual_reduction = resolve_reduction(reduction, reserve, attack_cost)

        if actual_reduction.nil? || actual_reduction.zero?
          max_affordable = calculate(reserve: reserve, attack_cost: attack_cost)[:seconds]
          respond "[QStrike] Cannot afford any reduction. Stamina: #{Char.stamina}, Reserve: #{reserve}, Attack cost: #{attack_cost}"
          return {
            success: false,
            reason: :cannot_afford,
            requested_reduction: reduction,
            max_affordable: max_affordable
          }
        end

        # Check if we can afford the requested reduction
        qstrike_cost = cost_for_reduction(actual_reduction)
        available = Char.stamina - reserve - attack_cost

        if qstrike_cost > available
          if adaptive
            # Calculate what we can actually afford
            max_affordable = calculate(reserve: reserve, attack_cost: attack_cost)[:seconds]
            if max_affordable.positive?
              actual_reduction = max_affordable
              qstrike_cost = cost_for_reduction(actual_reduction)
            else
              respond "[QStrike] Insufficient stamina. Need: #{qstrike_cost}, Available: #{available} (after #{reserve} reserve + #{attack_cost} attack)"
              return {
                success: false,
                reason: :insufficient_stamina,
                requested_reduction: reduction,
                available_stamina: available,
                qstrike_cost: qstrike_cost
              }
            end
          else
            max_affordable = calculate(reserve: reserve, attack_cost: attack_cost)[:seconds]
            respond "[QStrike] Insufficient stamina for #{actual_reduction}s reduction. Need: #{qstrike_cost}, Available: #{available}. Max affordable: #{max_affordable}s"
            return {
              success: false,
              reason: :insufficient_stamina,
              requested_reduction: reduction,
              available_stamina: available,
              qstrike_cost: qstrike_cost,
              max_affordable: max_affordable
            }
          end
        end

        # Execute the qstrike and attack
        execute_qstrike(actual_reduction)
        execute_attack(attack, target)

        {
          success: true,
          reduction_used: actual_reduction,
          qstrike_cost: qstrike_cost,
          attack_cost: attack_cost,
          total_cost: qstrike_cost + attack_cost,
          stamina_after: Char.stamina - qstrike_cost - attack_cost
        }
      end

      # Calculates the cost for a given reduction in seconds.
      #
      # @param seconds [Integer] the number of seconds to reduce.
      # @return [Integer] the cost associated with the reduction.
      def self.cost_for_reduction(seconds)
        return 0 if seconds.nil? || seconds <= 0

        cost_per_second_reduction * seconds
      end

      # Retrieves the base RT for the currently equipped weapon.
      #
      # @return [Integer] the base RT of the weapon.
      def self.base_rt
        hand = ranged_weapon? ? GameObj.left_hand : GameObj.right_hand
        weapon_speed_for(hand)[:base_rt]
      end

      # Calculates the reduction needed to reach a target RT.
      #
      # @param target_rt [Integer] the target RT to achieve.
      # @return [Integer] the calculated reduction.
      def self.reduction_for_target_rt(target_rt)
        current_base = base_rt
        return 0 if target_rt >= current_base

        [current_base - target_rt, MAX_REDUCTION].min
      end


      # Finds the weapon stats for a given hand.
      #
      # @param hand [Object] the weapon object to analyze.
      # @return [Hash, nil] the weapon stats or nil if not found.
      def self.find_weapon_stats(hand)
        return nil if hand.nil?

        # Strategy 1: Try the noun directly (works for "dagger", "broadsword", etc.)
        stats = Armaments::WeaponStats.find(hand.noun)
        return stats if stats

        # Strategy 2: Try the full name (works for "slim short sword" -> finds "short sword")
        stats = Armaments::WeaponStats.find(hand.name)
        return stats if stats

        # Strategy 3: Extract weapon type from name by removing common adjectives
        # e.g., "slim short sword" -> try "short sword"
        name = hand.name.to_s.downcase
        adjectives = %w[slim gleaming steel iron silver gold mithril vultite golvern
                        ora krodera drakar rhimar gornar zorchar eonake faenor invar
                        kelyn laje razern rolaren vaalorn veil imflass alexandrite
                        black white red blue green small large heavy light ornate
                        polished rusted ancient old new fine]

        words = name.split
        # Remove leading adjectives
        while words.length > 1 && adjectives.include?(words.first)
          words.shift
        end

        # Try progressively shorter suffixes: "short sword", then "sword"
        while words.length > 0
          attempt = words.join(' ')
          stats = Armaments::WeaponStats.find(attempt)
          return stats if stats
          words.shift
        end

        nil
      end

      # Checks if the currently equipped weapon is a ranged weapon.
      #
      # @return [Boolean] true if the weapon is ranged, false otherwise.
      def self.ranged_weapon?
        left = GameObj.left_hand
        return false if left.nil? || left.name == "Empty"

        stats = find_weapon_stats(left)
        stats&.dig(:category) == :ranged
      end

      # Calculates the speed for a given weapon based on its stats.
      #
      # @param hand [Object] the weapon object to analyze.
      # @return [Hash] a hash containing the weapon's speed stats.
      def self.weapon_speed_for(hand)
        empty_result = { base_rt: 0, category: nil, equipment_speed: 0 }
        return empty_result if hand.nil? || hand.name == "Empty"

        stats = find_weapon_stats(hand)
        return empty_result unless stats

        base_rt = stats[:base_rt]
        base_rt = base_rt.first if base_rt.is_a?(Array)
        base_rt = base_rt.to_i

        category = stats[:category]
        multiplier = SPEED_MULTIPLIERS[category] || DEFAULT_MULTIPLIER

        # Equipment Speed = Weapon Base RT * Speed Modifier
        equipment_speed = (base_rt * multiplier).to_i

        { base_rt: base_rt, category: category, equipment_speed: equipment_speed }
      end

      # Retrieves the equipment speed for the primary weapon.
      #
      # @return [Integer] the equipment speed of the primary weapon.
      def self.primary_equipment_speed
        hand = ranged_weapon? ? GameObj.left_hand : GameObj.right_hand
        weapon_speed_for(hand)[:equipment_speed]
      end

      # Retrieves the equipment speed for the secondary weapon.
      #
      # @return [Integer] the equipment speed of the secondary weapon.
      def self.secondary_equipment_speed
        hand = ranged_weapon? ? GameObj.right_hand : GameObj.left_hand
        weapon_speed_for(hand)[:equipment_speed]
      end

      # Calculates the cost per second for QStrike reduction.
      #
      # @return [Integer] the cost per second for reduction.
      def self.cost_per_second_reduction
        # Check memoization cache
        return @cached_cost if valid_cache?

        primary = primary_equipment_speed
        secondary = secondary_equipment_speed

        # Base formula: 10 + primary + (secondary / 2)
        base_cost = BASE_COST + primary + (secondary / 2)

        # Apply Striking Asp discount if active
        final_cost = (base_cost * striking_asp_multiplier).to_i

        # Cache the result
        cache_cost(final_cost)

        final_cost
      end

      def self.debug_calculation
        respond "=== QStrike Debug Calculation ==="

        # Right hand
        right = GameObj.right_hand
        respond "Right hand: #{right&.name || 'Empty'} (noun: #{right&.noun || 'nil'}, id: #{right&.id || 'nil'})"
        if right && right.name != "Empty"
          stats = find_weapon_stats(right)
          if stats
            respond "  Weapon found: #{stats[:base_name]} (category: #{stats[:category]})"
            respond "  base_rt: #{stats[:base_rt]}"
            multiplier = SPEED_MULTIPLIERS[stats[:category]] || DEFAULT_MULTIPLIER
            respond "  multiplier: #{multiplier}"
            equip_speed = (stats[:base_rt].to_i * multiplier).to_i
            respond "  equipment_speed: #{equip_speed}"
          else
            respond "  WARNING: No weapon stats found!"
          end
        end

        # Left hand
        left = GameObj.left_hand
        respond "Left hand: #{left&.name || 'Empty'} (noun: #{left&.noun || 'nil'}, id: #{left&.id || 'nil'})"
        if left && left.name != "Empty"
          stats = find_weapon_stats(left)
          if stats
            respond "  Weapon found: #{stats[:base_name]} (category: #{stats[:category]})"
            respond "  base_rt: #{stats[:base_rt]}"
            multiplier = SPEED_MULTIPLIERS[stats[:category]] || DEFAULT_MULTIPLIER
            respond "  multiplier: #{multiplier}"
            equip_speed = (stats[:base_rt].to_i * multiplier).to_i
            respond "  equipment_speed: #{equip_speed}"
          else
            respond "  WARNING: No weapon stats found!"
          end
        end

        # Primary/Secondary determination
        is_ranged = ranged_weapon?
        respond "Ranged mode: #{is_ranged}"
        respond "Primary hand: #{is_ranged ? 'LEFT' : 'RIGHT'}"
        respond "Secondary hand: #{is_ranged ? 'RIGHT' : 'LEFT'}"

        # Calculated values
        primary = primary_equipment_speed
        secondary = secondary_equipment_speed
        respond "Primary equipment_speed: #{primary}"
        respond "Secondary equipment_speed: #{secondary}"
        respond "Secondary / 2 (integer division): #{secondary / 2}"

        # Formula
        base_cost = BASE_COST + primary + (secondary / 2)
        respond "Formula: BASE_COST(#{BASE_COST}) + primary(#{primary}) + secondary/2(#{secondary / 2}) = #{base_cost}"

        # Striking Asp
        asp_mult = striking_asp_multiplier
        if (asp_mult - 1.0).abs > Float::EPSILON
          respond "Striking Asp multiplier: #{asp_mult}"
          final_cost = (base_cost * asp_mult).to_i
          respond "Final cost (with Asp): #{base_cost} * #{asp_mult} = #{final_cost}"
        else
          respond "Striking Asp: not active"
          respond "Final cost per second: #{base_cost}"
        end

        respond "=== End Debug ==="
      end


      # Checks if the Striking Asp buff is currently active.
      #
      # @return [Boolean] true if active, false otherwise.
      def self.striking_asp_active?
        return false unless defined?(Effects::Buffs)

        Effects::Buffs.active?('Striking Asp')
      rescue StandardError
        false
      end

      def self.striking_asp_rank
        return 0 unless defined?(CMan)

        CMan['striking_asp'].to_i
      rescue StandardError
        0
      end

      # Retrieves the multiplier for the Striking Asp buff based on its rank.
      #
      # @return [Float] the multiplier for the Striking Asp buff.
      def self.striking_asp_multiplier
        return 1.0 unless striking_asp_active?

        rank = striking_asp_rank
        STRIKING_ASP_MULTIPLIERS[rank] || 1.0
      end


      def self.hand_cache_key(hand)
        return "empty" if hand.nil?
        return "empty" if hand.name.nil? || hand.name.empty? || hand.name == "Empty"
        return "empty" if hand.id.nil?

        "#{hand.id}:#{hand.noun}"
      end

      def self.valid_cache?
        return false unless @cached_cost

        current_right = hand_cache_key(GameObj.right_hand)
        current_left = hand_cache_key(GameObj.left_hand)

        @cached_right_hand == current_right && @cached_left_hand == current_left
      rescue StandardError
        false
      end

      def self.cache_cost(cost)
        @cached_cost = cost
        @cached_right_hand = hand_cache_key(GameObj.right_hand)
        @cached_left_hand = hand_cache_key(GameObj.left_hand)
      rescue StandardError
        # Ignore caching errors
      end

      def self.clear_cache
        @cached_cost = nil
        @cached_right_hand = nil
        @cached_left_hand = nil
      end

      # === ATTACK COST LOOKUP ===

      # Module lookup configuration: [Module, class_var, type_symbol]
      TECHNIQUE_MODULES = [
        [:CMan, :@@combat_mans, :cman],
        [:Weapon, :@@weapon_techniques, :weapon],
        [:Shield, :@@shield_techniques, :shield],
      ].freeze

      # Looks up the cost of an attack by its name.
      #
      # @param name [String] the name of the attack to look up.
      # @return [Integer] the stamina cost of the attack.
      def self.lookup_attack_cost(name)
        name = name.to_s.downcase.gsub(/[\s-]+/, '_')

        # Handle explicit type prefixes for disambiguation
        TECHNIQUE_MODULES.each do |_, _, type|
          prefix = "#{type}_"
          return lookup_technique_cost(name.sub(prefix, ''), type) if name.start_with?(prefix)
        end

        # Try each module in order until we find a cost
        TECHNIQUE_MODULES.each do |_, _, type|
          cost = lookup_technique_cost(name, type)
          return cost if cost.positive?
        end

        0
      end

      # Looks up the technique cost for a given name and type.
      #
      # @param name [String] the name of the technique to look up.
      # @param type [Symbol] the type of technique (e.g., :cman, :weapon).
      # @return [Integer] the stamina cost of the technique.
      def self.lookup_technique_cost(name, type)
        mod_name, class_var, = TECHNIQUE_MODULES.find { |_, _, t| t == type }
        return 0 unless mod_name && defined_module?(mod_name)

        mod = Object.const_get(mod_name)
        data = mod.class_variable_get(class_var)
        entry = data[name] || data.values.find { |v| v[:short_name] == name }
        entry&.dig(:cost, :stamina).to_i
      rescue StandardError
        0
      end

      def self.defined_module?(mod_name)
        Object.const_defined?(mod_name)
      rescue StandardError
        false
      end

      # Determines the maximum number of seconds that can be afforded based on stamina.
      #
      # @param available_stamina [Integer] the available stamina to use.
      # @param cost_per_second [Integer] the cost per second of reduction.
      # @return [Integer] the maximum seconds that can be afforded.
      def self.find_max_seconds(available_stamina, cost_per_second)
        return 0 if cost_per_second <= 0

        # Simple division - how many full seconds can we afford?
        max = available_stamina / cost_per_second

        # Cap at reasonable maximum
        [max, MAX_REDUCTION].min
      end


      # Resolves the reduction value based on the input parameters.
      #
      # @param reduction [Integer, Symbol] the requested reduction value.
      # @param reserve [Integer] the stamina reserve to consider.
      # @param attack_cost [Integer] the cost of the attack.
      # @return [Integer, nil] the resolved reduction value.
      def self.resolve_reduction(reduction, reserve, attack_cost)
        case reduction
        when :max, :optimal
          calculate(reserve: reserve, attack_cost: attack_cost)[:seconds]
        when Integer
          if reduction.negative?
            # Negative = reduce by that many seconds
            reduction.abs
          elsif reduction.positive?
            # Positive = target absolute RT
            reduction_for_target_rt(reduction)
          else
            0
          end
        else
          nil
        end
      end

      # Normalizes the attack name for consistent lookup.
      #
      # @param attack [String] the attack name to normalize.
      # @return [String] the normalized attack name.
      def self.normalize_attack_name(attack)
        attack.to_s.downcase.gsub(/[\s-]+/, '_').gsub(/[^a-z0-9_]/, '')
      end

      # Executes the QStrike command with the specified reduction.
      #
      # @param reduction [Integer] the amount of reduction to apply.
      # @return [void]
      def self.execute_qstrike(reduction)
        return if reduction.nil? || reduction <= 0

        fput "qstrike -#{reduction}"
      end

      # Executes the specified attack against a target.
      #
      # @param attack [String] the name of the attack to execute.
      # @param target [String, nil] the target of the attack.
      # @return [void]
      def self.execute_attack(attack, target = nil)
        attack_str = attack.to_s
        normalized = normalize_attack_name(attack)

        # Detect and execute based on attack type
        attack_type = detect_attack_type(normalized)

        case attack_type
        when :cman
          if defined?(CMan) && CMan.respond_to?(:use)
            CMan.use(normalized, target)
          else
            fput build_attack_command(attack_str, target)
          end
        when :weapon
          if defined?(Weapon) && Weapon.respond_to?(:use)
            Weapon.use(normalized, target)
          else
            fput build_attack_command(attack_str, target)
          end
        when :shield
          if defined?(Shield) && Shield.respond_to?(:use)
            Shield.use(normalized, target)
          else
            fput build_attack_command(attack_str, target)
          end
        else
          # Basic command - just send it
          fput build_attack_command(attack_str, target)
        end
      end

      def self.detect_attack_type(name)
        TECHNIQUE_MODULES.each do |mod_name, class_var, type|
          next unless defined_module?(mod_name)

          begin
            mod = Object.const_get(mod_name)
            data = mod.class_variable_get(class_var)
            return type if data.key?(name) || data.values.any? { |v| v[:short_name] == name }
          rescue StandardError
            next
          end
        end

        :basic
      end

      def self.build_attack_command(attack, target = nil)
        if target && !target.empty?
          "#{attack} #{target}"
        else
          attack
        end
      end
    end
  end
end

# Top-level convenience alias
QStrike = Lich::Gemstone::QStrike unless defined?(QStrike)
