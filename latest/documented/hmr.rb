## hot module reloading
# Provides common functionality for the Lich project
# This module serves as a namespace for common utilities.
module Lich
  module Common
    # Hot Module Reloading (HMR) functionality
    # This module provides methods to clear cache, reload modules, and send messages.
    # @example Reloading a module
    #   Lich::Common::HMR.reload(/my_module/)
    module HMR
      # Clears the gem load paths cache
      # @return [void] This method does not return a value.
      def self.clear_cache
        Gem.clear_paths
      end

      # Sends a message to the appropriate output
      # @param message [String] The message to be sent
      # @return [void] This method does not return a value.
      # @note If the message contains HTML tags, it will use the _respond method if defined.
      # @example Sending a message
      #   Lich::Common::HMR.msg('Hello, World!')
      def self.msg(message)
        return _respond message if defined?(:_respond) && message.include?("<b>")
        return respond message if defined?(:respond)
        puts message
      end

      # Retrieves a list of loaded Ruby files
      # @return [Array<String>] An array of paths to loaded Ruby files.
      def self.loaded
        $LOADED_FEATURES.select { |path| path.end_with?(".rb") }
      end

      # Reloads modules matching the given pattern
      # @param pattern [Regexp] The regex pattern to match loaded files
      # @return [void] This method does not return a value.
      # @raise [LoadError] If a file fails to load during the reload process.
      # @example Reloading files matching a pattern
      #   Lich::Common::HMR.reload(/my_module/)
      def self.reload(pattern)
        self.clear_cache
        loaded_paths = self.loaded.grep(pattern)
        unless loaded_paths.empty?
          loaded_paths.each { |file|
            begin
              load(file)
              self.msg "<b>[lich.hmr] reloaded %s</b>" % file
            rescue => exception
              self.msg exception
              self.msg exception.backtrace.join("\n")
            end
          }
        else
          self.msg "<b>[lich.hmr] nothing matching regex pattern: %s</b>" % pattern.source
        end
      end
    end
  end
end
