module Lich
  module Common
    # Provides methods to manage account-related data.
    # This module includes functionality for handling account name,
    # subscription type, game code, and members.
    # @example Accessing account name
    #   Lich::Common::Account.name
    module Account
      @@name ||= nil
      @@subscription ||= nil
      @@game_code ||= nil
      @@members ||= {}
      @@character ||= nil

      # Returns the name of the account.
      # @return [String, nil] The account name or nil if not set.
      def self.name
        @@name
      end

      # Sets the name of the account.
      # @param value [String] The new account name.
      def self.name=(value)
        @@name = value
      end

      # Returns the character associated with the account.
      # @return [Object, nil] The character object or nil if not set.
      def self.character
        @@character
      end

      # Sets the character associated with the account.
      # @param value [Object] The character object to associate with the account.
      def self.character=(value)
        @@character = value
      end

      # Returns the subscription type of the account.
      # @return [String, nil] The subscription type or nil if not set.
      def self.subscription
        @@subscription
      end

      # Retrieves the account type based on game data.
      # @return [String, nil] The account type or nil if not applicable.
      def self.type
        if XMLData.game.is_a?(String) && XMLData.game =~ /^GS/
          Infomon.get("account.type")
        end
      end

      # Sets the subscription type of the account.
      # @param value [String] The subscription type (NORMAL, PREMIUM, TRIAL, INTERNAL, FREE).
      def self.subscription=(value)
        if value =~ /(NORMAL|PREMIUM|TRIAL|INTERNAL|FREE)/
          @@subscription = Regexp.last_match(1)
        end
      end

      # Returns the game code associated with the account.
      # @return [String, nil] The game code or nil if not set.
      def self.game_code
        @@game_code
      end

      # Sets the game code associated with the account.
      # @param value [String] The game code to associate with the account.
      def self.game_code=(value)
        @@game_code = value
      end

      # Returns the members associated with the account.
      # @return [Hash] A hash of member codes and names.
      def self.members
        @@members
      end

      # Sets the members associated with the account.
      # @param value [String] A string containing member codes and names.
      def self.members=(value)
        potential_members = {}
        for code_name in value.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
          char_code, char_name = code_name.split("\t")
          potential_members[char_code] = char_name
        end
        @@members = potential_members
      end

      # Returns the character names associated with the account members.
      # @return [Array] An array of character names.
      def self.characters
        @@members.values
      end
    end
  end
end
