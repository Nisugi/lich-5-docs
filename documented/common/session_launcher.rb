# frozen_string_literal: true

require 'rbconfig'
require_relative 'authentication/login_helpers'

# Provides common functionality for the Lich application.
#
# @see Lich::Common::SessionLauncher
module Lich
  module Common
    module SessionLauncher
      OPTIONAL_PATH_FLAGS = [
        { option: 'home', key: :home_dir, constant: :LICH_DIR },
        { option: 'data', key: :data_dir, constant: :DATA_DIR },
        { option: 'scripts', key: :script_dir, constant: :SCRIPT_DIR },
        { option: 'temp', key: :temp_dir, constant: :TEMP_DIR },
        { option: 'maps', key: :map_dir, constant: :MAP_DIR },
        { option: 'logs', key: :log_dir, constant: :LOG_DIR },
        { option: 'backup', key: :backup_dir, constant: :BACKUP_DIR },
        { option: 'lib', key: :lib_dir, constant: :LIB_DIR }
      ].freeze

      class << self
        # Launches a new session process with the given launch data.
        #
        # @param launch_data [Array] an array of data required to launch the session
        # @param launch_context [Hash, nil] optional context for the launch
        # @return [Hash] result of the launch operation, including success status and process ID
        # @raise [ArgumentError] if launch_data is not a non-empty array
        # @example Launch a session
        #   result = Lich::Common::SessionLauncher.launch(['--option', 'value'])
        def launch(launch_data, launch_context: nil)
          unless launch_data.is_a?(Array) && launch_data.any?
            return { ok: false, error: 'launch_data must be a non-empty Array' }
          end

          pid = spawn_process(launch_data, launch_context: launch_context)
          { ok: true, pid: pid }
        rescue StandardError => e
          { ok: false, error: e.message }
        end

        private

        # Spawns a new process for the session using the provided launch data.
        #
        # @param launch_data [Array] an array of data required to spawn the process
        # @param launch_context [Hash, nil] optional context for the launch
        # @return [Integer] the process ID of the spawned process
        def spawn_process(launch_data, launch_context: nil)
          ruby_bin = ruby_binary
          entrypoint = File.expand_path($PROGRAM_NAME)
          context = launch_context || {}
          working_dir = resolve_working_dir(context)
          launch_map = parse_launch_data(launch_data)
          spawn_args = build_spawn_args(entrypoint, launch_map, launch_context)

          pid = spawn(ruby_bin, *spawn_args, chdir: working_dir)
          Process.detach(pid)
          pid
        end

        # Resolves the working directory based on the provided context.
        #
        # @param context [Hash] the context containing potential directory overrides
        # @return [String] the resolved working directory path
        def resolve_working_dir(context)
          home_dir = context[:home_dir]
          return File.expand_path(home_dir) unless home_dir.to_s.empty?

          defined?(LICH_DIR) ? LICH_DIR : Dir.pwd
        end

        # Builds the arguments for spawning the session process.
        #
        # @param entrypoint [String] the entry point for the session
        # @param launch_map [Hash] parsed launch data
        # @param launch_context [Hash, nil] optional context for the launch
        # @return [Array<String>] the arguments to be passed to the spawn command
        # @raise [ArgumentError] if the character name is missing
        def build_spawn_args(entrypoint, launch_map, launch_context)
          context = launch_context || {}
          character = context[:char_name] || launch_map['CHARACTER'] || launch_map['NAME']
          game_code = context[:game_code] || launch_map['GAMECODE']
          frontend = context[:frontend] || frontend_from_launch(launch_map)
          custom_launch = context[:custom_launch] || launch_map['CUSTOMLAUNCH']

          raise ArgumentError, 'missing character for launcher spawn' if character.to_s.empty?

          args = [entrypoint, '--login', character.to_s]
          if game_code && !game_code.to_s.empty?
            game_flag = Lich::Common::Authentication::LoginHelpers.format_launch_flag(game_code)
            args << game_flag if game_flag
          end
          args << "--#{frontend}" if frontend && !frontend.to_s.empty?
          args << "--custom-launch=#{custom_launch}" if custom_launch && !custom_launch.to_s.empty?
          args.concat(optional_spawn_flags(context))
          args
        end

        # Constructs optional flags for the spawn command based on the context.
        #
        # @param context [Hash] the context containing potential flag values
        # @return [Array<String>] an array of optional flags for the spawn command
        def optional_spawn_flags(context)
          flags = []

          dark_mode = resolve_dark_mode(context)
          flags << "--dark-mode=#{dark_mode}" unless dark_mode.nil?

          OPTIONAL_PATH_FLAGS.each do |path_flag|
            value = overridden_path_value(context, path_flag)
            next if value.to_s.empty?

            flags << "--#{path_flag[:option]}=#{value}"
          end

          flags
        end

        # Parses the launch data from an array of strings into a hash.
        #
        # @param launch_data [Array] the raw launch data strings
        # @return [Hash] a hash mapping keys to values parsed from the launch data
        def parse_launch_data(launch_data)
          launch_data.each_with_object({}) do |line, data|
            next unless line.include?('=')

            key, value = line.split('=', 2)
            data[key.to_s.upcase] = value.to_s
          end
        end

        # Determines the frontend type based on the launch map.
        #
        # @param launch_map [Hash] the parsed launch data
        # @return [String, nil] the frontend type or nil if not found
        def frontend_from_launch(launch_map)
          case launch_map['GAME'].to_s.upcase
          when 'STORM' then 'stormfront'
          when 'WIZ' then 'wizard'
          when 'AVALON' then 'avalon'
          when 'SUKS' then 'suks'
          else nil
          end
        end

        # Resolves the dark mode setting from the context.
        #
        # @param context [Hash] the context containing dark mode information
        # @return [Boolean, nil] the dark mode setting or nil if not applicable
        def resolve_dark_mode(context)
          return context[:dark_mode] if context.key?(:dark_mode)
          return nil unless Lich.respond_to?(:track_dark_mode)

          Lich.track_dark_mode
        end

        # Retrieves the overridden path value from the context for a specific path flag.
        #
        # @param context [Hash] the context containing potential path values
        # @param path_flag [Hash] the path flag definition
        # @return [String, nil] the overridden path value or nil if not applicable
        def overridden_path_value(context, path_flag)
          context_key = path_flag[:key]
          constant_name = path_flag[:constant]
          return nil unless context.key?(context_key)

          value = context[context_key]
          return nil if value.to_s.empty?

          value_expanded = File.expand_path(value.to_s)
          default_value = default_path_value(path_flag[:option], constant_name, context)
          return nil if default_value && value_expanded == default_value

          value
        end

        # Determines the default path value for a given option name and constant name.
        #
        # @param option_name [String] the name of the option to resolve
        # @param constant_name [Symbol] the constant name to use for default resolution
        # @param context [Hash] the context containing potential directory overrides
        # @return [String, nil] the default path value or nil if not applicable
        def default_path_value(option_name, constant_name, context)
          if option_name == 'home'
            return Object.const_defined?(:LICH_DIR) ? File.expand_path(Object.const_get(:LICH_DIR).to_s) : nil
          end

          home_override = context[:home_dir]
          if !home_override.to_s.empty?
            return File.expand_path(File.join(home_override.to_s, option_name))
          end

          return nil unless Object.const_defined?(constant_name)

          File.expand_path(Object.const_get(constant_name).to_s)
        end

        # Retrieves the appropriate Ruby binary for the current platform.
        #
        # @return [String] the path to the Ruby binary
        def ruby_binary
          if windows?
            RbConfig.ruby.sub(/ruby(?:\.exe)?$/i, 'rubyw.exe')
          else
            RbConfig.ruby
          end
        end

        # Checks if the current platform is Windows.
        #
        # @return [Boolean] true if the platform is Windows, false otherwise
        def windows?
          RUBY_PLATFORM =~ /mingw|mswin|cygwin/i
        end
      end
    end
  end
end
