
module Lich
  module Common
    require 'sequel'
    # rubocop:disable Lint/RedundantRequireStatement
    require 'set' # Ensure Set is required for Ruby < 3.2, may be removed in future versions
    # rubocop:enable Lint/RedundantRequireStatement

    # settings_proxy.rb is now loaded after Settings module is defined, to allow it to call Settings._log
    # require_relative 'settings/settings_proxy'
    require_relative 'settings/database_adapter'
    require_relative 'settings/path_navigator'

    # Provides configuration settings for the Lich application.
    # This module handles logging, settings management, and data persistence.
    # @example Setting a log level
    #   Settings.set_log_level(:info)
    module Settings
      # Exception raised when a circular reference is detected.
      # @example Raising a CircularReferenceError
      #   raise CircularReferenceError.new("Custom message")
      class CircularReferenceError < StandardError
        def initialize(msg = "Circular Reference Detected")
          super(msg)
        end
      end

      # Logging Configuration
      LOG_LEVEL_NONE = 0
      LOG_LEVEL_ERROR = 1
      LOG_LEVEL_INFO = 2
      LOG_LEVEL_DEBUG = 3

      @@log_level = LOG_LEVEL_NONE # Default: logging disabled
      @@log_prefix = "[SettingsModule]".freeze

      # Sets the logging level for the Settings module.
      # @param level [Symbol] The log level to set (:none, :error, :info, :debug)
      # @return [Integer] The numeric value of the log level set
      # @raise CircularReferenceError if an invalid log level is specified
      # @example Setting log level to debug
      #   Settings.set_log_level(:debug)
      def self.set_log_level(level)
        numeric_level = case level
                        when :none, LOG_LEVEL_NONE then LOG_LEVEL_NONE
                        when :error, LOG_LEVEL_ERROR then LOG_LEVEL_ERROR
                        when :info, LOG_LEVEL_INFO then LOG_LEVEL_INFO
                        when :debug, LOG_LEVEL_DEBUG then LOG_LEVEL_DEBUG
                        else
                          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "Invalid log level specified: #{level.inspect}. Defaulting to NONE." })
                          LOG_LEVEL_NONE
                        end
        @@log_level = numeric_level
      end

      # Retrieves the current logging level for the Settings module.
      # @return [Integer] The current log level
      def self.get_log_level
        @@log_level
      end

      def self._log(level, prefix, message_proc)
        return unless Lich.respond_to?(:log)
        return unless level <= @@log_level

        level_str = case level
                    when LOG_LEVEL_ERROR then "[ERROR]"
                    when LOG_LEVEL_INFO  then "[INFO]"
                    when LOG_LEVEL_DEBUG then "[DEBUG]"
                    else "[UNKNOWN]"
                    end

        begin
          message = message_proc.call
          Lich.log("#{prefix} #{level_str} #{message}")
        rescue => e
          Lich.log("#{prefix} [ERROR] Logging failed: #{e.message} - Original message proc: #{message_proc.source_location if message_proc.respond_to?(:source_location)}")
        end
      end

      # Reattaches the live proxy to the current settings context.
      # @param proxy [SettingsProxy] The proxy to reattach
      # @return [Boolean] True if reattachment was successful, false otherwise
      # @example Reattaching a live proxy
      #   Settings._reattach_live!(my_proxy)
      def self._reattach_live!(proxy)
        script_name = Script.current.name
        scope       = proxy.scope
        path        = proxy.path

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "reattach_live!: scope=#{scope.inspect} path=#{path.inspect}" })

        @path_navigator.reset_path
        @path_navigator.set_path(path)
        live, _root = @path_navigator.navigate_to_path(script_name, true, scope)

        if live.nil?
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "reattach_live!: failed to resolve live target for path=#{path.inspect} scope=#{scope.inspect}" })
          return false
        end

        # Swap the proxy onto the live object via SettingsProxy API (encapsulated)
        # Centralizes invariants/logging within SettingsProxy itself.
        proxy.rebind_to_live!(live)
        true
      end

      @db_adapter = DatabaseAdapter.new(DATA_DIR, :script_auto_settings)
      @path_navigator = PathNavigator.new(@db_adapter)
      @settings_cache = {}
      DEFAULT_SCOPE = ":".freeze
      @safe_navigation_active = false

      # Checks if the given value is a container (Hash or Array).
      # @param value [Object] The value to check
      # @return [Boolean] True if the value is a container, false otherwise
      # @example Checking if a value is a container
      #   Settings.container?(my_value)
      def self.container?(value)
        value.is_a?(Hash) || value.is_a?(Array)
      end

      def self.unwrap_proxies(data, visited = Set.new)
        if visited.include?(data.object_id) && (data.is_a?(Hash) || data.is_a?(Array) || data.is_a?(SettingsProxy))
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "unwrap_proxies: Circular reference detected for object_id: #{data.object_id}" })
          raise CircularReferenceError.new("Circular reference detected during unwrap_proxies for object_id: #{data.object_id}")
        end

        visited.add(data.object_id) if data.is_a?(Hash) || data.is_a?(Array) || data.is_a?(SettingsProxy)

        result = case data
                 when SettingsProxy
                   _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "unwrap_proxies: Unwrapping SettingsProxy (target_object_id: #{data.target.object_id})" })
                   unwrap_proxies(data.target, visited)
                 when Hash
                   _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "unwrap_proxies: Unwrapping Hash (object_id: #{data.object_id})" })
                   new_hash = {}
                   data.each do |key, value|
                     new_hash[key] = unwrap_proxies(value, visited)
                   end
                   new_hash
                 when Array
                   _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "unwrap_proxies: Unwrapping Array (object_id: #{data.object_id})" })
                   data.map { |item| unwrap_proxies(item, visited) }
                 else
                   data
                 end

        visited.delete(data.object_id) if data.is_a?(Hash) || data.is_a?(Array) || data.is_a?(SettingsProxy)
        result
      end
      private_class_method :unwrap_proxies

      # Retrieves the root proxy for the given scope and script name.
      # @param scope [String] The scope for which to retrieve the root proxy
      # @param script_name [String] The name of the script (optional)
      # @return [SettingsProxy] The root proxy for the specified scope
      # @raise ArgumentError if the scope is nil or empty
      # @example Getting the root proxy
      #   proxy = Settings.root_proxy_for("my_scope")
      def self.root_proxy_for(scope, script_name: Script.current.name)
        raise ArgumentError, "scope must be a non-empty String" if scope.nil? || scope.to_s.strip.empty?

        script_name ||= ""
        cache_key = "#{script_name}::#{scope}"
        root = @settings_cache[cache_key] ||= @db_adapter.get_settings(script_name, scope)

        SettingsProxy.new(self, scope, [], root)
      end

      # Saves changes made to the given proxy back to the database.
      # @param proxy [SettingsProxy] The proxy containing changes to save
      # @return [nil] Always returns nil
      # @example Saving changes to a proxy
      #   Settings.save_proxy_changes(my_proxy)
      def self.save_proxy_changes(proxy)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Initiated for proxy.scope: #{proxy.scope.inspect}, proxy.path: #{proxy.path.inspect}, proxy.target_object_id: #{proxy.target.object_id}" })
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: proxy.target data: #{proxy.target.inspect}" })

        path        = proxy.path
        scope       = proxy.scope
        script_name = Script.current.name
        cache_key   = "#{script_name || ""}::#{scope}"

        # Local helper to keep cache in sync with the just-persisted root
        sync_cache = lambda do |root_obj|
          cached = @settings_cache[cache_key]
          if cached && !cached.equal?(root_obj)
            if cached.is_a?(Hash) && root_obj.is_a?(Hash)
              cached.replace(root_obj)
            elsif cached.is_a?(Array) && root_obj.is_a?(Array)
              cached.clear
              cached.concat(root_obj)
            else
              @settings_cache[cache_key] = root_obj
            end
          elsif cached.nil?
            @settings_cache[cache_key] = root_obj
          end
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Cache synchronized post-save for #{cache_key}" })
        end

        # --- Refresh-before-save to prevent stale-cache overwrites ---
        fresh_root = @db_adapter.get_settings(script_name, scope)

        cached = @settings_cache[cache_key]
        if cached
          if cached.is_a?(Hash) && fresh_root.is_a?(Hash)
            cached.replace(fresh_root)
            current_root_for_scope = cached
          elsif cached.is_a?(Array) && fresh_root.is_a?(Array)
            cached.clear
            cached.concat(fresh_root)
            current_root_for_scope = cached
          else
            @settings_cache[cache_key] = fresh_root
            current_root_for_scope = fresh_root
          end
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_proxy_changes: Cache refreshed from DB for #{cache_key} (object_id: #{current_root_for_scope.object_id}): #{current_root_for_scope.inspect}" })
        else
          @settings_cache[cache_key] = fresh_root
          current_root_for_scope = fresh_root
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_proxy_changes: Cache populated from DB for #{cache_key} (object_id: #{current_root_for_scope.object_id}): #{current_root_for_scope.inspect}" })
        end
        # -------------------------------------------------------------

        # EMPTY PATH → Save *current root* (not proxy.target). Also covers detached "view" proxies.
        if path.empty?
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Empty path; saving CURRENT ROOT for scope #{scope.inspect}" })

          unless current_root_for_scope.is_a?(Hash) || current_root_for_scope.is_a?(Array)
            _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_proxy_changes: Root not a container; initializing {} for scope #{scope.inspect}" })
            current_root_for_scope = {}
            @settings_cache[cache_key] = current_root_for_scope
          end

          if proxy.respond_to?(:detached?) && proxy.detached?
            _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Proxy is detached (view); persisting current root without copying view target." })
            save_to_database(current_root_for_scope, scope)
            sync_cache.call(current_root_for_scope)
            return nil
          end

          # Root identity drift: sync proxy.target into cached root if different objects (same-type containers).
          if !current_root_for_scope.equal?(proxy.target)
            if proxy.target.is_a?(Hash) && current_root_for_scope.is_a?(Hash)
              _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Root identity mismatch (cache #{current_root_for_scope.object_id} vs proxy #{proxy.target.object_id}); copying via Hash#replace" })
              current_root_for_scope.replace(proxy.target)
            elsif proxy.target.is_a?(Array) && current_root_for_scope.is_a?(Array)
              _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Root identity mismatch (Array); copying elements" })
              current_root_for_scope.clear
              current_root_for_scope.concat(proxy.target)
            else
              _log(LOG_LEVEL_WARN, @@log_prefix, -> { "save_proxy_changes: Root/target type mismatch; persisting current root only (root=#{current_root_for_scope.class}, target=#{proxy.target.class})." })
            end
          end

          save_to_database(current_root_for_scope, scope)
          sync_cache.call(current_root_for_scope)
          return nil
        end

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: script_name: #{script_name.inspect}, cache_key: #{cache_key}" })

        # From here on, we’re saving into a nested path. Ensure root is a container.
        unless current_root_for_scope.is_a?(Hash) || current_root_for_scope.is_a?(Array)
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_proxy_changes: Root not a container; initializing {} for scope #{scope.inspect}" })
          current_root_for_scope = {}
          @settings_cache[cache_key] = current_root_for_scope
        end

        parent_path = path[0...-1]
        leaf_key    = path.last

        # Pre-navigation diagnostics
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> {
          "save_proxy_changes: Navigation preflight — parent_path=#{parent_path.inspect} (#{parent_path.map { |s| s.class }.inspect}), leaf_key=#{leaf_key.inspect} (#{leaf_key.class}), root_class=#{current_root_for_scope.class}"
        })

        # Navigate **within the freshly-loaded root** (do NOT re-fetch via PathNavigator here).
        begin
          parent = current_root_for_scope
          parent_path.each_with_index do |seg, idx|
            next_seg = parent_path[idx + 1]

            if parent.is_a?(Hash)
              unless parent.key?(seg)
                parent[seg] = next_seg.is_a?(Integer) ? [] : {}
                _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Created #{parent[seg].class} at #{parent_path[0..idx].inspect} for scope #{scope.inspect}" })
              end
              parent = parent[seg]
            elsif parent.is_a?(Array)
              unless seg.is_a?(Integer) && seg >= 0
                _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_proxy_changes: Non-integer or negative index #{seg.inspect} for Array at #{parent_path[0..idx].inspect} in scope #{scope.inspect}" })
                return nil
              end
              if seg >= parent.length
                (parent.length..seg).each { parent << nil }
                _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Extended Array to index #{seg} at #{parent_path[0..idx].inspect} for scope #{scope.inspect}" })
              end
              parent[seg] ||= (next_seg.is_a?(Integer) ? [] : {})
              parent = parent[seg]
            else
              _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_proxy_changes: Parent is not a container at #{parent_path[0..idx].inspect} (#{parent.class}) for scope #{scope.inspect}" })
              return nil
            end
          end
        rescue => e
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> {
            "save_proxy_changes: Local navigation raised #{e.class}: #{e.message}. "\
            "scope=#{scope.inspect}, script_name=#{script_name.inspect}, cache_key=#{cache_key}, "\
            "parent_path=#{parent_path.inspect}, leaf_key=#{leaf_key.inspect}"
          })
          bt = (e.backtrace || [])[0, 5]
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_proxy_changes: Backtrace (top 5): #{bt.join(' | ')}" })
          return nil
        end

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Navigated/created parent (object_id: #{parent.object_id}, class=#{parent.class}): #{parent.inspect}" })

        if parent.is_a?(Hash)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Setting Hash key #{leaf_key.inspect} with proxy.target (object_id: #{proxy.target.object_id})" })
          parent[leaf_key] = proxy.target
        elsif parent.is_a?(Array) && leaf_key.is_a?(Integer)
          if leaf_key < 0
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_proxy_changes: Negative array index #{leaf_key} not supported at path #{path.inspect} in scope #{scope.inspect}" })
            return nil
          end
          if leaf_key >= parent.length
            (parent.length..leaf_key).each { parent << nil }
            _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Extended Array to index #{leaf_key} for parent at path #{parent_path.inspect}" })
          end
          parent[leaf_key] = proxy.target
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: Set Array index #{leaf_key} with proxy.target (object_id: #{proxy.target.object_id})" })
        else
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> {
            "save_proxy_changes: Cannot set value at path #{path.inspect} in scope #{scope.inspect}; "\
            "parent_class=#{parent.class}, leaf_key_class=#{leaf_key.class}"
          })
          return nil
        end

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_proxy_changes: root after update (object_id: #{current_root_for_scope.object_id}): #{current_root_for_scope.inspect}" })
        save_to_database(current_root_for_scope, scope)
        sync_cache.call(current_root_for_scope)
      end

      # Retrieves the current settings for the active script and scope.
      # @param scope [String] The scope for which to retrieve settings (default is ':')
      # @return [Object] The current settings for the specified scope
      # @example Getting current script settings
      #   settings = Settings.current_script_settings
      def self.current_script_settings(scope = DEFAULT_SCOPE)
        script_name = Script.current.name
        cache_key = "#{script_name || ""}::#{scope}" # Use an empty string if script_name is nil
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "current_script_settings: Request for scope: #{scope.inspect}, cache_key: #{cache_key}" })

        cached_data = @settings_cache[cache_key]
        if cached_data
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "current_script_settings: Cache hit for #{cache_key} (object_id: #{cached_data.object_id}). Returning DUP: #{cached_data.inspect}" })
          return cached_data.dup
        else
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "current_script_settings: Cache miss for #{cache_key}. Loading from DB." })
          settings = @db_adapter.get_settings(script_name, scope)
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "current_script_settings: Loaded from DB (object_id: #{settings.object_id}): #{settings.inspect}" })
          @settings_cache[cache_key] = settings
          _log(LOG_LEVEL_INFO, @@log_prefix, -> { "current_script_settings: Stored in cache (object_id: #{@settings_cache[cache_key].object_id}). Returning DUP." })
          return settings.dup
        end
      end

      # Saves the specified data to the database for the current script and scope.
      # @param data_to_save [Object] The data to save
      # @param scope [String] The scope for which to save the data (default is ':')
      # @return [nil] Always returns nil
      # @example Saving data to the database
      #   Settings.save_to_database(my_data)
      def self.save_to_database(data_to_save, scope = DEFAULT_SCOPE)
        script_name = Script.current.name

        if script_name.nil? || script_name.empty?
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "save_to_database: Aborting save. Script.current.name is nil or empty. Scope: #{scope.inspect}. Data will NOT be persisted." })
          return nil # Explicitly return nil
        end

        cache_key = "#{script_name}::#{scope}" # script_name is guaranteed to be non-nil/non-empty here
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_to_database: Saving for script: '#{script_name}', scope: #{scope.inspect}, cache_key: #{cache_key}" })
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_to_database: Data BEFORE unwrap_proxies (object_id: #{data_to_save.object_id}): #{data_to_save.inspect}" })

        unwrapped_settings = unwrap_proxies(data_to_save)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "save_to_database: Data AFTER unwrap_proxies (object_id: #{unwrapped_settings.object_id}): #{unwrapped_settings.inspect}" })

        @db_adapter.save_settings(script_name, unwrapped_settings, scope)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_to_database: Data saved to DB for script '#{script_name}'." })

        @settings_cache[cache_key] = unwrapped_settings
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "save_to_database: Cache updated for #{cache_key} with saved data (object_id: #{@settings_cache[cache_key].object_id})." })
      end

      # Refreshes the settings data for the current script and scope.
      # @param scope [String] The scope for which to refresh data (default is ':')
      # @return [Object] The refreshed settings for the specified scope
      # @example Refreshing settings data
      #   Settings.refresh_data
      def self.refresh_data(scope = DEFAULT_SCOPE)
        script_name = Script.current.name
        cache_key = "#{script_name || ""}::#{scope}" # Use an empty string if script_name is nil
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "refresh_data: Deleting cache for scope: #{scope.inspect}, cache_key: #{cache_key}" })
        @settings_cache.delete(cache_key)
        current_script_settings(scope)
      end

      # Resets the path navigator and returns the specified value.
      # @param value [Object] The value to return after resetting the path
      # @return [Object] The value passed in
      # @example Resetting path and returning a value
      #   result = Settings.reset_path_and_return(my_value)
      def self.reset_path_and_return(value)
        @path_navigator.reset_path_and_return(value)
      end

      # Navigates to the specified path within the current settings context.
      # @param create_missing [Boolean] Whether to create missing segments (default is true)
      # @param scope [String] The scope for which to navigate (default is ':')
      # @return [Array] An array containing the target and the root for the specified scope
      # @example Navigating to a path
      #   target, root = Settings.navigate_to_path
      def self.navigate_to_path(create_missing = true, scope = DEFAULT_SCOPE)
        root_for_scope = current_script_settings(scope)
        return [root_for_scope, root_for_scope] if @path_navigator.path.empty?

        target = root_for_scope
        @path_navigator.path.each do |key|
          if target.is_a?(Hash) && target.key?(key)
            target = target[key]
          elsif target.is_a?(Array) && key.is_a?(Integer) && key >= 0 && key < target.length
            target = target[key]
          elsif create_missing && (target.is_a?(Hash) || target.is_a?(Array))
            _log(LOG_LEVEL_INFO, @@log_prefix, -> { "navigate_to_path: Creating missing segment '#{key}' in DUPPED structure for scope #{scope.inspect}" })
            new_node = key.is_a?(Integer) ? [] : {}
            if target.is_a?(Hash)
              target[key] = new_node
            elsif target.is_a?(Array) && key.is_a?(Integer)
              target[key] = new_node
            end
            target = new_node
          else
            return [nil, root_for_scope]
          end
        end
        [target, root_for_scope]
      end

      # Sets a specific setting for the current script and scope.
      # @param scope [String] The scope for which to set the setting (default is ':')
      # @param name [String] The name of the setting to set
      # @param value [Object] The value to assign to the setting
      # @return [nil] Always returns nil
      # @example Setting a script setting
      #   Settings.set_script_settings("my_scope", "my_setting", "my_value")
      def self.set_script_settings(scope = DEFAULT_SCOPE, name, value)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "set_script_settings: scope: #{scope.inspect}, name: #{name.inspect}, value: #{value.inspect}, current_path: #{@path_navigator.path.inspect}" })
        unwrapped_value = unwrap_proxies(value)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "set_script_settings: unwrapped_value: #{unwrapped_value.inspect}" })

        current_root = current_script_settings(scope)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "set_script_settings: current_root (DUP) for scope #{scope.inspect} (object_id: #{current_root.object_id}): #{current_root.inspect}" })

        if @path_navigator.path.empty?
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "set_script_settings: Path is empty. Setting '#{name}' on current_root." })
          current_root[name] = unwrapped_value
          save_to_database(current_root, scope)
        else
          if !@path_navigator.path.empty?
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "set_script_settings: WARNING: Called with non-empty path_navigator path: #{@path_navigator.path.inspect}. This is unusual for Char/GameSettings direct assignment." })
          end
          if current_root.is_a?(Hash)
            current_root[name] = unwrapped_value
            save_to_database(current_root, scope)
          else
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "set_script_settings: current_root for scope #{scope.inspect} is not a Hash. Cannot set key '#{name}'. Root class: #{current_root.class}" })
          end
        end
        reset_path_and_return(value)
      end

      # Retrieves a setting by name for the current script and scope.
      # @param name [String] The name of the setting to retrieve
      # @return [Object] The value of the setting, or nil if not found
      # @example Getting a setting by name
      #   value = Settings["my_setting"]
      def self.[](name)
        scope_to_use = DEFAULT_SCOPE
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[]: name: #{name.inspect}, current_path: #{@path_navigator.path.inspect}, safe_nav: #{@safe_navigation_active}" })

        if @path_navigator.path.empty?
          data_for_scope = current_script_settings(scope_to_use)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[] (top-level): data_for_scope (DUP) (object_id: #{data_for_scope.object_id}): #{data_for_scope.inspect}" })
          value = get_value_from_container(data_for_scope, name)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[] (top-level): value for '#{name}': #{value.inspect}" })
          if value.nil? && !data_for_scope.is_a?(Array) && (!data_for_scope.is_a?(Hash) || !data_for_scope.key?(name))
            _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.[] (top-level): Key '#{name}' not found or value is nil. Activating safe_navigation." })
            @safe_navigation_active = true
          end
          return reset_path_and_return(wrap_value_if_container(value, scope_to_use, [name]))
        else
          current_target, _ = navigate_to_path(false, scope_to_use)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[] (path-based): current_target: #{current_target.inspect}" })
          value = get_value_from_container(current_target, name)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[] (path-based): value for '#{name}': #{value.inspect}" })
          new_path = @path_navigator.path + [name]
          if value.nil? && !current_target.is_a?(Array) && (!current_target.is_a?(Hash) || !current_target.key?(name))
            _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.[] (path-based): Key '#{name}' not found or value is nil in path. Activating safe_navigation." })
            @safe_navigation_active = true
          end
          return reset_path_and_return(wrap_value_if_container(value, scope_to_use, new_path))
        end
      end

      # Sets a value for a setting by name for the current script and scope.
      # @param name [String] The name of the setting to set
      # @param value [Object] The value to assign to the setting
      # @return [nil] Always returns nil
      # @example Setting a value by name
      #   Settings["my_setting"] = "new_value"
      def self.[]=(name, value)
        scope_to_use = DEFAULT_SCOPE
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "Settings.[]=: name: #{name.inspect}, value: #{value.inspect}, current_path: #{@path_navigator.path.inspect}" })
        @safe_navigation_active = false # Reset safe navigation on assignment

        if @path_navigator.path.empty?
          set_script_settings(scope_to_use, name, value)
        else
          target, root_settings = navigate_to_path(true, scope_to_use)
          if target && (target.is_a?(Hash) || target.is_a?(Array))
            actual_value = value.is_a?(SettingsProxy) ? unwrap_proxies(value) : value
            target[name] = actual_value
            save_to_database(root_settings, scope_to_use)
            reset_path_and_return(value)
          else
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "Settings.[]=: Cannot assign to non-container or nil target at path #{@path_navigator.path.inspect}" })
            reset_path_and_return(nil)
          end
        end
      end

      # Retrieves a scoped setting by key name.
      # @param scope_string [String] The scope to retrieve the setting from
      # @param key_name [String] The key name of the setting to retrieve
      # @return [Object] The value of the setting, or nil if not found
      # @example Getting a scoped setting
      #   value = Settings.get_scoped_setting("my_scope", "my_setting")
      def self.get_scoped_setting(scope_string, key_name)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "get_scoped_setting: scope: #{scope_string.inspect}, key: #{key_name.inspect}" })
        data_for_scope = current_script_settings(scope_string)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "get_scoped_setting: data_for_scope (DUP) (object_id: #{data_for_scope.object_id}): #{data_for_scope.inspect}" })
        value = get_value_from_container(data_for_scope, key_name)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "get_scoped_setting: value for '#{key_name}': #{value.inspect}" })

        if value.nil? && key_name
          key_absent_in_hash = data_for_scope.is_a?(Hash) && !data_for_scope.key?(key_name)
          key_invalid_for_array = data_for_scope.is_a?(Array) && (!key_name.is_a?(Integer) || key_name < 0 || key_name >= data_for_scope.length)

          if key_absent_in_hash || key_invalid_for_array || (data_for_scope.nil? || (data_for_scope.is_a?(Hash) && data_for_scope.empty?))
            _log(Settings::LOG_LEVEL_INFO, @@log_prefix, -> { "get_scoped_setting: Key '#{key_name}' not found in scope '#{scope_string}'. Value will be nil, supporting '|| default' idiom." })
          end
        end
        wrap_value_if_container(value, scope_string, key_name ? [key_name] : [])
      end

      # Wraps a value in a proxy if it is a container (Hash or Array).
      # @param value [Object] The value to wrap
      # @param scope [String] The scope for which to wrap the value
      # @param path_array [Array] The path array for the value
      # @return [Object] The wrapped value if it is a container, otherwise the original value
      # @example Wrapping a value if it is a container
      #   wrapped_value = Settings.wrap_value_if_container(my_value, "my_scope", ["my_key"])
      def self.wrap_value_if_container(value, scope, path_array)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "wrap_value_if_container: value_class: #{value.class}, scope: #{scope.inspect}, path: #{path_array.inspect}" })
        if container?(value)
          proxy = SettingsProxy.new(self, scope, path_array, value)
          _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "wrap_value_if_container: Wrapped in proxy: #{proxy.inspect}" })
          return proxy
        else
          return value
        end
      end

      # Converts the current settings to a hash representation.
      # @param scope [String] The scope to convert (default is ':')
      # @return [Hash] The settings as a hash
      # @example Converting settings to a hash
      #   settings_hash = Settings.to_hash
      def self.to_hash(scope = DEFAULT_SCOPE)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "to_hash: scope: #{scope.inspect}" })
        data = current_script_settings(scope)
        unwrapped_data = unwrap_proxies(data)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "to_hash: Returning unwrapped data (snapshot): #{unwrapped_data.inspect}" })
        return unwrapped_data
      end

      # Saves the current settings (legacy no-op).
      # @return [Symbol] Always returns :noop
      # @example Saving settings
      #   result = Settings.save
      def self.save
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.save called (legacy no-op)." })
        :noop
      end

      # Loads the current settings (legacy, aliasing to refresh_data).
      # @return [Object] The refreshed settings
      # @example Loading settings
      #   settings = Settings.load
      def self.load
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.load called (legacy, aliasing to refresh_data)." })
        refresh_data
      end

      # Converts the current settings to a hash representation (legacy, aliasing to to_hash).
      # @param scope [String] The scope to convert (default is ':')
      # @return [Hash] The settings as a hash
      # @example Converting settings to a hash
      #   settings_hash = Settings.to_h
      def self.to_h(scope = DEFAULT_SCOPE) # Added scope to match to_hash for consistency if used directly
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.to_h called (legacy, aliasing to to_hash)." })
        self.to_hash(scope)
      end

      # Saves all settings (legacy deprecated no-op).
      # @return [nil] Always returns nil
      # @example Saving all settings
      #   Settings.save_all
      def self.save_all
        Lich.deprecated('Settings.save_all', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.save_all called (legacy deprecated no-op)." })
        nil
      end

      # Clears all settings (legacy deprecated no-op).
      # @return [nil] Always returns nil
      # @example Clearing settings
      #   Settings.clear
      def self.clear
        Lich.deprecated('Settings.clear', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.clear called (legacy deprecated no-op)." })
        nil
      end

      # Sets the auto configuration (legacy deprecated no-op).
      # @param _val [Object] The value to set (not used)
      # @return [nil] Always returns nil
      # @example Setting auto configuration
      #   Settings.auto = true
      def self.auto=(_val)
        Lich.deprecated('Settings.auto=(val)', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.auto= called (legacy deprecated no-op)." })
      end

      # Retrieves the auto configuration (legacy deprecated no-op).
      # @return [nil] Always returns nil
      # @example Getting auto configuration
      #   auto_value = Settings.auto
      def self.auto
        Lich.deprecated('Settings.auto', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.auto called (legacy deprecated no-op)." })
        nil
      end

      # Autoloads settings (legacy deprecated no-op).
      # @return [nil] Always returns nil
      # @example Autoloading settings
      #   Settings.autoload
      def self.autoload
        Lich.deprecated('Settings.autoload', 'not using, not applicable,', caller[0], fe_log: true) if Lich.respond_to?(:deprecated)
        _log(LOG_LEVEL_INFO, @@log_prefix, -> { "Settings.autoload called (legacy deprecated no-op)." })
        nil
      end

      # Handles missing methods for the Settings module.
      # @param method [Symbol] The name of the missing method
      # @param args [Array] The arguments passed to the missing method
      # @param block [Proc] The block passed to the missing method
      # @return [Object] The result of the method call, or nil if safe navigation is active
      # @example Handling a missing method
      #   Settings.some_missing_method
      def self.method_missing(method, *args, &block)
        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "method_missing: method: #{method}, args: #{args.inspect}, path: #{@path_navigator.path.inspect}" })
        if @safe_navigation_active && !@path_navigator.path.empty?
          if method.to_s.end_with?("=")
            _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "method_missing: Attempted assignment (#{method}) on a nil path due to safe navigation." })
            return reset_path_and_return(nil)
          end
          return reset_path_and_return(nil)
        end

        _log(LOG_LEVEL_DEBUG, @@log_prefix, -> { "method_missing: Delegating to path_navigator: #{method}" })
        @path_navigator.send(method, *args, &block)
      end

      # Checks if the Settings module responds to a missing method.
      # @param method_name [Symbol] The name of the method to check
      # @param include_private [Boolean] Whether to include private methods in the check
      # @return [Boolean] True if the method is handled, false otherwise
      # @example Checking for a missing method
      #   exists = Settings.respond_to_missing?(:some_method)
      def self.respond_to_missing?(method_name, include_private = false)
        @path_navigator.respond_to?(method_name, include_private) || super
      end

      # Retrieves a value from a container (Hash or Array) by key.
      # @param container [Object] The container to retrieve the value from
      # @param key [Object] The key to look up in the container
      # @return [Object] The value found, or nil if not found
      # @example Getting a value from a container
      #   value = Settings.get_value_from_container(my_hash, "my_key")
      def self.get_value_from_container(container, key)
        if container.is_a?(Hash)
          container[key]
        elsif container.is_a?(Array) && key.is_a?(Integer)
          container[key]
        elsif container.is_a?(Array) && !key.is_a?(Integer)
          _log(LOG_LEVEL_ERROR, @@log_prefix, -> { "get_value_from_container: Attempted to access Array with non-Integer key: #{key.inspect}" })
          nil
        else
          nil
        end
      end
    end
  end
end

require_relative 'settings/settings_proxy'
