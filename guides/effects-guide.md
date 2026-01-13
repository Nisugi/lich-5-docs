# Effects Guide

This guide covers working with Effects in Lich scripts for GemStone IV.

## Effects vs Spells

While the `Spell` class represents individual spells you can cast, the `Effects` module tracks what's **currently active** on your character - including spells, buffs, debuffs, and cooldowns.

| Feature | Spell Class | Effects Module |
|---------|-------------|----------------|
| Purpose | Cast and manage spells | Track active effects |
| Scope | Individual spells | All active effects |
| Data source | Spell database | Game XML data |
| Use case | "Cast Haste" | "Is Haste active?" |

## The Effects Module

The Effects module provides four pre-defined registries for different types of effects:

```ruby
Effects::Spells    # Active spells on your character
Effects::Buffs     # Active buffs (non-spell enhancements)
Effects::Cooldowns # Abilities on cooldown
Effects::Debuffs   # Active debuffs/negative effects
```

## Basic Usage

### Checking if an Effect is Active

```ruby
# Check if a specific spell effect is active
if Effects::Spells.active?(506)  # Haste
  echo "Haste is active"
end

# Check by name (using Regexp)
if Effects::Spells.active?(/Haste/)
  echo "Haste is active"
end

# Check for buffs
if Effects::Buffs.active?("Berserking")
  echo "Berserking buff is active"
end

# Check for debuffs
if Effects::Debuffs.active?(/Stun/)
  echo "You're stunned!"
end
```

### Getting Time Remaining

```ruby
# Get time left in minutes
time_left = Effects::Spells.time_left(506)
echo "Haste has #{time_left.round(1)} minutes remaining"

# Get expiration time (seconds since epoch)
expires_at = Effects::Spells.expiration(506)
echo "Haste expires at #{Time.at(expires_at)}"
```

### Iterating Over Effects

```ruby
# List all active spells
Effects::Spells.each do |name, expiration|
  time_left = ((expiration - Time.now) / 60.0).round(1)
  echo "#{name}: #{time_left} minutes left"
end

# List all cooldowns
Effects::Cooldowns.each do |ability, expiration|
  time_left = ((expiration - Time.now) / 60.0).round(1)
  echo "#{ability} on cooldown: #{time_left} minutes"
end
```

### Converting to Hash

```ruby
# Get all active spells as a hash
active = Effects::Spells.to_h
echo "You have #{active.size} active spell effects"

# Get all buffs
buffs = Effects::Buffs.to_h
buffs.each do |name, exp|
  echo "Buff: #{name}"
end
```

## Displaying Effects

The Effects module includes a built-in display method:

```ruby
# Show all effects in a formatted table
Effects.display
```

This outputs a nicely formatted table showing:
- Spell ID
- Effect type (Spells, Cooldowns, Buffs, Debuffs)
- Effect name
- Time remaining

## Common Patterns

### Wait for Cooldown

```ruby
def wait_for_cooldown(ability)
  while Effects::Cooldowns.active?(ability)
    time_left = Effects::Cooldowns.time_left(ability)
    echo "Waiting #{time_left.round(1)} minutes for #{ability}..."
    sleep 10
  end
  echo "#{ability} ready!"
end
```

### Buff Monitoring

```ruby
# Check if any defensive buff is active
def has_defensive_buff?
  Effects::Buffs.active?(/Defense/) ||
  Effects::Buffs.active?(/Protection/) ||
  Effects::Spells.active?(401)  # Elemental Defense I
end

# Monitor and alert when buffs expire
def monitor_buffs(important_buffs)
  important_buffs.each do |buff|
    if Effects::Spells.active?(buff)
      time_left = Effects::Spells.time_left(buff)
      if time_left < 2  # Less than 2 minutes
        echo "WARNING: #{Spell[buff].name} expiring soon!"
      end
    end
  end
end

# Usage
monitor_buffs([401, 406, 414, 506])
```

### Combining with Spell Class

```ruby
# Refresh spell if effect is expiring
def refresh_if_needed(spell_num, min_minutes = 5)
  spell = Spell[spell_num]

  # Check via Effects (more accurate for active status)
  if !Effects::Spells.active?(spell_num)
    echo "#{spell.name} not active, casting..."
    spell.cast
  elsif Effects::Spells.time_left(spell_num) < min_minutes
    echo "#{spell.name} expiring soon, refreshing..."
    spell.cast
  end
end
```

### Debuff Detection

```ruby
# Check for harmful effects
def check_debuffs
  dangerous = []

  Effects::Debuffs.each do |debuff, _exp|
    dangerous << debuff
  end

  if dangerous.any?
    echo "Active debuffs: #{dangerous.join(', ')}"
    return true
  end
  false
end

# React to debuffs
if check_debuffs
  # Take action - cure, flee, etc.
end
```

### Cooldown-Aware Ability Use

```ruby
def use_ability_when_ready(ability_name)
  # Wait for cooldown
  if Effects::Cooldowns.active?(ability_name)
    time_left = Effects::Cooldowns.time_left(ability_name)
    echo "#{ability_name} on cooldown for #{time_left.round(1)} more minutes"
    return false
  end

  # Use the ability
  fput ability_name
  true
end
```

## Registry Methods Reference

Each Effects registry (`Spells`, `Buffs`, `Debuffs`, `Cooldowns`) provides:

| Method | Returns | Description |
|--------|---------|-------------|
| `active?(effect)` | Boolean | Is the effect currently active? |
| `time_left(effect)` | Float | Minutes remaining (0 if not active) |
| `expiration(effect)` | Integer | Expiration time (seconds since epoch) |
| `to_h` | Hash | All effects as {name => expiration} |
| `each` | Enumerator | Iterate over all effects |

The `effect` parameter can be:
- An Integer (spell number)
- A String (effect name)
- A Regexp (pattern to match)

## Effects vs Spell.active

Both can check if a spell is active, but they work differently:

```ruby
# Using Spell class
Spell[506].active?      # Checks Spell's internal tracking
Spell[506].timeleft     # Time in seconds

# Using Effects module
Effects::Spells.active?(506)   # Checks XML data from game
Effects::Spells.time_left(506) # Time in minutes
```

Use `Effects` when you need:
- Access to buffs, debuffs, and cooldowns (not just spells)
- Real-time data from the game's XML feed
- To iterate over all active effects

Use `Spell` when you need:
- To cast spells
- Spell metadata (circle, mana cost, etc.)
- The spell's known/affordable status

## See Also

- {Lich::Gemstone::Effects} - Effects module reference
- {Lich::Gemstone::Effects::Registry} - Registry class reference
- {file:guides/spells-guide.md Spells Guide} - Working with the Spell class
- {file:guides/scripting-basics.md Scripting Basics} - Core scripting concepts
