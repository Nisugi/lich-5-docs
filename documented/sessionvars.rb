
# Provides a way to manage session variables.
# This module allows for setting, getting, and listing session variables.
# @example Setting a session variable
#   SessionVars["user_id"] = 42
# @example Getting a session variable
#   user_id = SessionVars["user_id"]
module SessionVars
  @@svars = Hash.new

  # Retrieves the value of a session variable by name.
  # @param name [String] The name of the session variable to retrieve.
  # @return [Object, nil] The value of the session variable, or nil if not found.
  # @example
  #   value = SessionVars["user_id"]
  def SessionVars.[](name)
    @@svars[name]
  end

  # Sets the value of a session variable by name.
  # If the value is nil, the session variable is deleted.
  # @param name [String] The name of the session variable to set.
  # @param val [Object] The value to assign to the session variable.
  # @return [Object] The value that was set.
  # @example
  #   SessionVars["user_id"] = 42
  def SessionVars.[]=(name, val)
    if val.nil?
      @@svars.delete(name)
    else
      @@svars[name] = val
    end
  end

  # Returns a duplicate of the current session variables.
  # @return [Hash] A hash containing all session variables.
  def SessionVars.list
    @@svars.dup
  end

  # Handles calls to methods that are not defined in the module.
  # This allows for dynamic setting and getting of session variables.
  # @param arg1 [Symbol] The method name being called.
  # @param arg2 [Object] The value to set if the method name ends with '='.
  # @return [Object, nil] The value of the session variable, or nil if not found.
  # @example
  #   SessionVars.some_variable = 10
  #   value = SessionVars.some_variable
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
