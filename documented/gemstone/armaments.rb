require_relative "armaments/armor_stats.rb"
require_relative "armaments/weapon_stats.rb"
require_relative "armaments/shield_stats.rb"

# Provides functionality related to the Lich game framework.
#
# @see Lich::Gemstone
module Lich
  module Gemstone
    # Contains constants and methods related to armaments in the game.
    #
    # @see Lich::Gemstone
    module Armaments
      ##
      AG_INDEX_TO_NAME = {
        1 => "Cloth",
        2 => "Soft Leather",
        3 => "Rigid Leather",
        4 => "Chain",
        5 => "Plate"
      }.freeze

      ##
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
      # Finds an armament by its name.
      #
      # @param name [String] the name of the armament to find
      # @return [Hash, nil] a hash containing the type and data of the armament, or nil if not found
      # @example Find a weapon
      #   Armaments.find("sword")
      # @example Find an armor
      #   Armaments.find("plate")
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
      # Checks if the given name corresponds to a valid armament.
      #
      # @param name [String] the name to validate
      # @return [Boolean] true if the name is valid, false otherwise
      # @example Validate a weapon name
      #   Armaments.valid_name?("sword")
      def self.valid_name?(name)
        name = name.downcase.strip

        return true unless Armaments.find(name).nil? # if we found it, then it's valid
        return false # if nil, then the name was not found and it's not a valid name
      end

      ##
      # Retrieves a list of armament names, optionally filtered by type.
      #
      # @param type [Symbol, nil] the type of armament (:weapon, :armor, :shield) or nil for all
      # @return [Array<String>] an array of unique armament names
      # @example Get all armament names
      #   Armaments.names
      # @example Get only weapon names
      #   Armaments.names(:weapon)
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
      # Retrieves a list of armament categories, optionally filtered by type.
      #
      # @param type [Symbol, nil] the type of armament (:weapon, :armor, :shield) or nil for all
      # @return [Array<String>] an array of unique armament categories
      # @example Get all armament categories
      #   Armaments.categories
      # @example Get only armor categories
      #   Armaments.categories(:armor)
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
      #
      # @param name [String] the name of the armament
      # @return [Symbol, nil] the type of the armament (:weapon, :armor, :shield) or nil if not found
      # @example Get the type for a known weapon
      #   Armaments.type_for("sword")
      def self.type_for(name)
        name = name.downcase.strip

        return :weapon if WeaponStats.find(name)
        return :armor if ArmorStats.find(name)
        return :shield if ShieldStats.find(name)

        nil
      end

      ##
      # Retrieves the category of an armament based on its name.
      #
      # @param name [String] the name of the armament
      # @return [String, nil] the category of the armament or nil if not found
      # @example Get the category for a known armor
      #   Armaments.category_for("plate")
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
