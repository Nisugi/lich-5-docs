module Lich
  module Gemstone
    # Represents a disk item in the game.
    #
    # This class provides methods to identify, find, and manage disk objects.
    #
    # @see Lich::Gemstone::Disk#find_by_name
    # @see Lich::Gemstone::Disk#all
    class Disk
      NOUNS = %w{cassone chest coffer coffin coffret disk hamper saucer sphere trunk tureen}

      # Checks if the given object is a disk based on its name.
      # @param thing [Object] the object to check
      # @return [Boolean] true if the object is a disk, false otherwise
      def self.is_disk?(thing)
        thing.name =~ /\b([A-Z][a-z]+) #{Regexp.union(NOUNS)}\b/
      end

      # Finds a disk by its name.
      # @param name [String] the name of the disk to find
      # @return [Lich::Gemstone::Disk, nil] the found disk object or nil if not found
      # @example Find a disk by name
      #   disk = Lich::Gemstone::Disk.find_by_name("golden disk")
      def self.find_by_name(name)
        disk = GameObj.loot.find do |item|
          is_disk?(item) && item.name.include?(name)
        end
        return nil if disk.nil?
        Disk.new(disk)
      end

      # Mines for a disk based on the character's name.
      # @return [Lich::Gemstone::Disk, nil] the found disk object or nil if not found
      def self.mine
        find_by_name(Char.name)
      end

      # Retrieves all disk objects from the loot.
      # @return [Array<Lich::Gemstone::Disk>] an array of all disk objects
      def self.all()
        (GameObj.loot || []).select do |item|
          is_disk?(item)
        end.map do |i|
          Disk.new(i)
        end
      end

      attr_reader :id, :name

      # Initializes a new Disk object with the given game object.
      # @param obj [Object] the game object representing the disk
      # @return [void]
      def initialize(obj)
        @id   = obj.id
        @name = obj.name.split(" ").find do |word|
          word[0].upcase.eql?(word[0])
        end
      end

      # Compares this disk with another disk for equality.
      # @param other [Object] the object to compare
      # @return [Boolean] true if the disks are equal, false otherwise
      def ==(other)
        other.is_a?(Disk) && other.id == self.id
      end

      # Checks if this disk is equal to another disk.
      # @param other [Object] the object to compare
      # @return [Boolean] true if the disks are equal, false otherwise
      def eql?(other)
        self == other
      end

      def method_missing(method, *args)
        GameObj[@id].send(method, *args)
      end

      # Converts this disk to a container object.
      # @return [Container, GameObj] the corresponding container object or game object
      def to_container
        if defined?(Container)
          Container.new(@id)
        else
          GameObj["#{@id}"]
        end
      end
    end
  end
end
