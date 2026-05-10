
# Represents the NilClass, which is the class of the nil object.
#
# This class provides methods that return nil or behave as if they are nil.
# @see Object
class NilClass
  # Returns a duplicate of the nil object.
  # @return [nil]
  def dup
    nil
  end

  # Handles calls to methods that do not exist on the nil object.
  # @param args [Array] the arguments passed to the missing method
  # @return [nil]
  def method_missing(*_args)
    nil
  end

  # Splits the nil object into an array.
  # @param val [Array] the delimiter(s) to split by
  # @return [Array] an empty array
  def split(*_val)
    Array.new
  end

  # Converts the nil object to a string.
  # @return [String] an empty string
  def to_s
    ""
  end

  # Removes whitespace from the nil object.
  # @return [String] an empty string
  def strip
    ""
  end

  # Adds the nil object to another value.
  # @param val [Object] the value to add
  # @return [Object] the value passed in
  def +(val)
    val
  end

  # Checks if the nil object is considered closed.
  # @return [Boolean] always returns true
  def closed?
    true
  end
end
