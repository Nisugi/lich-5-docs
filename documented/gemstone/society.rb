require_relative '../util/util.rb' # needed to ensure it loads before Society tries to load

module Lich
  module Gemstone
    ##
    # Represents a society in the Lich game.
    # This class provides methods to access society membership, status, rank, and tasks.
    # @example Accessing society information
    #   status = Lich::Gemstone::Society.status
    class Society
      ##
      # Retrieves the current membership status of the society.
      # @return [String] The membership status.
      def self.membership
        Infomon.get("society.status")
      end

      ##
      # Retrieves the current status of the society.
      # @return [String] The current society status.
      # @example Getting society status
      #   status = Lich::Gemstone::Society.status
      def self.status
        self.membership
      end

      ##
      # Retrieves the current rank of the society.
      # @return [String] The current society rank.
      def self.rank
        Infomon.get("society.rank")
      end

      ##
      # Retrieves the current task of the society.
      # @return [String] The current society task.
      def self.task
        XMLData.society_task
      end

      ##
      # Serializes the society's membership and rank into an array.
      # @return [Array] An array containing the membership status and rank.
      def self.serialize
        [self.membership, self.rank]
      end

      ########################
      ## DEPRECATED METHODS ##
      ########################

      ##
      # Retrieves the membership status of the society (deprecated).
      # @deprecated Use Society.membership instead.
      # @return [String] The membership status.
      def self.member
        Lich.deprecated("Society.member", "Society.membership", caller[0], fe_log: false)
        self.membership
      end

      ##
      # Retrieves the rank of the society (deprecated).
      # @deprecated Use Society.rank instead.
      # @return [String] The society rank.
      def self.step
        Lich.deprecated("Society.step", "Society.rank", caller[0], fe_log: false)
        self.rank
      end

      ##
      # Retrieves the favor of the Order of Voln (deprecated).
      # @deprecated Use Society::OrderOfVoln.favor instead.
      # @return [String] The favor of the Order of Voln.
      def self.favor
        Lich.deprecated("Society.favor", "Society::OrderOfVoln.favor", caller[0], fe_log: false)
        # Infomon.get('resources.voln_favor')
        Societies::OrderOfVoln.favor
      end

      ##
      # Looks up a name in the provided lookups.
      # @param name [String] The name to look up.
      # @param lookups [Array<Hash>] The array of lookup entries.
      # @return [Hash, nil] The found entry or nil if not found.
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
      # Resolves a value, calling it if it's a Proc.
      # @param value [Object] The value to resolve.
      # @param context [Object, nil] The context to pass to the Proc if applicable.
      # @return [Object] The resolved value.
      def self.resolve(value, context = nil)
        return value.call if value.respond_to?(:call) && value.arity == 0
        return value.call(context) if value.respond_to?(:call) && value.arity == 1
        value
      end

      ##
      # Defines name methods on the target class based on provided data.
      # @param target_class [Class] The class to define methods on.
      # @param data [Hash] The data containing names for method definitions.
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
  # Retrieves the Order of Voln society.
  # @return [Class] The OrderOfVoln class.
  def self.voln
    OrderOfVoln
  end

  # Retrieves the Council of Light society.
  # @return [Class] The CouncilOfLight class.
  def self.col
    CouncilOfLight
  end

  # Retrieves the Guardians of Sunfist society.
  # @return [Class] The GuardiansOfSunfist class.
  def self.sunfist
    GuardiansOfSunfist
  end
end
