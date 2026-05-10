module Lich
  module Gemstone
    # Represents a disk item in the game.
    #
    # This class provides methods to identify, find, and manage disk objects.
    #
    # @see Lich::Gemstone
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
      # @return [Disk, nil] the Disk object if found, nil otherwise
      # @example
      #   disk = Disk.find_by_name("golden disk")
      #   puts disk.name if disk
      def self.find_by_name(name)
        disk = GameObj.loot.find do |item|
          is_disk?(item) && item.name.include?(name)
        end
        return nil if disk.nil?
        Disk.new(disk)
      end

      # Mines for a disk based on the character's name.
      # @return [Disk, nil] the Disk object if found, nil otherwise
      def self.mine
        find_by_name(Char.name)
      end

      # Retrieves all disk objects from the game.
      # @return [Array<Disk>] an array of all Disk objects
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

      # Compares this Disk object with another for equality.
      # @param other [Object] the object to compare
      # @return [Boolean] true if the objects are equal, false otherwise
      def ==(other)
        other.is_a?(Disk) && other.id == self.id
      end

      # Checks if this Disk object is equal to another.
      # @param other [Object] the object to compare
      # @return [Boolean] true if the objects are equal, false otherwise
      def eql?(other)
        self == other
      end

      # Handles calls to methods that are not defined on this Disk object.
      # @param method [Symbol] the name of the method being called
      # @param args [Array] the arguments passed to the method
      # @return [Object] the result of the method call on the underlying game object
      def method_missing(method, *args)
        GameObj[@id].send(method, *args)
      end

      # Converts this Disk object to a container object.
      # @return [Container, GameObj] the corresponding container object
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
