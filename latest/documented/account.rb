module Lich
  module Common
    # Provides methods to manage account-related data.
    # This module handles account name, subscription type, game code, and members.
    # @example Accessing account name
    #   Lich::Common::Account.name
    module Account
      @@name ||= nil
      @@subscription ||= nil
      @@game_code ||= nil
      @@members ||= {}
      @@character ||= nil

      # Retrieves the account name.
      # @return [String, nil] The account name or nil if not set.
      def self.name
        @@name
      end

      # Sets the account name.
      # @param value [String] The new account name.
      # @return [String] The set account name.
      # @example Setting the account name
      #   Lich::Common::Account.name = 'NewName'
      def self.name=(value)
        @@name = value
      end

      # Retrieves the current character associated with the account.
      # @return [Object, nil] The character object or nil if not set.
      def self.character
        @@character
      end

      # Sets the current character for the account.
      # @param value [Object] The character object to associate with the account.
      # @return [Object] The set character object.
      def self.character=(value)
        @@character = value
      end

      # Retrieves the subscription type of the account.
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

      # Sets the subscription type for the account.
      # @param value [String] The subscription type (NORMAL, PREMIUM, TRIAL, INTERNAL, FREE).
      # @return [String] The set subscription type.
      # @raise [ArgumentError] If the value is not a valid subscription type.
      # @example Setting the subscription type
      #   Lich::Common::Account.subscription = 'PREMIUM'
      def self.subscription=(value)
        if value =~ /(NORMAL|PREMIUM|TRIAL|INTERNAL|FREE)/
          @@subscription = Regexp.last_match(1)
        end
      end

      # Retrieves the game code associated with the account.
      # @return [String, nil] The game code or nil if not set.
      def self.game_code
        @@game_code
      end

      # Sets the game code for the account.
      # @param value [String] The game code to associate with the account.
      # @return [String] The set game code.
      def self.game_code=(value)
        @@game_code = value
      end

      # Retrieves the members associated with the account.
      # @return [Hash] A hash of member codes and names.
      def self.members
        @@members
      end

      # Sets the members for the account based on a formatted string.
      # @param value [String] The formatted string containing member codes and names.
      # @return [Hash] The set members hash.
      # @example Setting members
      #   Lich::Common::Account.members = 'C\t123\t456\t789\t012\tName1\tName2'
      def self.members=(value)
        potential_members = {}
        for code_name in value.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
          char_code, char_name = code_name.split("\t")
          potential_members[char_code] = char_name
        end
        @@members = potential_members
      end

      # Retrieves the names of all characters associated with the account.
      # @return [Array<String>] An array of character names.
      def self.characters
        @@members.values
      end
    end
  end
end
