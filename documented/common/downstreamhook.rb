
module Lich
  module Common
    # Handles downstream hooks for processing server strings.
    #
    # This class allows adding, running, removing, and listing hooks that can modify
    # server strings as they are processed.
    class DownstreamHook
      @@downstream_hooks ||= Hash.new
      @@downstream_hook_sources ||= Hash.new

      # Adds a new downstream hook.
      #
      # @param name [String] the name of the hook
      # @param action [Proc] the action to be executed as a hook
      # @return [Boolean] true if the hook was added successfully, false otherwise
      def DownstreamHook.add(name, action)
        unless action.is_a?(Proc)
          echo "DownstreamHook: not a Proc (#{action})"
          return false
        end
        @@downstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@downstream_hooks[name] = action
      end

      # Executes all registered downstream hooks on the given server string.
      #
      # @param server_string [String] the server string to process
      # @return [String, nil] the modified server string or nil if the input was nil
      # @raise [StandardError] if an error occurs during hook execution
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
      #
      # @param name [String] the name of the hook to remove
      # @return [void]
      def DownstreamHook.remove(name)
        @@downstream_hook_sources.delete(name)
        @@downstream_hooks.delete(name)
      end

      # Lists all registered downstream hooks.
      #
      # @return [Array<String>] an array of hook names
      def DownstreamHook.list
        @@downstream_hooks.keys.dup
      end

      # Provides a table of sources for each downstream hook.
      #
      # @return [String] a formatted string representation of the hook sources
      def DownstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@downstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Retrieves the hash of downstream hook sources.
      #
      # @return [Hash] a hash mapping hook names to their sources
      def DownstreamHook.hook_sources
        @@downstream_hook_sources
      end
    end
  end
end
