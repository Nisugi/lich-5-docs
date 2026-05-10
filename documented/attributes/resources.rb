module Lich
  module Resources
    # Retrieves the weekly resources.
    #
    # @return [String] the weekly resources data.
    # @see .total
    # @see .suffused
    # @see .type
    # @see .voln_favor
    # @see .covert_arts_charges
    # @see .shadow_essence
    def self.weekly
      Lich::Gemstone::Infomon.get('resources.weekly')
    end

    # Retrieves the total resources.
    #
    # @return [String] the total resources data.
    # @see .weekly
    # @see .suffused
    # @see .type
    # @see .voln_favor
    # @see .covert_arts_charges
    # @see .shadow_essence
    def self.total
      Lich::Gemstone::Infomon.get('resources.total')
    end

    # Retrieves the suffused resources.
    #
    # @return [String] the suffused resources data.
    # @see .weekly
    # @see .total
    # @see .type
    # @see .voln_favor
    # @see .covert_arts_charges
    # @see .shadow_essence
    def self.suffused
      Lich::Gemstone::Infomon.get('resources.suffused')
    end

    # Retrieves the type of resources.
    #
    # @return [String] the type of resources data.
    # @see .weekly
    # @see .total
    # @see .suffused
    # @see .voln_favor
    # @see .covert_arts_charges
    # @see .shadow_essence
    def self.type
      Lich::Gemstone::Infomon.get('resources.type')
    end

    # Retrieves the Voln favor resources.
    #
    # @return [String] the Voln favor resources data.
    # @see .weekly
    # @see .total
    # @see .suffused
    # @see .type
    # @see .covert_arts_charges
    # @see .shadow_essence
    def self.voln_favor
      Lich::Gemstone::Infomon.get('resources.voln_favor')
    end

    # Retrieves the covert arts charges resources.
    #
    # @return [String] the covert arts charges data.
    # @see .weekly
    # @see .total
    # @see .suffused
    # @see .type
    # @see .voln_favor
    # @see .shadow_essence
    def self.covert_arts_charges
      Lich::Gemstone::Infomon.get('resources.covert_arts_charges')
    end

    # Retrieves the shadow essence resources.
    #
    # @return [String] the shadow essence data.
    # @see .weekly
    # @see .total
    # @see .suffused
    # @see .type
    # @see .voln_favor
    # @see .covert_arts_charges
    def self.shadow_essence
      Lich::Gemstone::Infomon.get('resources.shadow_essence')
    end

    # Checks the current resources and returns an array of resource data.
    #
    # @param quiet [Boolean] whether to suppress output.
    # @return [Array<String>] an array containing weekly, total, and suffused resources.
    # @example
    #   resources = Lich::Resources.check
    #   puts resources.inspect
    # @note This method issues a command to retrieve resource data.
    def self.check(quiet = false)
      Lich::Util.issue_command('resource', /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/, /<prompt/, silent: true, quiet: quiet)
      return [self.weekly, self.total, self.suffused]
    end
  end
end
