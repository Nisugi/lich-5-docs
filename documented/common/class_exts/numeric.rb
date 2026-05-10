
# Represents a numeric value with additional time and formatting methods.
# @example Using Numeric methods
#   120.as_time # => "2:00:00"
#   1000.with_commas # => "1,000"
#   3600.ago # => Time.now - 3600 seconds
class Numeric
  # Converts the numeric value to a time string in "HH:MM:SS" format.
  # @return [String] The formatted time string.
  # @example
  #   3661.as_time # => "1:01:01"
  def as_time
    sprintf("%d:%02d:%02d", (self / 60).truncate, self.truncate % 60, ((self % 1) * 60).truncate)
  end

  # Formats the numeric value with commas as thousands separators.
  # @return [String] The numeric value as a string with commas.
  # @example
  #   1000000.with_commas # => "1,000,000"
  def with_commas
    self.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
  end

  # Returns the time that was the specified number of seconds ago.
  # @return [Time] The time object representing the past time.
  # @example
  #   3600.ago # => Time.now - 3600 seconds
  def ago
    Time.now - self
  end

  # Returns the numeric value as seconds.
  # @return [Numeric] The numeric value itself.
  # @example
  #   5.seconds # => 5
  def seconds
    return self
  end
  alias :second :seconds

  # Converts the numeric value to minutes.
  # @return [Numeric] The numeric value in seconds.
  # @example
  #   5.minutes # => 300
  def minutes
    return self * 60
  end
  alias :minute :minutes

  # Converts the numeric value to hours.
  # @return [Numeric] The numeric value in seconds.
  # @example
  #   2.hours # => 7200
  def hours
    return self * 3600
  end
  alias :hour :hours

  # Converts the numeric value to days.
  # @return [Numeric] The numeric value in seconds.
  # @example
  #   1.days # => 86400
  def days
    return self * 86400
  end
  alias :day :days
end
