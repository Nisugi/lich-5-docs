module Lich
  module Gemstone
    # Represents a bounty in the Lich game.
    #
    # This class encapsulates the tasks associated with a bounty.
    #
    # @see Lich::Gemstone::Task
    class Bounty
      class Task
        # Initializes a new task with the given options.
        # @param options [Hash] options for the task
        # @option options [String] :description (nil) the description of the task
        # @option options [String] :type (nil) the type of the task
        # @option options [Hash] :requirements (nil) the requirements for the task
        # @option options [String] :town (nil) the town associated with the task
        # @return [Task]
        def initialize(options = {})
          @description    = options[:description]
          @type           = options[:type]
          @requirements   = options[:requirements] || {}
          @town           = options[:town] || @requirements[:town]
        end
        attr_accessor :type, :requirements, :description, :town

        # Returns the type of the task.
        # @return [String] the type of the task
        def task; type; end
        # Returns the type of the task (alias for #task).
        # @return [String] the type of the task
        def kind; type; end
        def count; number; end

        # Returns the creature requirement for the task.
        # @return [String, nil] the creature required for the task
        def creature
          requirements[:creature]
        end

        # Returns the creature requirement for the task (alias for #creature).
        # @return [String, nil] the creature required for the task
        def critter
          requirements[:creature]
        end

        # Checks if the task has a creature requirement.
        # @return [Boolean] true if a creature is required, false otherwise
        def critter?
          !!requirements[:creature]
        end

        # Returns the location requirement for the task.
        # @return [String] the area required for the task or the town if not specified
        def location
          requirements[:area] || town
        end

        # Checks if the task type is a bandit task.
        # @return [Boolean] true if the task is a bandit task, false otherwise
        def bandit?
          type.to_s.start_with?("bandit")
        end

        # Checks if the task type is one of the creature-related types.
        # @return [Boolean] true if the task is creature-related, false otherwise
        def creature?
          [
            :creature_assignment, :cull, :dangerous, :dangerous_spawned, :rescue, :heirloom
          ].include?(type)
        end

        # Checks if the task type is a cull task.
        # @return [Boolean] true if the task is a cull task, false otherwise
        def cull?
          type.to_s.start_with?("cull")
        end

        # Checks if the task type is a dangerous task.
        # @return [Boolean] true if the task is dangerous, false otherwise
        def dangerous?
          type.to_s.start_with?("dangerous")
        end

        # Checks if the task type is an escort task.
        # @return [Boolean] true if the task is an escort task, false otherwise
        def escort?
          type.to_s.start_with?("escort")
        end

        # Checks if the task type is a gem task.
        # @return [Boolean] true if the task is a gem task, false otherwise
        def gem?
          type.to_s.start_with?("gem")
        end

        # Checks if the task type is an heirloom task.
        # @return [Boolean] true if the task is an heirloom task, false otherwise
        def heirloom?
          type.to_s.start_with?("heirloom")
        end

        # Checks if the task type is an herb task.
        # @return [Boolean] true if the task is an herb task, false otherwise
        def herb?
          type.to_s.start_with?("herb")
        end

        # Checks if the task type is a rescue task.
        # @return [Boolean] true if the task is a rescue task, false otherwise
        def rescue?
          type.to_s.start_with?("rescue")
        end

        # Checks if the task type is a skin task.
        # @return [Boolean] true if the task is a skin task, false otherwise
        def skin?
          type.to_s.start_with?("skin")
        end

        # Checks if the task is to search for an heirloom.
        # @return [Boolean] true if the task is a search for an heirloom, false otherwise
        def search_heirloom?
          [:heirloom].include?(type) &&
            requirements[:action] == "search"
        end

        # Checks if the task is to loot an heirloom.
        # @return [Boolean] true if the task is a loot for an heirloom, false otherwise
        def loot_heirloom?
          [:heirloom].include?(type) &&
            requirements[:action] == "loot"
        end

        # Checks if the task type indicates that an heirloom has been found.
        # @return [Boolean] true if the task indicates an heirloom found, false otherwise
        def heirloom_found?
          [
            :heirloom_found
          ].include?(type)
        end

        # Checks if the task is marked as done.
        # @return [Boolean] true if the task is done, false otherwise
        def done?
          [
            :failed, :guard, :taskmaster, :heirloom_found
          ].include?(type)
        end

        # Checks if the task has spawned.
        # @return [Boolean] true if the task has spawned, false otherwise
        def spawned?
          [
            :dangerous_spawned, :escort, :rescue_spawned
          ].include?(type)
        end

        # Checks if the task has been triggered (spawned).
        # @return [Boolean] true if the task has been triggered, false otherwise
        def triggered?; spawned?; end

        # Checks if there are any tasks.
        # @return [Boolean] true if there are tasks, false otherwise
        def any?
          !none?
        end

        # Checks if there are no tasks.
        # @return [Boolean] true if there are no tasks, false otherwise
        def none?
          [:none, nil].include?(type)
        end

        # Checks if the task type is a guard task.
        # @return [Boolean] true if the task is a guard task, false otherwise
        def guard?
          [
            :guard,
            :bandit_assignment, :creature_assignment, :heirloom_assignment, :heirloom_found, :rescue_assignment
          ].include?(type)
        end

        # Checks if the task is assigned.
        # @return [Boolean] true if the task is assigned, false otherwise
        def assigned?
          type.to_s.end_with?("assignment")
        end

        # Checks if the task is ready to be executed.
        # @return [Boolean] true if the task is ready, false otherwise
        def ready?
          [
            :bandit_assignment, :escort_assignment,
            :bandit, :cull, :dangerous, :escort, :gem, :heirloom, :herb, :rescue, :skin
          ].include?(type)
        end

        # Checks if the task description indicates a help task.
        # @return [Boolean] true if the task is a help task, false otherwise
        def help?
          description.start_with?("You have been tasked to help")
        end

        # Checks if the task is an assist task (alias for #help?).
        # @return [Boolean] true if the task is an assist task, false otherwise
        def assist?
          help?
        end

        # Checks if the task is a group task (alias for #help?).
        # @return [Boolean] true if the task is a group task, false otherwise
        def group?
          help?
        end

        # Handles calls to methods that are not defined.
        # @param symbol [Symbol] the method name being called
        # @param args [Array] arguments for the method
        # @param block [Proc] optional block for the method
        # @return [Object] the value of the requirement if it exists, otherwise calls super
        def method_missing(symbol, *args, &blk)
          if requirements&.keys&.include?(symbol)
            requirements[symbol]
          else
            super
          end
        end

        # Checks if the object responds to a missing method.
        # @param symbol [Symbol] the method name being checked
        # @param include_private [Boolean] whether to include private methods
        # @return [Boolean] true if the method is recognized, false otherwise
        def respond_to_missing?(symbol, include_private = false)
          requirements&.keys&.include?(symbol) || super
        end
      end
    end
  end
end
