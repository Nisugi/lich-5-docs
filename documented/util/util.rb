=begin
util.rb: Core lich file for collection of utilities to extend Lich capabilities.
Entries added here should always be accessible from Lich::Util.feature namespace.
=end

module Lich
  # Provides a collection of utilities to extend Lich capabilities.
  # Entries added here should always be accessible from Lich::Util feature namespace.
  # @example Accessing a utility method
  #   Lich::Util.normalize_name("Example Name")
  module Util
    include Enumerable

    # Normalizes the lookup for effects based on the value type.
    # @param effect [String] The effect type to look up.
    # @param val [String, Integer, Symbol] The value to normalize.
    # @return [Boolean] True if the lookup is valid, false otherwise.
    # @raise [RuntimeError] If the value type is invalid.
    # @example
    #   Lich::Util.normalize_lookup("some_effect", "some_value")
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
    # @param name [String, Symbol] The name to normalize.
    # @return [String] The normalized name.
    # @example
    #   Lich::Util.normalize_name("Example Name")
    def self.normalize_name(name)
      normal_name = name.to_s.downcase
      normal_name.gsub!(' ', '_') if name =~ (/\s/)
      normal_name.gsub!('-', '_') if name =~ (/-/)
      normal_name.gsub!(":", '') if name =~ (/:/)
      normal_name.gsub!("'", '') if name =~ (/'/)
      normal_name
    end

    # Generates a unique anonymous hook name based on the current time and a prefix.
    # @param prefix [String] An optional prefix for the hook name.
    # @return [String] The generated anonymous hook name.
    # @example
    #   Lich::Util.anon_hook("test")
    def self.anon_hook(prefix = '')
      now = Time.now
      "Util::#{prefix}-#{now}-#{Random.rand(10000)}"
    end

    # Issues a command and captures the output based on start and end patterns.
    # @param command [String] The command to issue.
    # @param start_pattern [Regexp] The pattern to identify the start of the output.
    # @param end_pattern [Regexp] The pattern to identify the end of the output (default: /<prompt/).
    # @param include_end [Boolean] Whether to include the end line in the result (default: true).
    # @param timeout [Integer] The timeout for the command (default: 5).
    # @param silent [Boolean, nil] Whether to suppress output (default: nil).
    # @param usexml [Boolean] Whether to use XML output (default: true).
    # @param quiet [Boolean] Whether to suppress output during processing (default: false).
    # @param use_fput [Boolean] Whether to use fput instead of put (default: true).
    # @return [Array<String>] The captured output lines.
    # @raise [Timeout::Error] If the command times out.
    # @example
    #   output = Lich::Util.issue_command("some_command", /start_pattern/, /end_pattern/)
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
    # @param command [String] The command to issue.
    # @param start_pattern [Regexp] The pattern to identify the start of the output.
    # @param end_pattern [Regexp] The pattern to identify the end of the output (default: /<prompt/).
    # @param include_end [Boolean] Whether to include the end line in the result (default: true).
    # @param timeout [Integer] The timeout for the command (default: 5).
    # @param silent [Boolean] Whether to suppress output (default: true).
    # @return [Array<String>] The captured output lines.
    # @example
    #   output = Lich::Util.quiet_command_xml("some_command", /start_pattern/, /end_pattern/)
    def self.quiet_command_xml(command, start_pattern, end_pattern = /<prompt/, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: true, quiet: true)
    end

    # Issues a command quietly and captures the output.
    # @param command [String] The command to issue.
    # @param start_pattern [Regexp] The pattern to identify the start of the output.
    # @param end_pattern [Regexp] The pattern to identify the end of the output.
    # @param include_end [Boolean] Whether to include the end line in the result (default: true).
    # @param timeout [Integer] The timeout for the command (default: 5).
    # @param silent [Boolean] Whether to suppress output (default: true).
    # @return [Array<String>] The captured output lines.
    # @example
    #   output = Lich::Util.quiet_command("some_command", /start_pattern/, /end_pattern/)
    def self.quiet_command(command, start_pattern, end_pattern, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: false, quiet: true)
    end

    # Counts the amount of silver available within a specified timeout.
    # @param timeout [Integer] The timeout for the count operation (default: 3).
    # @return [Integer] The amount of silver counted.
    # @example
    #   silver_amount = Lich::Util.silver_count(5)
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
    # @param gems_to_install [Hash] A hash of gem names and whether to require them after installation.
    # @raise [ArgumentError] If the input is not a hash or has invalid types.
    # @example
    #   Lich::Util.install_gem_requirements({"gem_name" => true})
    def self.install_gem_requirements(gems_to_install)
      raise ArgumentError, "install_gem_requirements must be passed a Hash" unless gems_to_install.is_a?(Hash)
      require "rubygems"
      require "rubygems/dependency_installer"
      installer = Gem::DependencyInstaller.new({ :user_install => true, :document => nil })
      installed_gems = Gem::Specification.map { |gem| gem.name }.sort.uniq
      failed_gems = []

      gems_to_install.each do |gem_name, should_require|
        unless gem_name.is_a?(String) && (should_require.is_a?(TrueClass) || should_require.is_a?(FalseClass))
          raise ArgumentError, "install_gem_requirements must be passed a Hash with String key and TrueClass/FalseClass as value"
        end
        begin
          unless installed_gems.include?(gem_name)
            respond("--- Lich: Installing missing ruby gem '#{gem_name}' now, please wait!")
            installer.install(gem_name)
            respond("--- Lich: Done installing '#{gem_name}' gem!")
          end
          require gem_name if should_require
        rescue StandardError
          respond("--- Lich: error: Failed to install Ruby gem: #{gem_name}")
          respond("--- Lich: error: #{$!}")
          Lich.log("error: Failed to install Ruby gem: #{gem_name}")
          Lich.log("error: #{$!}")
          failed_gems.push(gem_name)
        end
      end
      unless failed_gems.empty?
        raise("Please install the failed gems: #{failed_gems.join(', ')} to run #{$lich_char}#{Script.current.name}")
      end
    end

    ##
    # Deep freezes an object, including all nested elements.
    # @param obj [Object] The object to deep freeze.
    # @return [Object] The deep-frozen object.
    # @example
    #   frozen_obj = Lich::Util.deep_freeze({"key" => "value"})
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
