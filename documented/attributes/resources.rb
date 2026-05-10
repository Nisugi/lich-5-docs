# The Lich module
# This module serves as a namespace for the Lich project.
module Lich
  # The Resources module
  # This module provides methods to access various resource information.
  # @example Accessing resources
  #   resources = Lich::Resources.weekly
  module Resources
    # Retrieves the weekly resources.
    # @return [Object] The weekly resource data.
    # @example
    #   weekly_resources = Lich::Resources.weekly
    def self.weekly
      Lich::Gemstone::Infomon.get('resources.weekly')
    end

    # Retrieves the total resources.
    # @return [Object] The total resource data.
    # @example
    #   total_resources = Lich::Resources.total
    def self.total
      Lich::Gemstone::Infomon.get('resources.total')
    end

    # Retrieves the suffused resources.
    # @return [Object] The suffused resource data.
    # @example
    #   suffused_resources = Lich::Resources.suffused
    def self.suffused
      Lich::Gemstone::Infomon.get('resources.suffused')
    end

    # Retrieves the type of resources.
    # @return [Object] The resource type data.
    # @example
    #   resource_type = Lich::Resources.type
    def self.type
      Lich::Gemstone::Infomon.get('resources.type')
    end

    # Retrieves the Voln favor resources.
    # @return [Object] The Voln favor resource data.
    # @example
    #   voln_favor_resources = Lich::Resources.voln_favor
    def self.voln_favor
      Lich::Gemstone::Infomon.get('resources.voln_favor')
    end

    # Retrieves the covert arts charges resources.
    # @return [Object] The covert arts charges resource data.
    # @example
    #   covert_arts_charges = Lich::Resources.covert_arts_charges
    def self.covert_arts_charges
      Lich::Gemstone::Infomon.get('resources.covert_arts_charges')
    end

    # Retrieves the shadow essence resources.
    # @return [Object] The shadow essence resource data.
    # @example
    #   shadow_essence_resources = Lich::Resources.shadow_essence
    def self.shadow_essence
      Lich::Gemstone::Infomon.get('resources.shadow_essence')
    end

    # Checks the current resources and returns an array of weekly, total, and suffused resources.
    # @param quiet [Boolean] If true, suppresses output.
    # @return [Array<Object>] An array containing weekly, total, and suffused resource data.
    # @example
    #   resources = Lich::Resources.check(true)
    def self.check(quiet = false)
      Lich::Util.issue_command('resource', /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/, /<prompt/, silent: true, quiet: quiet)
      return [self.weekly, self.total, self.suffused]
    end
  end
end
