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
    # Watchable module provides a common interface for self-watching modules.
    #
    # Modules that include Watchable must implement a .watch! class method
    # that spawns a background thread to monitor conditions and trigger
    # initialization when ready.
    #
    # @see Lich::Common
    module Watchable
      # Raises a NotImplementedError indicating that the including class must implement .watch!.
      #
      # @raise [NotImplementedError] if the including class does not implement .watch!
      def watch!
        raise NotImplementedError, "#{self.name} must implement .watch! to use Watchable"
      end
    end
  end
end
