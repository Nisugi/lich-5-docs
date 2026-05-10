
module Lich
  module Common
    # Handles downstream hooks for the Lich project.
    # This class allows adding, running, removing, and listing hooks.
    # @example Adding a hook
    #   DownstreamHook.add("example_hook", Proc.new { |input| input.upcase })
    class DownstreamHook
      @@downstream_hooks ||= Hash.new
      @@downstream_hook_sources ||= Hash.new

      # Adds a new downstream hook.
      # @param name [String] The name of the hook.
      # @param action [Proc] The action to be executed when the hook is triggered.
      # @return [Boolean] Returns true if the hook was added successfully, false otherwise.
      # @raise [StandardError] Raises an error if action is not a Proc.
      # @example Adding a hook
      #   DownstreamHook.add("example_hook", Proc.new { |input| input.upcase })
      def DownstreamHook.add(name, action)
        unless action.is_a?(Proc)
          echo "DownstreamHook: not a Proc (#{action})"
          return false
        end
        @@downstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@downstream_hooks[name] = action
      end

      # Runs all registered downstream hooks with the given server string.
      # @param server_string [String] The server string to be processed by the hooks.
      # @return [String, nil] Returns the modified server string or nil if the input is nil.
      # @raise [StandardError] Catches exceptions raised by hooks and removes them from the registry.
      # @example Running hooks
      #   modified_string = DownstreamHook.run("input string")
      def DownstreamHook.run(server_string)
        for key in @@downstream_hooks.keys
          return nil if server_string.nil?
          begin
            server_string = @@downstream_hooks[key].call(server_string.dup) if server_string.is_a?(String)
          rescue
            @@downstream_hooks.delete(key)
            respond "--- Lich: DownstreamHook: #{$!}"
            respond $!.backtrace.first
          end
        end
        return server_string
      end

      # Removes a downstream hook by name.
      # @param name [String] The name of the hook to be removed.
      # @return [void] Returns nothing.
      def DownstreamHook.remove(name)
        @@downstream_hook_sources.delete(name)
        @@downstream_hooks.delete(name)
      end

      # Lists all registered downstream hooks.
      # @return [Array<String>] An array of names of all registered hooks.
      # @example Listing hooks
      #   hooks = DownstreamHook.list
      def DownstreamHook.list
        @@downstream_hooks.keys.dup
      end

      # Provides a formatted table of hook sources.
      # @return [String] A string representation of the table showing hooks and their sources.
      # @example Getting hook sources
      #   sources = DownstreamHook.sources
      def DownstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@downstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Returns the hash of hook sources.
      # @return [Hash] A hash mapping hook names to their sources.
      def DownstreamHook.hook_sources
        @@downstream_hook_sources
      end
    end
  end
end
