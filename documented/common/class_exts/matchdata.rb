
# Represents the result of a regular expression match.
#
# This class provides methods to access the captured groups and their names.
# @see #to_hash
# @see #to_struct
class MatchData
  # Converts the match data to an OpenStruct object.
  # @return [OpenStruct] an OpenStruct representation of the match data
  # @example Convert to OpenStruct
  #   match_data.to_struct
  def to_struct
    OpenStruct.new to_hash
  end

  # Converts the match data to a hash with named captures as keys.
  # @return [Hash] a hash mapping capture names to their values
  # @example Convert to hash
  #   match_data.to_hash
  def to_hash
    self.names.zip(self.captures.map(&:strip).map do |capture|
      if capture.is_i? then capture.to_i else capture end
    end).to_h
  end
end
