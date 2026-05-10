require_relative "./bounty/parser"
require_relative "./bounty/task"

module Lich
  module Gemstone
    # Represents a bounty in the Lich game.
    #
    # This class handles the current bounty task and provides methods to interact with it.
    #
    # @see Lich::Gemstone::Parser
    # @see Lich::Gemstone::Task
    class Bounty
      KNOWN_TASKS = Parser::TASK_MATCHERS.keys

      # Retrieves the current bounty task.
      # @return [Task] the current bounty task instance
      def self.current
        Task.new(Parser.parse(checkbounty))
      end

      def self.task
        current
      end

      # Retrieves bounty information for a specified person from LNet.
      #
      # If the person is found, a new Task is created with the bounty data.
      # @param person [String] the name of the person to retrieve bounty information for
      # @return [Task, nil] the bounty task instance if found, otherwise nil
      # @note Returns nil if no bounty information is available.
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
