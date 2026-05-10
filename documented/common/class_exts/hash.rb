
# Represents a collection of key-value pairs.
# This class extends the functionality of the standard Hash.
# @example Creating a new Hash
#   my_hash = Hash.new
class Hash
  # Inserts a value into a nested hash structure at the specified path.
  # @param target [Hash] The target hash to modify.
  # @param path [Array, String] The path where the value should be inserted.
  # @param val [Object] The value to insert into the hash.
  # @return [Hash] The modified target hash.
  # @raise [ArgumentError] If the path is empty.
  # @example Inserting a value into a nested hash
  #   my_hash = {}
  #   Hash.put(my_hash, "a.b.c", 42)
  #   # my_hash now is {"a" => {"b" => {"c" => 42}}}
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
  #   my_hash = {name: "John", age: 30}
  #   struct = my_hash.to_struct
  #   # struct.name returns "John"
  def to_struct
    OpenStruct.new self
  end
end
