
module Lich
  module DragonRealms
    # Validates characters in the game.
    # This class handles the validation of character names and provides methods to interact with them.
    # @example Creating a character validator
    #   validator = Lich::DragonRealms::CharacterValidator.new(true, false, true, "Hero")
    class CharacterValidator
      # The name of the LNET script used for communication.
      LNET_SCRIPT_NAME = 'lnet'
      # Message displayed when no matching adventurers are found.
      FIND_NOT_FOUND = 'There are no adventurers in the realms that match the names specified'

      # Initializes a new CharacterValidator.
      # @param announce [Boolean] Whether to announce the character's presence.
      # @param should_sleep [Boolean] Whether to put the script to sleep.
      # @param greet [Boolean] Whether to greet the character.
      # @param name [String] The name of the character.
      # @return [void]
      def initialize(announce, should_sleep, greet, name)
        waitrt?
        fput('sleep') if should_sleep

        @lnet = (Script.running + Script.hidden).find { |val| val.name == LNET_SCRIPT_NAME }
        @validated_characters = []
        @greet = greet
        @name = name

        unless lnet_available?
          Lich::Messaging.msg("bold", "CharacterValidator: lnet is not running. Chat features will be unavailable.")
          return
        end

        send_chat("#{@name} is up and running in room #{Room.current.id}! Whisper me 'help' for more details.") if announce
      end

      # Sends the Slack token to the specified character.
      # @param character [String] The name of the character to send the token to.
      # @return [void]
      # @note This method will only execute if lnet is available.
      def send_slack_token(character)
        return unless lnet_available?

        message = "slack_token: #{UserVars.slack_token || 'Not Found'}"
        Lich::Messaging.msg("plain", "CharacterValidator: Attempting to DM #{character} with message: #{message}")
        send_chat_to(character, message)
      end

      # Validates the specified character.
      # @param character [String] The name of the character to validate.
      # @return [void]
      # @note This method will only execute if lnet is available.
      def validate(character)
        return if valid?(character)
        return unless lnet_available?

        Lich::Messaging.msg("plain", "CharacterValidator: Attempting to validate: #{character}")
        @lnet.unique_buffer.push("who #{character}")
      end

      # Confirms the validation of the specified character.
      # @param character [String] The name of the character to confirm.
      # @return [void]
      # @note This method will greet the character if the greet flag is set.
      def confirm(character)
        return if valid?(character)

        Lich::Messaging.msg("plain", "CharacterValidator: Successfully validated: #{character}")
        @validated_characters << character

        return unless @greet

        put "whisper #{character} Hi! I'm your friendly neighborhood #{@name}. Whisper me 'help' for more details. Don't worry, I've memorized your name so you won't see this message again."
      end

      # Checks if the specified character is validated.
      # @param character [String] The name of the character to check.
      # @return [Boolean] Returns true if the character is validated, false otherwise.
      def valid?(character)
        @validated_characters.include?(character)
      end

      # Sends the current bank balance to the specified character.
      # @param character [String] The name of the character to send the balance to.
      # @param balance [Numeric] The current balance to send.
      # @return [void]
      # @note This method will only execute if lnet is available.
      def send_bankbot_balance(character, balance)
        return unless lnet_available?

        message = "Current Balance: #{balance}"
        Lich::Messaging.msg("plain", "CharacterValidator: Attempting to DM #{character} with message: #{message}")
        send_chat_to(character, message)
      end

      # Sends the current location to the specified character.
      # @param character [String] The name of the character to send the location to.
      # @return [void]
      # @note This method will only execute if lnet is available.
      def send_bankbot_location(character)
        return unless lnet_available?

        message = "Current Location: #{Room.current.id}"
        Lich::Messaging.msg("plain", "CharacterValidator: Attempting to DM #{character} with message: #{message}")
        send_chat_to(character, message)
      end

      # Sends help messages to the specified character.
      # @param character [String] The name of the character to send help messages to.
      # @param messages [Array] An array of help messages to send.
      # @return [void]
      # @note This method will only execute if lnet is available.
      def send_bankbot_help(character, messages)
        return unless lnet_available?

        messages.each do |message|
          Lich::Messaging.msg("plain", "CharacterValidator: Attempting to DM #{character} with message: #{message}")
          send_chat_to(character, message)
        end
      end

      # Checks if the specified character is currently in the game.
      # @param character [String] The name of the character to check.
      # @return [Boolean] Returns true if the character is in the game, false otherwise.
      def in_game?(character)
        result = DRC.bput("find #{character}", FIND_NOT_FOUND, /^\s{2}#{character}\.$/, 'Unknown command')
        result =~ /^\s{2}#{character}\.$/
      end

      private

      def lnet_available?
        !@lnet.nil?
      end

      def send_chat(message)
        @lnet.unique_buffer.push("chat #{message}")
      end

      def send_chat_to(character, message)
        @lnet.unique_buffer.push("chat to #{character} #{message}")
      end
    end
  end
end
