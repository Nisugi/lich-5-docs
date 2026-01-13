# Character Stats Guide

This guide covers accessing your character's statistics, skills, and resources in Lich scripts.

## The Char Class

The `Char` class provides quick access to your character's vital information.

### Basic Information

```ruby
Char.name           # Your character's name
Char.stance         # Current stance (offensive, defensive, etc.)
Char.percent_stance # Stance percentage (0-100)
Char.encumbrance    # Encumbrance level text
Char.percent_encumbrance  # Encumbrance percentage
Char.citizenship    # Your citizenship (GemStone only)
```

### Resources

```ruby
# Current values
Char.health         # Current health
Char.mana           # Current mana
Char.spirit         # Current spirit
Char.stamina        # Current stamina

# Maximum values
Char.max_health     # Maximum health
Char.max_mana       # Maximum mana
Char.max_spirit     # Maximum spirit
Char.max_stamina    # Maximum stamina

# Percentages
Char.percent_health   # Health percentage (0-100)
Char.percent_mana     # Mana percentage (0-100)
Char.percent_spirit   # Spirit percentage (0-100)
Char.percent_stamina  # Stamina percentage (0-100)
```

### Resource Checks

```ruby
# Wait for resources
wait_until { Char.mana >= 50 }
wait_until { Char.percent_health >= 80 }

# Check before actions
if Char.stamina < 10
  echo "Low on stamina!"
end

if Char.percent_mana < 25
  echo "Mana below 25%"
end
```

## The Stats Module

The `Stats` module provides detailed character statistics.

### Character Info

```ruby
Stats.race          # "Human", "Elf", "Dwarf", etc.
Stats.profession    # "Wizard", "Warrior", "Cleric", etc.
Stats.prof          # Alias for profession
Stats.gender        # "male" or "female"
Stats.age           # Character age
Stats.level         # Current level
Stats.exp           # Current experience points
```

### Primary Statistics

Each stat returns an OpenStruct with `value` and `bonus`:

```ruby
# Full stat access
str = Stats.strength
str.value           # Base stat value (e.g., 85)
str.bonus           # Stat bonus (e.g., 17)
str.enhanced.value  # Enhanced value (with enhancives)
str.enhanced.bonus  # Enhanced bonus

# All primary stats
Stats.strength      # STR
Stats.constitution  # CON
Stats.dexterity     # DEX
Stats.agility       # AGI
Stats.discipline    # DIS
Stats.aura          # AUR
Stats.logic         # LOG
Stats.intuition     # INT
Stats.wisdom        # WIS
Stats.influence     # INF
```

### Shorthand Access

```ruby
# Returns [value, bonus] array
Stats.str           # [value, bonus]
Stats.con
Stats.dex
Stats.agi
Stats.dis
Stats.aur
Stats.log
Stats.int
Stats.wis
Stats.inf

# Enhanced versions
Stats.enhanced_str  # [enhanced_value, enhanced_bonus]
Stats.enhanced_con
# ... etc.

# Example usage
value, bonus = Stats.str
echo "Strength: #{value} (bonus: +#{bonus})"
```

## The Skills Module

The `Skills` module provides access to your character's trained skills.

### Accessing Skills

```ruby
# Combat skills
Skills.two_weapon_combat
Skills.armor_use
Skills.shield_use
Skills.combat_maneuvers
Skills.edged_weapons
Skills.blunt_weapons
Skills.two_handed_weapons
Skills.ranged_weapons
Skills.thrown_weapons
Skills.polearm_weapons
Skills.brawling
Skills.ambush
Skills.multi_opponent_combat

# Physical skills
Skills.physical_fitness
Skills.dodging
Skills.survival
Skills.climbing
Skills.swimming

# Magic skills
Skills.arcane_symbols
Skills.magic_item_use
Skills.spell_aiming
Skills.harness_power
Skills.elemental_mana_control
Skills.mental_mana_control
Skills.spirit_mana_control

# Lore skills
Skills.elemental_lore_air
Skills.elemental_lore_earth
Skills.elemental_lore_fire
Skills.elemental_lore_water
Skills.spiritual_lore_blessings
Skills.spiritual_lore_religion
Skills.spiritual_lore_summoning
Skills.sorcerous_lore_demonology
Skills.sorcerous_lore_necromancy
Skills.mental_lore_divination
Skills.mental_lore_manipulation
Skills.mental_lore_telepathy
Skills.mental_lore_transference
Skills.mental_lore_transformation

# Utility skills
Skills.disarming_traps
Skills.picking_locks
Skills.stalking_and_hiding
Skills.perception
Skills.first_aid
Skills.trading
Skills.pickpocketing
```

### Shorthand Skill Names

```ruby
# Common shorthand versions
Skills.twoweaponcombat
Skills.armoruse
Skills.shielduse
Skills.combatmaneuvers
Skills.physicalfitness
Skills.arcanesymbols
Skills.magicitemuse
Skills.spellaiming
Skills.harnesspower
Skills.stalkingandhiding
Skills.firstaid

# Lore shorthand
Skills.elair         # elemental_lore_air
Skills.elearth       # elemental_lore_earth
Skills.elfire        # elemental_lore_fire
Skills.elwater       # elemental_lore_water
Skills.slblessings   # spiritual_lore_blessings
Skills.slreligion    # spiritual_lore_religion
Skills.mldivination  # mental_lore_divination

# Mana control shorthand
Skills.emc           # elemental_mana_control
Skills.mmc           # mental_mana_control
Skills.smc           # spirit_mana_control
```

### Calculating Skill Bonus

```ruby
# Calculate bonus from ranks
Skills.to_bonus(30)  # => 140

# The formula:
# Ranks 1-10:   5 per rank
# Ranks 11-20:  4 per rank
# Ranks 21-30:  3 per rank
# Ranks 31-40:  2 per rank
# Ranks 41+:    1 per rank

# Get bonus for a specific skill
Skills.to_bonus(:combat_maneuvers)
```

## Common Patterns

### Health Monitoring

```ruby
def low_health?
  Char.percent_health < 50
end

def critical_health?
  Char.percent_health < 20
end

# In a hunting script
loop do
  if critical_health?
    echo "CRITICAL! Retreating!"
    fput "retreat"
    break
  elsif low_health?
    echo "Low health, being careful..."
  end
  sleep 1
end
```

### Resource Waiting

```ruby
def wait_for_mana(amount)
  if Char.mana < amount
    echo "Waiting for #{amount} mana..."
    wait_until { Char.mana >= amount }
  end
end

def wait_for_full_resources
  wait_until {
    Char.percent_health >= 100 &&
    Char.percent_mana >= 100 &&
    Char.percent_spirit >= 100
  }
end
```

### Skill Checks

```ruby
def can_pick_locks?
  Skills.picking_locks >= 1
end

def can_disarm_traps?
  Skills.disarming_traps >= 1
end

def is_caster?
  Char.max_mana > 0
end

# Check if skilled enough for a task
def has_skill?(skill_name, min_ranks)
  Skills.send(skill_name) >= min_ranks
end

if has_skill?(:climbing, 50)
  echo "Good climber!"
end
```

### Stat-Based Decisions

```ruby
# Choose approach based on stats
if Stats.strength.bonus > Stats.dexterity.bonus
  echo "Favoring strength-based attacks"
else
  echo "Favoring dexterity-based attacks"
end

# Check profession
case Stats.profession
when "Wizard"
  echo "Pure caster"
when "Warrior"
  echo "Pure melee"
when "Paladin"
  echo "Hybrid character"
end
```

## Experience Tracking

```ruby
# Current experience
exp = Stats.exp
level = Stats.level

echo "Level #{level} with #{exp} experience"

# Note: Stats.exp returns total XP earned, not XP to next level
```

## See Also

- {Lich::Common::Char} - Char class reference
- {Lich::Gemstone::Stats} - Stats module reference
- {Lich::Gemstone::Skills} - Skills module reference
- {file:guides/scripting-basics.md Scripting Basics} - Core scripting concepts
