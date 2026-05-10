module Lich
  module Gemstone
    # Represents a disk in the game.
    # This class provides methods to identify and manage disks.
    # @example Creating a disk from a game object
    #   disk = Disk.new(game_object)
    class Disk
      # A list of nouns that represent different types of disks.
      NOUNS = %w{cassone chest coffer coffin coffret disk hamper saucer sphere trunk tureen}

      # Checks if the given object is a disk based on its name.
      # @param thing [Object] The object to check.
      # @return [Boolean] True if the object is a disk, false otherwise.
      # @example
      #   Disk.is_disk?(some_object)
      def self.is_disk?(thing)
        thing.name =~ /\b([A-Z][a-z]+) #{Regexp.union(NOUNS)}\b/
      end

      # Finds a disk by its name.
      # @param name [String] The name of the disk to find.
      # @return [Disk, nil] The found Disk object or nil if not found.
      # @example
      #   disk = Disk.find_by_name("golden disk")
      def self.find_by_name(name)
        disk = GameObj.loot.find do |item|
          is_disk?(item) && item.name.include?(name)
        end
        return nil if disk.nil?
        Disk.new(disk)
      end

      # Mines for a disk based on the character's name.
      # @return [Disk, nil] The found Disk object or nil if not found.
      # @example
      #   disk = Disk.mine
      def self.mine
        find_by_name(Char.name)
      end

      # Retrieves all disks from the game.
      # @return [Array<Disk>] An array of all Disk objects.
      # @example
      #   disks = Disk.all
      def self.all()
        (GameObj.loot || []).select do |item|
          is_disk?(item)
        end.map do |i|
          Disk.new(i)
        end
      end

      # The ID of the disk.
      # @return [String] The unique identifier for the disk.
      attr_reader :id, :name

      # Initializes a new Disk object from a game object.
      # @param obj [Object] The game object representing the disk.
      # @example
      #   disk = Disk.new(game_object)
      def initialize(obj)
        @id   = obj.id
        @name = obj.name.split(" ").find do |word|
          word[0].upcase.eql?(word[0])
        end
      end

      # Compares this disk with another disk for equality.
      # @param other [Object] The object to compare with.
      # @return [Boolean] True if the disks are equal, false otherwise.
      def ==(other)
        other.is_a?(Disk) && other.id == self.id
      end

      # Checks if this disk is equal to another disk.
      # @param other [Object] The object to compare with.
      # @return [Boolean] True if the disks are equal, false otherwise.
      def eql?(other)
        self == other
      end

      # Handles calls to methods that are not defined on this disk.
      # @param method [Symbol] The method name that was called.
      # @param args [Array] The arguments passed to the method.
      # @return [Object] The result of the method call on the underlying game object.
      def method_missing(method, *args)
        GameObj[@id].send(method, *args)
      end

      # Converts this disk to a container object.
      # @return [Container, GameObj] The container representation of the disk.
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
