# frozen_string_literal: true

# A module that provides functionality for transforming user settings.
#
# This module is responsible for enriching, defaulting,
# and migrating user settings based on a game-specific configuration hash.
#
# @see Lich::DragonRealms::SettingsConfig
=begin
  SettingsTransformer is a data-driven engine that enriches, defaults,
  and migrates user settings based on a game-specific configuration hash.

  All game-specific knowledge (key names, data files, UserVars fallback
  keys) comes from the config hash. The engine is generic.

  @example
    config = Lich::DragonRealms::SettingsConfig::TRANSFORM_CONFIG
    result = SettingsTransformer.transform(settings_hash, config, data_provider)
=end

require 'ostruct'

module Lich
  module Common
    module SettingsTransformer
      # Transforms the original settings based on the provided configuration and data provider.
      #
      # @param original_settings [Hash] the original settings to transform
      # @param config [Hash] the configuration hash containing transformation rules
      # @param data_provider [Proc] a callable that provides additional data needed for transformation
      # @return [OpenStruct] the transformed settings
      # @example Transform settings
      #   config = Lich::DragonRealms::SettingsConfig::TRANSFORM_CONFIG
      #   result = SettingsTransformer.transform(settings_hash, config, data_provider)
      def self.transform(original_settings, config, data_provider)
        settings = OpenStruct.new(original_settings)

        apply_defaults(settings, config, data_provider)
        enrich_spells(settings, config, data_provider)
        compose_lists(settings, config, data_provider)
        apply_uservars_fallback(settings, config)
        apply_hometown_lookups(settings, config)
        enforce_denylists(settings, config)
        apply_legacy_migrations(settings, config)

        settings
      rescue => e
        echo "*** ERROR TRANSFORMING SETTINGS ***"
        echo "*** Commonly this is due to malformed config in your yaml file ***"
        echo e.message
        e.backtrace.each { |msg| echo msg }
        OpenStruct.new
      end


      # Applies default values to the settings based on the configuration.
      #
      # @param settings [OpenStruct] the settings to apply defaults to
      # @param config [Hash] the configuration hash containing default values
      # @param data_provider [Proc] a callable that provides additional data needed for defaults
      # @return [void]
      def self.apply_defaults(settings, config, data_provider)
        return unless config[:empty_data_type]

        empty_data = data_provider.call(config[:empty_data_type])
        empty_values = empty_data&.empty_values
        return unless empty_values

        empty_values.each { |name, value| settings[name] = value if settings[name].nil? }
      end


      # Enriches spell settings with additional data from the configuration.
      #
      # @param settings [OpenStruct] the settings containing spell data
      # @param config [Hash] the configuration hash containing spell enrichment rules
      # @param data_provider [Proc] a callable that provides spell data
      # @return [void]
      def self.enrich_spells(settings, config, data_provider)
        return unless config[:spell_data_type]

        spell_source = data_provider.call(config[:spell_data_type])
        spells_data = spell_source&.spell_data
        return unless spells_data

        by_name = build_spell_lookup_by_name(spells_data)
        by_abbrev = build_spell_lookup_by_abbrev(spells_data)
        enrich_block = build_enrich_block(by_name, by_abbrev)

        # Waggle sets: map of set_name => map of spell_name => spell_props
        (config[:waggle_set_keys] || []).each do |key|
          next unless settings[key].is_a?(Hash)

          settings[key].transform_values! do |spells_map|
            if spells_map.is_a?(Hash)
              inject_spell_names(spells_map)
              spells_map.transform_values!(&enrich_block)
            else
              spells_map
            end
          end
        end

        # Spell maps: enrich name + data (keys are spell names)
        (config[:spell_map_enrich_name_keys] || []).each do |key|
          next unless settings[key].is_a?(Hash)

          inject_spell_names(settings[key])
          settings[key].transform_values!(&enrich_block)
        end

        # Spell maps by skill: enrich data only (keys are skill names)
        (config[:spell_map_enrich_data_keys] || []).each do |key|
          next unless settings[key].is_a?(Hash)

          settings[key].transform_values!(&enrich_block)
        end

        # Spell lists: array of spell_props
        (config[:spell_list_keys] || []).each do |key|
          next unless settings[key].is_a?(Array)

          settings[key].map!(&enrich_block)
        end

        # Single spell settings
        (config[:single_spell_keys] || []).each do |key|
          settings[key] = enrich_block.call(settings[key])
        end

        # TM prep defaults
        apply_tm_prep_defaults(settings, config, spells_data)

        # Battle cries
        battle_cries_data = spell_source&.battle_cries
        apply_battle_cries(settings, config, battle_cries_data)
      end


      # Composes lists of settings based on the configuration.
      #
      # @param settings [OpenStruct] the settings to compose lists for
      # @param config [Hash] the configuration hash containing list composition rules
      # @param data_provider [Proc] a callable that provides additional data needed for composition
      # @return [void]
      def self.compose_lists(settings, config, data_provider)
        (config[:composed_lists] || []).each do |list_config|
          base_sources = (list_config[:base_data_keys] || []).flat_map do |source|
            data = data_provider.call(source[:type])
            data&.send(source[:key]) || []
          end
          additions = settings[list_config[:additions_key]] || []
          subtractions = settings[list_config[:subtractions_key]] || []
          settings[list_config[:target_key]] = (base_sources + additions - subtractions).uniq
        end
      end


      # Applies user variable fallbacks to the settings based on the configuration.
      #
      # @param settings [OpenStruct] the settings to apply user variable fallbacks to
      # @param config [Hash] the configuration hash containing user variable mappings
      # @return [void]
      def self.apply_uservars_fallback(settings, config)
        (config[:uservars_fallback] || []).each do |mapping|
          key = mapping[:setting_key]
          uvar = mapping[:uservars_key]
          if mapping[:mode] == :append
            settings[key] = (settings[key] || []) + (UserVars.send(uvar) || [])
          else
            settings[key] = UserVars.send(uvar) if settings[key].nil?
          end
        end

        # Explicit allowlist of global variables -- avoids eval.
        allowed_globals = {
          '$HOMETOWN' => -> { $HOMETOWN rescue nil },
        }.freeze

        (config[:global_overrides] || []).each do |override|
          resolver = allowed_globals[override[:global_var]]
          next unless resolver

          global_val = resolver.call
          settings[override[:setting_key]] = global_val if global_val
        end
      end


      # Applies hometown lookups to the settings based on the configuration.
      #
      # @param settings [OpenStruct] the settings to apply hometown lookups to
      # @param config [Hash] the configuration hash containing hometown lookup keys
      # @return [void]
      def self.apply_hometown_lookups(settings, config)
        (config[:hometown_lookup_keys] || []).each do |key|
          next unless settings[key].is_a?(Hash)

          hometown_value = settings[key][settings.hometown]
          settings[key] = hometown_value if hometown_value
        end
      end


      # Enforces deny lists on the settings based on the configuration.
      #
      # @param settings [OpenStruct] the settings to enforce deny lists on
      # @param config [Hash] the configuration hash containing deny list rules
      # @return [void]
      def self.enforce_denylists(settings, config)
        (config[:denylists] || []).each do |denylist|
          blocked = denylist[:blocked_values]
          keys = denylist[:setting_keys]
          offending_key = keys.find { |key| blocked.include?(settings[key]) }
          next unless offending_key

          _respond("<pushBold/>#{settings[offending_key]} is not a valid #{offending_key} setting.<popBold/>")
          _respond("<pushBold/>Please edit your yaml to use a different value.<popBold/>")
          raise ArgumentError, "denylisted value '#{settings[offending_key]}' for setting '#{offending_key}'"
        end
      end


      # Applies legacy migrations to the settings based on the configuration.
      #
      # @param settings [OpenStruct] the settings to apply migrations to
      # @param config [Hash] the configuration hash containing migration rules
      # @return [void]
      def self.apply_legacy_migrations(settings, config)
        (config[:legacy_migrations] || []).each do |migration|
          target = settings[migration[:target_key]]
          next unless target.is_a?(Array)
          next if target.include?(migration[:value])

          case migration[:type]
          when :append_if_flag
            target.append(migration[:value]) if settings[migration[:flag_key]]
          when :append_if_nested
            source = settings[migration[:source_key]]
            target.append(migration[:value]) if source.is_a?(Hash) && source[migration[:nested_key]]
          end
        end
      end


      # Builds a lookup function for spells by name.
      #
      # @param spells_data [Array<Hash>] the spell data to build the lookup from
      # @return [Proc] a function that retrieves spell data by name
      def self.build_spell_lookup_by_name(spells_data)
        lambda do |name_to_find|
          return nil unless name_to_find

          spell_match = spells_data.find { |name, _| name.casecmp?(name_to_find) }
          return nil unless spell_match

          spell_data = spell_match.last
          spell_data['name'] ||= spell_match.first
          spell_data
        end
      end

      # Builds a lookup function for spells by abbreviation.
      #
      # @param spells_data [Array<Hash>] the spell data to build the lookup from
      # @return [Proc] a function that retrieves spell data by abbreviation
      def self.build_spell_lookup_by_abbrev(spells_data)
        lambda do |abbrev_to_find|
          return nil unless abbrev_to_find

          spell_match = spells_data.find { |_, data| data['abbrev']&.casecmp?(abbrev_to_find) }
          return nil unless spell_match

          spell_data = spell_match.last
          spell_data['name'] ||= spell_match.first
          spell_data
        end
      end

      # Builds a block for enriching spell settings with additional data.
      #
      # @param by_name [Proc] a function to lookup spells by name
      # @param by_abbrev [Proc] a function to lookup spells by abbreviation
      # @return [Proc] a block that enriches spell settings
      def self.build_enrich_block(by_name, by_abbrev)
        lambda do |spell_setting|
          return spell_setting unless spell_setting.is_a?(Hash)

          spell_data = by_name.call(spell_setting['name']) ||
                       by_abbrev.call(spell_setting['abbrev'])
          (spell_data || {}).merge(spell_setting)
        end
      end

      # Injects spell names into the spell settings if not already present.
      #
      # @param spells_map [Hash] the map of spell settings to inject names into
      # @return [void]
      def self.inject_spell_names(spells_map)
        spells_map.each do |spell_name, spell_setting|
          spell_setting['name'] ||= spell_name if spell_setting.is_a?(Hash)
        end
      end

      # Applies defaults for targeted magic preparation to the settings.
      #
      # @param settings [OpenStruct] the settings to apply defaults to
      # @param config [Hash] the configuration hash containing targeted magic keys
      # @param spells_data [Array<Hash>] the spell data to use for defaults
      # @return [void]
      def self.apply_tm_prep_defaults(settings, config, spells_data)
        key = config[:offensive_spells_key]
        return unless key && settings[key].is_a?(Array)

        settings[key].each do |spell_setting|
          next unless spell_setting.is_a?(Hash)

          spell_data = spells_data[spell_setting['name']] || {}
          is_native_tm = spell_setting['skill'] == 'Targeted Magic'
          is_sorcery_tm = spell_setting['skill'] == 'Sorcery' && spell_data['skill'] == 'Targeted Magic'
          spell_setting['prep'] ||= 'target' if is_native_tm || is_sorcery_tm
        end
      end

      # Applies battle cries to the settings based on the configuration.
      #
      # @param settings [OpenStruct] the settings to apply battle cries to
      # @param config [Hash] the configuration hash containing battle cry keys
      # @param battle_cries_data [Array<Hash>] the battle cries data to apply
      # @return [void]
      def self.apply_battle_cries(settings, config, battle_cries_data)
        key = config[:battle_cries_key]
        return unless key && settings[key].is_a?(Array) && battle_cries_data

        settings[key].map! do |bc_setting|
          next bc_setting unless bc_setting.is_a?(Hash)

          bc_data = battle_cries_data[bc_setting['name']]
          (bc_data || {}).merge(bc_setting)
        end
      end

      private_class_method :apply_defaults, :enrich_spells, :compose_lists,
                           :apply_uservars_fallback, :apply_hometown_lookups,
                           :enforce_denylists, :apply_legacy_migrations,
                           :build_spell_lookup_by_name, :build_spell_lookup_by_abbrev,
                           :build_enrich_block, :inject_spell_names,
                           :apply_tm_prep_defaults, :apply_battle_cries
    end
  end
end
