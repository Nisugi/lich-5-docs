# The Lich module serves as a namespace for the DragonRealms project.
module Lich
  # The DragonRealms module contains functionality specific to the DragonRealms game.
  module DragonRealms
    # The DRInfomon module provides information and utilities for the DRInfomon system.
    # @example Including the DRInfomon module
    #   include Lich::DragonRealms::DRInfomon
    module DRInfomon
      # The version of the DRInfomon system.
      # @return [String] The current version of DRInfomon.
      $DRINFOMON_VERSION = '3.0'

      # An array of core Lich defines used in DRInfomon.
      # @return [Array<String>] The list of core Lich defines.
      DRINFOMON_CORE_LICH_DEFINES = %W(drinfomon common common-arcana common-crafting common-healing common-healing-data common-items common-money common-moonmage common-summoning common-theurgy common-travel common-validation events slackbot equipmanager spellmonitor)

      # A boolean indicating if DRInfomon is included in the core Lich.
      # @return [Boolean] True if DRInfomon is in core Lich, false otherwise.
      DRINFOMON_IN_CORE_LICH = true
      require_relative 'drinfomon/drdefs'
      require_relative 'drinfomon/drvariables'
      require_relative 'drinfomon/drparser'
      require_relative 'drinfomon/drskill'
      require_relative 'drinfomon/drstats'
      require_relative 'drinfomon/drroom'
      require_relative 'drinfomon/drspells'
      require_relative 'drinfomon/events'
    end
  end
end
