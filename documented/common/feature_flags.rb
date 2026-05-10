
module Lich
  module Common
    # Provides persistent access to core feature flags.
    #
    # Provides persistent access to core feature flags.
    #
    # @see Lich::Common
    module FeatureFlags
      SETTINGS_PREFIX = 'feature_flag:'
      VALID_NAME_PATTERN = /\A[a-z0-9_]+\z/

      # Defines default values for known feature flags.
      #
      # Add new flags here as infrastructure is adopted by production code. The
      # persisted value in `lich_settings` always overrides the default.
      DEFAULTS = {}.freeze

      # Checks if a feature flag is enabled.
      #
      # @param name [String] the name of the feature flag
      # @return [Boolean] true if the feature flag is enabled, false otherwise
      # @raise [ArgumentError] if the flag name is invalid
      # @example
      #   FeatureFlags.enabled?("new_feature") #=> true
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
      # @param name [String] the name of the feature flag
      # @param value [Boolean] the value to set for the feature flag
      # @return [Boolean] true if the operation was successful, false otherwise
      # @raise [ArgumentError] if the flag name is invalid
      # @example
      #   FeatureFlags.set("new_feature", true) #=> true
      def self.set(name, value)
        flag_name = validate_flag_name!(normalize_name(name))
        begin
          write_flag(flag_name, value)
        rescue StandardError => e
          log_failure('write', flag_name, e)
          false
        end
      end

      # Normalizes the feature flag name by stripping whitespace and converting to lowercase.
      #
      # @param name [String] the name to normalize
      # @return [String] the normalized name
      def self.normalize_name(name)
        name.to_s.strip.downcase
      end
      private_class_method :normalize_name

      # Validates the feature flag name, ensuring it is non-empty and matches the valid pattern.
      #
      # @param flag_name [String] the name of the feature flag to validate
      # @return [String] the validated flag name
      # @raise [ArgumentError] if the flag name is invalid
      def self.validate_flag_name!(flag_name)
        raise ArgumentError, 'feature flag name must be non-empty' if flag_name.empty?
        raise ArgumentError, "feature flag name must match #{VALID_NAME_PATTERN.inspect}" unless flag_name.match?(VALID_NAME_PATTERN)

        flag_name
      end
      private_class_method :validate_flag_name!

      # Checks if a value is considered truthy for feature flags.
      #
      # @param value [String] the value to check
      # @return [Boolean] true if the value is truthy, false otherwise
      def self.truthy?(value)
        value.to_s.match?(/\A(?:1|true|on|yes)\z/i)
      end
      private_class_method :truthy?

      # Retrieves the default value for a feature flag.
      #
      # @param flag_name [String] the name of the feature flag
      # @return [Boolean] the default value for the feature flag
      def self.default_for(flag_name)
        DEFAULTS.fetch(flag_name.to_sym, false)
      end
      private_class_method :default_for

      # Reads the value of a feature flag from the database.
      #
      # @param flag_name [String] the name of the feature flag to read
      # @return [String, nil] the value of the feature flag, or nil if not found
      def self.read_flag(flag_name)
        db = fetch_db
        return nil unless db

        db.get_first_value('SELECT value FROM lich_settings WHERE name = ?;', setting_key(flag_name))
      end
      private_class_method :read_flag

      # Writes the value of a feature flag to the database.
      #
      # @param flag_name [String] the name of the feature flag to write
      # @param value [String] the value to set for the feature flag
      # @return [Boolean] true if the operation was successful, false otherwise
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

      # Generates the database key for a feature flag.
      #
      # @param flag_name [String] the name of the feature flag
      # @return [String] the database key for the feature flag
      def self.setting_key(flag_name)
        "#{SETTINGS_PREFIX}#{flag_name}"
      end
      private_class_method :setting_key

      # Fetches the database connection for feature flags.
      #
      # @return [Object, nil] the database connection or nil if not available
      def self.fetch_db
        return nil unless Lich.respond_to?(:db)

        Lich.db
      end
      private_class_method :fetch_db

      # Logs a failure that occurred during a feature flag operation.
      #
      # @param operation [String] the operation that failed
      # @param flag_name [String] the name of the feature flag
      # @param error [StandardError] the error that occurred
      def self.log_failure(operation, flag_name, error)
        return unless defined?(Lich) && Lich.respond_to?(:log)

        Lich.log("warning: FeatureFlags #{operation} failed for #{flag_name}: #{error.class}: #{error.message}")
      end
      private_class_method :log_failure
    end
  end
end
