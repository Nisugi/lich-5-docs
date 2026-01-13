# Society Guide

This guide covers working with the three societies (Order of Voln, Council of Light, Guardians of Sunfist) in Lich scripts for GemStone IV.

## Overview

The `Society` class and its subclasses provide access to your character's society membership, rank, tasks, and abilities.

## Basic Society Information

```ruby
# Get your society membership
Society.membership    # "Order of Voln", "Council of Light", "Guardians of Sunfist", or nil
Society.status        # Alias for membership

# Get your rank
Society.rank          # 0-26 for Voln, 0-20 for others

# Get current society task
Society.task          # Task description or status message
```

### Checking Membership

```ruby
# Check if member of specific society
def voln_member?
  Society.membership == "Order of Voln"
end

def col_member?
  Society.membership == "Council of Light"
end

def sunfist_member?
  Society.membership == "Guardians of Sunfist"
end

# Check if in any society
def in_society?
  !Society.membership.nil? && Society.membership != "None"
end
```

## Order of Voln

The Order of Voln is dedicated to releasing undead from their suffering.

### Accessing Voln Data

```ruby
# Quick access
Societies.voln              # Returns OrderOfVoln class

# Or full path
Lich::Gemstone::Societies::OrderOfVoln
```

### Voln Favor

```ruby
# Get current favor
Societies::OrderOfVoln.favor

# Check favor level
favor = Societies::OrderOfVoln.favor
if favor > 1000
  echo "Plenty of favor"
elsif favor < 100
  echo "Low on favor!"
end
```

### Voln Symbols (Abilities)

Voln members gain Symbols as they progress through ranks:

| Rank | Symbol |
|------|--------|
| 1 | Recognition |
| 2 | Blessing |
| 3 | Thought |
| 4 | Preservation |
| 5 | Dreams |
| 6 | Courage |
| 7 | Protection |
| 8 | Submission |
| 9 | Sleep |
| 10 | Transcendence |
| 11 | Mana |
| 12 | Sight |
| 13 | Recall |
| 14 | Turning |
| 15 | Strike |
| 16 | Holiness |
| 17 | Restoration |
| 18 | Need |
| 19 | Determination |
| 20 | Return |
| 21 | Supremacy |
| 22 | Kai's Smite |
| 23 | V'tull's Fury |
| 24 | Phoen's Illumination |
| 25 | Lorminstra's Blessing |
| 26 | Voln Master |

### Using Voln Symbols

```ruby
# Check if you know a symbol
if Society.rank >= 14
  echo "You know Symbol of Turning"
end

# Symbol costs vary - check favor before using
if Societies::OrderOfVoln.favor >= 50
  fput "symbol of turning"
end
```

## Council of Light

The Council of Light combats the forces of darkness through magical means.

### Accessing CoL Data

```ruby
# Quick access
Societies.col               # Returns CouncilOfLight class

# Or full path
Lich::Gemstone::Societies::CouncilOfLight
```

### CoL Abilities

Council of Light abilities are gained through ranks:

| Rank Range | Abilities |
|------------|-----------|
| 1-5 | Basic light manipulation |
| 6-10 | Enhanced defensive abilities |
| 11-15 | Offensive light powers |
| 16-20 | Master abilities |

## Guardians of Sunfist

The Guardians of Sunfist are warriors dedicated to protecting Elanthia.

### Accessing Sunfist Data

```ruby
# Quick access
Societies.sunfist           # Returns GuardiansOfSunfist class

# Or full path
Lich::Gemstone::Societies::GuardiansOfSunfist
```

### Sigil Abilities

Sunfist members use Sigils for their abilities:

| Rank Range | Sigil Types |
|------------|-------------|
| 1-5 | Basic combat sigils |
| 6-10 | Enhanced sigils |
| 11-15 | Advanced sigils |
| 16-20 | Master sigils |

## Common Patterns

### Society-Based Script Behavior

```ruby
def use_society_ability
  case Society.membership
  when "Order of Voln"
    if Societies::OrderOfVoln.favor >= 100
      fput "symbol of courage"
    end
  when "Council of Light"
    fput "sigil of light"  # Example
  when "Guardians of Sunfist"
    fput "sigil of defense"  # Example
  else
    echo "Not in a society"
  end
end
```

### Checking for Undead (Voln)

```ruby
def should_use_symbol?
  return false unless voln_member?
  return false if Societies::OrderOfVoln.favor < 50

  # Check for undead targets
  GameObj.npcs.any? { |npc| npc.type?("undead") }
end
```

### Society Task Handling

```ruby
def check_society_task
  task = Society.task

  if task =~ /release.*undead/i
    echo "Voln eternal duty - release undead"
  elsif task =~ /not currently in a society/i
    echo "Not in a society"
  else
    echo "Current task: #{task}"
  end
end
```

### Rank-Based Features

```ruby
def available_abilities
  rank = Society.rank
  abilities = []

  case Society.membership
  when "Order of Voln"
    abilities << "Recognition" if rank >= 1
    abilities << "Blessing" if rank >= 2
    abilities << "Turning" if rank >= 14
    abilities << "Supremacy" if rank >= 21
  end

  abilities
end

# Check if specific ability is available
def has_voln_turning?
  voln_member? && Society.rank >= 14
end
```

### Resource Management

```ruby
# Voln favor management
def conserve_favor?
  return false unless voln_member?
  Societies::OrderOfVoln.favor < 200
end

def use_expensive_symbol?
  return false unless voln_member?
  Societies::OrderOfVoln.favor >= 500
end
```

## Society Serialization

```ruby
# Get society status as array
Society.serialize
# Returns: [membership, rank]
# Example: ["Order of Voln", 15]
```

## Deprecated Methods

These methods still work but are deprecated:

```ruby
# Old                    # New
Society.member           # Use Society.membership
Society.step             # Use Society.rank
Society.favor            # Use Societies::OrderOfVoln.favor
```

## See Also

- {Lich::Gemstone::Society} - Society class reference
- {Lich::Gemstone::Societies::OrderOfVoln} - Voln reference
- {Lich::Gemstone::Societies::CouncilOfLight} - CoL reference
- {Lich::Gemstone::Societies::GuardiansOfSunfist} - Sunfist reference
- {file:guides/scripting-basics.md Scripting Basics} - Core scripting concepts
- {file:guides/spells-guide.md Spells Guide} - Working with spells
