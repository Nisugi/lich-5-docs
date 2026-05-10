## hot module reloading
module Lich
  module Common
    module HMR
      # Clears the gem cache.
      #
      # @return [void]
      def self.clear_cache
        Gem.clear_paths
      end

      # Sends a message to the console or responds if a response method is defined.
      #
      # @param message [String] the message to be displayed
      # @return [void]
      def self.msg(message)
        return _respond message if defined?(:_respond) && message.include?("<b>")
        return respond message if defined?(:respond)
        puts message
      end

      # Returns an array of loaded Ruby files.
      #
      # @return [Array<String>] an array of loaded Ruby file paths
      def self.loaded
        $LOADED_FEATURES.select { |path| path.end_with?(".rb") }
      end

      # Reloads files matching the given pattern after clearing the cache.
      #
      # @param pattern [Regexp] the pattern to match file paths
      # @return [void]
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
