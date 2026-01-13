# Game Data Guide

This guide covers accessing game world data in Lich scripts: rooms, maps, and game objects (NPCs, items, players).

## GameObj - Game Objects

The `GameObj` class represents everything in the game world: NPCs, items, loot, and other players.

### Finding Objects

```ruby
# Find by ID (string of numbers)
obj = GameObj["12345"]

# Find by noun (single word)
obj = GameObj["sword"]
obj = GameObj["kobold"]

# Find by name (full or partial)
obj = GameObj["silver sword"]
obj = GameObj["young kobold"]

# Find by regex pattern
obj = GameObj[/mithril/]
```

### Object Properties

```ruby
obj.id              # Unique object ID (string)
obj.noun            # Object noun ("sword", "kobold")
obj.name            # Full name ("gleaming silver sword")
obj.full_name       # Complete name with before/after text
obj.type            # Object type(s) as comma-separated string
obj.status          # Current status (for NPCs)
obj.contents        # Contents if it's a container
```

### Object Types

```ruby
# Check object type
obj.type            # Returns "weapon,sword" or similar
obj.type?("weapon") # Check specific type

# Common types:
# weapon, armor, gem, herb, skin, scroll, wand
# food, drink, box, clothing, jewelry
# creature, aggressive, undead
```

### Object Status

NPC statuses indicate their condition:

```ruby
obj.status
# Returns: nil (healthy), "stunned", "dead", "prone", "kneeling", etc.

# Check if NPC is incapacitated
if obj.status == "dead"
  echo "#{obj.name} is dead"
end
```

## Object Collections

### NPCs in Room

```ruby
# Get all NPCs
GameObj.npcs.each do |npc|
  echo "NPC: #{npc.name} (#{npc.status})"
end

# Find specific NPC
target = GameObj.npcs.find { |npc| npc.noun == "kobold" }

# Count NPCs
echo "#{GameObj.npcs.count} NPCs in room"
```

### Loot on Ground

```ruby
# Get all loot
GameObj.loot.each do |item|
  echo "Loot: #{item.name}"
end

# Find gems
gems = GameObj.loot.select { |item| item.type?("gem") }

# Find skins
skins = GameObj.loot.select { |item| item.type?("skin") }

# Find boxes
boxes = GameObj.loot.select { |item| item.type?("box") }
```

### Other Players

```ruby
# Get all PCs in room
GameObj.pcs.each do |pc|
  echo "Player: #{pc.name}"
end

# Find specific player
healer = GameObj.pcs.find { |pc| pc.name =~ /Healer/i }
```

### Your Inventory

```ruby
# All inventory items
GameObj.inv.each do |item|
  echo "Carrying: #{item.name}"
end

# What's in your hands
right = GameObj.right_hand
left = GameObj.left_hand

echo "Right hand: #{right&.name || 'empty'}"
echo "Left hand: #{left&.name || 'empty'}"
```

### Room Description Objects

```ruby
# Objects mentioned in room description (not interactable)
GameObj.room_desc.each do |obj|
  echo "Room item: #{obj.name}"
end
```

### Container Contents

```ruby
# Get contents of a container
container = GameObj["backpack"]
if container
  container.contents.each do |item|
    echo "Contains: #{item.name}"
  end
end
```

## The Map Class

The `Map` class provides navigation and room information from Lich's map database.

### Current Room

```ruby
# Get current room
room = Room.current
# or
room = Map.current

room.id             # Room ID number
room.title          # Room title(s)
room.description    # Room description(s)
room.paths          # Obvious exits text
room.location       # General location name
room.tags           # Room tags (town, node, etc.)
room.uid            # Unique identifier(s)
```

### Room Navigation

```ruby
# Check exits
room.wayto          # Hash of destination_id => direction
room.timeto         # Hash of destination_id => travel_time

# Get available exits
room.wayto.each do |dest_id, direction|
  echo "Can go #{direction} to room #{dest_id}"
end

# Check if outside
room.outside?       # true if room is outdoors
```

### Finding Rooms

```ruby
# By ID
room = Map[12345]

# By UID
room = Map["u12345"]

# By title or description
room = Map["Town Square"]
```

### Map Data

```ruby
# Get list of all rooms
Map.list            # Array of all Map objects

# Previous room
Map.previous        # Room you came from
Map.previous_room_id

# Current room ID
Map.current_room_id
```

### Pathfinding

```ruby
# Find path between rooms
start_id = Room.current.id
dest_id = 228  # Target room

# The path is calculated by Lich's navigation system
# Usually done through go2 script or similar

# Check if rooms are connected
room = Room.current
if room.wayto.key?(dest_id.to_s)
  direction = room.wayto[dest_id.to_s]
  echo "Can go directly: #{direction}"
end
```

## Common Patterns

### Target Selection

```ruby
def find_target
  # Find first living, non-stunned NPC
  GameObj.npcs.find { |npc|
    npc.status.nil? || !["dead", "gone"].include?(npc.status)
  }
end

def find_valid_targets
  GameObj.npcs.select { |npc|
    npc.status.nil? ||
    !["dead", "gone", "stunned"].include?(npc.status)
  }
end
```

### Loot Collection

```ruby
def collect_loot
  # Collect gems
  GameObj.loot.each do |item|
    if item.type?("gem") || item.type?("skin")
      fput "get ##{item.id}"
      sleep 0.3
    end
  end
end

def collect_boxes
  GameObj.loot.each do |item|
    if item.type?("box")
      fput "get ##{item.id}"
      sleep 0.3
    end
  end
end
```

### Hand Management

```ruby
def empty_hands
  if GameObj.right_hand
    fput "stow right"
  end
  if GameObj.left_hand
    fput "stow left"
  end
end

def holding?(item_name)
  right = GameObj.right_hand
  left = GameObj.left_hand
  (right && right.name =~ /#{item_name}/i) ||
  (left && left.name =~ /#{item_name}/i)
end
```

### Room Checks

```ruby
def in_town?
  room = Room.current
  room&.tags&.include?("town")
end

def at_node?
  room = Room.current
  room&.tags&.include?("node")
end

def room_has_npc?(npc_noun)
  GameObj.npcs.any? { |npc| npc.noun == npc_noun }
end
```

### Safe Movement

```ruby
def safe_go(direction)
  # Check NPCs before moving
  if GameObj.npcs.any? { |npc| npc.status.nil? }
    echo "Warning: live NPCs in room"
    return false
  end

  fput direction
  true
end
```

## Familiar Objects

If you have a familiar, there are separate collections:

```ruby
GameObj.fam_loot      # Loot your familiar sees
GameObj.fam_npcs      # NPCs your familiar sees
GameObj.fam_pcs       # Players your familiar sees
GameObj.fam_room_desc # Room objects your familiar sees
```

## See Also

- {Lich::Common::GameObj} - GameObj class reference
- {Lich::Common::Map} - Map class reference
- {file:guides/scripting-basics.md Scripting Basics} - Core scripting concepts
- {file:guides/spells-guide.md Spells Guide} - Working with spells
