
# Lich module
# This module serves as a namespace for the Lich project.
module Lich
  module Common
    # GameLoader module
    # This module handles the loading of game-specific resources.
    # @example Loading the gemstone game
    #   Lich::Common::GameLoader.gemstone
    module GameLoader
      # Prepares the common resources before loading a game.
      # This method requires necessary files for the game to function properly.
      def self.common_before
        require File.join(LIB_DIR, 'common', 'account.rb')
        require File.join(LIB_DIR, 'common', 'log.rb')
        require File.join(LIB_DIR, 'common', 'spell.rb')
        require File.join(LIB_DIR, 'util', 'util.rb')
        require File.join(LIB_DIR, 'util', 'textstripper.rb')
        require File.join(LIB_DIR, 'common', 'hmr.rb')
      end

      # Loads the resources specific to the gemstone game.
      # @return [void]
      # @raise [LoadError] if any required file cannot be loaded.
      # @example Loading gemstone resources
      #   Lich::Common::GameLoader.gemstone
      def self.gemstone
        self.common_before
        require File.join(LIB_DIR, 'gemstone', 'sk.rb')
        require File.join(LIB_DIR, 'common', 'map', 'map_gs.rb')
        require File.join(LIB_DIR, 'gemstone', 'effects.rb')
        require File.join(LIB_DIR, 'gemstone', 'bounty.rb')
        require File.join(LIB_DIR, 'gemstone', 'claim.rb')
        require File.join(LIB_DIR, 'gemstone', 'overwatch.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon.rb')
        require File.join(LIB_DIR, 'attributes', 'resources.rb')
        require File.join(LIB_DIR, 'attributes', 'stats.rb')
        require File.join(LIB_DIR, 'attributes', 'spells.rb')
        require File.join(LIB_DIR, 'attributes', 'skills.rb')
        require File.join(LIB_DIR, 'attributes', 'enhancive.rb')
        require File.join(LIB_DIR, 'gemstone', 'society.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon', 'status.rb')
        require File.join(LIB_DIR, 'gemstone', 'experience.rb')
        require File.join(LIB_DIR, 'attributes', 'spellsong.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon', 'activespell.rb')
        require File.join(LIB_DIR, 'gemstone', 'psms.rb')
        require File.join(LIB_DIR, 'attributes', 'char.rb')
        require File.join(LIB_DIR, 'gemstone', 'currency.rb')
        # require File.join(LIB_DIR, 'gemstone', 'character', 'disk.rb') # dup
        require File.join(LIB_DIR, 'gemstone', 'group.rb')
        require File.join(LIB_DIR, 'gemstone', 'critranks')
        require File.join(LIB_DIR, 'gemstone', 'injured')
        require File.join(LIB_DIR, 'gemstone', 'wounds.rb')
        require File.join(LIB_DIR, 'gemstone', 'scars.rb')
        require File.join(LIB_DIR, 'gemstone', 'gift.rb')
        # require File.join(LIB_DIR, 'gemstone', 'creature.rb') # combat tracker below loads this so not needed to preload
        require File.join(LIB_DIR, 'gemstone', 'combat', 'tracker.rb')
        require File.join(LIB_DIR, 'gemstone', 'readylist.rb')
        require File.join(LIB_DIR, 'gemstone', 'stowlist.rb')
        require File.join(LIB_DIR, 'gemstone', 'armaments.rb')
        ActiveSpell.watch!
        Infomon.watch!
        self.common_after
      end

      # Loads the resources specific to the dragon realms game.
      # @return [void]
      # @raise [LoadError] if any required file cannot be loaded.
      # @example Loading dragon realms resources
      #   Lich::Common::GameLoader.dragon_realms
      def self.dragon_realms
        self.common_before
        require File.join(LIB_DIR, 'common', 'map', 'map_dr.rb')
        require File.join(LIB_DIR, 'attributes', 'char.rb')
        require File.join(LIB_DIR, 'dragonrealms', 'dependency', 'settings_config.rb')
        require File.join(LIB_DIR, 'dragonrealms', 'drinfomon.rb')
        require File.join(LIB_DIR, 'dragonrealms', 'commons.rb')
        DRInfomon.watch!
        self.common_after
      end

      # Finalizes the loading process by requiring post-load resources.
      # This method ensures that all necessary final setups are completed.
      def self.common_after
        require File.join(LIB_DIR, 'common', 'postload.rb')
        PostLoad.register("settings_init") do
          # When the game server sends malformed <settingsInfo  space not found ...> XML,
          # it means this character has never logged in with the Wrayth client.
          # The reactive fix in handle_xml_error patches the XML and sets the flag.
          # Here we send a dummy <db> command to seed a valid client record so
          # the server sends properly formatted settingsInfo on future connects.
          if GameBase::Game.settings_init_needed?
            Game._puts("<db><settings client='1.0.1.28'></settings>")
          end
        end
        PostLoad.watch!
      end

      # Loads the appropriate game based on the XML data.
      # @return [void]
      # @raise [RuntimeError] if the game cannot be determined.
      # @example Loading a game based on XML data
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
