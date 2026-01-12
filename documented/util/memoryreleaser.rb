require 'fiddle'
require 'rbconfig'

module Lich
  module Util
    # Memory management module that provides automatic and manual memory release functionality
    # Memory management module that provides automatic and manual memory release functionality
    # @example Enabling auto-start
    #   MemoryReleaser.auto_start!
    module MemoryReleaser
      # Default settings for memory releaser
      # Default settings for memory releaser
      DEFAULT_SETTINGS = {
        auto_start: false, # Disabled by default, user must enable
        interval: 900, # default of 15 minutes
        verbose: false,
      }.freeze

      # Persistent command queue and launcher thread created at module load time.
      # This launcher thread exists at the main engine level and survives script termination,
      # which is critical for Windows/Lich compatibility where script-spawned threads are
      # killed when the script exits.
      @command_queue = Queue.new
      @worker_thread = nil
      @launcher_thread = Thread.new do
        Thread.current.abort_on_exception = false
        Thread.current.name = "MemoryReleaser-Launcher"

        loop do
          begin
            command = @command_queue.pop
            break if command[:action] == :shutdown

            case command[:action]
            when :start_worker
              # Kill any existing worker
              if @worker_thread&.alive?
                command[:manager].enabled = false # Signal graceful stop
                deadline = Time.now + 2
                while @worker_thread.alive? && Time.now < deadline
                  sleep 0.1
                end
                if @worker_thread.alive? # Last resort
                  @worker_thread.kill rescue nil
                end
              end

              # Create new worker thread from launcher context
              @worker_thread = Thread.new do
                Thread.current.abort_on_exception = false
                Thread.current.name = "MemoryReleaser-Worker"

                interval = command[:interval]
                verbose = command[:verbose]
                manager = command[:manager]

                respond "[MemoryReleaser] Memory releaser started (interval: #{interval}s)" if verbose

                loop do
                  break unless manager.enabled

                  # Sleep in small chunks to be more responsive
                  elapsed = 0
                  while elapsed < interval && manager.enabled
                    sleep(1)
                    elapsed += 1
                  end

                  break unless manager.enabled

                  begin
                    manager.release
                  rescue => e
                    respond "[MemoryReleaser] Error: #{e.message}"
                    respond e.backtrace.first(5).join("\n") if verbose
                  end
                end

                respond "[MemoryReleaser] Memory releaser stopped" if verbose
              end

            when :stop_worker
              if @worker_thread&.alive?
                # Give worker up to 2 seconds to exit gracefully
                deadline = Time.now + 2
                while @worker_thread.alive? && Time.now < deadline
                  sleep 0.1
                end
                # Last resort only
                if @worker_thread.alive?
                  @worker_thread.kill rescue nil
                end
              end
              @worker_thread = nil
            end
          rescue => e
            respond "[MemoryReleaser] Launcher error: #{e.message}"
          end
        end
      end

      # Manages the memory releaser settings and operations
      # @example Creating a manager instance
      #   manager = MemoryReleaser::Manager.new
      class Manager
        attr_accessor :enabled

        attr_accessor :interval

        attr_accessor :verbose

        attr_reader :settings

        # Initializes a new Manager instance
        # @return [Manager]
        def initialize
          load_settings
          @enabled = true
        end

        # Loads settings from the database
        # @return [Hash] The loaded settings
        # @raise [StandardError] If there's an error loading settings
        def load_settings
          # Load from DB_Store with per-character scope
          scope = "#{XMLData.game}:#{XMLData.name}"
          stored_settings = Lich::Common::DB_Store.read(scope, 'lich_memory_releaser') || {}
          @settings = DEFAULT_SETTINGS.merge(stored_settings)

          # Apply loaded settings to instance variables
          @interval = @settings[:interval]
          @verbose = @settings[:verbose]

          @settings
        rescue => e
          # If there's an error loading settings, use defaults
          respond "[MemoryReleaser] Error loading settings: #{e.message}, using defaults"
          @settings = DEFAULT_SETTINGS.dup
          @interval = @settings[:interval]
          @verbose = @settings[:verbose]
          @settings
        end

        # Saves current settings to the database
        # @return [Hash] The saved settings
        # @raise [StandardError] If there's an error saving settings
        def save_settings
          # Save current settings to DB_Store with per-character scope
          scope = "#{XMLData.game}:#{XMLData.name}"
          Lich::Common::DB_Store.save(scope, 'lich_memory_releaser', @settings)
          @settings
        rescue => e
          respond "[MemoryReleaser] Error saving settings: #{e.message}"
          @settings
        end

        def auto_start!
          @settings[:auto_start] = true
          save_settings
          start
        end

        def auto_disable!
          @settings[:auto_start] = false
          save_settings
          stop if running?
        end

        def interval!(seconds)
          seconds = [seconds, 60].max # Minimum 60 seconds
          @settings[:interval] = seconds
          @interval = seconds
          save_settings

          # If currently running, restart with new interval
          if running?
            log "Restarting with new interval: #{seconds}s"
            start
          end

          seconds
        end

        def verbose!(enabled)
          @settings[:verbose] = enabled
          @verbose = enabled
          save_settings
          enabled
        end

        def release
          run_gc
          release_to_os
          log "Memory release completed"
        end

        def start(interval: nil, verbose: nil)
          stop if running?

          # Use provided values or fall back to settings
          @interval = interval || @settings[:interval]
          @verbose = verbose.nil? ? @settings[:verbose] : verbose
          @enabled = true

          # Update settings with current values
          @settings[:interval] = @interval
          @settings[:verbose] = @verbose
          save_settings

          # Send command to persistent launcher thread
          MemoryReleaser.command_queue << {
            action: :start_worker,
            interval: @interval,
            verbose: @verbose,
            manager: self
          }

          # Wait for worker to start
          timeout = 0
          until running?
            sleep 0.1
            timeout += 1
            if timeout > 50
              respond "[MemoryReleaser] ERROR: Worker thread failed to start"
              return nil
            end
          end

          MemoryReleaser.worker_thread
        end

        def stop
          @enabled = false

          MemoryReleaser.command_queue << {
            action: :stop_worker
          }

          sleep 0.2
          log "Memory releaser stopped"
        end

        def running?
          worker = MemoryReleaser.worker_thread
          worker&.alive? || false
        end

        def status
          {
            running: running?,
            enabled: @enabled,
            auto_start: @settings[:auto_start],
            interval: @interval,
            verbose: @verbose,
            platform: RbConfig::CONFIG['host_os']
          }
        end

        def benchmark
          respond "=" * 60
          respond "Memory Usage Before Release:"
          respond "=" * 60
          before = print_memory_stats

          respond "\nReleasing memory..."
          release

          respond "\n" + "=" * 60
          respond "Memory Usage After Release:"
          respond "=" * 60
          after = print_memory_stats

          respond "\n" + "=" * 60
          respond "Change:"
          respond "=" * 60
          print_memory_diff(before, after)
        end

        private

        def log(message)
          respond "[MemoryReleaser] #{message}" if @verbose
        end

        def run_gc
          GC.start(full_mark: true, immediate_sweep: true)
          GC.compact if GC.respond_to?(:compact)
        end

        def release_to_os
          case RbConfig::CONFIG['host_os']
          when /linux/
            malloc_trim_linux
          when /darwin|mac os/
            malloc_zone_pressure_relief_macos
          when /mswin|mingw|cygwin/
            heapmin_windows
          end
        rescue => e
          respond "Memory release to OS failed: #{e.message}"
        end

        def malloc_trim_linux
          libc = Fiddle.dlopen(nil)
          malloc_trim = Fiddle::Function.new(
            libc['malloc_trim'],
            [Fiddle::TYPE_INT],
            Fiddle::TYPE_INT
          )
          malloc_trim.call(0)
          log "malloc_trim completed"
        end

        def malloc_zone_pressure_relief_macos
          libc = Fiddle.dlopen('/usr/lib/libSystem.B.dylib')
          func = Fiddle::Function.new(
            libc['malloc_zone_pressure_relief'],
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T],
            Fiddle::TYPE_VOID
          )
          func.call(nil, 0)
          log "malloc_zone_pressure_relief completed"
        end

        def heapmin_windows
          # Try EmptyWorkingSet first (from your original code)
          begin
            k32 = Fiddle.dlopen('kernel32')
            psapi = Fiddle.dlopen('psapi')
            get_proc = Fiddle::Function.new(
              k32['GetCurrentProcess'],
              [],
              Fiddle::TYPE_VOIDP
            )
            empty = Fiddle::Function.new(
              psapi['EmptyWorkingSet'],
              [Fiddle::TYPE_VOIDP],
              Fiddle::TYPE_INT
            )
            empty.call(get_proc.call)
            log "EmptyWorkingSet completed"
            return
          rescue => e
            log "EmptyWorkingSet failed, trying _heapmin: #{e.message}"
          end

          # Fallback to _heapmin
          crt_libs = if RUBY_PLATFORM =~ /ucrt/
                       ['ucrtbase', 'msvcrt']
                     elsif RUBY_PLATFORM =~ /mingw/
                       ['msvcrt', 'ucrtbase']
                     else
                       ['ucrtbase', 'msvcrt']
                     end

          crt_libs.each do |lib_name|
            begin
              crt = Fiddle.dlopen(lib_name)
              heapmin = Fiddle::Function.new(
                crt['_heapmin'],
                [],
                Fiddle::TYPE_INT
              )
              heapmin.call
              log "_heapmin completed with #{lib_name}"
              return true
            rescue Fiddle::DLError
              next
            end
          end

          respond "Could not find compatible method for Windows memory release"
          nil
        end

        def print_memory_stats
          stat = GC.stat

          stats = {
            heap_live_slots: stat[:heap_live_slots],
            heap_free_slots: stat[:heap_free_slots],
            heap_total_slots: stat[:heap_live_slots] + stat[:heap_free_slots],
            heap_allocated_pages: stat[:heap_allocated_pages],
            malloc_increase_bytes: stat[:malloc_increase_bytes],
            rss_mb: get_process_memory
          }

          respond "  Ruby Heap Live Slots:    #{stats[:heap_live_slots].to_s.rjust(12)}"
          respond "  Ruby Heap Free Slots:    #{stats[:heap_free_slots].to_s.rjust(12)}"
          respond "  Ruby Heap Total Slots:   #{stats[:heap_total_slots].to_s.rjust(12)}"
          respond "  Ruby Heap Pages:         #{stats[:heap_allocated_pages].to_s.rjust(12)}"
          respond "  Malloc Increase (bytes): #{stats[:malloc_increase_bytes].to_s.rjust(12)}"
          respond "  Process RSS (MB):        #{sprintf('%.2f', stats[:rss_mb]).rjust(12)}" if stats[:rss_mb]

          stats
        end

        def print_memory_diff(before, after)
          diff_slots = after[:heap_total_slots] - before[:heap_total_slots]
          diff_pages = after[:heap_allocated_pages] - before[:heap_allocated_pages]
          diff_malloc = after[:malloc_increase_bytes] - before[:malloc_increase_bytes]
          diff_rss = after[:rss_mb] ? after[:rss_mb] - before[:rss_mb] : nil

          respond "  Heap Slots:              #{format_diff(diff_slots)}"
          respond "  Heap Pages:              #{format_diff(diff_pages)}"
          respond "  Malloc Increase (bytes): #{format_diff(diff_malloc)}"
          respond "  Process RSS (MB):        #{sprintf('%+.2f', diff_rss).rjust(12)}" if diff_rss
        end

        def format_diff(value)
          formatted = value.to_s.rjust(12)
          value < 0 ? formatted : "+#{formatted}"
        end

        def get_process_memory
          case RbConfig::CONFIG['host_os']
          when /linux/
            File.read('/proc/self/status').match(/VmRSS:\s+(\d+)/)[1].to_f / 1024.0
          when /darwin|mac os/
            `ps -o rss= -p #{Process.pid}`.to_f / 1024.0
          when /mswin|mingw|cygwin/
            get_process_memory_windows
          end
        rescue
          nil
        end

        def get_process_memory_windows
          # Method 1: Try GetProcessMemoryInfo via PSAPI (most reliable, no console)
          begin
            return get_memory_via_psapi
          rescue => e
            log "GetProcessMemoryInfo failed: #{e.message}" if @verbose
          end

          # Method 2: Try WMI via WIN32OLE (no console, but slower)
          begin
            return get_memory_via_wmi
          rescue => e
            log "WMI failed: #{e.message}" if @verbose
          end

          # Method 3: PowerShell with hidden window (last resort)
          begin
            return get_memory_via_powershell
          rescue => e
            log "PowerShell failed: #{e.message}" if @verbose
          end

          nil
        end

        def get_memory_via_psapi
          # Use Windows PSAPI directly via Fiddle (no console window)
          k32 = Fiddle.dlopen('kernel32')
          psapi = Fiddle.dlopen('psapi')

          # Get current process handle
          get_current_process = Fiddle::Function.new(
            k32['GetCurrentProcess'],
            [],
            Fiddle::TYPE_VOIDP
          )

          # Detect if we're running 64-bit Ruby
          is_64bit = ['a'].pack('P').size == 8

          # PROCESS_MEMORY_COUNTERS structure size
          # 32-bit: 40 bytes, 64-bit: 72 bytes
          pmc_size = is_64bit ? 72 : 40
          pmc = Fiddle::Pointer.malloc(pmc_size)
          pmc[0, 4] = [pmc_size].pack('L') # cb member (always 4 bytes)

          # GetProcessMemoryInfo function
          get_memory_info = Fiddle::Function.new(
            psapi['GetProcessMemoryInfo'],
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
            Fiddle::TYPE_INT
          )

          result = get_memory_info.call(get_current_process.call, pmc, pmc_size)

          if result != 0
            # WorkingSetSize offset: 12 bytes (32-bit) or 16 bytes (64-bit)
            offset = is_64bit ? 16 : 12
            pack_format = is_64bit ? 'Q' : 'L' # Q for 64-bit, L for 32-bit
            size = is_64bit ? 8 : 4

            working_set = pmc[offset, size].unpack(pack_format)[0]
            return working_set / (1024.0 * 1024.0) # Convert bytes to MB
          end

          nil
        end

        def get_memory_via_wmi
          # Use WMI - no console window but requires win32ole
          require 'win32ole'

          wmi = WIN32OLE.connect("winmgmts://")
          processes = wmi.ExecQuery("SELECT WorkingSetSize FROM Win32_Process WHERE ProcessId = #{Process.pid}")

          processes.each do |process|
            return process.WorkingSetSize / (1024.0 * 1024.0) if process.WorkingSetSize
          end

          nil
        end

        def get_memory_via_powershell
          # Use PowerShell with hidden window as last resort
          script = "(Get-Process -Id #{Process.pid}).WorkingSet64"

          # Use PowerShell with WindowStyle Hidden to prevent console window
          output = `powershell.exe -WindowStyle Hidden -NoProfile -Command "#{script}" 2>NUL`

          if output && !output.empty?
            return output.strip.to_f / (1024.0 * 1024.0)
          end

          nil
        end
      end

      # Class-level singleton instance
      @instance = nil

      class << self
        attr_reader :command_queue

        attr_reader :worker_thread

        # Retrieves the singleton instance of the MemoryReleaser
        # @return [Manager] The singleton instance of the Manager
        def instance
          @mutex ||= Mutex.new
          @mutex.synchronize {
            @instance ||= begin
              manager = Manager.new

              # Auto-start if enabled in settings
              if manager.settings[:auto_start]
                manager.start
              end

              manager
            end
          }
        end

        # Starts the memory releaser worker using the singleton instance
        # @param interval [Integer, nil] The interval in seconds (optional)
        # @param verbose [Boolean, nil] Whether to enable verbose logging (optional)
        # @return [Thread, nil] The worker thread if started, otherwise nil
        def start(interval: nil, verbose: nil)
          instance.start(interval: interval, verbose: verbose)
        end

        # Stops the memory releaser worker using the singleton instance
        # @return [void]
        def stop
          instance.stop
        end

        # Enables auto-start for the memory releaser using the singleton instance
        # @return [Boolean] The status of auto-start after enabling
        def auto_start!
          instance.auto_start!
        end

        # Disables auto-start for the memory releaser using the singleton instance
        # @return [Boolean] The status of auto-start after disabling
        def auto_disable!
          instance.auto_disable!
        end

        # Sets the interval for memory release using the singleton instance
        # @param seconds [Integer] The interval in seconds (minimum 60)
        # @return [Integer] The new interval
        def interval!(seconds)
          instance.interval!(seconds)
        end

        # Sets the verbose mode for logging using the singleton instance
        # @param enabled [Boolean] Whether to enable verbose logging
        # @return [Boolean] The new verbose status
        def verbose!(enabled)
          instance.verbose!(enabled)
        end

        # Releases memory using the singleton instance
        # @return [void]
        def release
          instance.release
        end

        # Checks if the memory releaser worker is currently running using the singleton instance
        # @return [Boolean] True if running, false otherwise
        def running?
          instance.running?
        end

        # Retrieves the current status of the memory releaser using the singleton instance
        # @return [Hash] The current status including running, enabled, auto_start, interval, verbose, and platform
        def status
          instance.status
        end

        # Runs a benchmark to show memory usage before and after release using the singleton instance
        # @return [void]
        def benchmark
          instance.benchmark
        end

        def reset!
          @instance&.stop
          @instance = nil
        end
      end
    end
  end
end

# Usage examples:
#
# Enable auto-start (automatically starts the releaser):
#   MemoryReleaser.auto_start!
#
# Disable auto-start and stop the releaser:
#   MemoryReleaser.auto_disable!
#
# Start background thread with saved settings:
#   MemoryReleaser.start
#
# Start with custom interval and verbose output:
#   MemoryReleaser.start(interval: 600, verbose: true)
#
# Change interval (restarts if running):
#   MemoryReleaser.interval!(1200) # 20 minutes
#
# Change verbose setting:
#   MemoryReleaser.verbose!(true)
#
# Manual release:
#   MemoryReleaser.release
#
# Check status:
#   MemoryReleaser.status
#
# Stop background thread:
#   MemoryReleaser.stop
#
# Check if running:
#   MemoryReleaser.running?
#
# Run benchmark:
#   MemoryReleaser.benchmark
#
# For Lich5 integration with auto-start:
#   MemoryReleaser.auto_start!
#   before_dying { MemoryReleaser.stop }
#
# For Lich5 integration without auto-start:
#   MemoryReleaser.start(interval: 900, verbose: true)
#   before_dying { MemoryReleaser.stop }
