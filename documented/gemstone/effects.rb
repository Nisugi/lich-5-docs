module Lich
  module Gemstone
    module Effects
      # Manages a collection of effects for the Lich project.
      #
      # This class includes methods to handle the registration,
      # expiration, and active status of various effects.
      #
      # @see Lich::Gemstone::Effects::Spells
      # @see Lich::Gemstone::Effects::Buffs
      # @see Lich::Gemstone::Effects::Debuffs
      # @see Lich::Gemstone::Effects::Cooldowns
      class Registry
        include Enumerable

        # Initializes a new Registry instance.
        # @param dialog [String] the name of the dialog associated with this registry
        # @return [void]
        def initialize(dialog)
          @dialog = dialog
        end

        # Converts the registry to a hash representation.
        # @return [Hash] a hash of effects associated with the dialog
        def to_h
          XMLData.dialogs.fetch(@dialog, {})
        end

        # Iterates over each effect in the registry.
        # @yield [key, value] each key-value pair in the registry
        # @return [void]
        def each()
          to_h.each { |k, v| yield(k, v) }
        end

        # Retrieves the expiration time for a given effect.
        # @param effect [String, Regexp] the effect to check
        # @return [Integer] the expiration time in seconds, or 0 if not found
        def expiration(effect)
          if effect.is_a?(Regexp)
            to_h.find { |k, _v| k.to_s =~ effect }[1] || 0
          else
            to_h.fetch(effect, 0)
          end
        end

        # Checks if a given effect is currently active.
        # @param effect [String, Regexp] the effect to check
        # @return [Boolean] true if the effect is active, false otherwise
        def active?(effect)
          expiration(effect).to_f > Time.now.to_f
        end

        # Calculates the time left for a given effect.
        # @param effect [String, Regexp] the effect to check
        # @return [Integer] the time left in minutes, or the expiration time if not active
        def time_left(effect)
          if expiration(effect) != 0
            ((expiration(effect) - Time.now) / 60.to_f)
          else
            expiration(effect)
          end
        end
      end

      # A registry for active spells.
      # @see Lich::Gemstone::Effects::Registry
      Spells    = Registry.new("Active Spells")
      # A registry for buffs.
      # @see Lich::Gemstone::Effects::Registry
      Buffs     = Registry.new("Buffs")
      # A registry for debuffs.
      # @see Lich::Gemstone::Effects::Registry
      Debuffs   = Registry.new("Debuffs")
      # A registry for cooldowns.
      # @see Lich::Gemstone::Effects::Registry
      Cooldowns = Registry.new("Cooldowns")

      # Displays the current effects in a formatted table.
      # @return [void]
      def self.display
        effect_out = Terminal::Table.new :headings => ["ID", "Type", "Name", "Duration"]
        titles = ["Spells", "Cooldowns", "Buffs", "Debuffs"]
        existing_spell_nums = []
        active_spells = Spell.active
        active_spells.each { |s| existing_spell_nums << s.num }
        circle = nil
        [Effects::Spells, Effects::Cooldowns, Effects::Buffs, Effects::Debuffs].each { |effect|
          title = titles.shift
          id_effects = effect.to_h.select { |k, _v| k.is_a?(Integer) }
          text_effects = effect.to_h.reject { |k, _v| k.is_a?(Integer) }
          if id_effects.length != text_effects.length
            # has spell names disabled
            text_effects = id_effects
          end
          if id_effects.length == 0
            effect_out.add_row ["", title, "No #{title.downcase} found!", ""]
          else
            id_effects.each { |sn, end_time|
              stext = text_effects.shift[0]
              duration = ((end_time - Time.now) / 60.to_f)
              if duration < 0
                next
              elsif duration > 86400
                duration = "Indefinite"
              else
                duration = duration.as_time
              end
              if Spell[sn].circlename && circle != Spell[sn].circlename && title == 'Spells'
                circle = Spell[sn].circlename
              end
              effect_out.add_row [sn, title, stext, duration]
              existing_spell_nums.delete_if { |s| Spell[s].name =~ /#{Regexp.escape(stext)}/ || stext =~ /#{Regexp.escape(Spell[s].name)}/ || s == sn }
            }
          end
          effect_out.add_separator unless title == 'Debuffs' && existing_spell_nums.empty?
        }
        existing_spell_nums.each { |sn|
          effect_out.add_row [sn, "Other", Spell[sn].name, (Spell[sn].timeleft.as_time)]
        }
        Lich::Messaging.mono(effect_out.to_s)
      end
    end
  end
end
