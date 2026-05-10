
# Lich module for DragonRealms functionality
# This module contains methods for handling currency and wealth in the DragonRealms game.
# @example Including the module
#   include Lich::DragonRealms::DRCM
module Lich
  module DragonRealms
    module DRCM
      module_function

      # Strips XML tags from the given lines.
      # @param lines [Array<String>] The lines containing XML to be stripped.
      # @return [Array<String>] The lines without XML tags.
      # @example
      #   clean_lines = strip_xml(raw_lines)
      def strip_xml(lines)
        DRC.strip_xml(lines)
      end

      # Minimizes the number of coins needed to represent a given amount of copper.
      # @param copper [Integer] The amount of copper to minimize.
      # @return [Array<String>] An array of strings representing the minimized coins.
      # @example
      #   coins = minimize_coins(100)
      def minimize_coins(copper)
        DENOMINATIONS.inject([copper, []]) do |result, denomination|
          remaining = result.first
          display = result.last
          if remaining / denomination.first > 0
            display << "#{remaining / denomination.first} #{denomination.last}"
          end
          [remaining % denomination.first, display]
        end.last
      end

      # Converts a given amount in a specific denomination to copper.
      # @param amount [Numeric] The amount to convert.
      # @param denomination [String] The denomination to convert from.
      # @return [Integer] The equivalent amount in copper.
      # @example
      #   copper_amount = convert_to_copper(10, 'silver')
      def convert_to_copper(amount, denomination)
        denomination = denomination.to_s.strip
        unless denomination.empty?
          DENOMINATION_VALUES.each do |name, multiplier|
            return (amount.to_f * multiplier).to_i if name.start_with?(denomination.downcase)
          end
        end
        Lich::Messaging.msg('bold', "DRCM: Unknown denomination, assuming coppers: #{denomination}")
        amount.to_i
      end

      # Retrieves the canonical currency name for a given currency string.
      # @param currency [String] The currency string to look up.
      # @return [String, nil] The canonical currency name or nil if not found.
      # @example
      #   canonical_currency = get_canonical_currency('gold')
      def get_canonical_currency(currency)
        CURRENCIES.find { |c| c.start_with?(currency) }
      end

      # Converts an amount from one currency to another, applying a fee if necessary.
      # @param amount [Numeric] The amount to convert.
      # @param from [String] The currency to convert from.
      # @param to [String] The currency to convert to.
      # @param fee [Float] The conversion fee as a decimal.
      # @return [Integer] The converted amount in the target currency.
      # @example
      #   converted_amount = convert_currency(100, 'gold', 'silver', 0.05)
      def convert_currency(amount, from, to, fee)
        if fee < 0
          ((amount / EXCHANGE_RATES[from][to]).ceil / (1 + fee)).ceil
        else
          ((amount * EXCHANGE_RATES[from][to]).ceil * (1 - fee)).floor
        end
      end

      # Retrieves the currency used in a given hometown.
      # @param hometown_name [String] The name of the hometown.
      # @return [String] The currency used in the hometown.
      # @example
      #   currency = hometown_currency('Wehnimer's Landing')
      def hometown_currency(hometown_name)
        get_data('town')[hometown_name]['currency']
      end

      # Retrieves the currency used in a specified town.
      # @param town [String] The name of the town.
      # @return [String] The currency used in the town.
      # @example
      #   currency = town_currency('Wehnimer's Landing')
      def town_currency(town)
        hometown_currency(town)
      end

      # Checks the wealth of a specified currency.
      # @param currency [String] The currency to check wealth for.
      # @return [Integer] The amount of wealth in the specified currency.
      # @example
      #   wealth_amount = check_wealth('gold')
      def check_wealth(currency)
        DRC.bput("wealth #{currency}", /\(\d+ copper #{currency}\)/i, /No #{currency}/i).scan(/\d+/).first.to_i
      end

      # Retrieves the wealth for a given hometown.
      # @param hometown [String] The name of the hometown.
      # @return [Integer] The amount of wealth in the hometown's currency.
      # @example
      #   hometown_wealth = wealth('Wehnimer's Landing')
      def wealth(hometown)
        check_wealth(hometown_currency(hometown))
      end

      # Retrieves the total wealth across all currencies.
      # @return [Hash] A hash containing the total wealth in different currencies.
      # @example
      #   total_wealth = get_total_wealth
      def get_total_wealth
        wealth_lines = Lich::Util.issue_command(
          'wealth',
          /^Wealth:/,
          /<prompt/,
          usexml: true,
          quiet: true,
          include_end: false,
          timeout: 5
        )

        result = { 'kronars' => 0, 'lirums' => 0, 'dokoras' => 0 }
        return result if wealth_lines.nil?

        strip_xml(wealth_lines).each do |line|
          match = line.match(WEALTH_COPPER_REGEX)
          next unless match

          result[match[:currency].downcase] = match[:coppers].to_i
        end

        result
      end

      # Ensures that a specified amount of copper is available on hand.
      # @param copper [Integer] The amount of copper to ensure is available.
      # @param settings [Object] The settings object containing user preferences.
      # @param hometown [String, nil] The optional hometown name.
      # @return [Boolean] True if the required copper is available, false otherwise.
      # @example
      #   has_copper = ensure_copper_on_hand(50, user_settings)
      def ensure_copper_on_hand(copper, settings, hometown = nil)
        hometown = settings.hometown if hometown.nil?

        on_hand = wealth(hometown)
        return true if on_hand >= copper

        withdrawals = minimize_coins(copper - on_hand)

        withdrawals.all? { |amount| withdraw_exact_amount?(amount, settings, hometown) }
      end

      # Withdraws an exact amount of currency from the bank.
      # @param amount_as_string [String] The amount to withdraw as a string.
      # @param settings [Object] The settings object containing user preferences.
      # @param hometown [String, nil] The optional hometown name.
      # @return [Boolean] True if the withdrawal was successful, false otherwise.
      # @example
      #   success = withdraw_exact_amount?('10 gold', user_settings)
      def withdraw_exact_amount?(amount_as_string, settings, hometown = nil)
        hometown = settings.hometown if hometown.nil?

        if settings.bankbot_enabled
          DRCT.walk_to(settings.bankbot_room_id)
          DRC.release_invisibility
          if DRRoom.pcs.include?(settings.bankbot_name)
            amount_convert, type = amount_as_string.split
            amount = convert_to_copper(amount_convert, type)
            currency = hometown_currency(settings.hometown)
            case DRC.bput("whisper #{settings.bankbot_name} withdraw #{amount} #{currency}", 'offers you', 'Whisper what to who?')
            when 'offers you'
              DRC.bput('accept tip', 'Your current balance is')
            end
          else
            get_money_from_bank(amount_as_string, settings, hometown)
          end
        else
          get_money_from_bank(amount_as_string, settings, hometown)
        end
      end

      # Retrieves a specified amount of money from the bank.
      # @param amount_as_string [String] The amount to withdraw as a string.
      # @param settings [Object] The settings object containing user preferences.
      # @param hometown [String, nil] The optional hometown name.
      # @return [Boolean] True if the money was successfully retrieved, false otherwise.
      # @example
      #   success = get_money_from_bank('10 gold', user_settings)
      def get_money_from_bank(amount_as_string, settings, hometown = nil)
        hometown = settings.hometown if hometown.nil?

        DRCT.walk_to(get_data('town')[hometown]['deposit']['id'])
        DRC.release_invisibility
        loop do
          case DRC.bput("withdraw #{amount_as_string}", 'The clerk counts', 'The clerk tells',
                        'The clerk glares at you.', 'You count out', 'find a new deposit jar', 'If you value your hands',
                        'Hey!  Slow down!', "You must be at a bank teller's window to withdraw money",
                        "You don't have that much money", 'have an account',
                        /The clerk says, "I'm afraid you can't withdraw that much at once/,
                        /^How much do you wish to withdraw/i)
          when 'The clerk counts', 'You count out'
            break true
          when 'The clerk glares at you.', 'Hey!  Slow down!', "I don't know what you think you're doing"
            pause 15
          when 'The clerk tells', 'If you value your hands', 'find a new deposit jar',
            "You must be at a bank teller's window to withdraw money", "You don't have that much money",
            'have an account', /The clerk says, "I'm afraid you can't withdraw that much at once/,
            /^How much do you wish to withdraw/i
            break false
          else
            break false
          end
        end
      end

      # Retrieves the debt amount for a given hometown.
      # @param hometown [String] The name of the hometown.
      # @return [Integer] The amount of debt in the hometown's currency.
      # @example
      #   debt_amount = debt('Wehnimer's Landing')
      def debt(hometown)
        currency = hometown_currency(hometown)
        DRC.bput('wealth', /\(\d+ copper #{currency}\)/i, /Wealth:/i).scan(/\d+/).first.to_i
      end

      # Deposits coins into the bank, ensuring a specified amount of copper is kept on hand.
      # @param keep_copper [Integer] The amount of copper to keep on hand after deposit.
      # @param settings [Object] The settings object containing user preferences.
      # @param hometown [String, nil] The optional hometown name.
      # @return [void]
      # @example
      #   deposit_coins(50, user_settings)
      def deposit_coins(keep_copper, settings, hometown = nil)
        return if settings.skip_bank

        hometown = settings.hometown if hometown.nil?

        DRCT.walk_to(get_data('town')[hometown]['deposit']['id'])
        DRC.release_invisibility
        DRC.bput('wealth', 'Wealth:')
        case DRC.bput('deposit all', 'you drop all your', 'You hand the clerk some coins', "You don't have any",
                      'There is no teller here', 'reached the maximum balance I can permit',
                      'You find your jar with little effort', 'Searching methodically through the shelves')
        when 'There is no teller here'
          Lich::Messaging.msg('bold', "DRCM: No teller found at this location. Cannot deposit coins.")
          return
        end
        minimize_coins(keep_copper).each { |amount| withdraw_exact_amount?(amount, settings) } if settings.hometown == hometown
        balance_result = DRC.bput('check balance',
                                  /current balance is .*? (?:Kronars?|Dokoras?|Lirums?)\."$/,
                                  /If you would like to open one, you need only deposit a few (?:Kronars?|Dokoras?|Lirums?)\."$/,
                                  /As expected, there are .*? (?:Kronars?|Dokoras?|Lirums?)\.$/,
                                  'Perhaps you should find a new deposit jar for your financial needs.  Be sure to mark it with your name')
        case balance_result
        when /current balance is (?<bal>.*?) (?<cur>Kronars?|Dokoras?|Lirums?)\."$/,
             /As expected, there are (?<bal>.*?) (?<cur>Kronars?|Dokoras?|Lirums?)\.$/
          match = balance_result.match(/(?:current balance is|As expected, there are) (?<bal>.*?) (?<cur>Kronars?|Dokoras?|Lirums?)/)
          currency = match[:cur]
          balance = 0
          match[:bal].gsub(/and /, '').split(', ').each do |amount_as_string|
            amount, denomination = amount_as_string.split
            balance += convert_to_copper(amount, denomination)
          end
        when /If you would like to open one, you need only deposit a few (?<cur>Kronars?|Dokoras?|Lirums?)\."$/
          match = balance_result.match(/deposit a few (?<cur>Kronars?|Dokoras?|Lirums?)/)
          balance = 0
          currency = match[:cur]
        when /Perhaps you should find a new deposit jar/
          balance = 0
          currency = 'Dokoras'
        end
        [balance, currency]
      end
    end
  end
end
