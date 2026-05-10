## hot module reloading
# Provides common functionality for the Lich project.
#
# @see Lich::Common
module Lich
  module Common
    module HMR
      # Clears the gem load paths cache.
      # @return [void]
      def self.clear_cache
        Gem.clear_paths
      end

      # Sends a message to the appropriate output.
      #
      # If the message contains HTML, it will be handled by the _respond method if defined.
      # @param message [String] the message to be sent
      # @return [void]
      def self.msg(message)
        return _respond message if defined?(:_respond) && message.include?("<b>")
        return respond message if defined?(:respond)
        puts message
      end

      # Returns an array of loaded Ruby files.
      # @return [Array<String>] list of loaded Ruby file paths
      def self.loaded
        $LOADED_FEATURES.select { |path| path.end_with?(".rb") }
      end

      # Reloads files matching the given pattern.
      #
      # This method clears the cache and reloads all files that match the provided regex pattern.
      # @param pattern [Regexp] the pattern to match file paths
      # @return [void]
      # @raise [LoadError] if a file cannot be loaded
      def self.reload(pattern)
        self.clear_cache
        loaded_paths = self.loaded.grep(pattern)
        unless loaded_paths.empty?
          loaded_paths.each { |file|
            begin
              load(file)
              self.msg "<b>[lich.hmr] reloaded %s</b>" % file
            rescue => exception
              self.msg exception.message
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
