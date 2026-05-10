require "ostruct"

module Lich
  module Gemstone
    module Spells
      # Returns the name of the spell circle corresponding to the given number.
      #
      # @param num [Integer] the circle number
      # @return [String] the name of the spell circle
      def self.get_circle_name(num)
        case num.to_s
        when '1' then 'Minor Spirit'
        when '2' then 'Major Spirit'
        when '3' then 'Cleric'
        when '4' then 'Minor Elemental'
        when '5' then 'Major Elemental'
        when '6' then 'Ranger'
        when '7' then 'Sorcerer'
        when '8' then 'Old Healing List'
        when '9' then 'Wizard'
        when '10' then 'Bard'
        when '11' then 'Empath'
        when '12' then 'Minor Mental'
        when '16' then 'Paladin'
        when '17' then 'Arcane'
        when '65' then 'Imbedded Enchantment'
        when '66' then 'Death'
        when '90' then 'Micellaneous'
        when '95' then 'Armor Specialization'
        when '96' then 'Combat Maneuvers'
        when '97' then 'Guardians of Sunfist'
        when '98' then 'Order of Voln'
        when '99' then 'Council of Light'
        else 'Unknown Circle'
        end
      end

      # Returns a list of active spells.
      # @return [Array<Spell>] an array of active spells
      # @api private
      def self.active
        Spell.active
      end

      # Returns a list of known spells.
      # @return [Array<Spell>] an array of known spells
      def self.known
        known_spells = Array.new
        Spell.list.each { |spell| known_spells.push(spell) if spell.known? }
        return known_spells
      end

      # Checks if a cooldown is required for the given spell and applies it if necessary.
      #
      # @param spell [Spell] the spell to check
      # @return [Symbol] :ok if no cooldown is required
      def self.require_cooldown(spell)
        if (spell.num.to_i > 9013) && (spell.num.to_i < 9042) # Assume Aspect: Ranger
          cooldown_spell = Spell[spell.num + 1]
          cooldown_spell.putup
        elsif (spell.num == 515) && (recovery = Spell[599]) # Rapid Fire: Major Elemental
          recovery.putup
        else
          :ok
        end
      end

      # Serializes the spell lists into an array.
      # @return [Array<Integer>] an array of spell ranks
      def self.serialize
        [self.minor_elemental, self.major_elemental, self.minor_spiritual, self.major_spiritual, self.wizard, self.sorcerer, self.ranger, self.paladin, self.empath, self.cleric, self.bard, self.minormental]
      end

      # A list of spell types available in the game.
      #
      # @example
      #   @@spell_lists # => [:major_elemental, :major_spiritual, :minor_elemental, :minor_mental, :minor_spiritual, :bard, :cleric, :empath, :paladin, :ranger, :sorcerer, :wizard]
      @@spell_lists = %i(major_elemental major_spiritual minor_elemental minor_mental minor_spiritual bard cleric empath paladin ranger sorcerer wizard)
      # returns rank as integer
      @@spell_lists.each do |spell_list|
        self.define_singleton_method(spell_list) do
          Infomon.get("spell.%s" % spell_list).to_i
        end
      end

      # these are here for backwards compat
      %i(majorelemental majorspiritual minorelemental minormental minorspiritual).each do |shorthand|
        long_hand = @@spell_lists.find { |method| method.to_s.gsub(/_/, '').eql?(shorthand.to_s) }
        self.define_singleton_method(shorthand) do
          Spells.send(long_hand)
        end
      end
    end
  end
end
