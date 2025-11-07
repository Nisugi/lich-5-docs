# handles instances of modules that are game dependent

# The main module for the Lich project
# This module serves as a namespace for all components of the Lich project.
module Lich
  module Common
    # Handles instances of modules that are game dependent
    # This module provides methods to load game-specific resources.
    # @example Loading resources for a game
    #   Lich::Common::GameLoader.load!
    module GameLoader
      # Loads common dependencies before game-specific resources
      # This method requires necessary files for common functionality.
      # @return [void]
      def self.common_before
        require File.join(LIB_DIR, 'common', 'log.rb')
        require File.join(LIB_DIR, 'common', 'spell.rb')
        require File.join(LIB_DIR, 'util', 'util.rb')
        require File.join(LIB_DIR, 'common', 'hmr.rb')
      end

      # Loads resources specific to the Gemstone game
      # This method calls common_before and then requires Gemstone-specific files.
      # @return [void]
      # @example
      #   Lich::Common::GameLoader.gemstone
      def self.gemstone
        self.common_before
        require File.join(LIB_DIR, 'gemstone', 'sk.rb')
        require File.join(LIB_DIR, 'common', 'map', 'map_gs.rb')
        require File.join(LIB_DIR, 'gemstone', 'effects.rb')
        require File.join(LIB_DIR, 'gemstone', 'bounty.rb')
        require File.join(LIB_DIR, 'gemstone', 'claim.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon.rb')
        require File.join(LIB_DIR, 'attributes', 'resources.rb')
        require File.join(LIB_DIR, 'attributes', 'stats.rb')
        require File.join(LIB_DIR, 'attributes', 'spells.rb')
        require File.join(LIB_DIR, 'attributes', 'skills.rb')
        require File.join(LIB_DIR, 'gemstone', 'society.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon', 'status.rb')
        require File.join(LIB_DIR, 'gemstone', 'experience.rb')
        require File.join(LIB_DIR, 'attributes', 'spellsong.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon', 'activespell.rb')
        require File.join(LIB_DIR, 'gemstone', 'psms.rb')
        require File.join(LIB_DIR, 'attributes', 'char.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon', 'currency.rb')
        # require File.join(LIB_DIR, 'gemstone', 'character', 'disk.rb') # dup
        require File.join(LIB_DIR, 'gemstone', 'group.rb')
        require File.join(LIB_DIR, 'gemstone', 'critranks')
        require File.join(LIB_DIR, 'gemstone', 'wounds.rb')
        require File.join(LIB_DIR, 'gemstone', 'scars.rb')
        require File.join(LIB_DIR, 'gemstone', 'gift.rb')
        require File.join(LIB_DIR, 'gemstone', 'readylist.rb')
        require File.join(LIB_DIR, 'gemstone', 'stowlist.rb')
        ActiveSpell.watch!
        self.common_after
      end

      # Loads resources specific to the Dragon Realms game
      # This method calls common_before and then requires Dragon Realms-specific files.
      # @return [void]
      # @example
      #   Lich::Common::GameLoader.dragon_realms
      def self.dragon_realms
        self.common_before
        require File.join(LIB_DIR, 'common', 'map', 'map_dr.rb')
        require File.join(LIB_DIR, 'attributes', 'char.rb')
        require File.join(LIB_DIR, 'dragonrealms', 'drinfomon.rb')
        require File.join(LIB_DIR, 'dragonrealms', 'commons.rb')
        self.common_after
      end

      # Placeholder for actions to be taken after loading game resources
      # This method currently does nothing.
      # @return [void]
      def self.common_after
        # nil
      end

      # Loads the appropriate game resources based on the game type
      # This method checks the game type and calls the respective loading method.
      # @return [void]
      # @raise [RuntimeError] if the game type is unknown
      # @example
      #   Lich::Common::GameLoader.load!
      def self.load!
        sleep 0.1 while XMLData.game.nil? or XMLData.game.empty?
        return self.dragon_realms if XMLData.game =~ /DR/
        return self.gemstone if XMLData.game =~ /GS/
        echo "could not load game specifics for %s" % XMLData.game
      end
    end
  end
end
