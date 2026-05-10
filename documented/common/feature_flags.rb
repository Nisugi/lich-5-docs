
module Lich
  module Common
    # Provides persistent access to core feature flags.
    #
    # Provides persistent access to core feature flags.
    #
    # @example Usage of FeatureFlags
    #   Lich::Common::FeatureFlags.enabled?("new_feature")
    module FeatureFlags
      SETTINGS_PREFIX = 'feature_flag:'
      VALID_NAME_PATTERN = /\A[a-z0-9_]+\z/

      # Defines default values for known feature flags.
      #
      # Add new flags here as infrastructure is adopted by production code. The
      # persisted value in `lich_settings` always overrides the default.
      # Defines default values for known feature flags.
      #
      # Add new flags here as infrastructure is adopted by production code. The
      # persisted value in `lich_settings` always overrides the default.
      DEFAULTS = {}.freeze

      # Checks if a feature flag is enabled.
      #
      # @param name [String] The name of the feature flag.
      # @return [Boolean] True if the feature flag is enabled, false otherwise.
      # @raise [ArgumentError] If the feature flag name is invalid.
      # @example Checking if a feature is enabled
      #   Lich::Common::FeatureFlags.enabled?("new_feature")
      def self.enabled?(name)
        flag_name = validate_flag_name!(normalize_name(name))
        begin
          stored = read_flag(flag_name)
          return default_for(flag_name) if stored.nil?

          truthy?(stored)
        rescue StandardError => e
          log_failure('read', flag_name, e)
          default_for(flag_name)
        end
      end

      # Sets the value of a feature flag.
      #
      # @param name [String] The name of the feature flag.
      # @param value [Boolean] The value to set for the feature flag.
      # @return [Boolean] True if the value was set successfully, false otherwise.
      # @raise [ArgumentError] If the feature flag name is invalid.
      # @example Setting a feature flag
      #   Lich::Common::FeatureFlags.set("new_feature", true)
      def self.set(name, value)
        flag_name = validate_flag_name!(normalize_name(name))
        begin
          write_flag(flag_name, value)
        rescue StandardError => e
          log_failure('write', flag_name, e)
          false
        end
      end

      def self.normalize_name(name)
        name.to_s.strip.downcase
      end
      private_class_method :normalize_name

      def self.validate_flag_name!(flag_name)
        raise ArgumentError, 'feature flag name must be non-empty' if flag_name.empty?
        raise ArgumentError, "feature flag name must match #{VALID_NAME_PATTERN.inspect}" unless flag_name.match?(VALID_NAME_PATTERN)

        flag_name
      end
      private_class_method :validate_flag_name!

      # Checks if a value is considered truthy for feature flags.
      #
      # @param value [Object] The value to check.
      # @return [Boolean] True if the value is truthy, false otherwise.
      def self.truthy?(value)
        value.to_s.match?(/\A(?:1|true|on|yes)\z/i)
      end
      private_class_method :truthy?

      # Retrieves the default value for a feature flag.
      #
      # @param flag_name [String] The name of the feature flag.
      # @return [Boolean] The default value for the feature flag.
      def self.default_for(flag_name)
        DEFAULTS.fetch(flag_name.to_sym, false)
      end
      private_class_method :default_for

      # Reads the value of a feature flag from the database.
      #
      # @param flag_name [String] The name of the feature flag.
      # @return [String, nil] The value of the feature flag, or nil if not found.
      def self.read_flag(flag_name)
        db = fetch_db
        return nil unless db

        db.get_first_value('SELECT value FROM lich_settings WHERE name = ?;', setting_key(flag_name))
      end
      private_class_method :read_flag

      # Writes the value of a feature flag to the database.
      #
      # @param flag_name [String] The name of the feature flag.
      # @param value [Object] The value to write for the feature flag.
      # @return [Boolean] True if the value was written successfully, false otherwise.
      def self.write_flag(flag_name, value)
        db = fetch_db
        return false unless db

        db.execute(
          'INSERT OR REPLACE INTO lich_settings(name, value) VALUES(?, ?);',
          [setting_key(flag_name), value.to_s]
        )
        true
      end
      private_class_method :write_flag

      # Generates the setting key for a feature flag.
      #
      # @param flag_name [String] The name of the feature flag.
      # @return [String] The setting key for the feature flag.
      def self.setting_key(flag_name)
        "#{SETTINGS_PREFIX}#{flag_name}"
      end
      private_class_method :setting_key

      # Fetches the database connection for feature flags.
      #
      # @return [Object, nil] The database connection or nil if not available.
      def self.fetch_db
        return nil unless Lich.respond_to?(:db)

        Lich.db
      end
      private_class_method :fetch_db

      # Logs a failure when reading or writing a feature flag.
      #
      # @param operation [String] The operation that failed (read/write).
      # @param flag_name [String] The name of the feature flag.
      # @param error [StandardError] The error that occurred.
      def self.log_failure(operation, flag_name, error)
        return unless defined?(Lich) && Lich.respond_to?(:log)

        Lich.log("warning: FeatureFlags #{operation} failed for #{flag_name}: #{error.class}: #{error.message}")
      end
      private_class_method :log_failure
    end
  end
end
