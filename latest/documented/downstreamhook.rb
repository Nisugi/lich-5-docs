# Carve out from lich.rbw
# class DownstreamHook 2024-06-13

module Lich
  module Common
    # Handles downstream hooks for processing server strings.
    # This class allows adding, running, removing, and listing hooks that can modify server strings.
    # @example Adding a hook
    #   DownstreamHook.add(:my_hook, Proc.new { |str| str.upcase })
    class DownstreamHook
      # A hash storing all downstream hooks by name.
      @@downstream_hooks ||= Hash.new
      # A hash storing the sources of each downstream hook.
      @@downstream_hook_sources ||= Hash.new

      # Adds a new downstream hook.
      # @param name [Symbol] The name of the hook.
      # @param action [Proc] The action to be executed as a hook.
      # @return [Boolean] Returns true if the hook was added successfully, false otherwise.
      # @raise [ArgumentError] Raises an error if action is not a Proc.
      # @example Adding a hook
      #   DownstreamHook.add(:my_hook, Proc.new { |str| str.upcase })
      def DownstreamHook.add(name, action)
        unless action.is_a?(Proc)
          echo "DownstreamHook: not a Proc (#{action})"
          return false
        end
        @@downstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@downstream_hooks[name] = action
      end

      # Runs all registered downstream hooks on the given server string.
      # @param server_string [String] The server string to process.
      # @return [String, nil] Returns the modified server string or nil if the input is nil.
      # @raise [StandardError] Catches exceptions raised during hook execution and removes the faulty hook.
      # @example Running hooks
      #   modified_string = DownstreamHook.run(server_string)
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
      # @param name [Symbol] The name of the hook to remove.
      # @return [void] This method does not return a value.
      # @example Removing a hook
      #   DownstreamHook.remove(:my_hook)
      def DownstreamHook.remove(name)
        @@downstream_hook_sources.delete(name)
        @@downstream_hooks.delete(name)
      end

      # Lists all registered downstream hooks.
      # @return [Array<Symbol>] An array of names of all registered hooks.
      # @example Listing hooks
      #   hooks = DownstreamHook.list
      def DownstreamHook.list
        @@downstream_hooks.keys.dup
      end

      # Displays a table of hook names and their sources.
      # @return [String] A formatted string representation of the hook sources.
      # @example Displaying hook sources
      #   puts DownstreamHook.sources
      def DownstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@downstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Retrieves the hash of hook sources.
      # @return [Hash<Symbol, String>] A hash mapping hook names to their sources.
      # @example Getting hook sources
      #   sources = DownstreamHook.hook_sources
      def DownstreamHook.hook_sources
        @@downstream_hook_sources
      end
    end
  end
end
