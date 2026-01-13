# Spells Guide

This guide covers working with spells in Lich scripts for GemStone IV.

## The Spell Class

The `Spell` class is your primary interface for working with magic in Lich. Each spell has a number, name, and various properties.

## Accessing Spells

### By Number

```ruby
# Get a spell by its number
bless = Spell[304]
fire_spirit = Spell[111]
haste = Spell[506]

# Common spell numbers
# 101 - Spirit Warding I
# 107 - Spirit Fog
# 211 - Bravery
# 303 - Prayer of Protection
# 401 - Elemental Defense I
# 506 - Haste
# 911 - Mass Blur
```

### By Name

```ruby
# Get a spell by name
spell = Spell["Haste"]
spell = Spell["Spirit Warding I"]
```

## Checking Spell Status

### Is a Spell Active?

```ruby
# Check if a specific spell is active on you
if Spell[506].active?
  echo "Haste is active"
end

# Check time left
time_left = Spell[506].timeleft
echo "Haste has #{time_left} seconds remaining"

# Check if spell is known
if Spell[506].known?
  echo "I know Haste"
end
```

### List Active Spells

```ruby
# Get all active spells
Spell.active.each do |spell|
  echo "#{spell.name} (#{spell.num}) - #{spell.timeleft}s remaining"
end

# Get all known spells
known = Spells.known
echo "You know #{known.count} spells"
```

## Casting Spells

### Basic Casting

```ruby
# Cast on yourself
Spell[506].cast

# Cast on a target
Spell[101].cast("Merchant")

# Cast with results checking
result = Spell[506].cast
if result
  echo "Cast successful"
end
```

### Safe Casting Pattern

```ruby
def safe_cast(spell_num, target = nil)
  spell = Spell[spell_num]

  # Check if we know the spell
  unless spell.known?
    echo "Don't know spell #{spell_num}"
    return false
  end

  # Check mana
  if Char.mana < spell.mana_cost
    echo "Not enough mana for #{spell.name}"
    return false
  end

  # Wait for roundtime
  waitrt?
  waitcastrt?

  # Cast
  result = target ? spell.cast(target) : spell.cast
  result
end
```

## Spell Properties

```ruby
spell = Spell[506]

spell.num           # Spell number (506)
spell.name          # Spell name ("Haste")
spell.circle        # Spell circle (5 for Major Elemental)
spell.type          # Spell type
spell.stance        # Whether stance affects casting
spell.channel       # Whether spell can be channeled
spell.active?       # Is it currently active?
spell.known?        # Do you know it?
spell.timeleft      # Seconds remaining if active
spell.affordable?   # Do you have enough mana?
```

## Spell Circles

Each spell belongs to a circle based on its number:

| Circle | Number Range | Name |
|--------|--------------|------|
| 1xx | 100-199 | Minor Spirit |
| 2xx | 200-299 | Major Spirit |
| 3xx | 300-399 | Cleric |
| 4xx | 400-499 | Minor Elemental |
| 5xx | 500-599 | Major Elemental |
| 6xx | 600-699 | Ranger |
| 7xx | 700-799 | Sorcerer |
| 9xx | 900-999 | Wizard |
| 10xx | 1000-1099 | Bard |
| 11xx | 1100-1199 | Empath |
| 12xx | 1200-1299 | Minor Mental |
| 16xx | 1600-1699 | Paladin |
| 17xx | 1700-1799 | Arcane |

### Accessing Spell Circle Ranks

```ruby
# Get your ranks in each spell circle
Spells.minor_spirit      # Minor Spirit ranks
Spells.major_spirit      # Major Spirit ranks
Spells.cleric            # Cleric ranks
Spells.minor_elemental   # Minor Elemental ranks
Spells.major_elemental   # Major Elemental ranks
Spells.ranger            # Ranger ranks
Spells.sorcerer          # Sorcerer ranks
Spells.wizard            # Wizard ranks
Spells.bard              # Bard ranks
Spells.empath            # Empath ranks
Spells.minor_mental      # Minor Mental ranks
Spells.paladin           # Paladin ranks

# Get circle name from number
Spells.get_circle_name(5)  # => "Major Elemental"
```

## Buff Management

### Check and Refresh Buffs

```ruby
# Define your buff list
BUFFS = [401, 406, 414, 506, 911]

def check_buffs
  BUFFS.each do |spell_num|
    spell = Spell[spell_num]
    next unless spell.known?

    # Refresh if not active or low on time
    if !spell.active? || spell.timeleft < 60
      if spell.affordable?
        waitrt?
        waitcastrt?
        spell.cast
        echo "Refreshed #{spell.name}"
      end
    end
  end
end

# Use in a script
loop do
  check_buffs
  sleep 30  # Check every 30 seconds
end
```

### Minimum Buff Times

```ruby
def needs_refresh?(spell, min_time = 120)
  return true unless spell.active?
  spell.timeleft < min_time
end

# Refresh if under 2 minutes remaining
if needs_refresh?(Spell[506], 120)
  Spell[506].cast
end
```

## Waiting for Spells

```ruby
# Wait until a spell wears off
wait_until { !Spell[506].active? }

# Wait until you can cast again
waitcastrt?

# Wait for specific mana level
wait_until { Char.mana >= 50 }

# Wait for spell to become active (after casting)
Spell[506].cast
sleep 0.5
if Spell[506].active?
  echo "Haste is now active"
end
```

## Common Spell Patterns

### Combat Buffing

```ruby
def buff_for_combat
  combat_buffs = [401, 406, 414, 506]

  combat_buffs.each do |num|
    spell = Spell[num]
    next unless spell.known? && spell.affordable?
    next if spell.active?

    waitrt?
    waitcastrt?
    spell.cast
    sleep 0.3
  end
end
```

### Defensive Casting

```ruby
def cast_defensive(target)
  # Spirit Warding I
  unless Spell[101].active?
    Spell[101].cast
  end

  # Cast defensive spell on target
  Spell[101].cast(target) if target
end
```

### Checking Spell Effects

```ruby
# Check if you're hasted
def hasted?
  Spell[506].active? || Spell[535].active?
end

# Check total spell defense
def spell_defense_active?
  [101, 107, 401, 406, 414, 430].any? { |num|
    Spell[num].active?
  }
end
```

## Death and Spells

Some spells persist through death, others don't:

```ruby
spell = Spell[506]
spell.persist_on_death  # true/false

# Check which spells you'll lose on death
Spell.active.each do |spell|
  unless spell.persist_on_death
    echo "Will lose: #{spell.name}"
  end
end
```

## See Also

- {Lich::Common::Spell} - Spell class reference
- {Lich::Gemstone::Spells} - Spell utilities module
- {file:guides/scripting-basics.md Scripting Basics} - Core scripting concepts
