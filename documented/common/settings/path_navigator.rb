
module Lich
  module Common
    # Manages navigation through a path structure in a database.
    # This class provides methods to set, reset, and navigate paths.
    # @example Creating a PathNavigator instance
    #   navigator = Lich::Common::PathNavigator.new(db_adapter)
    class PathNavigator
      # Initializes a new PathNavigator instance.
      # @param db_adapter [Object] The database adapter used for retrieving settings.
      def initialize(db_adapter)
        @db_adapter = db_adapter
        @path = []
      end

      # The current path being navigated.
      # @return [Array] The current path.
      attr_reader :path

      # Sets the current path to a new value.
      # @param new_path [Array, Object] The new path to set.
      # @return [Array] The newly set path.
      def set_path(new_path)
        @path = Array(new_path).dup
      end

      # Resets the current path to an empty array.
      # @return [Array] The reset path (empty).
      def reset_path
        @path = []
      end

      # Resets the current path and returns a specified value.
      # @param value [Object] The value to return after resetting the path.
      # @return [Object] The provided value.
      def reset_path_and_return(value)
        reset_path
        value
      end

      # Navigates to a specified path based on the script name and scope.
      # @param script_name [String] The name of the script to navigate.
      # @param create_missing [Boolean] Whether to create missing path elements (default: true).
      # @param scope [String] The scope for the navigation (default: ":").
      # @param path [Array, nil] The path to navigate to (default: nil).
      # @return [Array] An array containing the target and root elements.
      # @raise ArgumentError if an invalid array index is encountered.
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
