
module Lich
  module Common
    module GUI
      # Handles communication between tabs in the GUI.
      #
      # This class allows for registering and notifying callbacks
      # when data changes occur, facilitating updates across
      # different parts of the application.
      #
      # @see Lich::Common::GUI
      class TabCommunicator
        def initialize
          @data_change_callbacks = []
        end

        # Registers a callback to be invoked when data changes.
        #
        # @param callback [Proc] the callback to register
        # @return [void]
        def register_data_change_callback(callback)
          @data_change_callbacks << callback if callback.respond_to?(:call)
        end

        # Notifies all registered callbacks that data has changed.
        #
        # @param change_type [Symbol] the type of change (default: :general)
        # @param data [Hash] the data associated with the change (default: {})
        # @return [void]
        # @example
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

        # Unregisters a previously registered callback.
        #
        # @param callback [Proc] the callback to unregister
        # @return [void]
        def unregister_data_change_callback(callback)
          @data_change_callbacks.delete(callback)
        end

        # Clears all registered data change callbacks.
        #
        # @return [void]
        def clear_callbacks
          @data_change_callbacks.clear
        end
      end
    end
  end
end
