module Lich
  module Gemstone
    # Represents a disk in the game.
    # This class provides methods to identify, find, and manage disks.
    # @example Finding a disk by name
    #   disk = Disk.find_by_name('golden disk')
    class Disk
      # List of nouns that represent different types of disks.
      NOUNS = %w{cassone chest coffer coffin coffret disk hamper saucer sphere trunk tureen}

      # Checks if the given object is a disk.
      # @param thing [Object] The object to check.
      # @return [Boolean] Returns true if the object is a disk, false otherwise.
      # @example Checking if an object is a disk
      #   Disk.is_disk?(some_object)
      def self.is_disk?(thing)
        thing.name =~ /\b([A-Z][a-z]+) #{Regexp.union(NOUNS)}\b/
      end

      # Finds a disk by its name.
      # @param name [String] The name of the disk to find.
      # @return [Disk, nil] Returns a Disk object if found, nil otherwise.
      # @example Finding a disk by name
      #   disk = Disk.find_by_name('golden disk')
      def self.find_by_name(name)
        disk = GameObj.loot.find do |item|
          is_disk?(item) && item.name.include?(name)
        end
        return nil if disk.nil?
        Disk.new(disk)
      end

      # Mines the disk associated with the current character.
      # @return [Disk, nil] Returns the Disk object if found, nil otherwise.
      # @example Mining the current character's disk
      #   disk = Disk.mine
      def self.mine
        find_by_name(Char.name)
      end

      # Retrieves all disks available in the game.
      # @return [Array<Disk>] An array of Disk objects.
      # @example Getting all disks
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

      # Initializes a new Disk object.
      # @param obj [Object] The object representing the disk.
      # @return [Disk] A new Disk instance.
      def initialize(obj)
        @id   = obj.id
        @name = obj.name.split(" ").find do |word|
          word[0].upcase.eql?(word[0])
        end
      end

      # Compares this disk with another disk for equality.
      # @param other [Object] The object to compare with.
      # @return [Boolean] Returns true if both disks are equal, false otherwise.
      def ==(other)
        other.is_a?(Disk) && other.id == self.id
      end

      # Checks if this disk is equal to another disk.
      # @param other [Object] The object to compare with.
      # @return [Boolean] Returns true if both disks are equal, false otherwise.
      def eql?(other)
        self == other
      end

      # Handles missing methods by delegating to the underlying GameObj.
      # @param method [Symbol] The method name that was called.
      # @param args [Array] The arguments passed to the method.
      # @return [Object] The result of the method call on the GameObj.
      def method_missing(method, *args)
        GameObj[@id].send(method, *args)
      end

      # Converts the disk to a container object.
      # @return [Container, GameObj] Returns a Container if defined, otherwise returns the GameObj.
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
