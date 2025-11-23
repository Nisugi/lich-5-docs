# frozen_string_literal: true

#
# Async Combat Processor - Thread-safe combat processing for performance
#

require 'concurrent'

module Lich
  module Gemstone
    module Combat
      # Asynchronous combat event processor
      #
      # Processes combat events in parallel using a thread pool for improved
      # performance during large combat encounters. Uses atomic operations
      # for thread-safe tracking.
      #
      # @example Basic usage
      #   processor = AsyncProcessor.new(max_threads: 2)
      #   processor.process_async(combat_lines)
      #   processor.shutdown  # Wait for all threads to complete
      #
      class AsyncProcessor
        # Initialize async processor
        #
        # @param max_threads [Integer] Maximum number of concurrent processing threads
        def initialize(max_threads = 2)
          @max_threads = max_threads
          @active_count = Concurrent::AtomicFixnum.new(0)
          @thread_pool = []
        end

        # Process a chunk of combat lines asynchronously
        #
        # Spawns a new thread to process the chunk if capacity allows.
        # Waits if thread pool is at max capacity.
        #
        # @param chunk [Array<String>] Array of game lines to process
        # @return [Thread, nil] The processing thread or nil if chunk was empty
        def process_async(chunk)
          return if chunk.empty?

          # Clean up dead threads
          @thread_pool.reject!(&:alive?)

          # Wait if at capacity
          while @active_count.value >= @max_threads
            sleep(0.01)
          end

          @active_count.increment

          thread = Thread.new do
            begin
              Thread.current[:start_time] = Time.now
              Thread.current[:line_count] = chunk.size

              Processor.process(chunk)

              elapsed = Time.now - Thread.current[:start_time]
              if elapsed > 0.5 && Tracker.debug?
                puts "[Combat] Processed #{chunk.size} lines in #{elapsed.round(3)}s"
              end
            rescue => e
              puts "[Combat] Processing error: #{e.message}" if Tracker.debug?
              puts e.backtrace.first(3) if Tracker.debug?
            ensure
              @active_count.decrement
            end
          end

          @thread_pool << thread
          thread
        end

        # Shutdown the processor and wait for all threads to complete
        #
        # Blocks until all active processing threads finish.
        #
        # @return [void]
        def shutdown
          puts "[Combat] Waiting for #{@thread_pool.count(&:alive?)} threads..." if Tracker.debug?
          @thread_pool.each(&:join)
          @thread_pool.clear
        end

        # Get current processing statistics
        #
        # @return [Hash] Stats including :active, :total, :max_threads, :processing
        def stats
          {
            active: @active_count.value,
            total: @thread_pool.count(&:alive?),
            max_threads: @max_threads,
            processing: @thread_pool.select(&:alive?).map do |thread|
              {
                lines: thread[:line_count] || 0,
                elapsed: thread[:start_time] ? (Time.now - thread[:start_time]).round(2) : 0
              }
            end
          }
        end
      end
    end
  end
end
