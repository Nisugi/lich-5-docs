module Lich
  module DragonRealms
    # Represents a room in the DragonRealms game.
    # This class manages the state of the room, including NPCs, PCs, and room properties.
    # @example Creating a room and accessing its properties
    #   room = Lich::DragonRealms::DRRoom
    #   room.title = 'A Dark Cave'
    class DRRoom
      @@npcs ||= []
      @@pcs ||= []
      @@group_members ||= []
      @@pcs_prone ||= []
      @@pcs_sitting ||= []
      @@dead_npcs ||= []
      @@room_objs ||= []
      @@exits ||= []
      @@title = ''
      @@description = ''

      # Returns the list of non-player characters (NPCs) in the room.
      # @return [Array] An array of NPCs in the room.
      # @example
      #   npcs = DRRoom.npcs
      def self.npcs
        @@npcs
      end

      # Sets the list of non-player characters (NPCs) in the room.
      # @param val [Array] The new array of NPCs to set.
      # @return [Array] The updated array of NPCs.
      # @example
      #   DRRoom.npcs = [npc1, npc2]
      def self.npcs=(val)
        @@npcs = val
      end

      # Returns the list of player characters (PCs) in the room.
      # @return [Array] An array of PCs in the room.
      # @example
      #   pcs = DRRoom.pcs
      def self.pcs
        @@pcs
      end

      # Sets the list of player characters (PCs) in the room.
      # @param val [Array] The new array of PCs to set.
      # @return [Array] The updated array of PCs.
      # @example
      #   DRRoom.pcs = [pc1, pc2]
      def self.pcs=(val)
        @@pcs = val
      end

      # Returns the exits available in the room.
      # @return [Array] An array of exits defined in the room.
      # @example
      #   exits = DRRoom.exits
      def self.exits
        XMLData.room_exits
      end

      # Returns the title of the room.
      # @return [String] The title of the room.
      # @example
      #   title = DRRoom.title
      def self.title
        XMLData.room_title
      end

      # Returns the description of the room.
      # @return [String] The description of the room.
      # @example
      #   description = DRRoom.description
      def self.description
        XMLData.room_description
      end

      # Returns the list of group members in the room.
      # @return [Array] An array of group members.
      # @example
      #   group_members = DRRoom.group_members
      def self.group_members
        @@group_members
      end

      # Sets the list of group members in the room.
      # @param val [Array] The new array of group members to set.
      # @return [Array] The updated array of group members.
      # @example
      #   DRRoom.group_members = [member1, member2]
      def self.group_members=(val)
        @@group_members = val
      end

      # Returns the list of player characters (PCs) that are prone in the room.
      # @return [Array] An array of prone PCs.
      # @example
      #   prone_pcs = DRRoom.pcs_prone
      def self.pcs_prone
        @@pcs_prone
      end

      # Sets the list of player characters (PCs) that are prone in the room.
      # @param val [Array] The new array of prone PCs to set.
      # @return [Array] The updated array of prone PCs.
      # @example
      #   DRRoom.pcs_prone = [prone_pc1, prone_pc2]
      def self.pcs_prone=(val)
        @@pcs_prone = val
      end

      # Returns the list of player characters (PCs) that are sitting in the room.
      # @return [Array] An array of sitting PCs.
      # @example
      #   sitting_pcs = DRRoom.pcs_sitting
      def self.pcs_sitting
        @@pcs_sitting
      end

      # Sets the list of player characters (PCs) that are sitting in the room.
      # @param val [Array] The new array of sitting PCs to set.
      # @return [Array] The updated array of sitting PCs.
      # @example
      #   DRRoom.pcs_sitting = [sitting_pc1, sitting_pc2]
      def self.pcs_sitting=(val)
        @@pcs_sitting = val
      end

      # Returns the list of dead non-player characters (NPCs) in the room.
      # @return [Array] An array of dead NPCs.
      # @example
      #   dead_npcs = DRRoom.dead_npcs
      def self.dead_npcs
        @@dead_npcs
      end

      # Sets the list of dead non-player characters (NPCs) in the room.
      # @param val [Array] The new array of dead NPCs to set.
      # @return [Array] The updated array of dead NPCs.
      # @example
      #   DRRoom.dead_npcs = [dead_npc1, dead_npc2]
      def self.dead_npcs=(val)
        @@dead_npcs = val
      end

      # Returns the list of objects in the room.
      # @return [Array] An array of room objects.
      # @example
      #   room_objects = DRRoom.room_objs
      def self.room_objs
        @@room_objs
      end

      # Sets the list of objects in the room.
      # @param val [Array] The new array of room objects to set.
      # @return [Array] The updated array of room objects.
      # @example
      #   DRRoom.room_objs = [obj1, obj2]
      def self.room_objs=(val)
        @@room_objs = val
      end
    end
  end
end
