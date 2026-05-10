module Lich
  module Common
    module Account
      @@name ||= nil
      @@subscription ||= nil
      @@game_code ||= nil
      @@members ||= {}
      @@character ||= nil

      # Returns the name associated with the account.
      #
      # @return [String, nil] the account name or nil if not set
      def self.name
        @@name
      end

      # Sets the name for the account.
      # @param value [String] the new account name
      # @return [void]
      def self.name=(value)
        @@name = value
      end

      # Returns the character associated with the account.
      #
      # @return [String, nil] the character name or nil if not set
      def self.character
        @@character
      end

      # Sets the character for the account.
      # @param value [String] the new character name
      # @return [void]
      def self.character=(value)
        @@character = value
      end

      # Returns the subscription type of the account.
      #
      # @return [String, nil] the subscription type or nil if not set
      def self.subscription
        @@subscription
      end

      # Returns the type of account based on the game code.
      #
      # @return [String, nil] the account type or nil if not applicable
      def self.type
        if XMLData.game.is_a?(String) && XMLData.game =~ /^GS/
          Infomon.get("account.type")
        end
      end

      # Sets the subscription type for the account.
      # @param value [String] the new subscription type (NORMAL, PREMIUM, TRIAL, INTERNAL, FREE)
      # @return [void]
      def self.subscription=(value)
        if value =~ /(NORMAL|PREMIUM|TRIAL|INTERNAL|FREE)/
          @@subscription = Regexp.last_match(1)
        end
      end

      # Returns the game code associated with the account.
      #
      # @return [String, nil] the game code or nil if not set
      def self.game_code
        @@game_code
      end

      # Sets the game code for the account.
      # @param value [String] the new game code
      # @return [void]
      def self.game_code=(value)
        @@game_code = value
      end

      # Returns the members associated with the account.
      #
      # @return [Hash] a hash of member codes and names
      def self.members
        @@members
      end

      # Sets the members for the account based on a formatted string.
      # @param value [String] the formatted string containing member codes and names
      # @return [void]
      def self.members=(value)
        potential_members = {}
        for code_name in value.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
          char_code, char_name = code_name.split("\t")
          potential_members[char_code] = char_name
        end
        @@members = potential_members
      end

      # Returns the character names of all members associated with the account.
      #
      # @return [Array<String>] an array of character names
      def self.characters
        @@members.values
      end
    end
  end
end
