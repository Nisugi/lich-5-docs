
# Represents a match data object that contains information about a regular expression match.
# @example Creating a match data object
#   match_data = /\d+/.match("123").to_struct
class MatchData
  # Converts the match data to an OpenStruct object.
  # @return [OpenStruct] An OpenStruct representation of the match data.
  # @example Converting to OpenStruct
  #   struct = match_data.to_struct
  def to_struct
    OpenStruct.new to_hash
  end

  # Converts the match data to a hash.
  # @return [Hash] A hash representation of the match data, with names as keys and captures as values.
  # @example Converting to hash
  #   hash = match_data.to_hash
  def to_hash
    self.names.zip(self.captures.map(&:strip).map do |capture|
      if capture.is_i? then capture.to_i else capture end
    end).to_h
  end
end
