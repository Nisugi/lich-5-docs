
# Represents a numeric value with additional utility methods.
#
# This class extends the functionality of the Numeric class in Ruby.
class Numeric
  # Converts the numeric value to a time string in "HH:MM:SS" format.
  # @return [String] formatted time string
  # @example
  #   3661.as_time #=> "1:01:01"
  def as_time
    sprintf("%d:%02d:%02d", (self / 60).truncate, self.truncate % 60, ((self % 1) * 60).truncate)
  end

  # Converts the numeric value to a string with commas as thousands separators.
  # @return [String] string representation with commas
  # @example
  #   1000000.with_commas #=> "1,000,000"
  def with_commas
    self.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
  end

  # Returns the time that was the specified number of seconds ago from now.
  # @return [Time] time in the past
  # @example
  #   60.ago #=> Time.now - 60
  def ago
    Time.now - self
  end

  # Returns the numeric value as seconds.
  # @return [Integer] the numeric value itself
  # @api private
  def seconds
    return self
  end
  alias :second :seconds

  # Converts the numeric value to minutes.
  # @return [Integer] the numeric value in seconds
  # @example
  #   5.minutes #=> 300
  def minutes
    return self * 60
  end
  alias :minute :minutes

  # Converts the numeric value to hours.
  # @return [Integer] the numeric value in seconds
  # @example
  #   2.hours #=> 7200
  def hours
    return self * 3600
  end
  alias :hour :hours

  # Converts the numeric value to days.
  # @return [Integer] the numeric value in seconds
  # @example
  #   1.days #=> 86400
  def days
    return self * 86400
  end
  alias :day :days
end
