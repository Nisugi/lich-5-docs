
module Lich
  module Common
    # Handles upstream hooks for the Lich project.
    # This class allows adding, running, removing, and listing hooks.
    # @example Adding a hook
    #   UpstreamHook.add("hook_name", Proc.new { |client| ... })
    class UpstreamHook
      @@upstream_hooks ||= Hash.new
      @@upstream_hook_sources ||= Hash.new

      # Adds a new upstream hook.
      # @param name [String] The name of the hook.
      # @param action [Proc] The action to be executed when the hook is triggered.
      # @return [Boolean] Returns true if the hook was added successfully, false otherwise.
      # @raise [StandardError] Raises an error if action is not a Proc.
      # @example Adding a hook
      #   UpstreamHook.add("example_hook", Proc.new { |client| ... })
      def UpstreamHook.add(name, action)
        unless action.is_a?(Proc)
          echo "UpstreamHook: not a Proc (#{action})"
          return false
        end
        @@upstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@upstream_hooks[name] = action
      end

      # Runs all registered upstream hooks in order.
      # @param client_string [String] The input string to be processed by the hooks.
      # @return [String, nil] Returns the processed string or nil if any hook returns nil.
      # @raise [StandardError] Catches exceptions from hook execution and logs them.
      def UpstreamHook.run(client_string)
        for key in @@upstream_hooks.keys
          begin
            client_string = @@upstream_hooks[key].call(client_string)
          rescue
            @@upstream_hooks.delete(key)
            respond "--- Lich: UpstreamHook: #{$!}"
            respond $!.backtrace.first
          end
          return nil if client_string.nil?
        end
        return client_string
      end

      # Removes an upstream hook by name.
      # @param name [String] The name of the hook to remove.
      # @return [void]
      def UpstreamHook.remove(name)
        @@upstream_hook_sources.delete(name)
        @@upstream_hooks.delete(name)
      end

      # Lists all registered upstream hooks.
      # @return [Array<String>] An array of hook names.
      def UpstreamHook.list
        @@upstream_hooks.keys.dup
      end

      # Provides a formatted table of hook sources.
      # @return [String] A string representation of the table showing hooks and their sources.
      def UpstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@upstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Returns a hash of upstream hook sources.
      # @return [Hash] A hash mapping hook names to their sources.
      def UpstreamHook.hook_sources
        @@upstream_hook_sources
      end
    end
  end
end
