module Lich
  module Gemstone
    module Armaments
      module ShieldStats
        # Static array of shield stats indexed by shield identifiers. Each shield
        # entry contains metadata such as category, alternative names, size and
        # evade modifiers, and base weight.
        # Static array of shield stats indexed by shield identifiers.
        # Each shield entry contains metadata such as category, alternative names,
        # size and evade modifiers, and base weight.
        @@shield_stats = {
          :small_shield  => {
            :category       => :small_shield,
            :base_name      => "small shield",
            :all_names      => ["buckler", "kidney shield", "small shield", "targe"],
            :size_modifier  => -0.15,
            :evade_modifier => -0.22,
            :base_weight    => 6,
          },
          :medium_shield => {
            :category       => :medium_shield,
            :base_name      => "medium shield",
            :all_names      => ["battle shield", "heater", "heater shield", "knight's shield", "krytze", "lantern shield", "medium shield", "parma", "target shield"],
            :size_modifier  => 0.0,
            :evade_modifier => -0.30,
            :base_weight    => 8,
          },
          :large_shield  => {
            :category       => :large_shield,
            :base_name      => "large shield",
            :all_names      => ["aegis", "kite shield", "large shield", "pageant shield", "round shield", "scutum"],
            :size_modifier  => 0.15,
            :evade_modifier => -0.38,
            :base_weight    => 9,
          },
          :tower_shield  => {
            :category       => :tower_shield,
            :base_name      => "tower shield",
            :all_names      => ["greatshield", "mantlet", "pavis", "tower shield", "wall shield"],
            :size_modifier  => 0.30,
            :evade_modifier => -0.50,
            :base_weight    => 12,
          },
        }

        Lich::Util.deep_freeze(@@shield_stats)

        ##
        # Finds shield information by category.
        # @param category [Symbol] the category of the shield to find
        # @return [Hash, nil] the shield information if found, otherwise nil
        def self.find_by_category(category)
          _, shield_info = @@shield_stats.find { |_, stats| stats[:category] == category }
          shield_info
        end

        ##
        # Returns a unique list of all shield names.
        # @return [Array<String>] an array of unique shield names
        def self.names
          @@shield_stats.map { |_, s| s[:all_names] }.flatten.uniq
        end

        ##
        # Finds a shield by its name.
        # @param name [String] the name of the shield to find
        # @return [Hash, nil] the shield information if found, otherwise nil
        def self.find(name)
          name = name.downcase.strip

          @@shield_stats.each_value do |shield|
            return shield if shield[:all_names]&.map(&:downcase)&.include?(name)
          end

          nil
        end

        ##
        # Lists shields within a specified evade modifier range.
        # @param min [Float] the minimum evade modifier
        # @param max [Float] the maximum evade modifier
        # @return [Array<Hash>] an array of shields that match the criteria
        def self.list_shields_by_evade_modifier(min:, max:)
          @@shield_stats.map(&:last).select do |shield|
            shield[:evade_modifier].between?(min, max)
          end
        end

        ##
        # Returns a list of all shield categories.
        # @return [Array<Symbol>] an array of shield categories
        def self.categories
          @@shield_stats.keys
        end

        ##
        # Retrieves the category for a given shield name.
        # @param name [String] the name of the shield
        # @return [Symbol, nil] the category of the shield if found, otherwise nil
        def self.category_for(name)
          name = name.downcase.strip

          shield = self.find(name)
          shield ? shield[:category] : nil
        end

        ##
        # Returns a formatted string representation of the shield's details.
        # @param name [String] the name of the shield
        # @return [String] a formatted string with shield details
        def self.pretty(name)
          shield = self.find(name)
          return "\n(no data)\n" unless shield.is_a?(Hash)

          lines = []
          lines << ""

          fields = {
            "Shield"      => shield[:base_name],
            "Category"    => shield[:category].to_s.gsub('_', ' ').capitalize,
            "Size Mod"    => format('%.2f', shield[:size_modifier]),
            "Evade Mod"   => format('%.2f', shield[:evade_modifier]),
            "Base Weight" => "#{shield[:base_weight]} lbs"
          }

          max_label = fields.keys.map(&:length).max

          fields.each do |label, value|
            lines << "%-#{max_label}s: %s" % [label, value]
          end

          if shield[:all_names]&.any?
            lines << "%-#{max_label}s: %s" % ["Alternate", shield[:all_names].join(", ")]
          end

          lines << ""
          lines.join("\n")
        end

        ##
        # Returns a detailed formatted string representation of the shield's details.
        # @param name [String] the name of the shield
        # @return [String] a formatted string with shield details
        def self.pretty_long(name)
          pretty(name)
        end

        ##
        # Retrieves all alternative names for a given shield.
        # @param name [String] the name of the shield
        # @return [Array<String>] an array of alternative names
        def self.aliases_for(name)
          name = name.downcase.strip
          shield = self.find(name)
          shield ? shield[:all_names] : []
        end

        ##
        # Compares two shields by their names and returns their attributes.
        # @param name1 [String] the name of the first shield
        # @param name2 [String] the name of the second shield
        # @return [Hash, nil] a hash containing the comparison data if both shields are found, otherwise nil
        def self.compare(name1, name2)
          name1 = name1.downcase.strip
          name2 = name2.downcase.strip

          s1 = find(name1)
          s2 = find(name2)
          return nil unless s1 && s2

          {
            name1: s1[:base_name],
            name2: s2[:base_name],
            size_modifier: [s1[:size_modifier], s2[:size_modifier]],
            evade_modifier: [s1[:evade_modifier], s2[:evade_modifier]],
            base_weight: [s1[:base_weight], s2[:base_weight]],
            category: [s1[:category], s2[:category]],
            aliases: [s1[:all_names], s2[:all_names]]
          }
        end

        ##
        # Searches for shields based on various filters.
        # @param filters [Hash] a hash of filters to apply
        # @return [Array<Hash>] an array of shields that match the filters
        def self.search(filters = {})
          @@shield_stats.values.select do |shield|
            next if filters[:name] && !shield[:all_names].include?(filters[:name].downcase.strip)
            next if filters[:category] && shield[:category] != filters[:category]
            next if filters[:min_evade_modifier] && shield[:evade_modifier] < filters[:min_evade_modifier]
            next if filters[:max_evade_modifier] && shield[:evade_modifier] > filters[:max_evade_modifier]
            next if filters[:min_size_modifier] && shield[:size_modifier] < filters[:min_size_modifier]
            next if filters[:max_size_modifier] && shield[:size_modifier] > filters[:max_size_modifier]
            next if filters[:max_weight] && shield[:base_weight] > filters[:max_weight]

            true
          end
        end

        ##
        # Checks if a given name is a valid shield name.
        # @param name [String] the name to validate
        # @return [Boolean] true if the name is valid, otherwise false
        # @api private
        def self.valid_name?(name)
          name = name.downcase.strip
          self.names.include?(name)
        end
      end
    end
  end
end
