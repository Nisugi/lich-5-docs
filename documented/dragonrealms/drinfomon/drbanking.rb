
module Lich
  module DragonRealms
    # DRBanking provides bank account tracking and vault information storage.
    #
    # Bank balances are tracked passively by parsing game output when players
    # deposit, withdraw, or check their balance at banks across Elanthia.
    #
    # DRBanking provides bank account tracking and vault information storage.
    #
    # Bank balances are tracked passively by parsing game output when players
    # deposit, withdraw, or check their balance at banks across Elanthia.
    # @example Usage
    #   Lich::DragonRealms::DRBanking.update_balance("town_name", 100)
    module DRBanking
      module Pattern
        # Deposit a portion of money
        # "The clerk slides a small metal box across the counter into which you drop 5 gold Kronars"
        DEPOSIT_PORTION = /The clerk slides a small metal box across the counter into which you drop (?<amount>\d+) (?<denomination>\w+) (?<currency>Kronars|Lirums|Dokoras)/i.freeze

        # Deposit all money (teller bank)
        # "The clerk slides a small metal box across the counter into which you drop all your Kronars."
        DEPOSIT_ALL_TELLER = /The clerk slides a small metal box across the counter into which you drop all your (?<currency>Kronars|Lirums|Dokoras)\.\s+She counts them carefully and records the deposit in her ledger/i.freeze

        # Deposit all money (jar bank - Hib, etc.)
        # "You cross through the old balance on the label and update it to reflect your new balance"
        DEPOSIT_ALL_JAR = /You cross through the old balance on the label and update it to reflect your new balance/i.freeze

        # Withdraw a portion of money
        # "The clerk counts out 5 gold Kronars and hands them over, making a notation in her ledger"
        # "You count out 5 gold Dokoras and quickly pocket them, updating the notation on your jar"
        WITHDRAW_PORTION = /(?:The clerk counts|You count) out (?<amount>\d+) (?<denomination>platinum|gold|silver|bronze|copper) (?<currency>Kronars|Lirums|Dokoras) (?:and hands them over, making a notation in her ledger|and quickly pocket them, updating the notation on your jar)/i.freeze

        # Withdraw all money
        # "The clerk counts out all your Kronars and hands them over"
        # "You count out all of your Dokoras and quickly pocket them"
        WITHDRAW_ALL = /(?:The clerk counts out all your|You count out all of your) (?<currency>Kronars|Lirums|Dokoras)/i.freeze

        # Balance check
        # "it looks like your current balance is 5 platinum Kronars"
        # "Here we are. Your current balance is 10 gold, 5 silver Lirums"
        # "As expected, there are 100 copper Dokoras"
        BALANCE_CHECK = /(?:it looks like|"Here we are\.)\s*[Yy]our current balance is (?<balance>.*)\s+(?<currency>Kronars|Lirums|Dokoras)|As expected, there are (?<balance>.*)\s+(?<currency>Kronars|Lirums|Dokoras)/i.freeze

        # No account at this bank
        NO_ACCOUNT = /you do not seem to have an account with us|you should find a new deposit jar for your financial needs/i.freeze
      end

      # Denomination multipliers for converting to copper
      # Denomination multipliers for converting to copper
      DENOMINATION_VALUES = {
        'platinum' => 10_000,
        'gold'     => 1_000,
        'silver'   => 100,
        'bronze'   => 10,
        'copper'   => 1
      }.freeze

      # Currency to bank list mapping
      # Currency to bank list mapping
      CURRENCY_BANKS = {
        'Kronars' => KRONAR_BANKS,
        'Lirums'  => LIRUM_BANKS,
        'Dokoras' => DOKORA_BANKS
      }.freeze

      # Settings key for banking data
      # Settings key for banking data
      SETTINGS_KEY = 'banking'

      # Pattern for parsing balance amounts from strings
      # Pattern for parsing balance amounts from strings
      BALANCE_AMOUNT_PATTERN = /(\d+)\s+(platinum|gold|silver|bronze|copper)/i.freeze

      # In-memory cache of accounts data
      @@accounts_cache = nil

      class << self
        # Returns all bank accounts for the current character.
        #
        # Loads accounts from cache if not already loaded.
        # @return [Hash] A hash of all accounts for the character.
        # @example
        #   accounts = Lich::DragonRealms::DRBanking.all_accounts
        def all_accounts
          load_accounts unless @@accounts_cache
          @@accounts_cache
        end

        # Returns the bank accounts for the current character.
        #
        # @return [Hash] A hash of the current character's bank accounts.
        # @example
        #   my_accounts = Lich::DragonRealms::DRBanking.my_accounts
        def my_accounts
          all_accounts[character_name] ||= {}
        end

        # Updates the balance for a specific town.
        #
        # @param town [String] The name of the town.
        # @param copper [Integer] The amount of copper to set as the new balance.
        # @return [void]
        # @example
        #   Lich::DragonRealms::DRBanking.update_balance("town_name", 100)
        def update_balance(town, copper)
          all_accounts[character_name] ||= {}
          all_accounts[character_name][town] = copper.to_i
          save_accounts
          Lich::Messaging.msg('info', "DRBanking: Updated #{town} balance to #{format_currency(copper)}")
        end

        # Clears the balance for a specific town by setting it to zero.
        #
        # @param town [String] The name of the town.
        # @return [void]
        # @example
        #   Lich::DragonRealms::DRBanking.clear_balance("town_name")
        def clear_balance(town)
          update_balance(town, 0)
        end

        # Calculates the total wealth across all accounts for the current character.
        #
        # @return [Integer] The total wealth in copper.
        # @example
        #   total = Lich::DragonRealms::DRBanking.total_wealth
        def total_wealth
          my_accounts.values.sum
        end

        # Calculates the total wealth across all characters.
        #
        # @return [Integer] The total wealth in copper for all characters.
        # @example
        #   total_all = Lich::DragonRealms::DRBanking.total_wealth_all
        def total_wealth_all
          all_accounts.values.map { |banks| banks.values.sum }.sum
        end

        # Converts an amount of currency to copper based on its denomination.
        #
        # @param amount [Integer] The amount of currency to convert.
        # @param denomination [String] The denomination of the currency.
        # @return [Integer] The equivalent amount in copper.
        # @example
        #   copper_amount = Lich::DragonRealms::DRBanking.to_copper(5, "gold")
        def to_copper(amount, denomination)
          multiplier = DENOMINATION_VALUES[denomination.downcase] || 1
          amount.to_i * multiplier
        end

        # Parses a balance string and converts it to copper.
        #
        # @param balance_string [String] The string containing the balance information.
        # @return [Integer] The total balance in copper.
        # @example
        #   copper = Lich::DragonRealms::DRBanking.parse_balance_string("10 gold, 5 silver")
        def parse_balance_string(balance_string)
          return 0 if balance_string.nil? || balance_string.empty?

          copper = 0
          balance_string.scan(BALANCE_AMOUNT_PATTERN) do |amount, denom|
            copper += to_copper(amount, denom)
          end
          copper
        end

        # Formats a copper amount into a human-readable currency string.
        #
        # @param copper [Integer] The amount in copper to format.
        # @return [String] The formatted currency string.
        # @example
        #   formatted = Lich::DragonRealms::DRBanking.format_currency(1500)
        def format_currency(copper)
          copper = copper.to_i
          return 'none' if copper <= 0

          parts = []
          DENOMINATION_VALUES.each do |name, value|
            count = copper / value
            if count > 0
              parts << "#{count} #{name}"
              copper %= value
            end
          end
          parts.empty? ? 'none' : parts.join(', ')
        end

        # Determines the current bank town based on the room title.
        #
        # @return [String, nil] The name of the current bank town or nil if not in a bank.
        # @example
        #   town = Lich::DragonRealms::DRBanking.current_bank_town
        def current_bank_town
          room_title = XMLData.room_title
          return nil if room_title.nil? || room_title.empty?

          BANK_TITLES.each do |town, titles|
            return town if titles.any? { |title| room_title.include?(title.gsub('[[', '').gsub(']]', '')) }
          end
          nil
        end

        # Parses a line of game output to update banking information.
        #
        # @param line [String] The line of game output to parse.
        # @return [void]
        # @example
        #   Lich::DragonRealms::DRBanking.parse("You count out 5 gold Kronars and quickly pocket them.")
        def parse(line)
          return unless line.is_a?(String)

          town = current_bank_town
          return unless town

          # Use explicit match variables instead of Regexp.last_match (more reliable)
          if (match = line.match(Pattern::DEPOSIT_PORTION))
            handle_deposit_portion(town, match)
          elsif line.match?(Pattern::DEPOSIT_ALL_TELLER) || line.match?(Pattern::DEPOSIT_ALL_JAR)
            handle_deposit_all(town)
          elsif (match = line.match(Pattern::WITHDRAW_PORTION))
            handle_withdraw_portion(town, match)
          elsif line.match?(Pattern::WITHDRAW_ALL)
            handle_withdraw_all(town)
          elsif (match = line.match(Pattern::BALANCE_CHECK))
            handle_balance_check(town, match)
          elsif line.match?(Pattern::NO_ACCOUNT)
            handle_no_account(town)
          end
        end

        # Displays the current character's bank balances.
        #
        # @return [void]
        # @example
        #   Lich::DragonRealms::DRBanking.display_banks
        def display_banks
          accounts = my_accounts
          if accounts.empty?
            Lich::Messaging.msg('info', 'DRBanking: No bank account info recorded.')
            return
          end

          Lich::Messaging.msg('info', 'DRBanking: Your bank balances:')
          Lich::Messaging.msg('info', '-' * 50)

          # Group by currency
          { 'Kronars' => KRONAR_BANKS, 'Lirums' => LIRUM_BANKS, 'Dokoras' => DOKORA_BANKS }.each do |currency, banks|
            currency_total = 0
            banks.each do |bank_town|
              next unless accounts[bank_town]

              amount = accounts[bank_town]
              currency_total += amount
              Lich::Messaging.msg('info', "  #{bank_town.rjust(25)}: #{format_currency(amount)}")
            end
            Lich::Messaging.msg('info', "  #{currency} Total:".rjust(27) + " #{format_currency(currency_total)}") if currency_total > 0
          end

          Lich::Messaging.msg('info', '-' * 50)
          Lich::Messaging.msg('info', "  #{'Grand Total:'.rjust(25)} #{format_currency(total_wealth)}")
        end

        # Displays the bank balances for all characters.
        #
        # @return [void]
        # @example
        #   Lich::DragonRealms::DRBanking.display_banks_all
        def display_banks_all
          accounts = all_accounts
          if accounts.empty?
            Lich::Messaging.msg('info', 'DRBanking: No bank account info recorded for any character.')
            return
          end

          Lich::Messaging.msg('info', 'DRBanking: Bank balances for all characters:')
          Lich::Messaging.msg('info', '=' * 60)

          grand_total = 0
          accounts.each do |char_name, char_accounts|
            next if char_accounts.empty?

            char_total = char_accounts.values.sum
            grand_total += char_total

            Lich::Messaging.msg('info', "#{char_name}:")
            char_accounts.each do |town, amount|
              Lich::Messaging.msg('info', "    #{town.rjust(23)}: #{format_currency(amount)}")
            end
            Lich::Messaging.msg('info', "    #{'Character Total:'.rjust(23)} #{format_currency(char_total)}")
            Lich::Messaging.msg('info', '')
          end

          Lich::Messaging.msg('info', '=' * 60)
          Lich::Messaging.msg('info', "Grand Total (all characters): #{format_currency(grand_total)}")
        end

        # Reloads the bank accounts from storage.
        #
        # @return [void]
        # @example
        #   Lich::DragonRealms::DRBanking.reload!
        def reload!
          @@accounts_cache = nil
          load_accounts
        end

        # Resets the bank data for the current character.
        #
        # @return [void]
        # @example
        #   Lich::DragonRealms::DRBanking.reset_character!
        def reset_character!
          all_accounts.delete(character_name)
          save_accounts
          Lich::Messaging.msg('info', "DRBanking: Cleared bank data for #{character_name}.")
        end

        # Resets the bank data for all characters.
        #
        # @return [void]
        # @example
        #   Lich::DragonRealms::DRBanking.reset_all!
        def reset_all!
          @@accounts_cache = {}
          save_accounts
          Lich::Messaging.msg('info', 'DRBanking: Cleared all bank data for all characters.')
        end

        private

        def character_name
          XMLData.name
        end

        def load_accounts
          @@accounts_cache = Lich::Common::InstanceSettings.game[SETTINGS_KEY] || {}
          # Convert SettingsProxy to plain hash if needed
          @@accounts_cache = @@accounts_cache.to_h if @@accounts_cache.respond_to?(:to_h) && !@@accounts_cache.is_a?(Hash)
        end

        def save_accounts
          Lich::Common::InstanceSettings.game[SETTINGS_KEY] = @@accounts_cache
        end

        def handle_deposit_portion(town, match)
          amount = match[:amount].to_i
          denomination = match[:denomination]
          copper = to_copper(amount, denomination)

          current = my_accounts[town]
          if current.nil?
            # No prior balance recorded - can't calculate new balance
            Lich::Messaging.msg('info', "DRBanking: Deposited #{format_currency(copper)} at #{town}. " \
                                        'No prior balance recorded - check BALANCE to sync.')
            return
          end

          update_balance(town, current.to_i + copper)
        end

        def handle_deposit_all(town)
          # After depositing all, we need to check balance
          # The game will show the new balance, so we trigger a balance check
          Lich::Messaging.msg('info', "DRBanking: Deposited all money at #{town}. Checking balance...")
          # The balance will be updated when the balance response comes through
        end

        def handle_withdraw_portion(town, match)
          amount = match[:amount].to_i
          denomination = match[:denomination]
          copper = to_copper(amount, denomination)

          current = my_accounts[town]
          if current.nil?
            # No prior balance recorded - can't calculate new balance
            Lich::Messaging.msg('info', "DRBanking: Withdrew #{format_currency(copper)} from #{town}. " \
                                        'No prior balance recorded - check BALANCE to sync.')
            return
          end

          new_balance = [current.to_i - copper, 0].max
          update_balance(town, new_balance)
        end

        def handle_withdraw_all(town)
          update_balance(town, 0)
          Lich::Messaging.msg('info', "DRBanking: Withdrew all money from #{town}.")
        end

        def handle_balance_check(town, match)
          balance_str = match[:balance]
          copper = parse_balance_string(balance_str)
          update_balance(town, copper)
        end

        def handle_no_account(town)
          clear_balance(town)
          Lich::Messaging.msg('info', "DRBanking: No account at #{town}.")
        end
      end
    end
  end
end
