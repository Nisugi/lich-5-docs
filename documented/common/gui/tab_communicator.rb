
module Lich
  module Common
    module GUI
      # Handles communication for tab data changes.
      # This class allows for registering callbacks that are invoked when data changes occur.
      # @example Creating a TabCommunicator and registering a callback
      #   communicator = Lich::Common::GUI::TabCommunicator.new
      #   communicator.register_data_change_callback(lambda { |change_type, data| puts "Data changed: #{change_type}, #{data}" })
      class TabCommunicator
        def initialize
          @data_change_callbacks = []
        end

        # Registers a callback to be invoked when data changes.
        # @param callback [Proc] The callback to be invoked on data change.
        # @return [void]
        def register_data_change_callback(callback)
          @data_change_callbacks << callback if callback.respond_to?(:call)
        end

        # Notifies all registered callbacks that data has changed.
        # @param change_type [Symbol] The type of change that occurred (default: :general).
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

        # Unregisters a previously registered callback.
        # @param callback [Proc] The callback to be removed.
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
