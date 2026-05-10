=begin
util.rb: Core lich file for collection of utilities to extend Lich capabilities.
Entries added here should always be accessible from Lich::Util.feature namespace.
=end

module Lich
  # Provides a collection of utility methods to extend Lich capabilities.
  #
  # All entries added here should be accessible from the Lich::Util feature namespace.
  module Util
    include Enumerable

    # Normalizes the lookup for effects based on the provided value.
    #
    # @param effect [String] the name of the effect to look up.
    # @param val [String, Integer, Symbol] the value to normalize and check.
    # @return [Boolean] true if the normalized value exists, false otherwise.
    # @raise [RuntimeError] if the lookup case is invalid.
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
    # @param name [String] the name to normalize.
    # @return [String] the normalized name.
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
    # @param prefix [String] an optional prefix for the hook name.
    # @return [String] the generated anonymous hook name.
    def self.anon_hook(prefix = '')
      now = Time.now
      "Util::#{prefix}-#{now}-#{Random.rand(10000)}"
    end

    # Issues a command and captures the output based on the provided patterns.
    #
    # @param command [String] the command to execute.
    # @param start_pattern [Regexp] the pattern to identify the start of the output.
    # @param end_pattern [Regexp] the pattern to identify the end of the output (default: /<prompt/).
    # @param include_end [Boolean] whether to include the end line in the result (default: true).
    # @param timeout [Integer] the maximum time to wait for the command to complete (default: 5).
    # @param silent [Boolean, nil] whether to suppress output (default: nil).
    # @param usexml [Boolean] whether to use XML output (default: true).
    # @param quiet [Boolean] whether to suppress output during processing (default: false).
    # @param use_fput [Boolean] whether to use fput instead of put (default: true).
    # @return [Array<String>] the lines of output captured from the command.
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
    # @param command [String] the command to execute.
    # @param start_pattern [Regexp] the pattern to identify the start of the output.
    # @param end_pattern [Regexp] the pattern to identify the end of the output (default: /<prompt/).
    # @param include_end [Boolean] whether to include the end line in the result (default: true).
    # @param timeout [Integer] the maximum time to wait for the command to complete (default: 5).
    # @param silent [Boolean] whether to suppress output (default: true).
    # @return [Array<String>] the lines of output captured from the command.
    def self.quiet_command_xml(command, start_pattern, end_pattern = /<prompt/, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: true, quiet: true)
    end

    # Issues a command quietly and captures the output.
    #
    # @param command [String] the command to execute.
    # @param start_pattern [Regexp] the pattern to identify the start of the output.
    # @param end_pattern [Regexp] the pattern to identify the end of the output.
    # @param include_end [Boolean] whether to include the end line in the result (default: true).
    # @param timeout [Integer] the maximum time to wait for the command to complete (default: 5).
    # @param silent [Boolean] whether to suppress output (default: true).
    # @return [Array<String>] the lines of output captured from the command.
    def self.quiet_command(command, start_pattern, end_pattern, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: false, quiet: true)
    end

    # Retrieves the count of silver from the output of a command.
    #
    # @param timeout [Integer] the maximum time to wait for the command to complete (default: 3).
    # @return [Integer] the count of silver.
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

    # Installs the specified Ruby gems and requires them if specified.
    #
    # @param gems_to_install [Hash] a hash of gem names and whether to require them.
    # @param user_install [Boolean] whether to install gems for the user (default: false).
    # @raise [ArgumentError] if gems_to_install is not a Hash or has invalid keys/values.
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
    # Recursively freezes an object and its contents.
    #
    # @param obj [Object] the object to freeze.
    # @return [Object] the frozen object.
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
