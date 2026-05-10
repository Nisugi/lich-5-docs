module Lich
  module Gemstone
    module SK
      @sk_known = nil

      # Retrieves the known SK spells.
      #
      # This method checks if the known spells are already loaded,
      # and if not, it attempts to load them from the database.
      # @return [Array<String>, nil] the list of known SK spells or nil if not set.
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

      # Sets the known SK spells.
      #
      # This method saves the provided list of spells to the database
      # and updates the internal state.
      # @param val [Array<String>] the list of spells to be known
      # @return [void]
      def self.sk_known=(val)
        unless @sk_known == val
          DB_Store.save("#{XMLData.game}:#{XMLData.name}", "sk_known", val)
          @sk_known = val
        end
      end

      # Checks if a specific spell is known.
      #
      # This method returns true if the spell is included in the known spells.
      # @param spell [Object] the spell object to check
      # @return [Boolean] true if the spell is known, false otherwise.
      def self.known?(spell)
        self.sk_known if @sk_known.nil?
        @sk_known.include?(spell.num.to_s)
      end

      # Lists the current known SK spells.
      #
      # This method outputs the current list of known spells to the user.
      # @return [void]
      def self.list
        respond "Current SK Spells: #{@sk_known.inspect}"
        respond ""
      end

      # Provides help information for managing SK spells.
      #
      # This method outputs the commands available for managing SK spells.
      # @return [void]
      def self.help
        respond "   Script to add SK spells to be known and used with Spell API calls."
        respond ""
        respond "   ;sk add <SPELL_NUMBER>  - Add spell number to saved list"
        respond "   ;sk rm <SPELL_NUMBER>   - Remove spell number from saved list"
        respond "   ;sk list                - Show all currently saved SK spell numbers"
        respond "   ;sk help                - Show this menu"
        respond ""
      end

      # Adds new spells to the known SK spells list.
      #
      # This method takes one or more spell numbers and adds them to the known spells.
      # @param numbers [Array<String>] the spell numbers to add
      # @return [void]
      def self.add(*numbers)
        self.sk_known = (@sk_known + numbers).uniq
        self.list
      end

      # Removes spells from the known SK spells list.
      #
      # This method takes one or more spell numbers and removes them from the known spells.
      # @param numbers [Array<String>] the spell numbers to remove
      # @return [void]
      def self.remove(*numbers)
        self.sk_known = (@sk_known - numbers).uniq
        self.list
      end

      # Main entry point for managing SK spells.
      #
      # This method processes the action requested and performs the corresponding operation.
      # @param action [Symbol] the action to perform (e.g., :add, :rm, :list)
      # @param spells [String, nil] the spell numbers to add or remove, as a space-separated string
      # @return [void]
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
