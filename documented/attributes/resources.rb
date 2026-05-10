module Lich
  module Resources
    # Retrieves the weekly resources.
    #
    # @return [String] the weekly resources data.
    def self.weekly
      Lich::Gemstone::Infomon.get('resources.weekly')
    end

    # Retrieves the total resources.
    #
    # @return [String] the total resources data.
    def self.total
      Lich::Gemstone::Infomon.get('resources.total')
    end

    # Retrieves the suffused resources.
    #
    # @return [String] the suffused resources data.
    def self.suffused
      Lich::Gemstone::Infomon.get('resources.suffused')
    end

    # Retrieves the type of resources.
    #
    # @return [String] the type of resources data.
    def self.type
      Lich::Gemstone::Infomon.get('resources.type')
    end

    # Retrieves the Voln favor resources.
    #
    # @return [String] the Voln favor resources data.
    def self.voln_favor
      Lich::Gemstone::Infomon.get('resources.voln_favor')
    end

    # Retrieves the covert arts charges resources.
    #
    # @return [String] the covert arts charges data.
    def self.covert_arts_charges
      Lich::Gemstone::Infomon.get('resources.covert_arts_charges')
    end

    # Retrieves the shadow essence resources.
    #
    # @return [String] the shadow essence resources data.
    def self.shadow_essence
      Lich::Gemstone::Infomon.get('resources.shadow_essence')
    end

    # Checks the current resources and returns the weekly, total, and suffused resources.
    #
    # @param quiet [Boolean] whether to suppress output.
    # @return [Array<String>] an array containing the weekly, total, and suffused resources.
    def self.check(quiet = false)
      Lich::Util.issue_command('resource', /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/, /<prompt/, silent: true, quiet: quiet)
      return [self.weekly, self.total, self.suffused]
    end
  end
end
