module Lich
  module Common
    module UserVars
      # Returns a list of user variables.
      #
      # @return [Array<String>] the list of user variables.
      # @see Vars.list
      def UserVars.list
        Vars.list
      end

      # Retrieves the value of a user variable by name.
      #
      # @param name [String] the name of the user variable.
      # @return [String, nil] the value of the user variable, or nil if not found.
      def UserVars.[](name)
        Vars[name]
      end

      # Sets the value of a user variable by name.
      #
      # @param name [String] the name of the user variable.
      # @param val [String] the value to set for the user variable.
      def UserVars.[]=(name, val)
        Vars[name] = val
      end

      # Handles calls to methods that are not defined in UserVars.
      #
      # @param method_name [Symbol] the name of the method being called.
      # @param args [Array] the arguments passed to the method.
      # @return [void]
      def UserVars.method_missing(method_name, *args)
        Vars.method_missing(method_name, *args)
      end

      # Checks if a method is available for the UserVars module.
      #
      # @param method_name [Symbol] the name of the method to check.
      # @param include_private [Boolean] whether to include private methods in the check.
      # @return [Boolean] true if the method is available, false otherwise.
      def UserVars.respond_to_missing?(method_name, include_private = false)
        Vars.respond_to_missing?(method_name, include_private)
      end

      # Changes the value of a user variable.
      #
      # @param var_name [String] the name of the user variable to change.
      # @param value [String] the new value for the user variable.
      def UserVars.change(var_name, value, _t = nil)
        Vars[var_name] = value
      end

      # Adds a value to a user variable, creating a comma-separated list if necessary.
      #
      # @param var_name [String] the name of the user variable to add to.
      # @param value [String] the value to add to the user variable.
      def UserVars.add(var_name, value, _t = nil)
        current = Vars[var_name]
        if current.nil? || current.empty?
          Vars[var_name] = value.to_s
        else
          Vars[var_name] = current.to_s.split(', ').push(value.to_s).join(', ')
        end
      end

      # Deletes a user variable by name.
      #
      # @param var_name [String] the name of the user variable to delete.
      def UserVars.delete(var_name, _t = nil)
        Vars[var_name] = nil
      end

      # Returns an empty array for global user variables.
      #
      # @return [Array] an empty array.
      def UserVars.list_global
        Array.new
      end

      # Returns a list of character-specific user variables.
      #
      # @return [Array<String>] the list of character-specific user variables.
      # @see Vars.list
      def UserVars.list_char
        Vars.list
      end
    end
  end
end
