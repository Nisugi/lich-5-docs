
# Represents a collection of key-value pairs.
#
# @see #put Adds a value to the hash at a specified path.
class Hash
  # Adds a value to the hash at the specified path.
  #
  # @param target [Hash] the hash to modify
  # @param path [Array<String>, String] the path where the value should be added
  # @param val [Object] the value to add at the specified path
  # @return [Hash] the modified hash
  # @raise [ArgumentError] if path is empty
  # @example Add a value to a nested hash
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

  # Converts the hash to an OpenStruct.
  #
  # @return [OpenStruct] an OpenStruct representation of the hash.
  def to_struct
    OpenStruct.new self
  end
end
