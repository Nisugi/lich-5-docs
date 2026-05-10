# Carve out deprecated (?) functions
# 2024-06-13

$version = LICH_VERSION
$room_count = 0
$psinet = false
$stormfront = true

# Checks if the character can survive poison effects.
#
# @return [Boolean] always returns true as there is no XML for poison rate.
# @api private
def survivepoison?
  echo 'survivepoison? called, but there is no XML for poison rate'
  return true
end

# Checks if the character can survive disease effects.
#
# @return [Boolean] always returns true as there is no XML for disease rate.
# @api private
def survivedisease?
  echo 'survivepoison? called, but there is no XML for disease rate'
  return true
end

# Fetches loot from the game object and places it in the user's bag.
#
# @param userbagchoice [String] the name of the bag to store loot in (default is UserVars.lootsack).
# @return [Boolean] returns false if there is no loot to fetch, otherwise returns true.
def fetchloot(userbagchoice = UserVars.lootsack)
  if GameObj.loot.empty?
    return false
  end

  if UserVars.excludeloot.empty?
    regexpstr = nil
  else
    regexpstr = UserVars.excludeloot.split(', ').join('|')
  end
  if checkright and checkleft
    stowed = GameObj.right_hand.noun
    fput "put my #{stowed} in my #{UserVars.lootsack}"
  else
    stowed = nil
  end
  GameObj.loot.each { |loot|
    unless not regexpstr.nil? and loot.name =~ /#{regexpstr}/
      fput "get #{loot.noun}"
      fput("put my #{loot.noun} in my #{userbagchoice}") if (checkright || checkleft)
    end
  }
  if stowed
    fput "take my #{stowed} from my #{UserVars.lootsack}"
  end
end

# Takes specified items and places them in the user's bag.
#
# @param items [Array<String>] the items to take.
# @return [void]
def take(*items)
  items.flatten!
  if (righthand? && lefthand?)
    weap = checkright
    fput "put my #{checkright} in my #{UserVars.lootsack}"
    unsh = true
  else
    unsh = false
  end
  items.each { |trinket|
    fput "take #{trinket}"
    fput("put my #{trinket} in my #{UserVars.lootsack}") if (righthand? || lefthand?)
  }
  if unsh then fput("take my #{weap} from my #{UserVars.lootsack}") end
end


# Extends the String class to add additional utility methods.
#
# @see #to_a for converting a string to an array.
# @see #silent for checking if the string is silent.
class String
  # Converts the string to an array containing itself.
  #
  # @return [Array<String>] an array with the string as its only element.
  def to_a # for compatibility with Ruby 1.8
    [self]
  end

  # Checks if the string is considered silent.
  #
  # @return [Boolean] always returns false.
  def silent
    false
  end

  # Splits the string into a list based on specific delimiters.
  #
  # @return [Array<String>] an array of non-empty trimmed strings.
  def split_as_list
    string = self
    string.sub!(/^You (?:also see|notice) |^In the .+ you see /, ',')
    string.sub('.', '').sub(/ and (an?|some|the)/, ', \1').split(',').reject { |str| str.strip.empty? }.collect { |str| str.lstrip }
  end
end
