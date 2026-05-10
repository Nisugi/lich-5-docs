
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
    module DRBanking
      module Pattern
        # Deposit a portion of money
        # "The clerk slides a small metal box across the counter into which you drop 5 gold Kronars"
        # Deposit a portion of money.
        #
        # Matches the output when a player deposits a specific amount of currency.
        # @example
        #   "The clerk slides a small metal box across the counter into which you drop 5 gold Kronars"
        # @see Pattern::DEPOSIT_ALL_TELLER
        # @see Pattern::DEPOSIT_ALL_JAR
        DEPOSIT_PORTION = /The clerk slides a small metal box across the counter into which you drop (?<amount>\d+) (?<denomination>\w+) (?<currency>Kronars|Lirums|Dokoras)/i.freeze

        # Deposit all money (teller bank)
        # "The clerk slides a small metal box across the counter into which you drop all your Kronars."
        # Deposit all money at a teller bank.
        #
        # Matches the output when a player deposits all their currency at a teller.
        # @example
        #   "The clerk slides a small metal box across the counter into which you drop all your Kronars."
        # @see Pattern::DEPOSIT_PORTION
        # @see Pattern::DEPOSIT_ALL_JAR
        DEPOSIT_ALL_TELLER = /The clerk slides a small metal box across the counter into which you drop all your (?<currency>Kronars|Lirums|Dokoras)\.\s+She counts them carefully and records the deposit in her ledger/i.freeze

        # Deposit all money (jar bank - Hib, etc.)
        # "You cross through the old balance on the label and update it to reflect your new balance"
        # Deposit all money at a jar bank.
        #
        # Matches the output when a player updates their balance in a jar bank.
        # @example
        #   "You cross through the old balance on the label and update it to reflect your new balance"
        DEPOSIT_ALL_JAR = /You cross through the old balance on the label and update it to reflect your new balance/i.freeze

        # Withdraw a portion of money
        # "The clerk counts out 5 gold Kronars and hands them over, making a notation in her ledger"
        # "You count out 5 gold Dokoras and quickly pocket them, updating the notation on your jar"
        # Withdraw a portion of money.
        #
        # Matches the output when a player withdraws a specific amount of currency.
        # @example
        #   "The clerk counts out 5 gold Kronars and hands them over, making a notation in her ledger"
        # @example
        #   "You count out 5 gold Dokoras and quickly pocket them, updating the notation on your jar"
        WITHDRAW_PORTION = /(?:The clerk counts|You count) out (?<amount>\d+) (?<denomination>platinum|gold|silver|bronze|copper) (?<currency>Kronars|Lirums|Dokoras) (?:and hands them over, making a notation in her ledger|and quickly pocket them, updating the notation on your jar)/i.freeze

        # Withdraw all money
        # "The clerk counts out all your Kronars and hands them over"
        # "You count out all of your Dokoras and quickly pocket them"
        # Withdraw all money.
        #
        # Matches the output when a player withdraws all their currency.
        # @example
        #   "The clerk counts out all your Kronars and hands them over"
        # @example
        #   "You count out all of your Dokoras and quickly pocket them"
        WITHDRAW_ALL = /(?:The clerk counts out all your|You count out all of your) (?<currency>Kronars|Lirums|Dokoras)/i.freeze

        # Balance check
        # "it looks like your current balance is 5 platinum Kronars"
        # "Here we are. Your current balance is 10 gold, 5 silver Lirums"
        # "As expected, there are 100 copper Dokoras"
        # Check the balance of a bank account.
        #
        # Matches the output when a player checks their current balance.
        # @example
        #   "it looks like your current balance is 5 platinum Kronars"
        # @example
        #   "Here we are. Your current balance is 10 gold, 5 silver Lirums"
        # @example
        #   "As expected, there are 100 copper Dokoras"
        BALANCE_CHECK = /(?:it looks like|"Here we are\.)\s*[Yy]our current balance is (?<balance>.*)\s+(?<currency>Kronars|Lirums|Dokoras)|As expected, there are (?<balance>.*)\s+(?<currency>Kronars|Lirums|Dokoras)/i.freeze

        # No account at this bank
        # Indicates that the player does not have an account at the bank.
        #
        # Matches the output when a player tries to access a bank without an account.
        # @example
        #   "you do not seem to have an account with us"
        # @example
        #   "you should find a new deposit jar for your financial needs"
        NO_ACCOUNT = /you do not seem to have an account with us|you should find a new deposit jar for your financial needs/i.freeze
      end

      # Denomination multipliers for converting to copper
      # Denomination multipliers for converting to copper.
      #
      # This hash maps currency denominations to their values in copper.
      DENOMINATION_VALUES = {
        'platinum' => 10_000,
        'gold'     => 1_000,
        'silver'   => 100,
        'bronze'   => 10,
        'copper'   => 1
      }.freeze

      # Currency to bank list mapping
      # Currency to bank list mapping.
      #
      # This hash maps currency types to their respective bank lists.
      CURRENCY_BANKS = {
        'Kronars' => KRONAR_BANKS,
        'Lirums'  => LIRUM_BANKS,
        'Dokoras' => DOKORA_BANKS
      }.freeze

      # Settings key for banking data
      # Settings key for banking data.
      #
      # This constant holds the key used to store and retrieve banking data.
      SETTINGS_KEY = 'banking'

      # Pattern for parsing balance amounts from strings
      # Pattern for parsing balance amounts from strings.
      #
      # Matches strings that represent balance amounts in various denominations.
      # @example
      #   "10 gold"
      # @example
      #   "5 platinum"
      BALANCE_AMOUNT_PATTERN = /(\d+)\s+(platinum|gold|silver|bronze|copper)/i.freeze

      # In-memory cache of accounts data
      @@accounts_cache = nil

      class << self
        # Retrieves all bank accounts for the current character.
        #
        # If the accounts are not already loaded, they will be loaded from storage.
        # @return [Hash] a hash of bank accounts for the character.
        def all_accounts
          load_accounts unless @@accounts_cache
          @@accounts_cache
        end

        # Retrieves the bank accounts for the current character.
        #
        # If no accounts exist, an empty hash is returned.
        # @return [Hash] a hash of the current character's bank accounts.
        def my_accounts
          all_accounts[character_name] ||= {}
        end

        # Updates the balance for a specific town.
        #
        # @param town [String] the name of the town where the account is held.
        # @param copper [Integer] the new balance in copper.
        # @return [void]
        def update_balance(town, copper)
          all_accounts[character_name] ||= {}
          all_accounts[character_name][town] = copper.to_i
          save_accounts
          Lich::Messaging.msg('info', "DRBanking: Updated #{town} balance to #{format_currency(copper)}")
        end

        # Clears the balance for a specific town by setting it to zero.
        #
        # @param town [String] the name of the town to clear the balance for.
        # @return [void]
        def clear_balance(town)
          update_balance(town, 0)
        end

        # Calculates the total wealth across all accounts for the current character.
        #
        # @return [Integer] the total wealth in copper.
        def total_wealth
          my_accounts.values.sum
        end

        # Calculates the total wealth across all characters' accounts.
        #
        # @return [Integer] the total wealth in copper.
        def total_wealth_all
          all_accounts.values.map { |banks| banks.values.sum }.sum
        end

        # Converts an amount of currency to copper based on its denomination.
        #
        # @param amount [Integer] the amount of currency to convert.
        # @param denomination [String] the denomination of the currency.
        # @return [Integer] the equivalent amount in copper.
        def to_copper(amount, denomination)
          multiplier = DENOMINATION_VALUES[denomination.downcase] || 1
          amount.to_i * multiplier
        end

        # Parses a balance string and converts it to copper.
        #
        # @param balance_string [String] the string representing the balance.
        # @return [Integer] the total balance in copper.
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
        # @param copper [Integer] the amount in copper to format.
        # @return [String] the formatted currency string.
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
        # @return [String, nil] the name of the current bank town or nil if not in a bank.
        def current_bank_town
          room_title = XMLData.room_title
          return nil if room_title.nil? || room_title.empty?

          BANK_TITLES.each do |town, titles|
            return town if titles.any? { |title| room_title.include?(title.gsub('[[', '').gsub(']]', '')) }
          end
          nil
        end

        # Parses a line of game output to handle banking actions.
        #
        # @param line [String] the line of output to parse.
        # @return [void]
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

        # Displays the bank balances for the current character.
        #
        # @return [void]
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
        def reload!
          @@accounts_cache = nil
          load_accounts
        end

        # Resets the bank data for the current character.
        #
        # @return [void]
        def reset_character!
          all_accounts.delete(character_name)
          save_accounts
          Lich::Messaging.msg('info', "DRBanking: Cleared bank data for #{character_name}.")
        end

        # Resets the bank data for all characters.
        #
        # @return [void]
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
