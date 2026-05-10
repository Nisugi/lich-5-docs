
# Represents the NilClass, which is the class of the nil object.
# This class provides methods that return nil or behave as if nil.
# @example Using NilClass methods
#   nil.dup # => nil
#   nil.to_s # => ""
class NilClass
  # Returns a duplicate of the nil object.
  # @return [NilClass] Always returns nil.
  # @example
  #   nil.dup # => nil
  def dup
    nil
  end

  # Handles calls to methods that do not exist on nil.
  # @param args [Array] The arguments passed to the missing method.
  # @return [NilClass] Always returns nil.
  # @example
  #   nil.some_method # => nil
  def method_missing(*_args)
    nil
  end

  # Splits the nil object into an array.
  # @param val [Array] The delimiter(s) to split by (not used).
  # @return [Array] Returns an empty array.
  # @example
  #   nil.split # => []
  def split(*_val)
    Array.new
  end

  # Converts the nil object to a string.
  # @return [String] Returns an empty string.
  # @example
  #   nil.to_s # => ""
  def to_s
    ""
  end

  # Strips whitespace from the nil object.
  # @return [String] Returns an empty string.
  # @example
  #   nil.strip # => ""
  def strip
    ""
  end

  # Adds the nil object to another value.
  # @param val [Object] The value to add to nil.
  # @return [Object] Returns the other value.
  # @example
  #   nil + 5 # => 5
  def +(val)
    val
  end

  # Checks if the nil object is closed.
  # @return [Boolean] Always returns true.
  # @example
  #   nil.closed? # => true
  def closed?
    true
  end
end
