# Scripting Basics Guide

This guide covers the fundamentals of writing Lich scripts for GemStone IV and DragonRealms.

## What is a Lich Script?

Lich scripts are Ruby programs that interact with the game through Lich's API. They can automate tasks, enhance gameplay, and provide information about your character and the game world.

## Script Structure

A basic Lich script looks like this:

```ruby
# my_script.rb
# A simple example script

echo "Hello from my script!"

# Do something useful
fput "look"
```

## Essential Functions

### Output Functions

```ruby
# Display message to the user (script output)
echo "This appears in your game window"

# Send a command to the game
fput "say Hello world"

# Put command without waiting for response
put "look"

# Send and wait for a specific response
result = dothistimeout "look", 5, /Obvious exits/
```

### Waiting and Timing

```ruby
# Wait for specific text from the game
waitfor "You are no longer stunned"

# Wait with timeout (returns nil if timeout)
line = waitfor? "Ready", 10

# Wait for roundtime to finish
waitrt?

# Wait for cast roundtime
waitcastrt?

# Pause script execution
sleep 2          # Wait 2 seconds
pause 0.5        # Same as sleep
```

### Game State Checks

```ruby
# Check if you're stunned, dead, etc.
if stunned?
  waitrt?
  wait_until { !stunned? }
end

# Check for conditions
dead?           # Are you dead?
stunned?        # Are you stunned?
webbed?         # Are you webbed?
bound?          # Are you bound?
silenced?       # Are you silenced?
```

## Working with Game Lines

```ruby
# Get lines from the game
line = get              # Get next line (blocks)
line = get?             # Get next line (non-blocking, returns nil if none)

# Match patterns in game output
if line =~ /attacks you/
  echo "Under attack!"
end

# Process multiple lines
loop do
  line = get
  if line =~ /You are stunned/
    echo "Got stunned!"
    break
  end
end
```

## Script Management

### Starting and Stopping Scripts

```ruby
# Start another script (returns immediately)
Script.start("scriptname")
Script.start("scriptname", "arg1 arg2")

# Start script and wait for it to finish
Script.run("scriptname")
Script.run("scriptname", "arg1 arg2")

# Key difference:
# - Script.start: Launches script, continues immediately
# - Script.run: Launches script, waits until it completes

# Stop a running script
Script.kill("scriptname")

# Check if a script is running
if Script.running?("bigshot")
  echo "Bigshot is running"
end

# Get list of running scripts
Script.running.each do |s|
  echo "Running: #{s.name}"
end
```

### Script Lifecycle

```ruby
# Run code when script exits
before_dying {
  echo "Script is ending!"
  fput "stand" if !standing?
}

# Clear exit handlers
undo_before_dying

# Hide script from ;running list
hide_me

# Prevent script from being killed by ;kill all
no_kill_all

# Prevent script from being paused by ;pause all
no_pause_all
```

## Script Variables

```ruby
# Access script arguments (note: capital S!)
Script.current.vars[0]    # All arguments as single string
Script.current.vars[1]    # First argument
Script.current.vars[2]    # Second argument

# Example: script called with ";myscript foo bar"
# Script.current.vars[0] => "foo bar"
# Script.current.vars[1] => "foo"
# Script.current.vars[2] => "bar"

# Check for specific arguments
if Script.current.vars[1] == "--debug"
  echo "Debug mode enabled"
end

# Common pattern using variable
args = Script.current.vars
if args[1] == "help"
  echo "Usage: ;myscript <target>"
  exit
end
```

## Pattern Matching

### Using Regex

```ruby
# Simple match
if line =~ /gold coins/
  echo "Found gold!"
end

# Capture groups
if line =~ /You have (\d+) gold coins/
  gold = $1.to_i
  echo "You have #{gold} gold"
end

# Match multiple patterns
attack_patterns = /attacks you|swings at you|hurls .* at you/
if line =~ attack_patterns
  echo "Incoming attack!"
end
```

### dothistimeout

```ruby
# Send command and wait for specific response
result = dothistimeout "open backpack", 5, /You open|already open|can't open/

case result
when /You open/
  echo "Opened successfully"
when /already open/
  echo "Was already open"
when /can't open/
  echo "Failed to open"
when nil
  echo "Timed out"
end
```

## Common Patterns

### Safe Command Execution

```ruby
def safe_move(direction)
  result = dothistimeout "go #{direction}", 3, /^Obvious|^You can't go/
  if result =~ /can't go/
    echo "Cannot go #{direction}"
    return false
  end
  true
end
```

### Retry Logic

```ruby
def try_action(max_attempts = 3)
  attempts = 0
  loop do
    attempts += 1
    result = dothistimeout "myaction", 5, /success|fail/

    return true if result =~ /success/

    if attempts >= max_attempts
      echo "Failed after #{max_attempts} attempts"
      return false
    end

    sleep 1
  end
end
```

### Waiting for Conditions

```ruby
# Wait until a condition is true
wait_until { Char.mana >= 50 }

# Wait until with timeout
wait_until(timeout: 30) { Char.health >= Char.max_health }
```

## Best Practices

1. **Use waitrt?** - Always wait for roundtime before actions
2. **Handle failures** - Check return values and handle errors
3. **Use timeouts** - Never wait forever; use `dothistimeout`
4. **Clean up** - Use `before_dying` to clean up on exit
5. **Be resource-friendly** - Add small sleeps in tight loops
6. **Log important events** - Use `echo` to help with debugging
7. **Case matters** - Ruby is case-sensitive: `Script` not `script`

## Debugging

```ruby
# Toggle echo to see script output
toggle_echo   # Toggles between on/off
echo_on       # Turn echo on
echo_off      # Turn echo off

# Print debug information
echo "DEBUG: Current room = #{Room.current.id}"
echo "DEBUG: Health = #{Char.health}/#{Char.max_health}"

# Silence script output
silence_me
```

## See Also

- {Lich::Common::Char} - Character information
- {Lich::Gemstone::Stats} - Character statistics
- {Lich::Gemstone::Skills} - Character skills
- {Lich::Common::Spell} - Spell management
- {Lich::Common::Map} - Map and navigation
