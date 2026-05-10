

module Lich
  # Common module for Lich project
  # This module contains shared functionality for authentication.
  # @example Including the module
  #   include Lich::Common::Authentication
  module Common
    module Authentication
      # Provides helper methods for login functionality.
      # This module includes methods for handling game codes, realms, and character data.
      # @example Using LoginHelpers
      #   Lich::Common::Authentication::LoginHelpers.realm_from_game_code("GS3")
      module LoginHelpers
        # Load up / require gem 'os' for operating system detection work
        Lich::Util.install_gem_requirements({ 'os' => true })

        # Valid game codes
        # Valid game codes for the Lich project.
        VALID_GAME_CODES = %w[GS3 GS4 GSX GSF GST DR DRX DRF DRT].freeze

        # Valid frontend flags accepted by CLI login argument parsing.
        # Note: only wizard/stormfront/avalon affect protocol path selection;
        # other values are treated as frontend launch selectors/modifiers.
        # Valid frontend flags accepted by CLI login argument parsing.
        VALID_FRONTENDS = %w[avalon stormfront wizard genie frostbite wrayth].freeze

        # Valid realms for elogin support
        # Valid realms for elogin support.
        VALID_REALMS = %w[prime platinum shattered test].freeze

        # Gemstone game flag aliases for CLI shorthand (--gs is alias for --gemstone)
        # Gemstone game flag aliases for CLI shorthand.
        GEMSTONE_FLAGS = %w[--gemstone --gs].freeze

        # DragonRealms game flag aliases for CLI shorthand (--dr is alias for --dragonrealms)
        # DragonRealms game flag aliases for CLI shorthand.
        DRAGONREALMS_FLAGS = %w[--dragonrealms --dr].freeze

        # Frontend pattern for regex matching
        # Frontend pattern for regex matching.
        FRONTEND_PATTERN = /^--(?<fe>avalon|stormfront|wizard|genie|frostbite|wrayth)$/i.freeze
        # Instance pattern for regex matching.
        INSTANCE_PATTERN = /^--(?<inst>GS.?$|DR.?$)/i.freeze

        # Custom launch pattern for regex matching
        # Custom launch pattern for regex matching.
        CUSTOM_LAUNCH_PATTERN = /^--custom-launch=(?<cl>.+)$/i.freeze

        # CLI flags that should never be interpreted as game-instance selectors.
        # CLI flags that should never be interpreted as game-instance selectors.
        NON_INSTANCE_FLAGS = %w[
          login gui no-gui without-frontend headless reconnect reconnected save
          genie frostbite wrayth
        ].freeze

        # CLI options (key portion before '=') that are non-instance modifiers.
        # CLI options that are non-instance modifiers.
        NON_INSTANCE_OPTION_KEYS = %w[
          start-scripts custom-launch dark-mode headless
          home data scripts temp maps logs backup lib
          script-dir data-dir temp-dir
          hosts-dir hosts-file account password character frontend frontend-command
          detachable-client reconnect-delay game wine wine-prefix
        ].freeze

        # Game code to realm mappings
        # Game code to realm mappings.
        GAME_CODE_TO_REALM = {
          'GSX' => 'platinum',
          'GSF' => 'shattered',
          'GST' => 'test'
        }.freeze

        # Realm to game code mappings
        # Realm to game code mappings.
        REALM_TO_GAME_CODE = {
          'prime'     => 'GS3',
          'platinum'  => 'GSX',
          'shattered' => 'GSF',
          'test'      => 'GST'
        }.freeze

        # Game code to human-readable name mappings
        # Game code to human-readable name mappings.
        GAME_CODE_TO_NAME = {
          'GS3' => 'GemStone IV',
          'GSX' => 'GemStone IV Platinum',
          'GSF' => 'GemStone IV Shattered',
          'GST' => 'GemStone IV Test',
          'DR'  => 'DragonRealms',
          'DRX' => 'DragonRealms Platinum',
          'DRF' => 'DragonRealms Fallen',
          'DRT' => 'DragonRealms Test'
        }.freeze

        # Retrieves the realm associated with a given game code.
        # @param code [String] The game code to look up.
        # @return [String] The corresponding realm name.
        def self.realm_from_game_code(code)
          GAME_CODE_TO_REALM.fetch(code.to_s.upcase, GameConfig::DEFAULT_REALM)
        end

        # Retrieves the game code associated with a given realm.
        # @param realm [String] The realm to look up.
        # @return [String, nil] The corresponding game code or nil if not found.
        def self.realm_to_game_code(realm)
          REALM_TO_GAME_CODE[realm]
        end

        # Retrieves the human-readable name for a given game code.
        # @param game_code [String] The game code to look up.
        # @return [String] The corresponding game name.
        def self.game_name_from_game_code(game_code)
          GAME_CODE_TO_NAME.fetch(game_code, GameConfig::DEFAULT_GAME_NAME)
        end

        # Checks if the provided realm is valid.
        # @param realm [String] The realm to check.
        # @return [Boolean] True if the realm is valid, false otherwise.
        def self.valid_realm?(realm)
          VALID_REALMS.include?(realm)
        end

        # Checks if the Lich version is at least the specified version.
        # @param major [Integer] The major version number.
        # @param minor [Integer] The minor version number (default: 0).
        # @param patch [Integer] The patch version number (default: 0).
        # @return [Boolean] True if the version is at least the specified version.
        def self.lich_version_at_least?(major, minor = 0, patch = 0)
          return false unless defined?(LICH_VERSION)

          Gem::Version.new(LICH_VERSION) >= Gem::Version.new([major, minor, patch].join('.'))
        end

        # Sends a message using the Lich messaging system.
        # @param level [String] The message level (e.g., 'info', 'error').
        # @param text [String] The message text.
        def self.messaging_msg(level, text)
          return unless defined?(Lich::Messaging)
          return unless Lich::Messaging.respond_to?(:msg)

          Lich::Messaging.msg(level, text)
        end

        # Recursively converts hash keys to symbols.
        # @param obj [Hash, Array] The object to convert.
        # @return [Hash, Array] The object with symbolized keys.
        def self.symbolize_keys(obj)
          case obj
          when Hash
            obj.each_with_object({}) do |(key, value), result|
              symbol_key = key.respond_to?(:to_sym) ? key.to_sym : key
              result[symbol_key] = symbolize_keys(value)
            end
          when Array
            obj.map { |element| symbolize_keys(element) }
          else
            obj
          end
        end

        # Determines the format of the provided data.
        # @param data [Array, Hash] The data to analyze.
        # @return [Symbol] The format type (:legacy_array, :yaml_accounts, or :unknown).
        def self.data_format(data)
          return :legacy_array if data.is_a?(Array)
          return :yaml_accounts if data.is_a?(Hash) && data.key?(:accounts)
          :unknown
        end

        # Extracts candidate characters from the provided data structure.
        # @param data [Array, Hash] The data structure containing character information.
        # @return [Array<Hash>] An array of character data hashes.
        def self.extract_candidate_characters_with_accounts(data)
          case data_format(data)
          when :legacy_array
            data.map { |char| { account_name: nil, account_data: nil, character: char } }
          when :yaml_accounts
            data[:accounts].flat_map do |account_name, account_data|
              (account_data[:characters] || []).map do |character|
                { account_name: account_name, account_data: account_data, character: character }
              end
            end
          else
            Lich::Messaging.msg('info', "[WARN] Unsupported character data structure.")
            Lich.log("info: Unsupported character data structure in saved entries.")
            []
          end
        end

        # Searches for characters across all accounts based on specified criteria.
        #
        # This method filters a symbolized account data structure to return character
        # records that match the provided character name, game code, and frontend.
        # All parameters are optional except for the symbolized data and character name,
        # allowing for flexible search patterns.
        #
        # Matching Rules:
        # Searches for characters based on specified attributes.
        # @param symbolized_data [Hash] The symbolized account data structure.
        # @param char_name [String, nil] The character name to search for (optional).
        # @param game_code [Symbol] The game code to filter by (optional, default: :__unset).
        # @param frontend [Symbol] The frontend to filter by (optional, default: :__unset).
        # @param custom_launch [String, nil] The custom launch filter (optional, default: :__unset).
        # @return [Array<Hash>] An array of matching character data hashes.
        def self.find_character_by_attributes(symbolized_data, char_name: nil, game_code: :__unset, frontend: :__unset, custom_launch: :__unset)
          candidates = extract_candidate_characters_with_accounts(symbolized_data)

          # Step 1: Try to find exact matches only
          exact_matches = candidates.filter_map do |entry|
            character = entry[:character] || entry # supports flat and nested formats
            account_name = entry[:account_name] rescue nil
            account_data = entry[:account_data] rescue nil

            next unless character[:char_name].casecmp?(char_name)
            next unless game_code == :__unset || character[:game_code].to_s.casecmp?(game_code.to_s)

            # Custom launch filter (if specified, ignore frontend filter)
            if custom_launch != :__unset && !custom_launch.nil?
              next unless character[:custom_launch].to_s.downcase.include?(custom_launch.to_s.downcase)
            elsif frontend != :__unset && !frontend.nil?
              # For standard entries, ensure custom_launch is nil to avoid matching custom entries
              next unless character[:custom_launch].nil? || character[:custom_launch].to_s.empty?
              next unless character[:frontend].to_s.casecmp?(frontend.to_s)
            end

            build_character_result(account_name, account_data, character)
          end

          messaging_msg('debug', "RETURNING EXACT MATCH COUNT OF #{exact_matches.count} RECORD(S).")
          messaging_msg('debug', "Exact match character = #{exact_matches[0][:char_name]} for instance #{exact_matches[0][:game_code]}.") unless exact_matches.empty?
          Lich.log("info: Returning exact match count of #{exact_matches.count}") if Lich.respond_to?(:log)
          return exact_matches unless exact_matches.empty?

          # Step 2: Fallback match (if needed)
          fallback_code = case game_code.to_s.upcase
                          when 'GST' then 'GS3'
                          when 'DRT' then 'DR'
                          else nil
                          end

          candidates.filter_map do |entry|
            account_name = entry[:account_name]
            account_data = entry[:account_data]
            character    = entry[:character]

            next unless character[:char_name].casecmp?(char_name)

            char_code = character[:game_code].to_s.upcase

            # Fallback logic
            next unless fallback_code && char_code == fallback_code

            # Optional: mark that this was a fallback
            character = character.dup
            character[:_requested_game_code] = game_code

            # Custom launch filter (if specified, ignore frontend filter)
            if custom_launch != :__unset && !custom_launch.nil?
              next unless character[:custom_launch].to_s.downcase.include?(custom_launch.to_s.downcase)
            elsif frontend != :__unset && !frontend.nil?
              # For standard entries, ensure custom_launch is nil to avoid matching custom entries
              next unless character[:custom_launch].nil? || character[:custom_launch].to_s.empty?
              next unless character[:frontend].to_s == frontend.to_s
            end

            build_character_result(account_name, account_data, character)
          end
        end

        def self.build_character_result(account_name, account_data, character)
          return character if account_name.nil? && account_data.nil?

          {
            username: account_name.to_s,
            password: account_data[:password],
            char_name: character[:char_name],
            game_code: character[:_requested_game_code] || character[:game_code],
            game_name: character[:game_name],
            frontend: character[:frontend],
            custom_launch: character[:custom_launch],
            custom_launch_dir: character[:custom_launch_dir],
            is_favorite: character[:is_favorite],
            favorite_order: character[:favorite_order],
            favorite_added: character[:favorite_added],
          }.compact
        end

        # Finds the first character matching the specified attributes.
        # @param symbolized_data [Hash] The symbolized account data structure.
        # @param char_name [String, nil] The character name to search for (optional).
        # @param game_code [Symbol] The game code to filter by (optional).
        # @param frontend [Symbol] The frontend to filter by (optional).
        # @return [Hash, nil] The first matching character data hash or nil if no match is found.
        def self.find_first_character_by_attributes(symbolized_data, char_name: nil, game_code: nil, frontend: nil)
          matches = find_character_by_attributes(symbolized_data, char_name: char_name, game_code: game_code, frontend: frontend)
          matches.first
        end

        # Finds a character by name.
        # @param symbolized_data [Hash] The symbolized account data structure.
        # @param char_name [String] The character name to search for.
        # @return [Hash, nil] The matching character data hash or nil if no match is found.
        def self.find_character_by_name(symbolized_data, char_name)
          find_character_by_attributes(symbolized_data, char_name: char_name)
        end

        # Finds a character by name and game code.
        # @param symbolized_data [Hash] The symbolized account data structure.
        # @param char_name [String] The character name to search for.
        # @param game_code [Symbol] The game code to filter by.
        # @return [Hash, nil] The matching character data hash or nil if no match is found.
        def self.find_character_by_name_and_game(symbolized_data, char_name, game_code)
          find_character_by_attributes(symbolized_data, char_name: char_name, game_code: game_code)
        end

        # Finds a character by name, game code, and frontend.
        # @param symbolized_data [Hash] The symbolized account data structure.
        # @param char_name [String] The character name to search for.
        # @param game_code [Symbol] The game code to filter by.
        # @param frontend [Symbol] The frontend to filter by.
        # @param custom_launch [String, nil] The custom launch filter (optional, default: :__unset).
        # @return [Hash, nil] The matching character data hash or nil if no match is found.
        def self.find_character_by_name_game_and_frontend(symbolized_data, char_name, game_code, frontend, custom_launch = :__unset)
          find_character_by_attributes(symbolized_data, char_name: char_name, game_code: game_code, frontend: frontend, custom_launch: custom_launch)
        end

        # Selects the best matching character data hash from an array based on weighted criteria.
        #
        # Rules:
        # - A match on `:char_name` is required for any record to be considered.
        # - If `requested_instance` is provided, a match on `:game_code` is also required.
        # Selects the best matching character data based on weighted criteria.
        # @param char_data_sets [Array<Hash>] The array of character data hashes to evaluate.
        # @param requested_character [String] The character name to match.
        # @param requested_instance [Symbol] The game code to filter by (optional, default: :__unset).
        # @param requested_fe [Symbol] The frontend to filter by (optional, default: :__unset).
        # @return [Hash, nil] The best matching character data hash or nil if no match is found.
        def self.select_best_fit(char_data_sets:, requested_character:, requested_instance: :__unset, requested_fe: :__unset)
          return nil if char_data_sets.nil? || char_data_sets.empty?
          return nil unless requested_character

          # Filter by required character match
          matching_chars = char_data_sets.select { |char| char[:char_name].casecmp?(requested_character) }
          return nil if matching_chars.empty?

          # Filter by game instance if explicitly provided and valid, includes fallback GST -> GS3
          if requested_instance != :__unset
            if requested_instance.nil? || !VALID_GAME_CODES.include?(requested_instance)
              Lich.log "error: Probable invalid instance detected. Valid instances: #{VALID_GAME_CODES.join(', ')}" if Lich.respond_to?(:log)
              messaging_msg('error', "Probable invalid instance detected. Valid instances: #{VALID_GAME_CODES.join(', ')}")

              return nil
            end

            matching_chars.select! do |char|
              effective_code = char[:_requested_game_code] || char[:game_code]
              effective_code == requested_instance
            end
            return nil if matching_chars.empty?
          end

          # Rank by frontend if provided
          best_match = matching_chars.first
          highest_score = 0

          matching_chars.each do |char|
            score = 0
            score += 1 if requested_fe != :__unset && char[:frontend] == requested_fe

            if score > highest_score
              best_match = char
              highest_score = score
            end
          end

          best_match
        end

        # Resolves the game instance from the provided arguments.
        # @param argv [Array<String>] The command line arguments.
        # @return [String, nil] The resolved game instance or nil if not found.
        def self.resolve_instance(argv)
          instance_flags_seen = false
          resolved_instance = nil

          # Check for --gemstone (or --gs alias) with variants
          if gemstone_flag?(argv)
            instance_flags_seen = true
            resolved_instance ||= 'GST' if argv.include?('--test')
            resolved_instance ||= 'GSX' if argv.include?('--platinum')
            resolved_instance ||= 'GSF' if argv.include?('--shattered')
            resolved_instance ||= 'GS3' # default gemstone
          end

          # Check for --dragonrealms (or --dr alias) with variants
          if dragonrealms_flag?(argv)
            instance_flags_seen = true
            resolved_instance ||= 'DRT' if argv.include?('--test')
            resolved_instance ||= 'DRX' if argv.include?('--platinum')
            resolved_instance ||= 'DRF' if argv.include?('--fallen')
            resolved_instance ||= 'DR' # default dragonrealms
          end

          # Check for standalone --shattered
          if argv.include?('--shattered')
            instance_flags_seen = true
            resolved_instance ||= 'GSF'
          end
          if argv.include?('--fallen')
            instance_flags_seen = true
            resolved_instance ||= 'DRF'
          end

          # Check for direct instance codes (GS3, GS4, GST, GSX, etc.).
          # Non-instance flags are ignored so CLI modifiers do not force invalid-instance
          # handling when the user did not request an explicit instance.
          if resolved_instance.nil?
            argv.each do |arg|
              next unless arg.start_with?('--')
              flag = arg.sub('--', '').downcase
              if VALID_GAME_CODES.include?(flag.upcase)
                instance_flags_seen = true
                resolved_instance = flag.upcase
                break
              elsif non_instance_option_flag?(flag)
                next
              else
                instance_flags_seen = true # set to true so that we fall through to returning nil
              end
            end
          end

          return resolved_instance unless resolved_instance.nil?
          return :__unset unless instance_flags_seen
          nil
        end

        # Checks if the provided flag is a non-instance option.
        # @param flag [String] The flag to check.
        # @return [Boolean] True if the flag is a non-instance option, false otherwise.
        def self.non_instance_option_flag?(flag)
          return true if VALID_FRONTENDS.include?(flag)
          return true if NON_INSTANCE_FLAGS.include?(flag)

          option_key = flag.split('=', 2).first
          NON_INSTANCE_OPTION_KEYS.include?(option_key)
        end

        # Checks if any gemstone flags are present in the arguments.
        # @param argv [Array<String>] The command line arguments.
        # @return [Boolean] True if any gemstone flags are present, false otherwise.
        def self.gemstone_flag?(argv)
          GEMSTONE_FLAGS.any? { |flag| argv.include?(flag) }
        end

        # Checks if any dragonrealms flags are present in the arguments.
        # @param argv [Array<String>] The command line arguments.
        # @return [Boolean] True if any dragonrealms flags are present, false otherwise.
        def self.dragonrealms_flag?(argv)
          DRAGONREALMS_FLAGS.any? { |flag| argv.include?(flag) }
        end

        # Parses Lich CLI args to determine game instance, frontend, and custom launch filter.
        #
        # Parses command line arguments to determine game instance, frontend, and custom launch filter.
        # @param argv [Array<String>] The command line arguments.
        # @return [Array] An array containing the resolved instance, frontend, and custom launch filter.
        def self.resolve_login_args(argv)
          frontend = :__unset
          custom_launch = :__unset
          instance = resolve_instance(argv)

          argv.each do |arg|
            case arg
            when FRONTEND_PATTERN
              frontend = Regexp.last_match[:fe].downcase
            when CUSTOM_LAUNCH_PATTERN
              custom_launch = Regexp.last_match[:cl]
            end
          end

          messaging_msg('debug', "Login arguments from CLI login -> #{argv.inspect}")
          messaging_msg('debug', "Resolved instance: #{instance.inspect}, frontend: #{frontend.inspect}, custom_launch: #{custom_launch.inspect}")
          Lich.log "debug: Login arguments from CLI login -> #{argv.inspect}" if Lich.respond_to?(:log)
          Lich.log "debug: Resolved instance: #{instance.inspect}, frontend: #{frontend.inspect}, custom_launch: #{custom_launch.inspect}" if Lich.respond_to?(:log)

          [instance, frontend, custom_launch]
        end

        # Resolves the frontend based on the requested frontend and arguments.
        # @param requested_frontend [Symbol] The requested frontend.
        # @param argv [Array<String>] The command line arguments.
        # @return [Symbol] The resolved frontend or :__unset if not applicable.
        def self.resolve_lookup_frontend(requested_frontend, argv)
          return :__unset if argv.include?('--without-frontend')

          requested_frontend
        end

        # Formats the launch flag for a given game code.
        # @param game_code [String] The game code to format.
        # @return [String, nil] The formatted launch flag or nil if the game code is invalid.
        def self.format_launch_flag(game_code)
          return nil if game_code.to_s.strip.empty?

          normalized_code = game_code.to_s.upcase

          if LoginHelpers.lich_version_at_least?(5, 12, 0)
            "--#{normalized_code}"
          else
            case normalized_code
            when 'GST' then '--gst'
            when 'DRT' then '--drt'
            else nil
            end
          end
        end

        # Spawns a login session for the specified character.
        # @param entry [Hash] The character entry containing login details.
        # @param lich_path [String, nil] The path to the Lich executable (optional).
        # @param startup_scripts [Array<String>] The startup scripts to run (optional).
        # @param instance_override [String, nil] The instance to override (optional).
        # @param frontend_override [String, nil] The frontend to override (optional).
        # @param custom_launch_filter [String, nil] The custom launch filter (optional).
        # @return [Integer, nil] The process ID of the spawned login session or nil if an error occurred.
        def self.spawn_login(entry, lich_path: nil, startup_scripts: [], instance_override: nil, frontend_override: nil, custom_launch_filter: nil)
          ruby_path = OS.windows? ? RbConfig.ruby.sub('ruby', 'rubyw') : RbConfig.ruby
          lich_path ||= File.join(LICH_DIR, 'lich.rbw')

          spawn_cmd = [
            "#{ruby_path}",
            "#{lich_path}",
            '--login', entry[:char_name]
          ]
          if instance_override
            flag = format_launch_flag(instance_override)
            spawn_cmd << flag if flag
          end
          spawn_cmd << "--#{frontend_override}" unless frontend_override.nil?
          spawn_cmd << "--custom-launch=#{custom_launch_filter}" if custom_launch_filter
          spawn_cmd << "--start-scripts=#{startup_scripts.join(',')}" if startup_scripts.any?

          Lich::Messaging.msg('info', "Spawning login: #{spawn_cmd}")

          begin
            pid = Process.spawn(*spawn_cmd)
            Process.detach(pid)
          rescue Errno::ENOENT => e
            Lich::Messaging.msg('error', "Executable not found: #{e.message}")
            Lich.log "error: Executable not found: #{e.message}"
            nil
          rescue StandardError => e
            Lich::Messaging.msg('error', "Failed to launch login session: #{e.class} - #{e.message}")
            Lich.log "error: Failed to launch login session: #{e.class} - #{e.message}"
            nil
          end
        end
      end
    end
  end
end
