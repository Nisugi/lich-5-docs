# Bounty System Guide

This guide covers working with the Adventurer's Guild bounty system in Lich scripts for GemStone IV.

## Overview

The `Bounty` class parses your current bounty task and provides structured access to task requirements, allowing scripts to automate or assist with bounty completion.

## Getting Your Current Bounty

```ruby
# Get current bounty task
bounty = Bounty.current
# or
bounty = Bounty.task

# Check if you have a bounty
if bounty.any?
  echo "You have a bounty: #{bounty.type}"
else
  echo "No current bounty"
end
```

## Bounty Properties

```ruby
bounty = Bounty.current

bounty.type           # Task type symbol (:cull, :gem, :herb, etc.)
bounty.description    # Full task description text
bounty.town           # Associated town
bounty.requirements   # Hash of task requirements
bounty.creature       # Creature to hunt (if applicable)
bounty.location       # Where to complete the task
```

## Bounty Types

The bounty system recognizes these task types:

| Type | Description |
|------|-------------|
| `:cull` | Kill a number of creatures |
| `:dangerous` | Kill a dangerous creature |
| `:dangerous_spawned` | Dangerous creature has spawned |
| `:creature_assignment` | Go to taskmaster for creature task |
| `:gem` | Collect gems from creatures |
| `:herb` | Forage specific herbs |
| `:skin` | Skin specific creatures |
| `:heirloom` | Find a lost heirloom |
| `:heirloom_found` | Heirloom has been found |
| `:rescue` | Rescue a kidnapped child |
| `:rescue_spawned` | Rescue target has spawned |
| `:escort` | Escort a traveler |
| `:escort_assignment` | Go get escort assignment |
| `:bandit` | Kill bandits |
| `:bandit_assignment` | Go to taskmaster for bandit task |
| `:guard` | Return to taskmaster |
| `:taskmaster` | Need to visit taskmaster |
| `:failed` | Task has failed |
| `:none` | No current task |

## Checking Bounty Status

### Basic Checks

```ruby
bounty = Bounty.current

# Do you have a bounty?
bounty.any?           # true if you have a task
bounty.none?          # true if no task

# Is the task complete?
bounty.done?          # true if ready to turn in

# Task type checks
bounty.cull?          # Is it a cull task?
bounty.dangerous?     # Is it a dangerous creature?
bounty.gem?           # Is it a gem task?
bounty.herb?          # Is it an herb task?
bounty.skin?          # Is it a skinning task?
bounty.heirloom?      # Is it an heirloom task?
bounty.rescue?        # Is it a rescue task?
bounty.escort?        # Is it an escort task?
bounty.bandit?        # Is it a bandit task?
```

### Status Checks

```ruby
bounty = Bounty.current

# Has the creature/target spawned?
bounty.spawned?       # true for dangerous_spawned, rescue_spawned
bounty.triggered?     # alias for spawned?

# Do you need to go to taskmaster?
bounty.guard?         # Need to return to taskmaster
bounty.assigned?      # Have an assignment to pick up

# Is the task ready to work on?
bounty.ready?         # Task is actionable

# Is this a group/help task?
bounty.help?          # Were you asked to help someone?
bounty.assist?        # alias for help?
bounty.group?         # alias for help?
```

### Creature Tasks

```ruby
bounty = Bounty.current

# Does the task involve creatures?
bounty.creature?      # true for creature-based tasks

# Get creature info
if bounty.critter?
  echo "Hunt: #{bounty.creature}"
  echo "Location: #{bounty.location}"
end
```

### Heirloom Tasks

```ruby
bounty = Bounty.current

if bounty.heirloom?
  if bounty.search_heirloom?
    echo "Need to search for heirloom"
  elsif bounty.loot_heirloom?
    echo "Need to loot heirloom from creature"
  end
end

if bounty.heirloom_found?
  echo "Heirloom found! Return to taskmaster"
end
```

## Task Requirements

The `requirements` hash contains task-specific details:

```ruby
bounty = Bounty.current
reqs = bounty.requirements

# Common requirement keys:
reqs[:creature]       # Creature name
reqs[:area]           # Area/location
reqs[:town]           # Associated town
reqs[:number]         # Count required
reqs[:action]         # Action type (search, loot, etc.)

# Access via method_missing
bounty.creature       # Same as bounty.requirements[:creature]
bounty.number         # Same as bounty.requirements[:number]
```

## Common Patterns

### Bounty Dispatcher

```ruby
def handle_bounty
  bounty = Bounty.current

  return if bounty.none?

  case
  when bounty.guard? || bounty.done?
    echo "Returning to taskmaster..."
    # Navigate to taskmaster
  when bounty.cull?
    echo "Hunting #{bounty.creature}..."
    # Go hunt
  when bounty.gem?
    echo "Collecting gems..."
    # Hunt for gems
  when bounty.herb?
    echo "Foraging #{bounty.requirements[:herb]}..."
    # Go forage
  when bounty.skin?
    echo "Skinning #{bounty.creature}..."
    # Hunt and skin
  when bounty.heirloom?
    echo "Finding heirloom..."
    # Search or hunt
  when bounty.rescue?
    echo "Rescue mission..."
    # Go to rescue area
  when bounty.escort?
    echo "Escort mission..."
    # Handle escort
  when bounty.bandit?
    echo "Hunting bandits..."
    # Kill bandits
  when bounty.assigned?
    echo "Getting assignment..."
    # Go to taskmaster
  end
end
```

### Checking If Hunting Is Needed

```ruby
def needs_hunting?
  bounty = Bounty.current
  bounty.any? && (
    bounty.cull? ||
    bounty.dangerous? ||
    bounty.gem? ||
    bounty.skin? ||
    bounty.bandit? ||
    bounty.creature?
  )
end
```

### Waiting for Dangerous Spawn

```ruby
def wait_for_spawn
  bounty = Bounty.current

  return unless bounty.dangerous?

  echo "Waiting for dangerous creature to spawn..."
  wait_until {
    bounty = Bounty.current
    bounty.spawned? || bounty.done?
  }
  echo "Target spawned!" if bounty.spawned?
end
```

### Task Type Summary

```ruby
def bounty_summary
  bounty = Bounty.current

  if bounty.none?
    echo "No bounty"
    return
  end

  echo "Type: #{bounty.type}"
  echo "Status: #{bounty.done? ? 'DONE' : 'In Progress'}"

  if bounty.creature
    echo "Creature: #{bounty.creature}"
  end

  if bounty.location
    echo "Location: #{bounty.location}"
  end

  if bounty.town
    echo "Town: #{bounty.town}"
  end
end
```

## LNet Integration

You can check other players' bounties via LNet:

```ruby
# Get another player's bounty
other_bounty = Bounty.lnet("PlayerName")

if other_bounty
  echo "#{PlayerName}'s bounty: #{other_bounty.type}"
else
  echo "Could not get bounty info"
end
```

## Known Task Types

For reference, all recognized task types:

```ruby
Bounty::KNOWN_TASKS
# Returns array of all known task type symbols
```

## See Also

- {Lich::Gemstone::Bounty} - Bounty class reference
- {Lich::Gemstone::Bounty::Task} - Task class reference
- {file:guides/scripting-basics.md Scripting Basics} - Core scripting concepts
- {file:guides/game-data.md Game Data Guide} - GameObj and Map information
