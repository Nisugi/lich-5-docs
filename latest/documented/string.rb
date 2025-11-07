# Carve out from lich.rbw
# extension to String class

# Extends the String class with additional functionality.
# This class adds methods to enhance string manipulation.
# @example Using the extended String class
#   my_string = 'Hello'.stream = 'my_stream'
class String
  # Returns a duplicate of the string.
  # @return [String] A duplicate of the original string.
  # @example
  #   'Hello'.to_s # => 'Hello'
  def to_s
    self.dup
  end

  # Retrieves the current stream value.
  # @return [Object] The current stream value.
  # @example
  #   my_string.stream # => 'my_stream'
  def stream
    @stream
  end

  # Sets the stream value if it hasn't been set already.
  # @param val [Object] The value to set as the stream.
  # @return [Object] The value of the stream after setting.
  # @example
  #   my_string.stream = 'new_stream'
  def stream=(val)
    @stream ||= val
  end

  #  def to_a # for compatibility with Ruby 1.8
  #    [self]
  #  end

  #  def silent
  #    false
  #  end

  #  def split_as_list
  #    string = self
  #    string.sub!(/^You (?:also see|notice) |^In the .+ you see /, ',')
  #    string.sub('.', '').sub(/ and (an?|some|the)/, ', \1').split(',').reject { |str| str.strip.empty? }.collect { |str| str.lstrip }
  #  end
end
