# frozen_string_literal: true

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

# Module containing common functionality for the Lich project.
# @example Using the Lich module
#   Lich::Common::Frontend.register(:example, capabilities: [:xml])
module Lich
  module Common
    module Frontend
      @session_file = nil
      @tmp_session_dir = File.join Dir.tmpdir, "simutronics", "sessions"
      @frontend_pid = nil
      @pid_mutex = Mutex.new

      # ─── Frontend Registry ─────────────────────────────────────
      # Each registered frontend has:
      #   - capabilities: Set of symbols (e.g., :xml, :streams, :mono)
      #   - metadata: Hash of additional data (e.g., client_string)
      #
      # This registry-based approach allows adding new frontends via
      # configuration without modifying the controller code.
      @registry = Hash.new { |h, k| h[k] = { capabilities: Set.new, metadata: {} } }

      # Registers a new frontend with the given name, capabilities, and metadata.
      # @param name [Symbol] The name of the frontend to register.
      # @param capabilities [Array<Symbol>] The capabilities of the frontend.
      # @param metadata [Hash] Additional metadata for the frontend.
      # @return [void]
      # @example Registering a frontend
      #   Lich::Common::Frontend.register(:new_frontend, capabilities: [:xml])
      def self.register(name, capabilities: [], metadata: {})
        entry = @registry[name.to_s.downcase]
        entry[:capabilities].merge(capabilities.map(&:to_sym))
        entry[:metadata].merge!(metadata)
      end

      # Checks if a frontend has a specific capability.
      # @param frontend_name [Symbol] The name of the frontend to check.
      # @param capability [Symbol] The capability to check for.
      # @return [Boolean] True if the frontend has the capability, false otherwise.
      # @example Checking capability
      #   Lich::Common::Frontend.has_capability?(:wrayth, :xml)
      def self.has_capability?(frontend_name, capability)
        return false if frontend_name.nil?

        @registry[frontend_name.to_s.downcase][:capabilities].include?(capability.to_sym)
      end

      # Retrieves metadata for a registered frontend.
      # @param frontend_name [Symbol] The name of the frontend.
      # @param key [Symbol] The key of the metadata to retrieve.
      # @return [Object, nil] The metadata value or nil if not found.
      # @example Retrieving metadata
      #   Lich::Common::Frontend.metadata_for(:wrayth, :client_string)
      def self.metadata_for(frontend_name, key)
        return nil if frontend_name.nil?

        @registry[frontend_name.to_s.downcase][:metadata][key]
      end

      # Returns a list of all registered frontend names.
      # @return [Array<Symbol>] An array of registered frontend names.
      # @example Listing registered frontends
      #   Lich::Common::Frontend.registered_frontends
      def self.registered_frontends
        @registry.keys
      end

      # Returns a list of frontend names that have a specific capability.
      # @param capability [Symbol] The capability to filter frontends by.
      # @return [Array<Symbol>] An array of frontend names with the specified capability.
      # @example Finding frontends with capability
      #   Lich::Common::Frontend.frontends_with_capability(:xml)
      def self.frontends_with_capability(capability)
        @registry.select { |_name, data| data[:capabilities].include?(capability.to_sym) }.keys
      end

      # ─── Default Frontend Registrations ────────────────────────
      # Ideally this would live in a separate config file loaded during init.

      register(:wrayth,
               capabilities: %i[xml streams mono room_window])

      register(:stormfront,
               capabilities: %i[xml streams mono room_window])

      register(:profanity,
               capabilities: %i[xml streams])

      register(:genie,
               capabilities: %i[xml mono])

      register(:frostbite,
               capabilities: %i[xml])

      register(:wizard,
               capabilities: %i[gsl])

      register(:avalon,
               capabilities: %i[gsl])

      # ─── Client String ─────────────────────────────────────────
      # Default client string (Wrayth identity) sent during handshake
      # Default client string (Wrayth identity) sent during handshake.
      CLIENT_STRING = "/FE:WRAYTH /VERSION:1.0.1.28 /P:WIN_UNKNOWN /XML"

      # ─── Backward-Compatible Constants ─────────────────────────
      # These arrays are derived from the registry for backward compatibility.
      # External code may still reference these constants directly.
      # Array of frontends that support XML capabilities.
      XML_FRONTENDS    = frontends_with_capability(:xml).freeze
      # Array of frontends that support GSL capabilities.
      GSL_FRONTENDS    = frontends_with_capability(:gsl).freeze
      # Array of frontends that support stream capabilities.
      STREAM_FRONTENDS = frontends_with_capability(:streams).freeze
      # Array of frontends that support mono capabilities.
      MONO_FRONTENDS   = frontends_with_capability(:mono).freeze


      # Checks if the specified frontend supports XML capabilities.
      # @param fe [Symbol] The frontend to check (default is $frontend).
      # @return [Boolean] True if the frontend supports XML, false otherwise.
      # @example Checking XML support
      #   Lich::Common::Frontend.supports_xml?(:wrayth)
      def self.supports_xml?(fe = $frontend)
        has_capability?(fe, :xml)
      end

      # Checks if the specified frontend supports GSL capabilities.
      # @param fe [Symbol] The frontend to check (default is $frontend).
      # @return [Boolean] True if the frontend supports GSL, false otherwise.
      # @example Checking GSL support
      #   Lich::Common::Frontend.supports_gsl?(:wrayth)
      def self.supports_gsl?(fe = $frontend)
        has_capability?(fe, :gsl)
      end

      # Checks if the specified frontend supports stream capabilities.
      # @param fe [Symbol] The frontend to check (default is $frontend).
      # @return [Boolean] True if the frontend supports streams, false otherwise.
      # @example Checking streams support
      #   Lich::Common::Frontend.supports_streams?(:wrayth)
      def self.supports_streams?(fe = $frontend)
        has_capability?(fe, :streams)
      end

      # Checks if the specified frontend supports mono capabilities.
      # @param fe [Symbol] The frontend to check (default is $frontend).
      # @return [Boolean] True if the frontend supports mono, false otherwise.
      # @example Checking mono support
      #   Lich::Common::Frontend.supports_mono?(:wrayth)
      def self.supports_mono?(fe = $frontend)
        has_capability?(fe, :mono)
      end

      # Checks if the specified frontend supports room window capabilities.
      # @param fe [Symbol] The frontend to check (default is $frontend).
      # @return [Boolean] True if the frontend supports room window, false otherwise.
      # @example Checking room window support
      #   Lich::Common::Frontend.supports_room_window?(:wrayth)
      def self.supports_room_window?(fe = $frontend)
        has_capability?(fe, :room_window)
      end

      # Returns the current frontend client.
      # @return [Symbol] The current frontend client.
      def self.client
        $frontend
      end

      # Sets the current frontend client.
      # @param value [Symbol] The frontend client to set.
      # @return [void]
      # @example Setting the client
      #   Lich::Common::Frontend.client = :wrayth
      def self.client=(value)
        $frontend = value
      end

      # Sends a handshake message to the frontend.
      # @param version_string [String] The version string to send.
      # @return [void]
      # @example Sending a handshake
      #   Lich::Common::Frontend.send_handshake("/FE:WRAYTH /VERSION:1.0.1.28")
      def self.send_handshake(version_string)
        $_CLIENTBUFFER_.push(version_string.dup)
        Game._puts(version_string)
        2.times do
          sleep 0.3
          $_CLIENTBUFFER_.push("#{$cmd_prefix}\r\n")
          Game._puts($cmd_prefix)
        end
        ["#{$cmd_prefix}_injury 2",
         "#{$cmd_prefix}_flag Display Inventory Boxes 1",
         "#{$cmd_prefix}_flag Display Dialog Boxes 0"].each do |cmd|
          $_CLIENTBUFFER_.push(cmd)
          Game._puts(cmd)
        end
      end

      # Creates a session file with the specified name, host, and port.
      # @param name [String] The name of the session.
      # @param host [String] The host for the session.
      # @param port [Integer] The port for the session.
      # @param display_session [Boolean] Whether to display the session descriptor (default is true).
      # @return [void]
      # @example Creating a session file
      #   Lich::Common::Frontend.create_session_file("session1", "localhost", 3000)
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

      # Returns the location of the current session file.
      # @return [String, nil] The session file location or nil if not set.
      def self.session_file_location
        @session_file
      end

      # Cleans up the current session file if it exists.
      # @return [void]
      # @example Cleaning up session file
      #   Lich::Common::Frontend.cleanup_session_file
      def self.cleanup_session_file
        return if @session_file.nil?
        File.delete(@session_file) if File.exist? @session_file
      end


      # Returns the current frontend process ID (PID).
      # @return [Integer, nil] The current PID or nil if not set.
      def self.pid
        @pid_mutex.synchronize { @frontend_pid }
      end

      # Sets the current frontend process ID (PID).
      # @param value [Integer] The PID to set.
      # @return [void]
      # @example Setting the PID
      #   Lich::Common::Frontend.pid = 12345
      def self.pid=(value)
        value = value.to_i
        @pid_mutex.synchronize { @frontend_pid = value }
      end

      # Initializes the frontend from the parent process ID.
      # @param parent_pid [Integer] The parent process ID to initialize from.
      # @return [Integer] The resolved PID.
      # @example Initializing from parent
      #   Lich::Common::Frontend.init_from_parent(Process.ppid)
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

      # Sets the frontend PID from the client.
      # @param pid [Integer] The PID to set from the client.
      # @return [Integer] The set PID.
      # @example Setting from client
      #   Lich::Common::Frontend.set_from_client(12345)
      def self.set_from_client(pid)
        self.pid = pid
        Lich.log "Frontend PID set from client: #{pid}" if defined?(Lich.log)
        pid
      end

      # Detects the frontend process ID (PID).
      # @return [Integer, nil] The detected PID or nil if not found.
      # @example Detecting PID
      #   Lich::Common::Frontend.detect_pid
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

      # Refocuses the frontend window based on the detected platform.
      # @return [Boolean] True if refocus was successful, false otherwise.
      # @example Refocusing frontend
      #   Lich::Common::Frontend.refocus
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

      # Returns a callback proc for refocusing the frontend.
      # @return [Proc] The refocus callback proc.
      def self.refocus_callback
        proc {
          if defined?(GLib) && GLib.respond_to?(:Idle)
            GLib::Idle.add(50) { self.refocus; false }
          else
            self.refocus
          end
        }
      end

      # Detects the current platform.
      # @return [Symbol] The detected platform (:windows, :macos, :linux, or :unsupported).
      def self.detect_platform
        case RUBY_PLATFORM
        when /mingw|mswin/ then :windows
        when /darwin/      then :macos
        when /linux/       then :linux
        else                    :unsupported
        end
      end

      # Resolves the process ID (PID) based on the platform.
      # @param pid [Integer] The PID to resolve.
      # @return [Integer] The resolved PID.
      # @example Resolving PID
      #   Lich::Common::Frontend.resolve_pid(12345)
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

      # Resolves the Windows process ID (PID) to find the owning process.
      # @param pid [Integer] The PID to resolve.
      # @return [Integer] The resolved PID.
      # @example Resolving Windows PID
      #   Lich::Common::Frontend.resolve_windows_pid(12345)
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

      # Retrieves the parent process ID for a given Windows PID.
      # @param wmi [WIN32OLE] The WMI connection object.
      # @param pid [Integer] The PID to get the parent for.
      # @return [Integer] The parent process ID or 0 if not found.
      def self.windows_parent_pid(wmi, pid)
        rows = wmi.ExecQuery("SELECT ParentProcessId FROM Win32_Process WHERE ProcessId=#{pid}")
        row = rows.each.first rescue nil
        row ? row.ParentProcessId.to_i : 0
      end

      # Resolves the Linux process ID (PID) to find the owning process.
      # @param pid [Integer] The PID to resolve.
      # @return [Integer] The resolved PID.
      # @example Resolving Linux PID
      #   Lich::Common::Frontend.resolve_linux_pid(12345)
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

      # Refocuses the Windows window for the given PID.
      # @param pid [Integer] The PID of the window to refocus.
      # @return [Boolean] True if refocus was successful, false otherwise.
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

      # Refocuses the macOS window for the given PID.
      # @param pid [Integer] The PID of the window to refocus.
      # @return [Boolean] True if refocus was successful, false otherwise.
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

      # Refocuses the Linux window for the given PID.
      # @param pid [Integer] The PID of the window to refocus.
      # @return [Boolean] True if refocus was successful, false otherwise.
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

      # Ensures that the necessary Windows modules are loaded.
      # @return [Boolean] True if modules are loaded, false otherwise.
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

# Top-level alias so all consumers can use bare `Frontend`
Frontend = Lich::Common::Frontend unless defined?(Frontend)
