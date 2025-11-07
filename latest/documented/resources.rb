module Lich
  # Provides methods to access various resource information.
  # This module includes methods to retrieve weekly, total, and other resource-related data.
  # @example Accessing resource information
  #   resources = Lich::Resources.weekly
  module Resources
    # Retrieves the weekly resource information.
    # @return [Object] The weekly resource data.
    def self.weekly
      Lich::Gemstone::Infomon.get('resources.weekly')
    end

    # Retrieves the total resource information.
    # @return [Object] The total resource data.
    def self.total
      Lich::Gemstone::Infomon.get('resources.total')
    end

    # Retrieves the suffused resource information.
    # @return [Object] The suffused resource data.
    def self.suffused
      Lich::Gemstone::Infomon.get('resources.suffused')
    end

    # Retrieves the type of resources available.
    # @return [Object] The resource type data.
    def self.type
      Lich::Gemstone::Infomon.get('resources.type')
    end

    # Retrieves the Voln favor resource information.
    # @return [Object] The Voln favor resource data.
    def self.voln_favor
      Lich::Gemstone::Infomon.get('resources.voln_favor')
    end

    # Retrieves the covert arts charges resource information.
    # @return [Object] The covert arts charges data.
    def self.covert_arts_charges
      Lich::Gemstone::Infomon.get('resources.covert_arts_charges')
    end

    # Checks the current resource status and returns relevant data.
    # @param quiet [Boolean] If true, suppresses output (default: false).
    # @return [Array<Object>] An array containing weekly, total, and suffused resource data.
    # @note This method issues a command to check resources and may depend on external state.
    def self.check(quiet = false)
      Lich::Util.issue_command('resource', /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/, /<prompt/, silent: true, quiet: quiet)
      return [self.weekly, self.total, self.suffused]
    end
  end
end
