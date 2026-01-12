require 'tempfile'
require 'json'
require 'fileutils'
require 'fiddle'
require 'fiddle/import'
require 'open3'

# Windows API modules for frontend PID detection and window focus
# These need to be defined at the top level
if RUBY_PLATFORM =~ /mingw|mswin/
  unless defined?(::Win32Enum)
    module ::Win32Enum
      extend Fiddle::Importer
      dlload 'user32.dll'
      extern 'int EnumWindows(void*, long)'
      extern 'int IsWindowVisible(void*)'
      extern 'int GetWindowThreadProcessId(void*, void*)'
    end
  end

  unless defined?(::WinAPI)
    module ::WinAPI
      extend Fiddle::Importer
      dlload 'user32.dll'
      extern 'int EnumWindows(void*, long)'
      extern 'int GetWindowThreadProcessId(void*, void*)'
      extern 'int IsWindowVisible(void*)'
      extern 'int SetForegroundWindow(void*)'
    end
  end
end

# Namespace for the Lich application
# Contains common functionality for the application.
module Lich
  module Common
    # Frontend module for managing session files and process IDs
    # This module handles the creation and management of session files and process IDs.
    module Frontend
      @session_file = nil
      @tmp_session_dir = File.join Dir.tmpdir, "simutronics", "sessions"
      @frontend_pid = nil
      @pid_mutex = Mutex.new

      # Creates a session file with the given parameters
      # @param name [String] The name of the session
      # @param host [String] The host address
      # @param port [Integer] The port number
      # @param display_session [Boolean] Whether to display the session descriptor
      # @return [void]
      # @example
      #   Frontend.create_session_file("MySession", "localhost", 3000)
      def self.create_session_file(name, host, port, display_session: true)
        return if name.nil?
        FileUtils.mkdir_p @tmp_session_dir
        @session_file = File.join(@tmp_session_dir, "%s.session" % name.downcase.capitalize)
        session_descriptor = { name: name, host: host, port: port }.to_json
        puts "writing session descriptor to %s\n%s" % [@session_file, session_descriptor] if display_session
        File.open(@session_file, "w") do |fd|
          fd << session_descriptor
        end
      end

      # Returns the location of the current session file
      # @return [String, nil] The path to the session file or nil if not set
      def self.session_file_location
        @session_file
      end

      # Cleans up the session file if it exists
      # @return [void]
      def self.cleanup_session_file
        return if @session_file.nil?
        File.delete(@session_file) if File.exist? @session_file
      end


      # Returns the current frontend process ID
      # @return [Integer, nil] The frontend process ID or nil if not set
      def self.pid
        @pid_mutex.synchronize { @frontend_pid }
      end

      # Sets the frontend process ID
      # @param value [Integer] The process ID to set
      # @return [void]
      def self.pid=(value)
        value = value.to_i
        @pid_mutex.synchronize { @frontend_pid = value }
      end

      # Initializes the frontend from the parent process ID
      # @param parent_pid [Integer] The parent process ID
      # @return [Integer] The resolved frontend process ID
      # @example
      #   Frontend.init_from_parent(Process.ppid)
      def self.init_from_parent(parent_pid)
        Lich.log "=== Frontend.init_from_parent called ==="
        Lich.log "Parent process PID: #{parent_pid}"

        # Let's see what process this actually is on Windows
        if RUBY_PLATFORM =~ /mingw|mswin/
          begin
            require 'win32ole'
            wmi = WIN32OLE.connect('winmgmts://')
            rows = wmi.ExecQuery("SELECT Name, ProcessId FROM Win32_Process WHERE ProcessId=#{parent_pid}")
            row = rows.each.first rescue nil
            if row
              Lich.log "Parent process name: #{row.Name}"
            end
          rescue => e
            Lich.log "Could not get parent process name: #{e.message}"
          end
        end

        resolved_pid = resolve_pid(parent_pid)
        Lich.log "resolve_pid(#{parent_pid}) returned: #{resolved_pid}"

        self.pid = resolved_pid
        Lich.log "Frontend PID set to: #{self.pid}"

        resolved_pid
      end

      # Sets the frontend process ID from the client
      # @param pid [Integer] The process ID from the client
      # @return [Integer] The set process ID
      def self.set_from_client(pid)
        self.pid = pid
        Lich.log "Frontend PID set from client: #{pid}" if defined?(Lich.log)
        pid
      end

      # Detects the frontend process ID
      # @return [Integer, nil] The detected process ID or nil if not found
      def self.detect_pid
        # Return existing PID if already set
        current_pid = self.pid
        return current_pid if current_pid && current_pid > 0

        # Try to detect based on launch method
        # This is a fallback for cases where init wasn't called
        parent_pid = Process.ppid
        resolved_pid = resolve_pid(parent_pid)

        if resolved_pid && resolved_pid > 0
          self.pid = resolved_pid
          Lich.log "Frontend PID detected (fallback): #{resolved_pid}" if defined?(Lich.log)
          resolved_pid
        else
          Lich.log "Failed to detect frontend PID" if defined?(Lich.log)
          nil
        end
      end

      # Refocuses the frontend window based on the detected platform
      # @return [Boolean] True if refocused successfully, false otherwise
      def self.refocus
        pid = self.pid
        return false unless pid && pid > 0

        case detect_platform
        when :windows
          refocus_windows(pid)
        when :macos
          refocus_macos(pid)
        when :linux
          refocus_linux(pid)
        else
          false
        end
      end

      # Returns a callback proc for refocusing the window
      # @return [Proc] A proc that refocuses the window
      def self.refocus_callback
        proc {
          if defined?(GLib) && GLib.respond_to?(:Idle)
            GLib::Idle.add(50) { self.refocus; false }
          else
            self.refocus
          end
        }
      end

      # Detects the current platform
      # @return [Symbol] The platform type (:windows, :macos, :linux, or :unsupported)
      def self.detect_platform
        case RUBY_PLATFORM
        when /mingw|mswin/ then :windows
        when /darwin/      then :macos
        when /linux/       then :linux
        else                    :unsupported
        end
      end

      # Resolves the process ID to find the correct one based on the platform
      # @param pid [Integer] The process ID to resolve
      # @return [Integer] The resolved process ID
      def self.resolve_pid(pid)
        pid = pid.to_i
        return pid if pid <= 0 # Return as-is if invalid

        # Use the FrontendPID resolver logic
        case detect_platform
        when :windows
          resolve_windows_pid(pid)
        when :linux
          resolve_linux_pid(pid)
        else
          # macOS/other: PID usually already owns the window
          pid
        end
      end

      # Resolves the Windows process ID to find the correct one
      # @param pid [Integer] The process ID to resolve
      # @return [Integer] The resolved process ID
      def self.resolve_windows_pid(pid)
        Lich.log "=== resolve_windows_pid starting with PID: #{pid} ==="

        ensure_windows_modules
        require 'win32ole' rescue (return pid)

        begin
          wmi = WIN32OLE.connect('winmgmts://')
          p = pid

          16.times do
            # Get process name for debugging
            rows = wmi.ExecQuery("SELECT Name FROM Win32_Process WHERE ProcessId=#{p}")
            row = rows.each.first rescue nil
            process_name = row ? row.Name : "unknown"
            Lich.log "  Process name: #{process_name}"

            # Check if this process owns any visible window
            found = false
            cb = Fiddle::Closure::BlockCaller.new(
              Fiddle::TYPE_INT,
              [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG]
            ) do |hwnd, _|
              next 1 if ::Win32Enum.IsWindowVisible(hwnd).zero?
              buf = [0].pack('L')
              ::Win32Enum.GetWindowThreadProcessId(hwnd, buf)
              if buf.unpack1('L') == p
                found = true
                Lich.log "  Found visible window for PID #{p}"
                0  # stop enumeration
              else
                1  # continue enumeration
              end
            end
            ::Win32Enum.EnumWindows(cb, 0)

            if found
              Lich.log "  Stopping at PID #{p} (#{process_name}) - has visible window"
              return p
            end

            # Walk up to parent process
            parent = windows_parent_pid(wmi, p)

            break if parent.nil? || parent.zero? || parent == p
            p = parent
          end
        rescue => e
          Lich.log "ERROR in resolve_windows_pid: #{e}"
        end

        Lich.log "Fallback: returning original PID #{pid}"
        pid
      end

      # Retrieves the parent process ID for a given Windows process ID
      # @param wmi [WIN32OLE] The WMI connection object
      # @param pid [Integer] The process ID to check
      # @return [Integer] The parent process ID or 0 if not found
      def self.windows_parent_pid(wmi, pid)
        rows = wmi.ExecQuery("SELECT ParentProcessId FROM Win32_Process WHERE ProcessId=#{pid}")
        row = rows.each.first rescue nil
        row ? row.ParentProcessId.to_i : 0
      end

      # Resolves the Linux process ID to find the correct one
      # @param pid [Integer] The process ID to resolve
      # @return [Integer] The resolved process ID
      def self.resolve_linux_pid(pid)
        return pid unless system('which xdotool > /dev/null 2>&1')

        p = pid
        16.times do
          # Check if this process has a window
          return p if system("xdotool search --pid #{p} >/dev/null 2>&1")

          # Walk up to parent process
          begin
            status = File.read("/proc/#{p}/status")
            parent = status[/PPid:\s+(\d+)/, 1].to_i
          rescue
            parent = 0
          end
          return pid if parent.zero? || parent == p
          p = parent
        end

        pid # fallback
      rescue => e
        Lich.log "Error resolving Linux PID: #{e}" if defined?(Lich.log)
        pid
      end

      # Refocuses the window for a given Windows process ID
      # @param pid [Integer] The process ID to refocus
      # @return [Boolean] True if refocused successfully, false otherwise
      def self.refocus_windows(pid)
        ensure_windows_modules

        hwnd_buf = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)

        enum_cb = Fiddle::Closure::BlockCaller.new(
          Fiddle::TYPE_INT,
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG]
        ) do |hwnd, _|
          next 1 if ::WinAPI.IsWindowVisible(hwnd).zero?

          pid_tmp = [0].pack('L')
          ::WinAPI.GetWindowThreadProcessId(hwnd, pid_tmp)
          win_pid = pid_tmp.unpack1('L')

          if win_pid == pid
            hwnd_buf[0, Fiddle::SIZEOF_VOIDP] = [hwnd].pack('L!')
            0  # stop enumeration
          else
            1  # continue enumeration
          end
        end

        ::WinAPI.EnumWindows(enum_cb, 0)
        hwnd = hwnd_buf[0, Fiddle::SIZEOF_VOIDP].unpack1('L!')

        if hwnd != 0
          ::WinAPI.SetForegroundWindow(hwnd)
          true
        else
          Lich.log "Frontend window for PID #{pid} not found" if defined?(Lich.log)
          false
        end
      rescue => e
        Lich.log "Error refocusing Windows: #{e}" if defined?(Lich.log)
        false
      end

      # Refocuses the window for a given macOS process ID
      # @param pid [Integer] The process ID to refocus
      # @return [Boolean] True if refocused successfully, false otherwise
      def self.refocus_macos(pid)
        return false unless system('which osascript > /dev/null 2>&1')

        script = %{tell application "System Events" to set frontmost of (first process whose unix id is #{pid}) to true}
        _stdout, stderr, status = Open3.capture3('osascript', '-e', script)

        if status.success?
          true
        else
          Lich.log "Error refocusing macOS: #{stderr}" if defined?(Lich.log)
          false
        end
      rescue => e
        Lich.log "Error refocusing macOS: #{e}" if defined?(Lich.log)
        false
      end

      # Refocuses the window for a given Linux process ID
      # @param pid [Integer] The process ID to refocus
      # @return [Boolean] True if refocused successfully, false otherwise
      def self.refocus_linux(pid)
        return false unless system('which xdotool > /dev/null 2>&1')

        _stdout, stderr, status = Open3.capture3('xdotool', 'search', '--pid', pid.to_s, 'windowactivate')

        if status.success?
          true
        else
          Lich.log "Error refocusing Linux: #{stderr}" if defined?(Lich.log)
          false
        end
      rescue => e
        Lich.log "Error refocusing Linux: #{e}" if defined?(Lich.log)
        false
      end

      # Ensures that the Windows API modules are loaded
      # @return [Boolean] True if modules are loaded, false otherwise
      def self.ensure_windows_modules
        # Check if modules exist - they should be defined at file load time
        if RUBY_PLATFORM =~ /mingw|mswin/
          return defined?(::Win32Enum) && defined?(::WinAPI)
        end
        false
      end
    end
  end
end
