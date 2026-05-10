require_relative '../util/util.rb' # needed to ensure it loads before Society tries to load

module Lich
  module Gemstone
    ##
    # Represents a society in the Lich game.
    #
    # This class provides methods to access society-related information such as membership,
    # status, rank, and tasks.
    #
    # @see Lich::Gemstone::Societies
    class Society
      ##
      # Retrieves the current membership status of the society.
      # @return [String] the membership status
      def self.membership
        Infomon.get("society.status")
      end

      ##
      # Retrieves the current status of the society.
      # @return [String] the society status
      def self.status
        self.membership
      end

      ##
      # Retrieves the current rank of the society.
      # @return [String] the society rank
      def self.rank
        Infomon.get("society.rank")
      end

      ##
      # Retrieves the current task assigned to the society.
      # @return [String] the society task
      def self.task
        XMLData.society_task
      end

      ##
      # Serializes the current membership and rank of the society into an array.
      # @return [Array<String>] an array containing the membership status and rank
      def self.serialize
        [self.membership, self.rank]
      end

      ########################
      ## DEPRECATED METHODS ##
      ########################

      ##
      # Retrieves the current membership status of the society (deprecated).
      # This method is deprecated in favor of {.membership}.
      # @return [String] the membership status
      # @deprecated Use {.membership} instead
      def self.member
        Lich.deprecated("Society.member", "Society.membership", caller[0], fe_log: false)
        self.membership
      end

      ##
      # Retrieves the current rank of the society (deprecated).
      # This method is deprecated in favor of {.rank}.
      # @return [String] the society rank
      # @deprecated Use {.rank} instead
      def self.step
        Lich.deprecated("Society.step", "Society.rank", caller[0], fe_log: false)
        self.rank
      end

      ##
      # Retrieves the favor of the Order of Voln (deprecated).
      # This method is deprecated in favor of {.OrderOfVoln.favor}.
      # @return [String] the favor of the Order of Voln
      # @deprecated Use {.OrderOfVoln.favor} instead
      def self.favor
        Lich.deprecated("Society.favor", "Society::OrderOfVoln.favor", caller[0], fe_log: false)
        # Infomon.get('resources.voln_favor')
        Societies::OrderOfVoln.favor
      end

      ##
      # Looks up a name in the provided list of lookups.
      # @param name [String] the name to look up
      # @param lookups [Array<Hash>] the list of lookups to search through
      # @return [Hash, nil] the found entry or nil if not found
      def self.lookup(name, lookups)
        normalized = Lich::Util.normalize_name(name)

        lookups.find do |entry|
          [entry[:short_name], entry[:long_name]]
            .compact
            .map { |n| Lich::Util.normalize_name(n) }
            .include?(normalized)
        end
      end

      ##
      # Resolves a value, calling it if it is a callable object.
      # @param value [Object] the value to resolve
      # @param context [Object, nil] optional context for the callable
      # @return [Object] the resolved value
      def self.resolve(value, context = nil)
        return value.call if value.respond_to?(:call) && value.arity == 0
        return value.call(context) if value.respond_to?(:call) && value.arity == 1
        value
      end

      ##
      # Defines name methods on the target class based on provided data.
      # @param target_class [Class] the class to define methods on
      # @param data [Hash] the data containing names to define methods for
      # @return [void]
      def self.define_name_methods(target_class, data)
        data.values.each do |entry|
          short_method = Lich::Util.normalize_name(entry[:short_name])
          long_method  = Lich::Util.normalize_name(entry[:long_name])

          target_class.define_singleton_method(short_method) { target_class[entry[:short_name]] }
          target_class.define_singleton_method(long_method)  { target_class[entry[:short_name]] }
        end
      end
    end
  end
end

# these are at the bottom because Society has to be loaded first before the sub-classes can be loaded
require_relative 'societies/council_of_light.rb'
require_relative 'societies/guardians_of_sunfist.rb'
require_relative 'societies/order_of_voln.rb'

module Lich::Gemstone::Societies
  def self.voln
    OrderOfVoln
  end

  def self.col
    CouncilOfLight
  end

  def self.sunfist
    GuardiansOfSunfist
  end
end
