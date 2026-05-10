## hot module reloading
# Provides common functionality for the Lich project.
# @example Including the Common module
#   include Lich::Common
module Lich
  module Common
    # Handles hot module reloading functionality.
    # @example Using the HMR module
    #   Lich::Common::HMR.reload(/my_pattern/)
    module HMR
      # Clears the gem load paths cache.
      # @return [void]
      def self.clear_cache
        Gem.clear_paths
      end

      # Sends a message to the appropriate output.
      # @param message [String] The message to be sent.
      # @return [void]
      # @note If the message contains HTML, it will be handled differently.
      def self.msg(message)
        return _respond message if defined?(:_respond) && message.include?("<b>")
        return respond message if defined?(:respond)
        puts message
      end

      # Returns a list of loaded Ruby files.
      # @return [Array<String>] An array of loaded Ruby file paths.
      def self.loaded
        $LOADED_FEATURES.select { |path| path.end_with?(".rb") }
      end

      # Reloads files matching the given pattern.
      # @param pattern [Regexp] The regex pattern to match file paths.
      # @return [void]
      # @raise [LoadError] If a file fails to load.
      # @example Reloading files
      #   Lich::Common::HMR.reload(/my_pattern/)
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
