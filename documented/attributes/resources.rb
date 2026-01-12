module Lich
  # Provides methods to access various resource information.
  # @example Accessing resource information
  #   resources = Lich::Resources.weekly
  module Resources
    # Retrieves the weekly resource information.
    # @return [Object] The weekly resource data.
    # @example
    #   weekly_data = Lich::Resources.weekly
    def self.weekly
      Lich::Gemstone::Infomon.get('resources.weekly')
    end

    # Retrieves the total resource information.
    # @return [Object] The total resource data.
    # @example
    #   total_data = Lich::Resources.total
    def self.total
      Lich::Gemstone::Infomon.get('resources.total')
    end

    # Retrieves the suffused resource information.
    # @return [Object] The suffused resource data.
    # @example
    #   suffused_data = Lich::Resources.suffused
    def self.suffused
      Lich::Gemstone::Infomon.get('resources.suffused')
    end

    # Retrieves the type of resources.
    # @return [Object] The resource type data.
    # @example
    #   type_data = Lich::Resources.type
    def self.type
      Lich::Gemstone::Infomon.get('resources.type')
    end

    # Retrieves the Voln favor resource information.
    # @return [Object] The Voln favor resource data.
    # @example
    #   voln_favor_data = Lich::Resources.voln_favor
    def self.voln_favor
      Lich::Gemstone::Infomon.get('resources.voln_favor')
    end

    # Retrieves the covert arts charges resource information.
    # @return [Object] The covert arts charges data.
    # @example
    #   covert_arts_data = Lich::Resources.covert_arts_charges
    def self.covert_arts_charges
      Lich::Gemstone::Infomon.get('resources.covert_arts_charges')
    end

    # Retrieves the shadow essence resource information.
    # @return [Object] The shadow essence data.
    # @example
    #   shadow_essence_data = Lich::Resources.shadow_essence
    def self.shadow_essence
      Lich::Gemstone::Infomon.get('resources.shadow_essence')
    end

    # Checks the current resource status.
    # @param quiet [Boolean] If true, suppresses output.
    # @return [Array<Object>] An array containing weekly, total, and suffused resource data.
    # @example
    #   resources_status = Lich::Resources.check(true)
    def self.check(quiet = false)
      Lich::Util.issue_command('resource', /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/, /<prompt/, silent: true, quiet: quiet)
      return [self.weekly, self.total, self.suffused]
    end
  end
end
