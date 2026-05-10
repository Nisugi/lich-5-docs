# frozen_string_literal: true

=begin
  Atomic file writing utilities for the update system.

  Provides safe_write (tmp-rename-delete pattern) and SHA map building
  for detecting file changes.
=end

# Provides utility methods for the Lich update system.
#
# @see Lich::Util
# @see Lich::Util::Update
module Lich
  module Util
    module Update
      module FileWriter
        # Safely writes content to a file using a temporary rename-delete pattern.
        #
        # @param path [String] the path to the file to write
        # @param content [String] the content to write to the file
        # @return [void]
        # @raise [StandardError] if the write operation fails
        def self.safe_write(path, content)
          tmp = "#{path}.tmp"
          old = "#{path}.old"
          File.rename(path, old) if File.exist?(path)
          begin
            File.binwrite(tmp, content)
            File.rename(tmp, path)
          rescue StandardError
            File.rename(old, path) if File.exist?(old)
            File.delete(tmp) if File.exist?(tmp)
            raise
          end
          File.delete(old) if File.exist?(old)
        end

        # Builds a SHA1 hash map for files in a directory matching a given pattern.
        #
        # @param dir [String] the directory to scan for files
        # @param pattern [String] the pattern to match files (default is '*.lic')
        # @return [Hash] a hash mapping file names to their SHA1 hashes
        # @example
        #   sha_map = Lich::Util::Update::FileWriter.build_local_sha_map("/path/to/dir")
        def self.build_local_sha_map(dir, pattern = '*.lic')
          Dir[File.join(dir, pattern)].each_with_object({}) do |path, map|
            body = File.binread(path)
            map[File.basename(path)] = Digest::SHA1.hexdigest("blob #{body.size}\0#{body}")
          end
        end
      end
    end
  end
end
