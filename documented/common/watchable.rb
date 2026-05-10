# frozen_string_literal: true

# Watchable module provides a common interface for self-watching modules
# that manage their own lifecycle through background threads.
#
# Modules that include Watchable must implement a .watch! class method
# that spawns a background thread to monitor conditions and trigger
# initialization when ready.
#
# Example:

# Lich module serves as a namespace for the project.
#
# This module contains common functionality and modules used throughout the Lich project.
module Lich
  module Common
    # Watchable module provides a common interface for self-watching modules.
    #
    # Modules that include Watchable must implement a .watch! class method
    # that spawns a background thread to monitor conditions and trigger
    # initialization when ready.
    # @example Including the Watchable module
    #   module MyModule
    #     include Lich::Common::Watchable
    #     def self.watch!
    #       # implementation here
    #     end
    #   end
    module Watchable
      # Raises a NotImplementedError if called directly.
      # This method must be implemented by any class that includes the Watchable module.
      # @raise [NotImplementedError] if the method is not implemented.
      # @example Implementing the watch! method
      #   def self.watch!
      #     # start monitoring
      #   end
      def watch!
        raise NotImplementedError, "#{self.name} must implement .watch! to use Watchable"
      end
    end
  end
end
