module Lich
  module Common
    # A proxy class for managing settings with a target object.
    #
    # This class allows for dynamic delegation of method calls to a target object,
    # while maintaining a context of scope and path for settings management.
    #
    # @see Lich::Common::Settings
    class SettingsProxy
      LOG_PREFIX = "[SettingsProxy]".freeze

      # Initializes a new SettingsProxy instance.
      #
      # @param settings_module [Module] the settings module to use for logging and management
      # @param scope [Object] the scope in which the settings are applied
      # @param path [Array] the path to the settings
      # @param target [Object] the target object to delegate method calls to
      # @param detached [Boolean] whether the proxy is detached from the target (default: false)
      # @param script_name [String, nil] optional script name for logging
      # @return [SettingsProxy]
      def initialize(settings_module, scope, path, target, detached: false, script_name: nil)
        @settings_module = settings_module # This should be the Settings module itself
        @scope  = scope
        @path   = path.dup
        @target = target
        @detached = detached
        @script_name = script_name
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "INIT scope: #{@scope.inspect}, path: #{@path.inspect}, target_class: #{@target.class}, target_object_id: #{@target.object_id}, detached: #{@detached}, script_name: #{@script_name.inspect}" })
      end

      attr_reader :target, :path, :scope, :script_name

      # Checks if the proxy is detached from its target.
      #
      # @return [Boolean] true if the proxy is detached, false otherwise
      def detached?
        !!@detached
      end

      def nil?
        @target.nil?
      end

      # Performs a binary operation with the target object.
      #
      # @param operator [Symbol] the operator to apply (e.g., :+, :-, :==)
      # @param other [Object] the other operand for the operation
      # @return [Object] the result of the operation
      def binary_op(operator, other)
        other_value = other.is_a?(SettingsProxy) ? other.target : other
        @target.send(operator, other_value)
      end

      [:==, :!=, :eql?, :equal?, :<=>, :<, :<=, :>, :>=, :|, :&].each do |op|
        define_method(op) do |other|
          binary_op(op, other)
        end
      end

      # Returns the hash value of the target object.
      #
      # @return [Integer] the hash value of the target
      def hash
        @target.hash
      end

      # Helper method for delegating conversion methods with appropriate return types
      # Helper method for delegating conversion methods with appropriate return types.
      #
      # @param method [Symbol] the conversion method to delegate (e.g., :to_s)
      # @param options [Hash] options for delegation, including :strict and :default
      # @return [Object] the result of the delegated method or default value
      private def delegate_conversion(method, options = {})
        if @target.respond_to?(method)
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "#{method}: delegating" })
          @target.send(method)
        else
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "#{method}: not supported" })

          if options[:strict]
            # For strict methods, raise NoMethodError
            raise NoMethodError.new("undefined method `#{method}' for #{@target.inspect}:#{@target.class}")
          else
            # For permissive methods, return the default value
            options[:default]
          end
        end
      end

      # Rebinds the proxy to a new target object.
      #
      # @param new_target [Object] the new target object to bind to
      # @return [SettingsProxy] self for method chaining
      private def rebind_to_live!(new_target)
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> {
          "REBIND to live: old_target_oid=#{@target&.object_id}, new_target_oid=#{new_target&.object_id}, scope=#{@scope.inspect}, path=#{@path.inspect}"
        })
        @target = new_target
        @detached = false if instance_variable_defined?(:@detached)
        self
      end

      def to_s
        delegate_conversion(:to_s, default: '')
      end

      def to_str
        delegate_conversion(:to_str, strict: true)
      end

      def to_sym
        delegate_conversion(:to_sym, strict: true)
      end

      def to_i
        delegate_conversion(:to_i, default: 0)
      end

      def to_int
        delegate_conversion(:to_int, strict: true)
      end

      def to_f
        delegate_conversion(:to_f, default: 0.0)
      end

      def to_r
        delegate_conversion(:to_r, strict: true)
      end

      def to_c
        delegate_conversion(:to_c, default: Complex(0, 0))
      end

      def to_a
        delegate_conversion(:to_a, default: [])
      end

      def to_ary
        delegate_conversion(:to_ary, strict: true)
      end

      def to_h
        delegate_conversion(:to_h, default: {})
      end

      def to_hash
        delegate_conversion(:to_hash, strict: true)
      end

      # Converts the target object to JSON format.
      #
      # @param args [Array] optional arguments for JSON conversion
      # @return [String] the JSON representation of the target object
      # @raise [NoMethodError] if the target does not respond to :to_json
      def to_json(*args)
        if @target.respond_to?(:to_json)
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "to_json: delegating with args" })
          @target.to_json(*args)
        else
          raise NoMethodError, "undefined method :to_json for #{@target.inspect}:#{@target.class}"
        end
      end

      def to_proc
        delegate_conversion(:to_proc, strict: true)
      end

      def to_io
        delegate_conversion(:to_io, strict: true)
      end

      def to_path
        delegate_conversion(:to_path, strict: true)
      end

      def to_enum(*args, &block)
        if @target.respond_to?(:to_enum)
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "to_enum: delegating" })
          @target.to_enum(*args, &block)
        else
          @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "to_enum: using default enum_for" })
          self.enum_for(*args, &block)
        end
      end

      def inspect
        @target.inspect
      end

      def proxy_details
        "<SettingsProxy scope=#{@scope.inspect} path=#{@path.inspect} target_class=#{@target.class} target_object_id=#{@target.object_id} detached=#{@detached} script_name=#{@script_name.inspect}>"
      end

      def pretty_print(pp)
        pp.pp(@target)
      end

      def is_a?(klass)
        @target.is_a?(klass)
      end

      def kind_of?(klass)
        @target.kind_of?(klass)
      end

      def instance_of?(klass)
        @target.instance_of?(klass)
      end

      def respond_to?(method, include_private = false)
        super || @target.respond_to?(method, include_private)
      end

      def each(&_block)
        return enum_for(:each) unless block_given?
        if @target.respond_to?(:each)
          @target.each do |item|
            if @settings_module.container?(item)
              yield SettingsProxy.new(@settings_module, @scope, [], item, detached: true, script_name: @script_name)
            else
              yield item
            end
          end
        end
        self
      end

      NON_DESTRUCTIVE_METHODS = [
        :+, :-, :&, :|, :*,
        :all?, :any?, :assoc, :at, :bsearch, :bsearch_index, :chunk, :chunk_while,
        :collect, :collect_concat, :compact, :compare_by_identity?, :count, :cycle,
        :default, :default_proc, :detect, :dig, :drop, :drop_while,
        :each_cons, :each_entry, :each_slice, :each_with_index, :each_with_object, :empty?,
        :entries, :except, :fetch, :fetch_values, :filter, :find, :find_all, :find_index,
        :first, :flat_map, :flatten, :frozen?, :grep, :grep_v, :group_by, :has_value?,
        :include?, :inject, :invert, :join, :key, :keys, :last, :lazy, :length,
        :map, :max, :max_by, :member?, :merge, :min, :min_by, :minmax, :minmax_by,
        :none?, :one?, :pack, :partition, :permutation, :product, :rassoc, :reduce,
        :reject, :reverse, :rotate, :sample, :select, :shuffle, :size, :slice,
        :slice_after, :slice_before, :slice_when, :sort, :sort_by, :sum,
        :take, :take_while, :to_a, :to_h, :to_proc, :transform_keys, :transform_values,
        :uniq, :values, :values_at, :zip
      ].freeze

      # Subset of non-destructive methods that return container "views"
      NON_DESTRUCTIVE_CONTAINER_VIEWS = [
        :map, :collect, :select, :filter, :reject, :find_all, :grep, :grep_v,
        :sort, :sort_by, :uniq, :compact, :flatten, :slice, :take, :drop, :values
      ].freeze

      def [](key)
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "GET scope: #{@scope.inspect}, path: #{@path.inspect}, key: #{key.inspect}, target_object_id: #{@target.object_id}" })
        value = @target[key]
        if @settings_module.container?(value)
          new_path = @path.dup
          new_path << key
          SettingsProxy.new(@settings_module, @scope, new_path, value, script_name: @script_name)
        else
          value
        end
      end

      def []=(key, value)
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "SET scope: #{@scope.inspect}, path: #{@path.inspect}, key: #{key.inspect}, value: #{value.inspect}, target_object_id: #{@target.object_id}" })
        actual_value = value.is_a?(SettingsProxy) ? @settings_module.unwrap_proxies(value) : value # Corrected to use @settings_module
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "SET   target_before_set: #{@target.inspect}" })
        @target[key] = actual_value
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "SET   target_after_set: #{@target.inspect}" })
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "SET   calling save_proxy_changes on settings module" })
        @settings_module.save_proxy_changes(self)
        # rubocop:disable Lint/Void
        # This is Ruby expected behavior to return the value.
        value
        # rubocop:enable Lint/Void
      end

      # Handles calls to methods that are not explicitly defined in the proxy.
      #
      # This method delegates the call to the target object if it responds to the method.
      #
      # @param method [Symbol] the name of the method being called
      # @param args [Array] arguments for the method call
      # @param block [Proc] optional block for the method call
      # @return [Object] the result of the method call or raises NoMethodError
      def method_missing(method, *args, &block)
        @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL scope: #{@scope.inspect}, path: #{@path.inspect}, method: #{method}, args: #{args.inspect}, target_object_id: #{@target.object_id}" })
        if @target.respond_to?(method)
          if NON_DESTRUCTIVE_METHODS.include?(method)
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   non-destructive method: #{method}" })
            target_dup = @target.dup
            unwrapped_args = args.map { |arg| arg.is_a?(SettingsProxy) ? @settings_module.unwrap_proxies(arg) : arg } # Corrected
            result = target_dup.send(method, *unwrapped_args, &block)
            # Minimal change: pass method name so we can tag views as detached and keep path
            return handle_non_destructive_result(method, result)
          else
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   destructive method: #{method}" })

            # NEW (5.12.7+): auto-reattach derived views before mutating
            # ensure destructive methods (.push) do not target a proxy non-destructive method (.sort)
            if detached?
              unless @settings_module._reattach_live!(self)
                @settings_module._log(Settings::LOG_LEVEL_ERROR, LOG_PREFIX, -> { "CALL   reattach failed; aborting destructive op #{method} on detached view" })
                return self
              end
            end

            unwrapped_args = args.map { |arg| arg.is_a?(SettingsProxy) ? @settings_module.unwrap_proxies(arg) : arg } # Corrected
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   target_before_op: #{@target.inspect}" })
            result = @target.send(method, *unwrapped_args, &block)
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   target_after_op: #{@target.inspect}" })
            @settings_module._log(Settings::LOG_LEVEL_DEBUG, LOG_PREFIX, -> { "CALL   calling save_proxy_changes on settings module" })
            @settings_module.save_proxy_changes(self)
            return handle_method_result(result)
          end
        else
          super
        end
      end

      # Handles the result of non-destructive method calls.
      #
      # @param method [Symbol] the method that was called
      # @param result [Object] the result of the method call
      # @return [Object] the processed result, potentially wrapped in a new SettingsProxy
      def handle_non_destructive_result(method, result)
        @settings_module.reset_path_and_return(
          if @settings_module.container?(result)
            if @target.is_a?(Array) && [:find, :detect].include?(method)
              # For Array#find / Array#detect, identify the element index in the
              # original array and create a proxy that points to that element.
              idx = @target.index(result)

              if !idx.nil?
                element_path = @path.dup
                element_path << idx
                SettingsProxy.new(@settings_module, @scope, element_path, result, script_name: @script_name)
              else
                # Fallback: if we somehow can't locate the element, preserve
                # the old behavior (path == @path, no index).
                is_view = NON_DESTRUCTIVE_CONTAINER_VIEWS.include?(method)
                SettingsProxy.new(@settings_module, @scope, @path.dup, result, detached: is_view, script_name: @script_name)
              end
            else
              # Existing behavior for all other non-destructive container methods
              is_view = NON_DESTRUCTIVE_CONTAINER_VIEWS.include?(method)
              SettingsProxy.new(@settings_module, @scope, @path.dup, result, detached: is_view, script_name: @script_name)
            end
          else
            # Non-container results (e.g., Hash#keys) stay as plain values
            result
          end
        )
      end

      # Handles the result of method calls that may modify the target.
      #
      # @param result [Object] the result of the method call
      # @return [Object] self if the target was modified in-place, otherwise the result
      def handle_method_result(result)
        if result.equal?(@target)
          self # Return self if the method modified the target in-place and returned it
        elsif @settings_module.container?(result)
          # If a new container is returned (e.g. some destructive methods might return a new object)
          # Wrap it in a new proxy, maintaining the current path and scope.
          SettingsProxy.new(@settings_module, @scope, @path, result, script_name: @script_name)
        else
          result
        end
      end

      def respond_to_missing?(method, include_private = false)
        @target.respond_to?(method, include_private) || super
      end
    end
  end
end
