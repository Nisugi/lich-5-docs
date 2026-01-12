require_relative "armaments/armor_stats.rb"
require_relative "armaments/weapon_stats.rb"
require_relative "armaments/shield_stats.rb"

module Lich
  module Gemstone
    module Armaments
      ##
      # A mapping of armor group indices to their names.
      # @example Accessing armor group name
      #   name = Armaments::AG_INDEX_TO_NAME[1]
      AG_INDEX_TO_NAME = {
        1 => "Cloth",
        2 => "Soft Leather",
        3 => "Rigid Leather",
        4 => "Chain",
        5 => "Plate"
      }.freeze

      ##
      # A mapping of armor subtype indices to their names.
      # @example Accessing armor subtype name
      #   name = Armaments::ASG_INDEX_TO_NAME[1]
      ASG_INDEX_TO_NAME = {
        1  => "Robes",
        2  => "Light Leather",
        3  => "Full Leather",
        4  => "Double Leather",
        5  => "Leather Breastplate",
        6  => "Cuirbouilli",
        7  => "Studded Leather",
        8  => "Reinforced Leather",
        9  => "Hardened Leather",
        10 => "Brigandine",
        11 => "Chain Mail",
        12 => "Double Chain",
        13 => "Augmented Chain",
        14 => "Chain Hauberk",
        15 => "Metal Breastplate",
        16 => "Augmented Breastplate",
        17 => "Half Plate",
        18 => "Full Plate",
        19 => "Field Plate",
        20 => "Augmented Plate"
      }.freeze

      ##
      # A mapping of spell circle indices to their names and abbreviations.
      # @example Accessing spell circle name
      #   spell_circle = Armaments::SPELL_CIRCLE_INDEX_TO_NAME[1]
      SPELL_CIRCLE_INDEX_TO_NAME = {
        0  => { name: "Action",                  abbr: "Act"    },
        1  => { name: "Minor Spiritual",         abbr: "MinSp"  },
        2  => { name: "Major Spiritual",         abbr: "MajSp"  },
        3  => { name: "Cleric",                  abbr: "Clerc"  },
        4  => { name: "Minor Elemental",         abbr: "MinEl"  },
        5  => { name: "Major Elemental",         abbr: "MajEl"  },
        6  => { name: "Ranger",                  abbr: "Rngr"   },
        7  => { name: "Sorcerer",                abbr: "Sorc"   },
        8  => { name: "Old Empath (Deprecated)", abbr: "OldEm"  },
        9  => { name: "Wizard",                  abbr: "Wiz"    },
        10 => { name: "Bard",                    abbr: "Bard"   },
        11 => { name: "Empath",                  abbr: "Emp"    },
        12 => { name: "Minor Mental",            abbr: "MinMn"  },
        13 => { name: "Major Mental",            abbr: "MajMn"  },
        14 => { name: "Savant",                  abbr: "Sav"    },
        15 => { name: "Unused",                  abbr: " - "    },
        16 => { name: "Paladin",                 abbr: "Pal"    },
        17 => { name: "Arcane Spells",           abbr: "Arcne"  },
        18 => { name: "Unused",                  abbr: " - "    },
        19 => { name: "Lost Arts",               abbr: "Lost"   },
      }.freeze

      ##
      # Finds an armament by name and returns its type and data.
      # @param name [String] The name of the armament to find.
      # @return [Hash, nil] A hash containing the type and data of the armament, or nil if not found.
      # @example Finding an armament
      #   result = Armaments.find("sword")
      def self.find(name)
        name = name.downcase.strip

        if (data = WeaponStats.find(name))
          return { type: :weapon, data: data }
        end

        if (data = ArmorStats.find(name))
          return { type: :armor, data: data }
        end

        if (data = ShieldStats.find(name))
          return { type: :shield, data: data }
        end

        nil
      end

      ##
      # Checks if the given name is valid by attempting to find it.
      # @param name [String] The name to validate.
      # @return [Boolean] True if the name is valid, false otherwise.
      # @example Validating an armament name
      #   is_valid = Armaments.valid_name?("shield")
      def self.valid_name?(name)
        name = name.downcase.strip

        return true unless Armaments.find(name).nil? # if we found it, then it's valid
        return false # if nil, then the name was not found and it's not a valid name
      end

      ##
      # Retrieves a list of names for armaments of a specified type.
      # @param type [Symbol, nil] The type of armament (:weapon, :armor, :shield) or nil for all.
      # @return [Array<String>] An array of unique armament names.
      # @example Getting all armament names
      #   all_names = Armaments.names
      def self.names(type = nil)
        case type
        when :weapon then WeaponStats.names
        when :armor  then ArmorStats.names
        when :shield then ShieldStats.names
        else
          WeaponStats.names + ArmorStats.names + ShieldStats.names
        end.uniq
      end

      ##
      # Retrieves a list of categories for armaments of a specified type.
      # @param type [Symbol, nil] The type of armament (:weapon, :armor, :shield) or nil for all.
      # @return [Array<String>] An array of unique armament categories.
      # @example Getting all armament categories
      #   all_categories = Armaments.categories
      def self.categories(type = nil)
        case type
        when :weapon then WeaponStats.categories
        when :armor  then ArmorStats.categories
        when :shield then ShieldStats.categories
        else
          WeaponStats.categories + ArmorStats.categories + ShieldStats.categories
        end.uniq
      end

      ##
      # Determines the type of armament based on its name.
      # @param name [String] The name of the armament.
      # @return [Symbol, nil] The type of the armament (:weapon, :armor, :shield) or nil if not found.
      # @example Getting the type of an armament
      #   armament_type = Armaments.type_for("sword")
      def self.type_for(name)
        name = name.downcase.strip

        return :weapon if WeaponStats.find(name)
        return :armor if ArmorStats.find(name)
        return :shield if ShieldStats.find(name)

        nil
      end

      ##
      # Retrieves the category of an armament based on its name.
      # @param name [String] The name of the armament.
      # @return [String, nil] The category of the armament or nil if not found.
      # @example Getting the category of an armament
      #   armament_category = Armaments.category_for("sword")
      def self.category_for(name)
        name = name.downcase.strip

        category = WeaponStats.category_for(name)
        return category unless category.nil?

        category = ArmorStats.category_for(name)
        return category unless category.nil?

        category = ShieldStats.category_for(name)
        return category unless category.nil?

        nil
      end
    end
  end
end
