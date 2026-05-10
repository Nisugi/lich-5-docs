
# Represents the result of a regular expression match.
#
# This class provides methods to access the captured groups and their names.
# @see Regexp
class MatchData
  # Converts the match data to an OpenStruct.
  # @return [OpenStruct] an OpenStruct representation of the match data.
  def to_struct
    OpenStruct.new to_hash
  end

  # Converts the match data to a hash.
  #
  # The hash keys are the names of the captures, and the values are the corresponding captures.
  # @return [Hash] a hash mapping capture names to their values.
  def to_hash
    self.names.zip(self.captures.map(&:strip).map do |capture|
      if capture.is_i? then capture.to_i else capture end
    end).to_h
  end
end
