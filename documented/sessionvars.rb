
# Provides a way to manage session variables.
#
# This module allows for dynamic access to session variables using a hash.
# @see SessionVars.[]
# @see SessionVars.[]=
module SessionVars
  @@svars = Hash.new

  # Retrieves the value of a session variable by name.
  # @param name [String] the name of the session variable to retrieve
  # @return [String, nil] the value of the session variable, or nil if not found
  def SessionVars.[](name)
    @@svars[name]
  end

  # Sets the value of a session variable by name.
  # @param name [String] the name of the session variable to set
  # @param val [String, nil] the value to set, or nil to delete the variable
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
  # This allows for setting and getting session variables using method names.
  # @param arg1 [String] the name of the session variable
  # @param arg2 [String, nil] the value to set, if applicable
  # @return [String, nil] the value of the session variable, or nil if not found
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
