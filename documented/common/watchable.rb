# frozen_string_literal: true

# Watchable module provides a common interface for self-watching modules
# that manage their own lifecycle through background threads.
#
# Modules that include Watchable must implement a .watch! class method
# that spawns a background thread to monitor conditions and trigger
# initialization when ready.
#
# Example:

# Lich module serves as a namespace for the Lich5 project.
#
# @see Lich::Common
module Lich
  module Common
    # Watchable module provides a common interface for self-watching modules
    # that manage their own lifecycle through background threads.
    #
    # Modules that include Watchable must implement a .watch! class method
    # that spawns a background thread to monitor conditions and trigger
    # initialization when ready.
    #
    # @see Lich::Common
    module Watchable
      # Raises a NotImplementedError if the .watch! method is not implemented.
      #
      # @raise [NotImplementedError] if the method is not implemented by the including module
      # @api private
      def watch!
        raise NotImplementedError, "#{self.name} must implement .watch! to use Watchable"
      end
    end
  end
end
