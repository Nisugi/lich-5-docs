require 'singleton'
require 'ostruct'

module Lich
  module Gemstone
    # Represents a template for creatures in the game.
    #
    # This class is responsible for loading and managing creature templates.
    #
    # @see CreatureInstance for instances of creatures based on these templates.
    class CreatureTemplate
      @@templates = {}
      @@loaded = false
      @@max_templates = 500 # Prevent unbounded template cache growth

      attr_reader :name, :url, :picture, :level, :family, :type,
                  :undead, :otherclass, :areas, :bcs, :max_hp,
                  :speed, :height, :size, :attack_attributes,
                  :defense_attributes, :treasure, :messaging,
                  :special_other, :abilities, :alchemy

      BOON_ADJECTIVES = %w[
        adroit afflicted apt barbed belligerent blurry canny combative dazzling deft diseased drab
        dreary ethereal flashy flexile flickering flinty frenzied ghastly ghostly gleaming glittering
        glorious glowing grotesque hardy illustrious indistinct keen lanky luminous lustrous muculent
        nebulous oozing pestilent radiant raging ready resolute robust rune-covered shadowy shifting
        shimmering shining sickly green sinuous slimy sparkling spindly spiny stalwart steadfast stout
        tattoed tenebrous tough twinkling unflinching unyielding wavering wispy
      ]

      def initialize(data)
        @name = data[:name]
        @url = data[:url]
        @picture = data[:picture]
        @level = data[:level].to_i
        @family = data[:family]
        @type = data[:type]
        @undead = data[:undead]
        @otherclass = data[:otherclass] || []
        @areas = data[:areas] || []
        @bcs = data[:bcs]
        @max_hp = data[:max_hp]&.to_i || data[:hitpoints]&.to_i
        @speed = data[:speed]
        @height = data[:height].to_i
        @size = data[:size]

        atk = data[:attack_attributes] || {}
        @attack_attributes = OpenStruct.new(
          physical_attacks: atk[:physical_attacks] || [],
          bolt_spells: atk[:bolt_spells] || [],
          warding_spells: normalize_spells(atk[:warding_spells]),
          offensive_spells: normalize_spells(atk[:offensive_spells]),
          maneuvers: atk[:maneuvers] || [],
          special_abilities: (atk[:special_abilities] || []).map { |s| SpecialAbility.new(s) }
        )

        @defense_attributes = DefenseAttributes.new(data[:defense_attributes] || {})
        @treasure = Treasure.new(data[:treasure] || {})
        @messaging = Messaging.new(data[:messaging] || {})
        @special_other = data[:special_other]
        @abilities = data[:abilities] || []
        @alchemy = data[:alchemy] || []
      end

      # Loads all creature templates from the specified directory.
      # @return [void]
      # @note This method will only load templates if they have not been loaded already.
      def self.load_all
        return if @@loaded

        templates_dir = File.join(File.dirname(__FILE__), 'creatures')
        return unless File.directory?(templates_dir)

        template_count = 0
        Dir[File.join(templates_dir, '*.rb')].each do |path|
          next if File.basename(path) == '_creature_template.rb'

          # Check template limit
          if template_count >= @@max_templates
            respond "--- warning: Template cache limit (#{@@max_templates}) reached, skipping remaining templates" if $creature_debug
            break
          end

          template_name = File.basename(path, '.rb').tr('_', ' ')
          normalized_name = fix_template_name(template_name)

          begin
            # Safer loading with validation
            file_content = File.read(path)
            data = load_template_data(file_content, path)
            next unless data.is_a?(Hash)

            data[:name] = template_name
            template = new(data)
            @@templates[normalized_name] = template
            template_count += 1
          rescue => e
            respond "--- error loading template #{template_name}: #{e.message}" if $creature_debug
          end
        end

        @@loaded = true
        respond "--- loaded #{template_count} creature templates" if $creature_debug
      end

      # Clean creature name by removing boon adjectives
      # Optimized to use single compiled regex instead of 50+ sequential matches
      BOON_REGEX = /^(#{BOON_ADJECTIVES.join('|')})\s+/i.freeze

      # Cleans up the template name by removing boon adjectives.
      # @param template_name [String] the name of the template to clean
      # @return [String] the cleaned template name
      def self.fix_template_name(template_name)
        name = template_name.dup.downcase
        name.sub!(BOON_REGEX, '')
        name.strip
      end

      # Loads template data from the given file content.
      # @param file_content [String] the content of the template file
      # @param path [String] the path of the template file
      # @return [Hash] the parsed template data
      # @raise [RuntimeError] if the data is not a Hash
      def self.load_template_data(file_content, path)
        # Use binding.eval for slightly better isolation
        data = binding.eval(file_content, path, 1)

        # Validate it's a hash
        unless data.is_a?(Hash)
          raise "Template must return a Hash, got #{data.class}"
        end

        data
      end
      private_class_method :load_template_data

      # Retrieves a creature template by name.
      # @param name [String] the name of the template to retrieve
      # @return [CreatureTemplate, nil] the corresponding creature template or nil if not found
      def self.[](name)
        load_all unless @@loaded
        return nil unless name

        # Try exact match first
        template = @@templates[name.downcase]
        return template if template

        # Try with boon adjectives removed
        normalized_name = fix_template_name(name)
        @@templates[normalized_name]
      end

      # Returns all loaded creature templates.
      # @return [Array<CreatureTemplate>] an array of all creature templates
      def self.all
        load_all unless @@loaded
        @@templates.values.uniq
      end

      private

      def normalize_spells(spells)
        (spells || []).map do |s|
          {
            name: s[:name].to_s.strip,
            cs: parse_td(s[:cs])
          }
        end
      end

      def parse_td(val)
        return nil if val.nil?
        return val if val.is_a?(Range)

        # Parse range strings without eval (safer)
        if val.is_a?(String) && val.match?(/\A(\d+)\.\.(\d+)\z/)
          start_val, end_val = val.split('..').map(&:to_i)
          return start_val..end_val
        end

        val
      end
    end

    # Represents an instance of a creature in the game.
    #
    # This class manages the state and behavior of individual creatures.
    class CreatureInstance
      @@instances = {}
      @@max_size = 1000
      @@auto_register = true

      attr_accessor :id, :noun, :name, :status, :injuries, :health, :damage_taken, :created_at, :fatal_crit, :status_timestamps,
                    :ucs_smote, :ucs_updated
      attr_writer :ucs_position, :ucs_tierup

      BODY_PARTS = %w[abdomen back chest head leftArm leftEye leftFoot leftHand leftLeg neck nerves rightArm rightEye rightFoot rightHand rightLeg]

      UCS_TTL = 120        # UCS data expires after 2 minutes
      UCS_SMITE_TTL = 15   # Smite effect expires after 15 seconds

      # Status effect durations (in seconds) for auto-cleanup
      # nil = no auto-cleanup (waits for removal message)
      STATUS_DURATIONS = {
        'breeze'      => 6, # 6 seconds roundtime
        'bind'        => 10, # 10 seconds typical
        'web'         => 8, # 8 seconds typical
        'entangle'    => 10, # 10 seconds typical
        'hypnotism'   => 12, # 12 seconds typical
        'calm'        => 15, # 15 seconds typical
        'mass_calm'   => 15, # 15 seconds typical
        'sleep'       => 8, # 8 seconds typical (can wake early)
        # Statuses with reliable removal messages - no duration needed
        'stunned'     => nil, # Has removal messages
        'immobilized' => nil, # Has removal messages
        'prone'       => nil,         # Has removal messages
        'blind'       => nil,         # Has removal messages
        'sunburst'    => nil, # Has removal messages
        'webbed'      => nil, # Has removal messages
        'poisoned'    => nil # Has removal messages
      }.freeze

      def initialize(id, noun, name)
        @id = id.to_i
        @noun = noun
        @name = name
        @status = []
        @injuries = Hash.new(0)
        @health = nil
        @damage_taken = 0
        @created_at = Time.now
        @fatal_crit = false
        @status_timestamps = {}
        @ucs_position = nil
        @ucs_tierup = nil
        @ucs_smote = nil
        @ucs_updated = nil
      end

      # Retrieves the template associated with this creature instance.
      # @return [CreatureTemplate, nil] the creature template or nil if not found
      def template
        @template ||= CreatureTemplate[@name]
      end

      def has_template?
        !template.nil?
      end

      # Adds a status effect to the creature instance.
      # @param status [String] the status to add
      # @param duration [Integer, nil] optional duration for the status effect
      # @return [void]
      def add_status(status, duration = nil)
        return if @status.include?(status)

        @status << status

        # Set expiration timestamp for timed statuses
        status_key = status.to_s.downcase
        duration ||= STATUS_DURATIONS[status_key]
        if duration
          @status_timestamps[status] = Time.now + duration
          respond "  +status: #{status} (expires in #{duration}s)" if $creature_debug
        else
          respond "  +status: #{status} (no auto-expiry)" if $creature_debug
        end
      end

      # Removes a status effect from the creature instance.
      # @param status [String] the status to remove
      # @return [void]
      def remove_status(status)
        @status.delete(status)
        @status_timestamps.delete(status)
        respond "  -status: #{status}" if $creature_debug
      end

      # Cleans up any expired status effects from the creature instance.
      # @return [void]
      def cleanup_expired_statuses
        return unless @status_timestamps && !@status_timestamps.empty?

        now = Time.now
        @status_timestamps.select { |_status, expires_at| expires_at <= now }.keys.each do |expired_status|
          @status.delete(expired_status)
          @status_timestamps.delete(expired_status)
          respond "  ~status: #{expired_status} (auto-expired)" if $creature_debug
        end
      end

      # Checks if the creature instance has a specific status effect.
      # @param status [String] the status to check
      # @return [Boolean] true if the status is present, false otherwise
      def has_status?(status)
        cleanup_expired_statuses # Clean up expired statuses first
        @status.include?(status.to_s)
      end

      def statuses
        cleanup_expired_statuses # Clean up expired statuses first
        @status.dup
      end


      # Converts a position string to a tier number.
      # @param pos [String, Integer] the position to convert
      # @return [Integer, nil] the corresponding tier number or nil if invalid
      def position_to_tier(pos)
        case pos
        when "decent", 1, "1" then 1
        when "good", 2, "2" then 2
        when "excellent", 3, "3" then 3
        else nil
        end
      end

      # Sets the UCS position for the creature instance.
      # @param position [String, Integer] the new position to set
      # @return [void]
      def set_ucs_position(position)
        new_tier = position_to_tier(position)
        return unless new_tier

        # Clear tierup if tier changed
        @ucs_tierup = nil if new_tier != @ucs_position

        @ucs_position = new_tier
        @ucs_updated = Time.now
        respond "  UCS: position=#{new_tier}" if $creature_debug
      end

      # Sets the UCS tier-up type for the creature instance.
      # @param attack_type [String] the type of attack that caused the tier-up
      # @return [void]
      def set_ucs_tierup(attack_type)
        @ucs_tierup = attack_type
        @ucs_updated = Time.now
        respond "  UCS: tierup=#{attack_type}" if $creature_debug
      end

      # Marks the creature instance as smote.
      # @return [void]
      def smite!
        @ucs_smote = Time.now
        @ucs_updated = Time.now
        respond "  UCS: smote!" if $creature_debug
      end

      # Checks if the creature instance is currently smote.
      # @return [Boolean] true if smote, false otherwise
      def smote?
        return false unless @ucs_smote

        # Check if smite effect has expired
        if Time.now - @ucs_smote > UCS_SMITE_TTL
          @ucs_smote = nil
          return false
        end

        true
      end

      def clear_smote
        @ucs_smote = nil
        @ucs_updated = Time.now
        respond "  UCS: smote cleared" if $creature_debug
      end

      # Checks if the UCS data for the creature instance has expired.
      # @return [Boolean] true if expired, false otherwise
      def ucs_expired?
        return true unless @ucs_updated
        (Time.now - @ucs_updated) > UCS_TTL
      end

      def ucs_position
        return nil if ucs_expired?
        @ucs_position
      end

      def ucs_tierup
        return nil if ucs_expired?
        @ucs_tierup
      end

      # Adds an injury to a specific body part of the creature instance.
      # @param body_part [String] the body part to injure
      # @param amount [Integer] the amount of injury to add
      # @return [void]
      # @raise [ArgumentError] if the body part is invalid
      def add_injury(body_part, amount = 1)
        unless BODY_PARTS.include?(body_part.to_s)
          raise ArgumentError, "Invalid body part: #{body_part}"
        end
        @injuries[body_part.to_sym] += amount
      end

      def injured?(location, threshold = 1)
        @injuries[location.to_sym] >= threshold
      end

      def mark_fatal_crit!
        @fatal_crit = true
      end

      def fatal_crit?
        @fatal_crit
      end

      def injured_locations(threshold = 1)
        @injuries.select { |_, value| value >= threshold }.keys
      end

      # Adds damage to the creature instance.
      # @param amount [Integer] the amount of damage to add
      # @return [void]
      def add_damage(amount)
        @damage_taken += amount.to_i
      end

      def max_hp
        # Try template first
        hp = template&.max_hp
        return hp if hp && hp > 0

        # Fall back to combat tracker setting if available
        begin
          if defined?(Lich::Gemstone::Combat::Tracker) &&
             Lich::Gemstone::Combat::Tracker.respond_to?(:fallback_hp)
            fallback = Lich::Gemstone::Combat::Tracker.fallback_hp
            return fallback if fallback && fallback > 0
          end
        rescue
          # Ignore errors accessing tracker
        end

        # Last resort: hardcoded fallback
        400
      end

      # Calculates the current hit points of the creature instance.
      # @return [Integer, nil] the current hit points or nil if max_hp is not set
      def current_hp
        return nil unless max_hp
        [max_hp - @damage_taken, 0].max
      end

      def hp_percent
        return nil unless max_hp && max_hp > 0
        ((current_hp.to_f / max_hp) * 100).round(1)
      end

      # Checks if the creature instance is below a certain HP threshold.
      # @param threshold [Integer] the HP percentage threshold to check against
      # @return [Boolean] true if below the threshold, false otherwise
      def low_hp?(threshold = 25)
        return false unless hp_percent
        hp_percent <= threshold
      end

      def dead?
        current_hp == 0
      end

      def reset_damage
        @damage_taken = 0
      end

      # Retrieves essential data about the creature instance.
      # @return [Hash] a hash containing essential attributes of the creature instance
      def essential_data
        {
          id: @id,
          noun: @noun,
          name: @name,
          status: @status,
          injuries: @injuries,
          health: @health,
          damage_taken: @damage_taken,
          max_hp: max_hp,
          current_hp: current_hp,
          hp_percent: hp_percent,
          has_template: has_template?,
          created_at: @created_at,
          ucs_position: ucs_position,
          ucs_tierup: ucs_tierup,
          ucs_smote: smote?
        }
      end

      # Class methods for managing creature instances.
      class << self
        def configure(max_size: 1000, auto_register: true)
          @@max_size = max_size
          @@auto_register = auto_register
        end

        def auto_register?
          @@auto_register
        end

        def size
          @@instances.size
        end

        def full?
          size >= @@max_size
        end

        # Registers a new creature instance.
        # @param name [String] the name of the creature
        # @param id [Integer] the unique identifier for the creature
        # @param noun [String, nil] optional noun representing the creature
        # @return [CreatureInstance, nil] the registered creature instance or nil if registration failed
        def register(name, id, noun = nil)
          return nil unless auto_register?
          return @@instances[id.to_i] if @@instances[id.to_i] # Already exists

          # Auto-cleanup old instances if registry is full - get progressively more aggressive
          if full?
            # Try 120 minutes, then 15 minute intervals.
            [7200, 6300, 5400, 4500, 3600, 2700, 1800, 900].each do |age_threshold|
              removed = cleanup_old(age_threshold)
              respond "--- Auto-cleanup: removed #{removed} old creatures (threshold: #{age_threshold}s)" if removed > 0 && $creature_debug
              break unless full?
            end
            return nil if full? # Still full after all cleanup attempts
          end

          instance = new(id, noun, name)
          @@instances[id.to_i] = instance
          respond "--- Creature registered: #{name} (#{id})" if $creature_debug
          instance
        end

        def [](id)
          @@instances[id.to_i]
        end

        def all
          @@instances.values
        end

        def clear
          @@instances.clear
        end

        # Cleans up old creature instances based on their age.
        # @param max_age_seconds [Integer] the maximum age in seconds for instances to keep
        # @return [Integer] the number of instances removed
        def cleanup_old(max_age_seconds = 600)
          cutoff = Time.now - max_age_seconds
          removed = @@instances.select { |_id, instance| instance.created_at < cutoff }.size
          @@instances.reject! { |_id, instance| instance.created_at < cutoff }
          removed
        end
      end
    end

    module Creature
      def self.[](id)
        CreatureInstance[id]
      end

      def self.register(name, id, noun = nil)
        CreatureInstance.register(name, id, noun)
      end

      def self.configure(**options)
        CreatureInstance.configure(**options)
      end

      def self.stats
        {
          instances: CreatureInstance.size,
          templates: CreatureTemplate.all.size,
          max_size: CreatureInstance.class_variable_get(:@@max_size),
          auto_register: CreatureInstance.auto_register?
        }
      end

      def self.clear
        CreatureInstance.clear
      end

      def self.cleanup_old(**options)
        CreatureInstance.cleanup_old(**options)
      end

      def self.damage_report(**options)
        CreatureInstance.damage_report(**options)
      end

      def self.print_damage_report(**options)
        CreatureInstance.print_damage_report(**options)
      end

      def self.all
        CreatureInstance.all
      end
    end

    # Represents a special ability for a creature.
    class SpecialAbility
      attr_accessor :name, :note

      def initialize(data)
        @name = data[:name]
        @note = data[:note]
      end
    end

    # Represents the treasure associated with a creature.
    class Treasure
      def initialize(data = {})
        @data = {
          coins: false,
          gems: false,
          boxes: false,
          skin: nil,
          magic_items: nil,
          other: nil,
          blunt_required: false
        }.merge(data)
      end

      def has_coins? = !!@data[:coins]
      def has_gems? = !!@data[:gems]
      def has_boxes? = !!@data[:boxes]
      def has_skin? = !!@data[:skin]
      def blunt_required? = !!@data[:blunt_required]

      def to_h = @data
    end

    # Represents the messaging associated with a creature.
    class Messaging
      attr_accessor :description, :arrival, :flee, :death,
                    :spell_prep, :frenzy, :sympathy, :bite,
                    :claw, :attack, :enrage, :mstrike

      PLACEHOLDER_MAP = {
        Pronoun: %w[He Her His It She],
        pronoun: %w[he her his it she],
        direction: %w[north south east west up down northeast northwest southeast southwest],
        weapon: %w[RAW:.+?]
      }

      def initialize(data)
        data.each do |key, value|
          instance_variable_set("@#{key}", normalize(value))
        end
      end

      def normalize(value)
        if value.is_a?(Array)
          value.map { |v| normalize(v) }
        elsif value.is_a?(String) && value.match?(/\{[a-zA-Z_]+\}/)
          phs = value.scan(/\{([a-zA-Z_]+)\}/).flatten.map(&:to_sym)
          placeholders = phs.map { |ph| [ph, PLACEHOLDER_MAP[ph] || []] }.to_h
          PlaceholderTemplate.new(value, placeholders)
        else
          value
        end
      end

      def display(field, subs = {})
        msg = send(field)
        if msg.is_a?(Array)
          msg.map { |m| m.is_a?(PlaceholderTemplate) ? m.to_display(subs) : m }.join("\n")
        elsif msg.is_a?(PlaceholderTemplate)
          msg.to_display(subs)
        else
          msg
        end
      end

      def match(field, str)
        msg = send(field)
        if msg.is_a?(PlaceholderTemplate)
          msg.match(str)
        else
          msg == str ? {} : nil
        end
      end
    end

    # Represents the defensive attributes of a creature.
    class DefenseAttributes
      attr_accessor :asg, :melee, :ranged, :bolt, :udf,
                    :bar_td, :cle_td, :emp_td, :pal_td,
                    :ran_td, :sor_td, :wiz_td, :mje_td, :mne_td,
                    :mjs_td, :mns_td, :mnm_td, :immunities,
                    :defensive_spells, :defensive_abilities, :special_defenses

      def initialize(data)
        @asg = data[:asg]
        @melee = parse_td(data[:melee])
        @ranged = parse_td(data[:ranged])
        @bolt = parse_td(data[:bolt])
        @udf = parse_td(data[:udf])

        %i[bar_td cle_td emp_td pal_td ran_td sor_td wiz_td mje_td mne_td mjs_td mns_td mnm_td].each do |key|
          instance_variable_set("@#{key}", parse_td(data[key]))
        end

        @immunities = data[:immunities] || []
        @defensive_spells = data[:defensive_spells] || []
        @defensive_abilities = data[:defensive_abilities] || []
        @special_defenses = data[:special_defenses] || []
      end

      private

      def parse_td(val)
        return nil if val.nil?
        return val if val.is_a?(Range)

        # Parse range strings without eval (safer)
        if val.is_a?(String) && val.match?(/\A(\d+)\.\.(\d+)\z/)
          start_val, end_val = val.split('..').map(&:to_i)
          return start_val..end_val
        end

        val
      end
    end

    # Represents a template with placeholders for dynamic content.
    class PlaceholderTemplate
      # Initializes a new placeholder template with the given template and placeholders.
      # @param template [String] the template string
      # @param placeholders [Hash] a hash of placeholders and their options
      # @return [PlaceholderTemplate]
      def initialize(template, placeholders = {})
        @template = template
        @placeholders = placeholders
        @regex_cache = {}
      end

      def template
        @template
      end

      def placeholders
        @placeholders
      end

      def to_display(subs = {})
        line = @template.dup
        @placeholders.each do |key, options|
          value = subs[key] || options.sample || ""
          line.gsub!("{#{key}}", value.to_s)
        end
        line
      end

      def to_regex(literals = {})
        # Use cache to avoid rebuilding regex on every call
        cache_key = literals.hash
        return @regex_cache[cache_key] if @regex_cache[cache_key]

        regex = if @template.is_a?(Array)
                  regexes = @template.map { |t| self.class.new(t, @placeholders).to_regex(literals) }
                  Regexp.union(*regexes)
                else
                  build_regex(literals)
                end

        @regex_cache[cache_key] = regex
      end

      private

      def build_regex(literals)
        pattern = Regexp.escape(@template)
        @placeholders.each do |key, options|
          if options == [:wildcard] || options.first&.start_with?('RAW:')
            raw = options.first.start_with?('RAW:') ? options.first[4..-1] : options.first
            pattern.gsub!(/\\\{#{key}\\\}/, raw)
          else
            regex_group = "(?<#{key}>#{(literals[key] || options).map { |opt| Regexp.escape(opt) }.join('|')})"
            pattern.gsub!(/\\\{#{key}\\\}/, regex_group)
          end
        end
        Regexp.new("#{pattern}")
      end

      def match(str, literals = {})
        regex = to_regex(literals)
        m = regex.match(str)
        return nil unless m
        m.names.any? ? m.named_captures.transform_keys(&:to_sym) : m.captures
      end
    end
  end
end
