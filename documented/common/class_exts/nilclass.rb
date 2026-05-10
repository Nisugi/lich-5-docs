
# Represents the NilClass, which is the class of the nil object.
# This class provides methods that return nil or behave as if they were called on nil.
#
# @see Object
class NilClass
  # Returns nil, as duplicating nil results in nil.
  # @return [nil]
  def dup
    nil
  end

  # Handles calls to methods that do not exist on nil, returning nil.
  # @param args [Array] the arguments passed to the missing method
  # @return [nil]
  def method_missing(*_args)
    nil
  end

  # Returns an empty array, as splitting nil results in no parts.
  # @param val [Array] the delimiter(s) to split by
  # @return [Array] an empty array
  def split(*_val)
    Array.new
  end

  # Returns an empty string, as nil is represented as an empty string.
  # @return [String] an empty string
  def to_s
    ""
  end

  # Returns an empty string, as stripping nil results in an empty string.
  # @return [String] an empty string
  def strip
    ""
  end

  # Returns the value passed to it, as adding nil to any value results in that value.
  # @param val [String, nil] the value to add to nil
  # @return [String, nil] the value passed in
  def +(val)
    val
  end

  # Returns true, indicating that nil is always considered closed.
  # @return [Boolean] true
  def closed?
    true
  end
end
