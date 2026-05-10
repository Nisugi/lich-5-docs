module Lich
  module Common
    # Provides methods to manage user variables.
    # @example Using UserVars
    #   UserVars["name"] = "Alice"
    #   UserVars.list
    module UserVars
      # Returns a list of user variables.
      # @return [Array] The list of user variables.
      # @example Listing user variables
      #   UserVars.list
      def UserVars.list
        Vars.list
      end

      # Retrieves the value of a user variable by name.
      # @param name [String] The name of the user variable.
      # @return [Object] The value of the user variable.
      # @example Getting a user variable
      #   value = UserVars["name"]
      def UserVars.[](name)
        Vars[name]
      end

      # Sets the value of a user variable by name.
      # @param name [String] The name of the user variable.
      # @param val [Object] The value to set for the user variable.
      # @example Setting a user variable
      #   UserVars["name"] = "Alice"
      def UserVars.[]=(name, val)
        Vars[name] = val
      end

      # Handles calls to methods that are not defined.
      # @param method_name [Symbol] The name of the method called.
      # @param args [Array] The arguments passed to the method.
      # @return [Object] The result of the method call.
      # @example Calling a missing method
      #   UserVars.some_missing_method
      def UserVars.method_missing(method_name, *args)
        Vars.method_missing(method_name, *args)
      end

      # Checks if the object responds to a missing method.
      # @param method_name [Symbol] The name of the method.
      # @param include_private [Boolean] Whether to include private methods.
      # @return [Boolean] True if the method is handled, false otherwise.
      # @example Checking for a missing method
      #   UserVars.respond_to_missing?(:some_missing_method)
      def UserVars.respond_to_missing?(method_name, include_private = false)
        Vars.respond_to_missing?(method_name, include_private)
      end

      # Changes the value of a user variable.
      # @param var_name [String] The name of the user variable.
      # @param value [Object] The new value for the user variable.
      # @param _t [Object] An optional parameter (unused).
      # @example Changing a user variable
      #   UserVars.change("name", "Bob")
      def UserVars.change(var_name, value, _t = nil)
        Vars[var_name] = value
      end

      # Adds a value to a user variable, creating a list if necessary.
      # @param var_name [String] The name of the user variable.
      # @param value [Object] The value to add to the user variable.
      # @param _t [Object] An optional parameter (unused).
      # @example Adding to a user variable
      #   UserVars.add("tags", "new_tag")
      def UserVars.add(var_name, value, _t = nil)
        current = Vars[var_name]
        if current.nil? || current.empty?
          Vars[var_name] = value.to_s
        else
          Vars[var_name] = current.to_s.split(', ').push(value.to_s).join(', ')
        end
      end

      # Deletes a user variable by name.
      # @param var_name [String] The name of the user variable to delete.
      # @param _t [Object] An optional parameter (unused).
      # @example Deleting a user variable
      #   UserVars.delete("name")
      def UserVars.delete(var_name, _t = nil)
        Vars[var_name] = nil
      end

      # Returns an empty array for global user variables.
      # @return [Array] An empty array.
      # @example Listing global user variables
      #   UserVars.list_global
      def UserVars.list_global
        Array.new
      end

      # Returns a list of character-specific user variables.
      # @return [Array] The list of character user variables.
      # @example Listing character user variables
      #   UserVars.list_char
      def UserVars.list_char
        Vars.list
      end
    end
  end
end
