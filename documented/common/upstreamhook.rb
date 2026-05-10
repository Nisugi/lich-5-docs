
module Lich
  module Common
    # Handles upstream hooks for the Lich project.
    #
    # This class allows adding, running, removing, and listing hooks that can modify client strings.
    class UpstreamHook
      @@upstream_hooks ||= Hash.new
      @@upstream_hook_sources ||= Hash.new

      # Adds a new upstream hook.
      #
      # @param name [String] the name of the hook
      # @param action [Proc] the action to be executed for the hook
      # @return [Boolean] true if the hook was added successfully, false otherwise
      # @example Add a hook
      #   UpstreamHook.add("example_hook", Proc.new { |client_string| client_string.upcase })
      def UpstreamHook.add(name, action)
        unless action.is_a?(Proc)
          echo "UpstreamHook: not a Proc (#{action})"
          return false
        end
        @@upstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@upstream_hooks[name] = action
      end

      # Executes all registered upstream hooks in order.
      #
      # @param client_string [String] the string to be modified by the hooks
      # @return [String, nil] the modified string or nil if an error occurred
      # @raise [StandardError] if a hook raises an error during execution
      # @example Run hooks on a client string
      #   modified_string = UpstreamHook.run("input string")
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
      #
      # @param name [String] the name of the hook to remove
      # @return [void]
      def UpstreamHook.remove(name)
        @@upstream_hook_sources.delete(name)
        @@upstream_hooks.delete(name)
      end

      # Lists all registered upstream hooks.
      #
      # @return [Array<String>] an array of hook names
      def UpstreamHook.list
        @@upstream_hooks.keys.dup
      end

      # Provides a formatted table of upstream hook sources.
      #
      # @return [String] a string representation of the sources in a table format
      def UpstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@upstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Returns a hash of upstream hook sources.
      #
      # @return [Hash] a hash mapping hook names to their sources
      def UpstreamHook.hook_sources
        @@upstream_hook_sources
      end
    end
  end
end
