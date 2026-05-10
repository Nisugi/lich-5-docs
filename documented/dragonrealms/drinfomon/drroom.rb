
module Lich
  module DragonRealms
    # Represents a room in the DragonRealms game.
    #
    # This class manages the state of the room, including NPCs, PCs,
    # and various room attributes.
    #
    # @see Lich::DragonRealms for related modules.
    class DRRoom
      @@npcs ||= []
      @@pcs ||= []
      @@group_members ||= []
      @@pcs_prone ||= []
      @@pcs_sitting ||= []
      @@dead_npcs ||= []
      @@room_objs ||= []
      @@exits ||= []

      # Returns the list of non-player characters (NPCs) in the room.
      # @return [Array] an array of NPCs currently in the room.
      def self.npcs
        @@npcs
      end

      # Sets the list of non-player characters (NPCs) in the room.
      # @param val [Array] an array of NPCs to set for the room.
      # @return [void]
      def self.npcs=(val)
        @@npcs = val
      end

      # Returns the list of player characters (PCs) in the room.
      # @return [Array] an array of PCs currently in the room.
      def self.pcs
        @@pcs
      end

      # Sets the list of player characters (PCs) in the room.
      # @param val [Array] an array of PCs to set for the room.
      # @return [void]
      def self.pcs=(val)
        @@pcs = val
      end

      # Returns the exits available from the room.
      # @return [Array] an array of exits defined in the room.
      def self.exits
        XMLData.room_exits
      end

      # Returns the title of the room.
      # @return [String] the title of the room.
      def self.title
        XMLData.room_title
      end

      # Returns the description of the room.
      # @return [String] the description of the room.
      def self.description
        XMLData.room_description
      end

      # Returns the list of group members in the room.
      # @return [Array] an array of group members.
      def self.group_members
        @@group_members
      end

      # Sets the list of group members in the room.
      # @param val [Array] an array of group members to set for the room.
      # @return [void]
      def self.group_members=(val)
        @@group_members = val
      end

      # Returns the list of player characters (PCs) that are prone in the room.
      # @return [Array] an array of PCs that are currently prone.
      def self.pcs_prone
        @@pcs_prone
      end

      # Sets the list of player characters (PCs) that are prone in the room.
      # @param val [Array] an array of PCs to set as prone.
      # @return [void]
      def self.pcs_prone=(val)
        @@pcs_prone = val
      end

      # Returns the list of player characters (PCs) that are sitting in the room.
      # @return [Array] an array of PCs that are currently sitting.
      def self.pcs_sitting
        @@pcs_sitting
      end

      # Sets the list of player characters (PCs) that are sitting in the room.
      # @param val [Array] an array of PCs to set as sitting.
      # @return [void]
      def self.pcs_sitting=(val)
        @@pcs_sitting = val
      end

      # Returns the list of dead non-player characters (NPCs) in the room.
      # @return [Array] an array of dead NPCs.
      def self.dead_npcs
        @@dead_npcs
      end

      # Sets the list of dead non-player characters (NPCs) in the room.
      # @param val [Array] an array of dead NPCs to set for the room.
      # @return [void]
      def self.dead_npcs=(val)
        @@dead_npcs = val
      end

      # Returns the list of objects in the room.
      # @return [Array] an array of objects present in the room.
      def self.room_objs
        @@room_objs
      end

      # Sets the list of objects in the room.
      # @param val [Array] an array of objects to set for the room.
      # @return [void]
      def self.room_objs=(val)
        @@room_objs = val
      end
    end
  end
end
