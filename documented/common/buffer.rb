
module Lich
  module Common
    module Buffer
      # Represents the downstream stripped stream constant
      DOWNSTREAM_STRIPPED = 1
      # Represents the downstream raw stream constant
      DOWNSTREAM_RAW      = 2
      # Represents the downstream modified stream constant
      DOWNSTREAM_MOD      = 4
      # Represents the upstream stream constant
      UPSTREAM            = 8
      # Represents the upstream modified stream constant
      UPSTREAM_MOD        = 16
      # Represents the script output stream constant
      SCRIPT_OUTPUT       = 32
      @@index             = Hash.new
      @@streams           = Hash.new
      @@mutex             = Mutex.new
      @@offset            = 0
      @@buffer            = Array.new
      @@max_size          = 3000
      # Retrieves the next line from the buffer, blocking if necessary.
      # @return [Line] The next line from the buffer, or nil if no line is available.
      # @note This method blocks until a line is available.
      # @example Retrieving a line from the buffer
      #   line = Buffer.gets
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

      # Retrieves the next line from the buffer, returning nil if no line is available.
      # @return [Line, nil] The next line from the buffer, or nil if no line is available.
      # @example Attempting to retrieve a line from the buffer
      #   line = Buffer.gets?
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
      # @return [Buffer] The Buffer instance itself.
      def Buffer.rewind
        thread_id = Thread.current.object_id
        @@index[thread_id] = @@offset
        @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
        return self
      end

      # Clears the lines from the buffer for the current thread.
      # @return [Array<Line>] An array of lines that were cleared from the buffer.
      # @example Clearing lines from the buffer
      #   cleared_lines = Buffer.clear
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

      # Updates the buffer with a new line, optionally setting its stream.
      # @param line [Line] The line to add to the buffer.
      # @param stream [Integer, nil] The stream identifier for the line.
      # @return [Buffer] The Buffer instance itself.
      # @example Updating the buffer with a new line
      #   Buffer.update(new_line, stream_id)
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
      # Retrieves the current stream value for the calling thread.
      # @return [Integer] The current stream value for the thread.
      def Buffer.streams
        @@streams[Thread.current.object_id]
      end

      # Sets the stream value for the calling thread.
      # @param val [Integer] The new stream value to set.
      # @raise [StandardError] If the provided value is invalid.
      def Buffer.streams=(val)
        if (!val.is_a?(Integer)) or ((val & 63) == 0)
          respond "--- Lich: error: invalid streams value\n\t#{$!.caller[0..2].join("\n\t")}"
        else
          @@streams[Thread.current.object_id] = val
        end
      end

      # rubocop:enable Lint/HashCompareByIdentity
      # Cleans up the index and streams for threads that are no longer active.
      # @return [Buffer] The Buffer instance itself.
      def Buffer.cleanup
        @@index.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        @@streams.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        return self
      end
    end
  end
end
