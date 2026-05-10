=begin
util.rb: Core lich file for collection of utilities to extend Lich capabilities.
Entries added here should always be accessible from Lich::Util.feature namespace.
=end

# Provides utility methods to extend Lich capabilities.
#
# This module includes various utility functions that can be used throughout the Lich framework.
# @see Lich::Util
module Lich
  module Util
    include Enumerable

    # Normalizes a lookup for effects based on the provided value.
    #
    # This method checks if the provided value exists in the specified effect's mappings.
    # @param effect [String] the name of the effect to look up
    # @param val [String, Integer, Symbol] the value to normalize and check
    # @return [Boolean] true if the value exists in the effect's mappings
    # @raise [RuntimeError] if the lookup case is invalid
    def self.normalize_lookup(effect, val)
      caller_type = "Effects::#{effect}"
      case val
      when String
        (eval caller_type).to_h.transform_keys(&:to_s).transform_keys(&:downcase).include?(val.downcase.gsub('_', ' '))
      when Integer
        #      seek = mappings.fetch(val, nil)
        (eval caller_type).active?(val)
      when Symbol
        (eval caller_type).to_h.transform_keys(&:to_s).transform_keys(&:downcase).include?(val.to_s.downcase.gsub('_', ' '))
      else
        fail "invalid lookup case #{val.class.name}"
      end
    end

    # Normalizes a given name by converting it to a lowercase string and replacing or removing certain characters.
    #
    # The normalization process handles the following cases:
    # - Converts spaces and hyphens to underscores.
    # - Removes colons and apostrophes.
    # - Converts symbols to strings.
    # Normalizes a given name by converting it to a lowercase string and replacing or removing certain characters.
    #
    # The normalization process handles the following cases:
    # - Converts spaces and hyphens to underscores.
    # - Removes colons and apostrophes.
    # - Converts symbols to strings.
    # @param name [String, Symbol] the name to normalize
    # @return [String] the normalized name
    def self.normalize_name(name)
      normal_name = name.to_s.downcase
      normal_name.gsub!(' ', '_') if name =~ (/\s/)
      normal_name.gsub!('-', '_') if name =~ (/-/)
      normal_name.gsub!(":", '') if name =~ (/:/)
      normal_name.gsub!("'", '') if name =~ (/'/)
      normal_name
    end

    # Generates a unique anonymous hook name based on the current time and a random number.
    #
    # This method is useful for creating unique identifiers for hooks that do not need to be referenced later.
    # @param prefix [String] an optional prefix for the hook name
    # @return [String] a unique hook name
    def self.anon_hook(prefix = '')
      now = Time.now
      "Util::#{prefix}-#{now}-#{Random.rand(10000)}"
    end

    # Issues a command and captures the output based on specified patterns.
    #
    # This method allows for executing commands and processing their output until certain patterns are matched.
    # @param command [String] the command to execute
    # @param start_pattern [Regexp] the pattern to start capturing output
    # @param end_pattern [Regexp] the pattern to stop capturing output (default: /<prompt/)
    # @param include_end [Boolean] whether to include the end line in the result (default: true)
    # @param timeout [Integer] the maximum time to wait for the command to complete (default: 5)
    # @param silent [Boolean, nil] whether to suppress output (default: nil)
    # @param usexml [Boolean] whether to use XML output (default: true)
    # @param quiet [Boolean] whether to suppress output during processing (default: false)
    # @param use_fput [Boolean] whether to use fput instead of put (default: true)
    # @return [Array<String>] the captured output lines
    def self.issue_command(command, start_pattern, end_pattern = /<prompt/, include_end: true, timeout: 5, silent: nil, usexml: true, quiet: false, use_fput: true)
      result = []
      name = self.anon_hook
      filter = false
      ignore_end = end_pattern.eql?(:ignore)

      save_script_silent = Script.current.silent
      save_want_downstream = Script.current.want_downstream
      save_want_downstream_xml = Script.current.want_downstream_xml

      Script.current.silent = silent if !silent.nil?
      Script.current.want_downstream = !usexml
      Script.current.want_downstream_xml = usexml

      begin
        Timeout::timeout(timeout, Interrupt) {
          DownstreamHook.add(name, proc { |line|
            if filter
              if ignore_end || line =~ end_pattern
                DownstreamHook.remove(name)
                filter = false
                if quiet && !ignore_end
                  next(nil)
                else
                  line
                end
              else
                if quiet
                  next(nil)
                else
                  line
                end
              end
            elsif line =~ start_pattern
              filter = true
              if quiet
                next(nil)
              else
                line
              end
            else
              line
            end
          })
          use_fput ? fput(command) : put(command)

          until (line = get) =~ start_pattern; end
          result << line.rstrip
          unless ignore_end
            until (line = get) =~ end_pattern
              result << line.rstrip
            end
          end
          unless ignore_end
            if include_end
              result << line.rstrip
            end
          end
        }
      rescue Interrupt
        nil
      ensure
        DownstreamHook.remove(name)
        Script.current.silent = save_script_silent if !silent.nil?
        Script.current.want_downstream = save_want_downstream
        Script.current.want_downstream_xml = save_want_downstream_xml
      end
      return result
    end

    # Issues a command quietly and captures the output in XML format.
    #
    # This method is a wrapper around issue_command to simplify quiet XML command execution.
    # @param command [String] the command to execute
    # @param start_pattern [Regexp] the pattern to start capturing output
    # @param end_pattern [Regexp] the pattern to stop capturing output (default: /<prompt/)
    # @param include_end [Boolean] whether to include the end line in the result (default: true)
    # @param timeout [Integer] the maximum time to wait for the command to complete (default: 5)
    # @param silent [Boolean] whether to suppress output (default: true)
    # @return [Array<String>] the captured output lines
    def self.quiet_command_xml(command, start_pattern, end_pattern = /<prompt/, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: true, quiet: true)
    end

    # Issues a command quietly and captures the output.
    #
    # This method is a wrapper around issue_command to simplify quiet command execution.
    # @param command [String] the command to execute
    # @param start_pattern [Regexp] the pattern to start capturing output
    # @param end_pattern [Regexp] the pattern to stop capturing output
    # @param include_end [Boolean] whether to include the end line in the result (default: true)
    # @param timeout [Integer] the maximum time to wait for the command to complete (default: 5)
    # @param silent [Boolean] whether to suppress output (default: true)
    # @return [Array<String>] the captured output lines
    def self.quiet_command(command, start_pattern, end_pattern, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: false, quiet: true)
    end

    # Retrieves the silver count from the current context.
    #
    # This method captures output until the silver count is found and returns it as an integer.
    # @param timeout [Integer] the maximum time to wait for the silver count (default: 3)
    # @return [Integer] the silver count
    def self.silver_count(timeout = 3)
      silence_me unless (undo_silence = silence_me)
      result = ''
      name = self.anon_hook
      filter = false

      start_pattern = /^\s*Name\:/
      end_pattern = /^\s*Mana\:\s+\-?[0-9]+\s+Silver\:\s+([0-9,]+)/
      ttl = Time.now + timeout
      begin
        # main thread
        DownstreamHook.add(name, proc { |line|
          if filter
            if line =~ end_pattern
              result = $1.dup
              DownstreamHook.remove(name)
              filter = false
            else
              next(nil)
            end
          elsif line =~ start_pattern
            filter = true
            next(nil)
          else
            line
          end
        })
        # script thread
        fput 'info'
        loop {
          # non-blocking check, this allows us to
          # check the time even when the buffer is empty
          line = get?
          break if line && line =~ end_pattern
          break if Time.now > ttl
          sleep(0.01) # prevent a tight-loop
        }
      ensure
        DownstreamHook.remove(name)
        silence_me if undo_silence
      end
      return result.gsub(',', '').to_i
    end

    # Installs the specified Ruby gems and requires them if needed.
    #
    # This method checks for missing gems, installs them, and requires them based on the provided hash.
    # @param gems_to_install [Hash] a hash of gem names and whether to require them
    # @param user_install [Boolean] whether to install gems for the user (default: false)
    # @raise [ArgumentError] if gems_to_install is not a Hash
    # @return [void]
    def self.install_gem_requirements(gems_to_install, user_install: false)
      raise ArgumentError, "install_gem_requirements must be passed a Hash" unless gems_to_install.is_a?(Hash)
      require "rubygems"
      require "rubygems/dependency_installer"
      installer = Gem::DependencyInstaller.new({ :user_install => user_install, :document => nil })
      installed_gems = Gem::Specification.map { |gem| gem.name }.sort.uniq
      failed_gems = []

      gems_to_install.each do |gem_name, should_require|
        unless gem_name.is_a?(String) && (should_require.is_a?(TrueClass) || should_require.is_a?(FalseClass))
          raise ArgumentError, "install_gem_requirements must be passed a Hash with String key and TrueClass/FalseClass as value"
        end
        begin
          unless installed_gems.include?(gem_name)
            respond("--- Lich: Installing missing ruby gem '#{gem_name}' now, please wait!") if defined?(Script)
            Lich.log("--- Lich: Installing missing ruby gem '#{gem_name}' now, please wait!")
            result = installer.install(gem_name)
            Gem.clear_paths
            Gem::Specification.reset
            Gem::Specification.find_by_name(gem_name).activate
            Lich.log("RubyGem Installer Result: #{result.inspect}")
            unless Gem::Specification.map { |gem| gem.name }.sort.uniq.include?(gem_name)
              Lich.log("RubyGems failed, attempting system method instead!")
              result = system(File.join(RbConfig::CONFIG['bindir'], 'gem'), 'install', gem_name)
              Lich.log("SYSTEM Call Result: #{result.inspect}")
              Gem.clear_paths
              Gem::Specification.reset
              Gem::Specification.find_by_name(gem_name).activate
            end
            respond("--- Lich: Done installing '#{gem_name}' gem!") if defined?(Script)
            Lich.log("--- Lich: Done installing '#{gem_name}' gem!")
          end
          require gem_name if should_require
        rescue LoadError, StandardError
          respond("--- Lich: error: Failed to install/require Ruby gem: #{gem_name}") if defined?(Script)
          respond("--- Lich: error: #{$!}") if defined?(Script)
          Lich.log("installed_gems.include?(#{gem_name}): #{installed_gems.include?(gem_name)} - #{installed_gems.find_all { |gem| gem == gem_name }.inspect}")
          Lich.log("error: Failed to install/require Ruby gem: #{gem_name}")
          Lich.log("error: #{$!}")
          failed_gems.push(gem_name)
        end
      end
      unless failed_gems.empty?
        if defined?(Script.current.name) && Script.current.name != "unknown"
          raise("Please install the failed gems: #{failed_gems.join(', ')} manually to run #{$lich_char}#{Script.current.name}")
        else
          raise("Please install the failed gems: #{failed_gems.join(', ')} manually to continue.")
        end
      end
    end

    ##
    # Deep freezes an object, including all nested elements.
    #
    # This method recursively freezes hashes and arrays to ensure immutability.
    # @param obj [Object] the object to deep freeze
    # @return [Object] the frozen object
    def self.deep_freeze(obj)
      case obj
      when Hash
        obj.each do |k, v|
          deep_freeze(k)
          deep_freeze(v)
        end
      when Array
        obj.each { |el| deep_freeze(el) }
      end
      obj.freeze
    end
  end
end
