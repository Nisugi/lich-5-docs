
# Represents a collection of key-value pairs.
#
# This class extends the functionality of the standard Hash in Ruby.
class Hash
  # Inserts a value into a nested hash structure at the specified path.
  #
  # @param target [Hash] the hash to modify
  # @param path [Array<String>, String] the path to the key where the value should be inserted
  # @param val [Object] the value to insert
  # @return [Hash] the modified hash
  # @raise [ArgumentError] if path is empty
  def self.put(target, path, val)
    path = [path] unless path.is_a?(Array)
    fail ArgumentError, "path cannot be empty" if path.empty?
    root = target
    path.slice(0..-2).each { |key| target = target[key] ||= {} }
    target[path.last] = val
    root
  end

  # Converts the hash to an OpenStruct object.
  # @return [OpenStruct] an OpenStruct representation of the hash
  def to_struct
    OpenStruct.new self
  end
end
