module Lich
  module Gemstone
    # Represents a bounty in the Lich game.
    #
    # This class encapsulates the concept of a bounty, which includes various tasks and requirements.
    class Bounty
      class Task
        # Initializes a new Task instance.
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
        # Returns the type of the task.
        # @return [String] the type of the task
        def kind; type; end
        # Returns the number associated with the task.
        # @return [Integer] the number associated with the task
        def count; number; end

        # Returns the creature requirement for the task.
        # @return [String, nil] the creature required for the task, or nil if not specified
        def creature
          requirements[:creature]
        end

        # Returns the creature requirement for the task.
        # @return [String, nil] the creature required for the task, or nil if not specified
        def critter
          requirements[:creature]
        end

        # Checks if there is a creature requirement for the task.
        # @return [Boolean] true if a creature is required, false otherwise
        def critter?
          !!requirements[:creature]
        end

        # Returns the location requirement for the task.
        # @return [String] the area required for the task, or the town if not specified
        def location
          requirements[:area] || town
        end

        # Checks if the task type is a bandit type.
        # @return [Boolean] true if the task type starts with "bandit", false otherwise
        def bandit?
          type.to_s.start_with?("bandit")
        end

        # Checks if the task type is one of the creature types.
        # @return [Boolean] true if the task type is a creature type, false otherwise
        def creature?
          [
            :creature_assignment, :cull, :dangerous, :dangerous_spawned, :rescue, :heirloom
          ].include?(type)
        end

        # Checks if the task type is a cull type.
        # @return [Boolean] true if the task type starts with "cull", false otherwise
        def cull?
          type.to_s.start_with?("cull")
        end

        # Checks if the task type is a dangerous type.
        # @return [Boolean] true if the task type starts with "dangerous", false otherwise
        def dangerous?
          type.to_s.start_with?("dangerous")
        end

        # Checks if the task type is an escort type.
        # @return [Boolean] true if the task type starts with "escort", false otherwise
        def escort?
          type.to_s.start_with?("escort")
        end

        # Checks if the task type is a gem type.
        # @return [Boolean] true if the task type starts with "gem", false otherwise
        def gem?
          type.to_s.start_with?("gem")
        end

        # Checks if the task type is an heirloom type.
        # @return [Boolean] true if the task type starts with "heirloom", false otherwise
        def heirloom?
          type.to_s.start_with?("heirloom")
        end

        # Checks if the task type is an herb type.
        # @return [Boolean] true if the task type starts with "herb", false otherwise
        def herb?
          type.to_s.start_with?("herb")
        end

        # Checks if the task type is a rescue type.
        # @return [Boolean] true if the task type starts with "rescue", false otherwise
        def rescue?
          type.to_s.start_with?("rescue")
        end

        # Checks if the task type is a skin type.
        # @return [Boolean] true if the task type starts with "skin", false otherwise
        def skin?
          type.to_s.start_with?("skin")
        end

        # Checks if the task is to search for an heirloom.
        # @return [Boolean] true if the task type is heirloom and action is "search", false otherwise
        def search_heirloom?
          [:heirloom].include?(type) &&
            requirements[:action] == "search"
        end

        # Checks if the task is to loot an heirloom.
        # @return [Boolean] true if the task type is heirloom and action is "loot", false otherwise
        def loot_heirloom?
          [:heirloom].include?(type) &&
            requirements[:action] == "loot"
        end

        # Checks if the task type indicates that an heirloom has been found.
        # @return [Boolean] true if the task type is heirloom_found, false otherwise
        def heirloom_found?
          [
            :heirloom_found
          ].include?(type)
        end

        # Checks if the task is marked as done.
        # @return [Boolean] true if the task type is one of the done types, false otherwise
        def done?
          [
            :failed, :guard, :taskmaster, :heirloom_found
          ].include?(type)
        end

        # Checks if the task has spawned.
        # @return [Boolean] true if the task type is one of the spawned types, false otherwise
        def spawned?
          [
            :dangerous_spawned, :escort, :rescue_spawned
          ].include?(type)
        end

        # Checks if the task has been triggered.
        # @return [Boolean] true if the task has spawned, false otherwise
        def triggered?; spawned?; end

        # Checks if there are any tasks.
        # @return [Boolean] true if there are tasks, false otherwise
        def any?
          !none?
        end

        # Checks if there are no tasks.
        # @return [Boolean] true if the task type is none or nil, false otherwise
        def none?
          [:none, nil].include?(type)
        end

        # Checks if the task type is a guard type.
        # @return [Boolean] true if the task type is one of the guard types, false otherwise
        def guard?
          [
            :guard,
            :bandit_assignment, :creature_assignment, :heirloom_assignment, :heirloom_found, :rescue_assignment
          ].include?(type)
        end

        # Checks if the task is assigned.
        # @return [Boolean] true if the task type ends with "assignment", false otherwise
        def assigned?
          type.to_s.end_with?("assignment")
        end

        # Checks if the task is ready to be executed.
        # @return [Boolean] true if the task type is one of the ready types, false otherwise
        def ready?
          [
            :bandit_assignment, :escort_assignment,
            :bandit, :cull, :dangerous, :escort, :gem, :heirloom, :herb, :rescue, :skin
          ].include?(type)
        end

        # Checks if the task description indicates a help task.
        # @return [Boolean] true if the description starts with "You have been tasked to help", false otherwise
        def help?
          description.start_with?("You have been tasked to help")
        end

        # Checks if the task is an assist task.
        # @return [Boolean] true if the task is a help task, false otherwise
        def assist?
          help?
        end

        # Checks if the task is a group task.
        # @return [Boolean] true if the task is a help task, false otherwise
        def group?
          help?
        end

        # Handles calls to methods that are not defined.
        # @param symbol [Symbol] the method name being called
        # @param args [Array] arguments passed to the method
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
        # @param include_private [Boolean] whether to include private methods in the check
        # @return [Boolean] true if the method exists in requirements, false otherwise
        def respond_to_missing?(symbol, include_private = false)
          requirements&.keys&.include?(symbol) || super
        end
      end
    end
  end
end
