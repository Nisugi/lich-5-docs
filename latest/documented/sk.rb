# The Lich module
# This module serves as a namespace for the Lich project.
module Lich
  # The Gemstone module
  # This module contains functionality related to the Gemstone aspect of the Lich project.
  module Gemstone
    # The SK module
    # This module manages the spells known by the SK character class.
    # @example Usage
    #   Lich::Gemstone::SK.add(123)
    #   Lich::Gemstone::SK.list
    module SK
      @sk_known = nil

      # Retrieves the list of known SK spells.
      # @return [Array<String>] The list of known SK spell numbers.
      def self.sk_known
        if @sk_known.nil?
          val = DB_Store.read("#{XMLData.game}:#{XMLData.name}", "sk_known")
          if val.nil? || (val.is_a?(Hash) && val.empty?)
            old_settings = DB_Store.read("#{XMLData.game}:#{XMLData.name}", "vars")["sk/known"]
            if old_settings.is_a?(Array)
              val = old_settings
            else
              val = []
            end
            self.sk_known = val
          end
          @sk_known = val unless val.nil?
        end
        return @sk_known
      end

      # Sets the list of known SK spells.
      # @param val [Array<String>] The new list of known SK spell numbers.
      # @return [Array<String>] The updated list of known SK spell numbers.
      def self.sk_known=(val)
        return @sk_known if @sk_known == val
        DB_Store.save("#{XMLData.game}:#{XMLData.name}", "sk_known", val)
        @sk_known = val
      end

      # Checks if a specific spell is known.
      # @param spell [Object] The spell object to check.
      # @return [Boolean] True if the spell is known, false otherwise.
      # @example Checking if a spell is known
      #   Lich::Gemstone::SK.known?(some_spell)
      def self.known?(spell)
        self.sk_known if @sk_known.nil?
        @sk_known.include?(spell.num.to_s)
      end

      # Lists the current known SK spells.
      # @return [void] This method does not return a value.
      # @example Listing known spells
      #   Lich::Gemstone::SK.list
      def self.list
        respond "Current SK Spells: #{@sk_known.inspect}"
        respond ""
      end

      # Provides help information for SK commands.
      # @return [void] This method does not return a value.
      # @example Displaying help
      #   Lich::Gemstone::SK.help
      def self.help
        respond "   Script to add SK spells to be known and used with Spell API calls."
        respond ""
        respond "   ;sk add <SPELL_NUMBER>  - Add spell number to saved list"
        respond "   ;sk rm <SPELL_NUMBER>   - Remove spell number from saved list"
        respond "   ;sk list                - Show all currently saved SK spell numbers"
        respond "   ;sk help                - Show this menu"
        respond ""
      end

      # Adds one or more spell numbers to the known list.
      # @param numbers [Array<Integer>] The spell numbers to add.
      # @return [void] This method does not return a value.
      def self.add(*numbers)
        self.sk_known = (@sk_known + numbers).uniq
        self.list
      end

      # Removes one or more spell numbers from the known list.
      # @param numbers [Array<Integer>] The spell numbers to remove.
      # @return [void] This method does not return a value.
      def self.remove(*numbers)
        self.sk_known = (@sk_known - numbers).uniq
        self.list
      end

      # Main entry point for SK commands.
      # @param action [Symbol] The action to perform (add, rm, list, help).
      # @param spells [String, nil] The spell numbers to add or remove, as a space-separated string.
      # @return [void] This method does not return a value.
      def self.main(action = help, spells = nil)
        self.sk_known if @sk_known.nil?
        action = action.to_sym
        spells = spells.split(" ").uniq
        case action
        when :add
          self.add(*spells) unless spells.empty?
          self.help if spells.empty?
        when :rm
          self.remove(*spells) unless spells.empty?
          self.help if spells.empty?
        when :list
          self.list
        else
          self.help
        end
      end
    end
  end
end
