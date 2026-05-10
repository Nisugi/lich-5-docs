
module Lich
  module Common
    module GUI
      # Handles communication for tabs in the GUI.
      # This class allows for registering and notifying data change callbacks.
      # @example Creating a TabCommunicator instance
      #   communicator = Lich::Common::GUI::TabCommunicator.new
      class TabCommunicator
        # Initializes a new TabCommunicator instance.
        # @return [TabCommunicator]
        def initialize
          @data_change_callbacks = []
        end

        # Registers a callback to be notified when data changes.
        # @param callback [Proc] The callback to register.
        # @return [void]
        # @note Callbacks must respond to :call.
        def register_data_change_callback(callback)
          @data_change_callbacks << callback if callback.respond_to?(:call)
        end

        # Notifies all registered callbacks that data has changed.
        # @param change_type [Symbol] The type of change (default: :general).
        # @param data [Hash] The data associated with the change (default: {}).
        # @return [void]
        # @raise [StandardError] If an error occurs during callback execution.
        # @example Notifying data change
        #   communicator.notify_data_changed(:update, { key: "value" })
        def notify_data_changed(change_type = :general, data = {})
          @data_change_callbacks.each do |callback|
            begin
              callback.call(change_type, data)
            rescue StandardError => e
              Lich.log "error: Error in data change callback: #{e.message}"
            end
          end
        end

        # Unregisters a previously registered data change callback.
        # @param callback [Proc] The callback to unregister.
        # @return [void]
        def unregister_data_change_callback(callback)
          @data_change_callbacks.delete(callback)
        end

        # Clears all registered data change callbacks.
        # @return [void]
        def clear_callbacks
          @data_change_callbacks.clear
        end
      end
    end
  end
end
