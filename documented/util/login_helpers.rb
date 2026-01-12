
module Lich
  module Util
    module LoginHelpers
      # Load up / require gem 'os' for operating system detection work
      Lich::Util.install_gem_requirements({ 'os' => true })

      # Valid game codes
      # Valid game codes
      VALID_GAME_CODES = %w[GS3 GS4 GSX GSF GST DR DRX DRF DRT].freeze

      # Valid frontend flags
      # Valid frontend flags
      VALID_FRONTENDS = %w[avalon stormfront wizard].freeze

      # Valid realms for elogin support
      # Valid realms for elogin support
      VALID_REALMS = %w[prime platinum shattered test].freeze

      # Frontend pattern for regex matching
      # Frontend pattern for regex matching
      FRONTEND_PATTERN = /^--(?<fe>avalon|stormfront|wizard)$/i.freeze
      INSTANCE_PATTERN = /^--(?<inst>GS.?$|DR.?$)/i.freeze

      # Game code to realm mappings
      # Game code to realm mappings
      GAME_CODE_TO_REALM = {
        'GSX' => 'platinum',
        'GSF' => 'shattered',
        'GST' => 'test'
      }.freeze

      # Realm to game code mappings
      # Realm to game code mappings
      REALM_TO_GAME_CODE = {
        'prime'     => 'GS3',
        'platinum'  => 'GSX',
        'shattered' => 'GSF',
        'test'      => 'GST'
      }.freeze

      # Game code to human-readable name mappings
      # Game code to human-readable name mappings
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
      def self.realm_from_game_code(code)
        GAME_CODE_TO_REALM.fetch(code.to_s.upcase, GameConfig::DEFAULT_REALM)
      end

      # Retrieves the game code associated with a given realm.
      def self.realm_to_game_code(realm)
        REALM_TO_GAME_CODE[realm]
      end

      # Retrieves the human-readable name for a given game code.
      def self.game_name_from_game_code(game_code)
        GAME_CODE_TO_NAME.fetch(game_code, GameConfig::DEFAULT_GAME_NAME)
      end

      # Checks if the provided realm is valid.
      def self.valid_realm?(realm)
        VALID_REALMS.include?(realm)
      end

      # Checks if the Lich version is at least the specified version.
      def self.lich_version_at_least?(major, minor = 0, patch = 0)
        return false unless defined?(LICH_VERSION)

        Gem::Version.new(LICH_VERSION) >= Gem::Version.new([major, minor, patch].join('.'))
      end

      # Recursively converts hash keys to symbols.
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
      def self.data_format(data)
        return :legacy_array if data.is_a?(Array)
        return :yaml_accounts if data.is_a?(Hash) && data.key?(:accounts)
        :unknown
      end

      # Extracts candidate characters from the provided account data.
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
      # Searches for characters across all accounts based on specified criteria.
      def self.find_character_by_attributes(symbolized_data, char_name: nil, game_code: :__unset, frontend: :__unset)
        candidates = extract_candidate_characters_with_accounts(symbolized_data)

        # Step 1: Try to find exact matches only
        exact_matches = candidates.filter_map do |entry|
          character = entry[:character] || entry # supports flat and nested formats
          account_name = entry[:account_name] rescue nil
          account_data = entry[:account_data] rescue nil

          next unless character[:char_name].casecmp?(char_name)
          next unless game_code == :__unset || character[:game_code].to_s.casecmp?(game_code.to_s)

          build_character_result(account_name, account_data, character)
        end

        Lich::Messaging.msg('debug', "RETURNING EXACT MATCH COUNT OF #{exact_matches.count} RECORD(S).")
        Lich::Messaging.msg('debug', "Exact match character = #{exact_matches[0][:char_name]} for instance #{exact_matches[0][:game_code]}.") unless exact_matches.empty?
        Lich.log("info: Returning exact match count of #{exact_matches.count}")
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

          # Frontend filter
          if frontend != :__unset && !frontend.nil?
            next unless character[:frontend].to_s == frontend.to_s
          end

          build_character_result(account_name, account_data, character)
        end
      end

      # Constructs a character result hash from account and character data.
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
      def self.find_first_character_by_attributes(symbolized_data, char_name: nil, game_code: nil, frontend: nil)
        matches = find_character_by_attributes(symbolized_data, char_name: char_name, game_code: game_code, frontend: frontend)
        matches.first
      end

      # Finds a character by its name.
      def self.find_character_by_name(symbolized_data, char_name)
        find_character_by_attributes(symbolized_data, char_name: char_name)
      end

      # Finds a character by its name and game code.
      def self.find_character_by_name_and_game(symbolized_data, char_name, game_code)
        find_character_by_attributes(symbolized_data, char_name: char_name, game_code: game_code)
      end

      # Finds a character by its name, game code, and frontend.
      def self.find_character_by_name_game_and_frontend(symbolized_data, char_name, game_code, frontend)
        find_character_by_attributes(symbolized_data, char_name: char_name, game_code: game_code, frontend: frontend)
      end

      # Selects the best matching character data hash from an array based on weighted criteria.
      #
      # Rules:
      # - A match on `:char_name` is required for any record to be considered.
      # - If `requested_instance` is provided, a match on `:game_code` is also required.
      # Selects the best matching character data hash from an array based on weighted criteria.
      def self.select_best_fit(char_data_sets:, requested_character:, requested_instance: :__unset, requested_fe: :__unset)
        return nil if char_data_sets.nil? || char_data_sets.empty?
        return nil unless requested_character

        # Filter by required character match
        matching_chars = char_data_sets.select { |char| char[:char_name].casecmp?(requested_character) }
        return nil if matching_chars.empty?

        # Filter by game instance if explicitly provided and valid, includes fallback GST -> GS3
        if requested_instance != :__unset
          if requested_instance.nil? || !VALID_GAME_CODES.include?(requested_instance)
            Lich.log "error: Probable invalid instance detected. Valid instances: #{VALID_GAME_CODES.join(', ')}"
            Lich::Messaging.msg('error', "Probable invalid instance detected. Valid instances: #{VALID_GAME_CODES.join(', ')}")

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

      # Resolves the game instance from command-line arguments.
      def self.resolve_instance(argv)
        instance_flags_seen = false
        resolved_instance = nil

        # Check for --gemstone with variants
        if argv.include?('--gemstone')
          instance_flags_seen = true
          resolved_instance ||= 'GST' if argv.include?('--test')
          resolved_instance ||= 'GSX' if argv.include?('--platinum')
          resolved_instance ||= 'GSF' if argv.include?('--shattered')
          resolved_instance ||= 'GS3' # default gemstone
        end

        if argv.include?('--dragonrealms')
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

        # Check for direct instance codes (GS3, GS4, GST, GSX, etc.)
        # this filter ignores --login, --start-scripts=, and captures valid game codes
        # if anything else is sent with a --flag, it is processed as an incorrect instance
        if resolved_instance.nil?
          argv.each do |arg|
            next unless arg.start_with?('--')
            flag = arg.sub('--', '').downcase
            if VALID_GAME_CODES.include?(flag.upcase)
              instance_flags_seen = true
              resolved_instance = flag.upcase
              break
            elsif VALID_FRONTENDS.include?(flag) # ignore anything else that isn't a valid game code
              next
            elsif flag =~ /^(?:start-scripts|login)$/
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

      # Resolves login arguments from command-line arguments.
      def self.resolve_login_args(argv)
        frontend = :__unset
        instance = resolve_instance(argv)

        argv.each do |arg|
          case arg
          when FRONTEND_PATTERN
            frontend = Regexp.last_match[:fe].downcase
          end
        end

        Lich::Messaging.msg('debug', "Login arguments from CLI login -> #{argv.inspect}")
        Lich::Messaging.msg('debug', "Resolved instance: #{instance.inspect}, frontend: #{frontend.inspect}")
        Lich.log "debug: Login arguments from CLI login -> #{argv.inspect}"
        Lich.log "debug: Resolved instance: #{instance.inspect}, frontend: #{frontend.inspect}"
        # $stdout.puts "[DEBUG] ARGV: #{argv.inspect}"
        # $stdout.puts "[DEBUG] Resolved instance: #{instance.inspect}, frontend: #{frontend.inspect}"

        [instance, frontend]
      end

      # Formats the launch flag for a given game code.
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
      def self.spawn_login(entry, lich_path: nil, startup_scripts: [], instance_override: nil, frontend_override: nil)
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
