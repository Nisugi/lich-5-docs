
# Provides a simple session variable storage mechanism.
#
# This module allows for storing and retrieving session variables using a hash.
#
# @see SessionVars.[]
# @see SessionVars.[]=
module SessionVars
  @@svars = Hash.new

  # Retrieves the value of a session variable by name.
  # @param name [String] the name of the session variable to retrieve
  # @return [Object, nil] the value of the session variable, or nil if not found
  def SessionVars.[](name)
    @@svars[name]
  end

  # Sets the value of a session variable by name.
  # If the value is nil, the session variable is deleted.
  # @param name [String] the name of the session variable to set
  # @param val [Object, nil] the value to assign to the session variable
  # @return [void]
  def SessionVars.[]=(name, val)
    if val.nil?
      @@svars.delete(name)
    else
      @@svars[name] = val
    end
  end

  # Returns a duplicate of the current session variables.
  # @return [Hash] a hash containing all session variables
  def SessionVars.list
    @@svars.dup
  end

  # Handles dynamic method calls for session variable access.
  # Allows for setting and getting session variables using method names.
  # @param arg1 [String] the method name called
  # @param arg2 [String, nil] the value to set if the method name ends with '='
  # @return [Object, nil] the value of the session variable, or nil if not found
  def SessionVars.method_missing(arg1, arg2 = '')
    if arg1[-1, 1] == '='
      if arg2.nil?
        @@svars.delete(arg1.to_s.chop)
      else
        @@svars[arg1.to_s.chop] = arg2
      end
    else
      @@svars[arg1.to_s]
    end
  end
end
