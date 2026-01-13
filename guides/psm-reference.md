# PSM Reference Guide

Player System Manager (PSM) skills are combat abilities in GemStone IV that your character can learn and use. This guide covers how to work with PSMs in Lich scripts.

## What are PSMs?

PSMs include:

| Category | Description | Examples |
|----------|-------------|----------|
| **CMan** | Combat Maneuvers | Bull Rush, Feint, Coup de Grace |
| **Shield** | Shield Specializations | Shield Bash, Bulwark, Phalanx |
| **Feat** | Character Feats | Cunning Defense, Combat Mastery |
| **Weapon** | Weapon Techniques | Cripple, Whirling Blade |
| **Armor** | Armor Specializations | Armor Spike, Armored Stealth |
| **Warcry** | Battle Cries | Bertrandt's Bellow, Yertie's Yowlp |
| **Ascension** | Ascension Abilities | Various ascension skills |
| **QStrike** | Quick Strikes | Rapid attack abilities |

## Skill Types

Each PSM has a type that determines how it works:

- **:passive** - Always active once learned, no activation needed
- **:attack** - Offensive action against a target
- **:buff** - Temporary enhancement to your character
- **:stance** / **:martial_stance** - Combat stance that modifies behavior
- **:setup** - Prepares for a follow-up action
- **:area_of_effect** - Affects multiple targets
- **:concentration** - Requires focus to maintain

## Using PSMs in Scripts

### Check if You Can Use a Skill

```ruby
# Check if you have enough stamina for Bull Rush
if PSMS.assess("bullrush", "CMan", true)
  fput "bullrush"
end

# Check with forced RT consideration
if PSMS.assess("feint", "CMan", true, forcert_count: 2)
  fput "feint"
end
```

### Check Skill Availability

```ruby
# Is the skill off cooldown and not overexerted?
if PSMS.available?("bullrush")
  # Safe to use
end

# Ignore cooldown check (for skills with ignorable cooldowns)
if PSMS.available?("burst", true)
  # Use even if on cooldown
end
```

### Get Skill Information

```ruby
# Find a skill by name
skill = PSMS.find_name("feint", "CMan")
# => { :long_name => "combat_feint", :short_name => "feint", :cost => {...} }

# Normalize a skill name for lookup
PSMS.name_normal("Bull Rush")
# => "bull_rush"
```

### Forced Roundtime (Multi-Opponent Combat)

Characters with Multi-Opponent Combat training can perform multiple actions:

```ruby
# Check max forcert rounds based on MOC ranks
PSMS.max_forcert_count
# => 0 (0-9 ranks), 1 (10-34), 2 (35-74), 3 (75-124), 4 (125+)

# Can I do 2 forcert rounds?
if PSMS.can_forcert?(2)
  # Yes, MOC is 35+
end
```

### Handle Failures

PSMs can fail for various reasons. Use the built-in failure detection:

```ruby
result = dothistimeout "bullrush", 3, /^You |#{PSMS::FAILURES_REGEXES}/

if PSMS::FAILURES_REGEXES.match?(result)
  echo "Action failed: #{result}"
end
```

Common failure messages:
- "You are unable to do that right now."
- "You don't seem to be able to move to do that."
- "You are still stunned."
- "You lack the momentum to attempt another skill."

## Combat Maneuvers (CMan)

Combat Maneuvers are trained through the Combat Maneuvers skill. Key maneuvers include:

### Offensive
- **Bull Rush** - Area attack, 14 stamina
- **Berserk** - Rage mode, 20 stamina
- **Coup de Grace** - Finishing move, 20 stamina
- **Feint** - Setup attack, stamina varies

### Defensive/Utility
- **Burst of Swiftness** - Speed buff, 30/60 stamina
- **Combat Mobility** - Passive defense
- **Combat Toughness** - Passive health

### Passive (Always Active)
- Acrobat's Leap
- Block Specialization
- Combat Focus
- Combat Movement

## Shield Specializations

Shield skills require wielding the appropriate shield type.

### Passive Abilities
- **Adamantine Bulwark** - Enhanced blocking
- **Block the Elements** - Elemental resistance
- **Deflect Magic** - Spell deflection (requires 3 ranks in Shield Focus)
- **Deflect Missiles** - Ranged deflection

### Active Abilities
- **Shield Bash** - Offensive shield attack
- **Shield Charge** - Rushing attack
- **Disarming Presence** - Martial stance, 20 stamina

### Shield Focus Types
- Small Shield Focus
- Medium Shield Focus
- Large Shield Focus
- Tower Shield Focus

## Script Integration Example

Here's a complete example of using PSMs in a hunting script:

```ruby
# Check resources before engaging
def can_attack?
  return false if Spell[9007].active?  # No attacking while dead
  return false if stunned?
  return false unless PSMS.available?("bullrush")
  return false unless PSMS.assess("bullrush", "CMan", true)
  true
end

# Attempt a combat maneuver with error handling
def try_bullrush
  return unless can_attack?

  result = dothistimeout "bullrush", 3, /^You |#{PSMS::FAILURES_REGEXES}/

  if PSMS::FAILURES_REGEXES.match?(result)
    echo "Bull Rush failed"
    return false
  end

  true
end
```

## See Also

- {Lich::Gemstone::PSMS} - Main PSM module
- {Lich::Gemstone::CMan} - Combat Maneuvers
- {Lich::Gemstone::Shield} - Shield Specializations
- {Lich::Gemstone::Feat} - Feats
- {Lich::Gemstone::Weapon} - Weapon Techniques
- {Lich::Gemstone::Armor} - Armor Specializations
- {Lich::Gemstone::Warcry} - Warcries
