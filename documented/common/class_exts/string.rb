
# Represents a string object with additional functionality.
#
# @see #to_s Standard string conversion method.
class String
  # Returns a string representation of the object.
  # @return [String] the string itself.
  def to_s
    self.dup
  end

  # Retrieves the current stream associated with the string.
  # @return [Object, nil] the current stream or nil if not set.
  def stream
    @stream
  end

  # Sets the stream for the string if it is not already set.
  # @param val [Object] the stream to associate with the string.
  # @return [Object] the stream that was set.
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
