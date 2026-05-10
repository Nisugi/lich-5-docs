
# Represents a string object with additional functionality.
# @example Creating a string object
#   my_string = String.new("Hello, World!")
class String
  # Returns a string representation of the object.
  # @return [String] the string itself
  def to_s
    self.dup
  end

  # Returns the current stream associated with the string.
  # @return [Object] the current stream
  def stream
    @stream
  end

  # Sets the stream for the string if it hasn't been set already.
  # @param val [Object] the stream to set
  # @return [Object] the stream that was set
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
