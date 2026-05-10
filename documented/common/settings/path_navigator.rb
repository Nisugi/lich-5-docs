
module Lich
  module Common
    # Manages navigation through a path structure in a database.
    #
    # This class provides methods to set, reset, and navigate through paths.
    #
    # @see Lich::Common
    class PathNavigator
      def initialize(db_adapter)
        @db_adapter = db_adapter
        @path = []
      end

      attr_reader :path

      # Sets the current path to the specified value.
      # @param new_path [Array<String>, String] the new path to set
      # @return [Array<String>] the updated path
      def set_path(new_path)
        @path = Array(new_path).dup
      end

      # Resets the current path to an empty array.
      # @return [void]
      def reset_path
        @path = []
      end

      # Resets the current path and returns the specified value.
      # @param value [Object] the value to return after resetting the path
      # @return [Object] the provided value
      def reset_path_and_return(value)
        reset_path
        value
      end

      # Navigates to a specified path within the database structure.
      # @param script_name [String] the name of the script to navigate
      # @param create_missing [Boolean] whether to create missing path elements (default: true)
      # @param scope [String] the scope for the navigation (default: ":")
      # @param path [Array<String>, nil] the path to navigate to (default: current path)
      # @return [Array<Object>] the target object at the end of the path and the root object
      def navigate_to_path(script_name, create_missing = true, scope = ":", path = nil)
        work_path = path ? Array(path) : @path
        root = @db_adapter.get_settings(script_name, scope)
        return [root, root] if work_path.empty?

        target = root
        work_path.each_with_index do |key, idx|
          next_key = work_path[idx + 1]

          if target.is_a?(Hash)
            if target.key?(key)
              target = target[key]
            elsif create_missing
              target[key] = next_key.is_a?(Integer) ? [] : {}
              target = target[key]
            else
              return [nil, root]
            end

          elsif target.is_a?(Array)
            unless key.is_a?(Integer) && key >= 0
              return [nil, root] unless create_missing
              raise ArgumentError, "Array index must be a non-negative Integer (got: #{key.inspect})"
            end

            if key >= target.length
              (target.length..key).each { target << nil }
            end

            if target[key].nil? && create_missing
              target[key] = next_key.is_a?(Integer) ? [] : {}
            end
            return [nil, root] if target[key].nil? && !create_missing
            target = target[key]

          else
            # Non-container encountered mid-path; only replace if allowed.
            return [nil, root] unless create_missing
            replacement = next_key.is_a?(Integer) ? [] : {}
            target = replacement
          end
        end

        [target, root]
      end
    end
  end
end
