
# Represents a numeric value with additional time-related methods.
#
# @see #as_time
# @see #with_commas
# @see #ago
# @see #seconds
# @see #minutes
# @see #hours
# @see #days
class Numeric
  # Converts the numeric value to a time string in "HH:MM:SS" format.
  # @return [String] formatted time string
  # @example Convert 3661 seconds to time
  #   3661.as_time # => "1:01:01"
  def as_time
    sprintf("%d:%02d:%02d", (self / 60).truncate, self.truncate % 60, ((self % 1) * 60).truncate)
  end

  # Formats the numeric value with commas for thousands.
  # @return [String] formatted number with commas
  # @example Format a large number
  #   1234567.with_commas # => "1,234,567"
  def with_commas
    self.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
  end

  # Returns the time that was the given number of seconds ago from now.
  # @return [Time] the time in the past
  # @example Get the time 60 seconds ago
  #   60.ago # => Time.now - 60
  def ago
    Time.now - self
  end

  # Returns the numeric value as seconds.
  # @return [Integer] the numeric value in seconds
  def seconds
    return self
  end
  alias :second :seconds

  # Returns the numeric value converted to minutes.
  # @return [Integer] the numeric value in minutes
  def minutes
    return self * 60
  end
  alias :minute :minutes

  # Returns the numeric value converted to hours.
  # @return [Integer] the numeric value in hours
  def hours
    return self * 3600
  end
  alias :hour :hours

  # Returns the numeric value converted to days.
  # @return [Integer] the numeric value in days
  def days
    return self * 86400
  end
  alias :day :days
end
