require_relative "./bounty/parser"
require_relative "./bounty/task"

module Lich
  module Gemstone
    # Represents a bounty in the Lich Gemstone module.
    # This class handles tasks related to bounties.
    # @example Creating a bounty instance
    #   bounty = Lich::Gemstone::Bounty.new
    class Bounty
      # A list of known tasks for bounties.
      # This constant holds the keys from the task matchers defined in the Parser.
      KNOWN_TASKS = Parser::TASK_MATCHERS.keys

      # Retrieves the current bounty task.
      # @return [Task] The current bounty task instance.
      # @example Getting the current bounty task
      #   task = Lich::Gemstone::Bounty.current
      def self.current
        Task.new(Parser.parse(checkbounty))
      end

      # Alias for the current bounty task.
      # @return [Task] The current bounty task instance.
      # @example Getting the current bounty task via alias
      #   task = Lich::Gemstone::Bounty.task
      def self.task
        current
      end

      # Retrieves bounty information for a given person from LNet.
      # @param person [String] The name of the person to retrieve bounty information for.
      # @return [Task, nil] The bounty task instance or nil if not found.
      # @example Getting bounty information for a person
      #   task = Lich::Gemstone::Bounty.lnet("John Doe")
      def self.lnet(person)
        if (target_info = LNet.get_data(person.dup, 'bounty'))
          Task.new(Parser.parse(target_info))
        else
          if target_info == false
            text = "No one on LNet with a name like #{person}"
          else
            text = "Empty response from LNet for bounty from #{person}\n"
          end
          Lich::Messaging.msg("warn", text)
          nil
        end
      end

      # Delegate class methods to a new instance of the current bounty task
      [:status, :type, :requirements, :town, :any?, :none?, :done?].each do |attr|
        self.class.instance_eval do
          define_method(attr) do |*args, &blk|
            current&.send(attr, *args, &blk)
          end
        end
      end
    end
  end
end
