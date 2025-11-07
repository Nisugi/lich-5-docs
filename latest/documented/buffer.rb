# Carve out module Buffer
# 2024-06-13
# has rubocop error Lint/HashCompareByIdentity - cop disabled until reviewed

module Lich
  # Provides common functionality for the Lich project.
  # @example Including the Common module
  #   include Lich::Common
  module Common
    # Manages a buffer for handling streams of data.
    # This module provides methods to read from and write to a buffer, as well as manage stream states.
    # @example Using the Buffer module
    #   Lich::Common::Buffer.update(line, stream)
    #   line = Lich::Common::Buffer.gets
    module Buffer
      # Constant representing the stripped downstream stream type.
      DOWNSTREAM_STRIPPED = 1
      # Constant representing the raw downstream stream type.
      DOWNSTREAM_RAW      = 2
      # Constant representing the modified downstream stream type.
      DOWNSTREAM_MOD      = 4
      # Constant representing the upstream stream type.
      UPSTREAM            = 8
      # Constant representing the modified upstream stream type.
      UPSTREAM_MOD        = 16
      # Constant representing the script output stream type.
      SCRIPT_OUTPUT       = 32
      @@index             = Hash.new
      @@streams           = Hash.new
      @@mutex             = Mutex.new
      @@offset            = 0
      @@buffer            = Array.new
      @@max_size          = 3000
      # Reads a line from the buffer, blocking until a line is available.
      # @return [Line] The line read from the buffer.
      # @note This method blocks until a line is available.
      # @example Reading a line from the buffer
      #   line = Lich::Common::Buffer.gets
      def Buffer.gets
        thread_id = Thread.current.object_id
        if @@index[thread_id].nil?
          @@mutex.synchronize {
            @@index[thread_id] = (@@offset + @@buffer.length)
            @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
          }
        end
        line = nil
        loop {
          if (@@index[thread_id] - @@offset) >= @@buffer.length
            sleep 0.05 while ((@@index[thread_id] - @@offset) >= @@buffer.length)
          end
          @@mutex.synchronize {
            if @@index[thread_id] < @@offset
              @@index[thread_id] = @@offset
            end
            line = @@buffer[@@index[thread_id] - @@offset]
          }
          @@index[thread_id] += 1
          break if ((line.stream & @@streams[thread_id]) != 0)
        }
        return line
      end

      # Attempts to read a line from the buffer without blocking.
      # @return [Line, nil] The line read from the buffer or nil if no line is available.
      # @example Attempting to read a line from the buffer
      #   line = Lich::Common::Buffer.gets?
      def Buffer.gets?
        thread_id = Thread.current.object_id
        if @@index[thread_id].nil?
          @@mutex.synchronize {
            @@index[thread_id] = (@@offset + @@buffer.length)
            @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
          }
        end
        line = nil
        loop {
          if (@@index[thread_id] - @@offset) >= @@buffer.length
            return nil
          end

          @@mutex.synchronize {
            if @@index[thread_id] < @@offset
              @@index[thread_id] = @@offset
            end
            line = @@buffer[@@index[thread_id] - @@offset]
          }
          @@index[thread_id] += 1
          break if ((line.stream & @@streams[thread_id]) != 0)
        }
        return line
      end

      # Resets the buffer index for the current thread to the offset.
      # @return [Buffer] The Buffer instance for method chaining.
      # @example Rewinding the buffer
      #   Lich::Common::Buffer.rewind
      def Buffer.rewind
        thread_id = Thread.current.object_id
        @@index[thread_id] = @@offset
        @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
        return self
      end

      # Clears the buffer and returns all lines that match the current stream.
      # @return [Array<Line>] An array of lines that were cleared from the buffer.
      # @example Clearing the buffer
      #   lines = Lich::Common::Buffer.clear
      def Buffer.clear
        thread_id = Thread.current.object_id
        if @@index[thread_id].nil?
          @@mutex.synchronize {
            @@index[thread_id] = (@@offset + @@buffer.length)
            @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
          }
        end
        lines = Array.new
        loop {
          if (@@index[thread_id] - @@offset) >= @@buffer.length
            return lines
          end

          line = nil
          @@mutex.synchronize {
            if @@index[thread_id] < @@offset
              @@index[thread_id] = @@offset
            end
            line = @@buffer[@@index[thread_id] - @@offset]
          }
          @@index[thread_id] += 1
          lines.push(line) if ((line.stream & @@streams[thread_id]) != 0)
        }
        return lines
      end

      # Updates the buffer with a new line and an optional stream type.
      # @param line [Line] The line to add to the buffer.
      # @param stream [Integer, nil] The stream type for the line (optional).
      # @return [Buffer] The Buffer instance for method chaining.
      # @example Updating the buffer with a new line
      #   Lich::Common::Buffer.update(new_line, stream_type)
      def Buffer.update(line, stream = nil)
        @@mutex.synchronize {
          frozen_line = line.dup
          unless stream.nil?
            frozen_line.stream = stream
          end
          frozen_line.freeze
          @@buffer.push(frozen_line)
          while (@@buffer.length > @@max_size)
            @@buffer.shift
            @@offset += 1
          end
        }
        return self
      end

      # rubocop:disable Lint/HashCompareByIdentity
      # Retrieves the current stream type for the calling thread.
      # @return [Integer] The current stream type for the thread.
      # @example Getting the current stream type
      #   current_stream = Lich::Common::Buffer.streams
      def Buffer.streams
        @@streams[Thread.current.object_id]
      end

      # Sets the stream type for the calling thread.
      # @param val [Integer] The new stream type to set.
      # @return [nil] Returns nil if the value is invalid.
      # @raise [ArgumentError] If the provided value is not a valid stream type.
      # @example Setting the stream type
      #   Lich::Common::Buffer.streams = new_stream_type
      def Buffer.streams=(val)
        if (!val.is_a?(Integer)) or ((val & 63) == 0)
          respond "--- Lich: error: invalid streams value\n\t#{$!.caller[0..2].join("\n\t")}"
          return nil
        end
        @@streams[Thread.current.object_id] = val
      end

      # rubocop:enable Lint/HashCompareByIdentity
      # Cleans up the index and streams for threads that are no longer active.
      # @return [Buffer] The Buffer instance for method chaining.
      # @example Cleaning up the buffer
      #   Lich::Common::Buffer.cleanup
      def Buffer.cleanup
        @@index.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        @@streams.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        return self
      end
    end
  end
end
