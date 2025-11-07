# extension to class Hash 2025-03-14

# Extension to the Hash class
# This class adds additional functionality to the built-in Hash class.
# @example Using the extended Hash methods
#   my_hash = Hash.new
#   Hash.put(my_hash, 'a.b.c', 42)
class Hash
  # Puts a value into a nested hash structure at the specified path.
  # @param target [Hash] The target hash to modify.
  # @param path [Array, String] The path where the value should be placed.
  # @param val [Object] The value to be inserted at the specified path.
  # @return [Hash] The original target hash.
  # @raise [ArgumentError] If the path is empty.
  # @example Inserting a value into a nested hash
  #   my_hash = {}
  #   Hash.put(my_hash, 'a.b.c', 42) # my_hash is now { 'a' => { 'b' => { 'c' => 42 } } }
  def self.put(target, path, val)
    path = [path] unless path.is_a?(Array)
    fail ArgumentError, "path cannot be empty" if path.empty?
    root = target
    path.slice(0..-2).each { |key| target = target[key] ||= {} }
    target[path.last] = val
    root
  end

  # Converts the hash to an OpenStruct object.
  # @return [OpenStruct] An OpenStruct representation of the hash.
  # @example Converting a hash to OpenStruct
  #   my_hash = { name: 'John', age: 30 }
  #   struct = my_hash.to_struct # struct.name => 'John', struct.age => 30
  def to_struct
    OpenStruct.new self
  end
end
