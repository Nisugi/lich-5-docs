
module Lich
  module Common
    module Buffer
      # Represents the downstream stripped mode.
      #
      # @see Buffer#streams
      DOWNSTREAM_STRIPPED = 1
      # Represents the downstream raw mode.
      #
      # @see Buffer#streams
      DOWNSTREAM_RAW      = 2
      # Represents the downstream modified mode.
      #
      # @see Buffer#streams
      DOWNSTREAM_MOD      = 4
      # Represents the upstream mode.
      #
      # @see Buffer#streams
      UPSTREAM            = 8
      # Represents the upstream modified mode.
      #
      # @see Buffer#streams
      UPSTREAM_MOD        = 16
      # Represents the script output mode.
      #
      # @see Buffer#streams
      SCRIPT_OUTPUT       = 32
      @@index             = Hash.new
      @@streams           = Hash.new
      @@mutex             = Mutex.new
      @@offset            = 0
      @@buffer            = Array.new
      @@max_size          = 3000
      # Reads a line from the buffer, blocking until a line is available.
      # @return [Line] the line read from the buffer, or nil if no line is available
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
      # @return [Line, nil] the line read from the buffer, or nil if no line is available
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
      # @return [Buffer] self
      def Buffer.rewind
        thread_id = Thread.current.object_id
        @@index[thread_id] = @@offset
        @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
        return self
      end

      # Clears the lines from the buffer for the current thread.
      # @return [Array<Line>] the lines that were cleared from the buffer
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
      # @param line [Line] the line to add to the buffer
      # @param stream [Integer, nil] the stream identifier for the line
      # @return [Buffer] self
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
      # Retrieves the current stream settings for the thread.
      # @return [Integer] the current stream settings
      def Buffer.streams
        @@streams[Thread.current.object_id]
      end

      # Sets the stream settings for the current thread.
      # @param val [Integer] the new stream settings
      # @raise ArgumentError if val is not a valid stream value
      def Buffer.streams=(val)
        if (!val.is_a?(Integer)) or ((val & 63) == 0)
          respond "--- Lich: error: invalid streams value\n\t#{$!.caller[0..2].join("\n\t")}"
        else
          @@streams[Thread.current.object_id] = val
        end
      end

      # rubocop:enable Lint/HashCompareByIdentity
      # Cleans up the buffer by removing entries for threads that no longer exist.
      # @return [Buffer] self
      def Buffer.cleanup
        @@index.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        @@streams.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        return self
      end
    end
  end
end
