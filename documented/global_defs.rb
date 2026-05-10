
# Lich module containing common functionality for scripts.
#
# @see Lich::Common for shared constants and methods.
module Lich
  module Common
    CORE_GET_SETTINGS = true
    CORE_SCRIPT_LOADER = true
    CORE_PARSE_ARGS = true
    CORE_AUTOSTART = true
  end
end


# Starts a script with the given name and optional command line variables.
#
# @param script_name [String] the name of the script to start
# @param cli_vars [Array<String>] command line variables to pass to the script
# @param flags [Hash] additional flags for script execution
# @return [void]
def start_script(script_name, cli_vars = [], flags = Hash.new)
  if flags == true
    flags = { :quiet => true }
  end
  Script.start(script_name, cli_vars.join(' '), flags)
end

# Starts multiple scripts in sequence.
#
# @param script_names [Array<String>] names of scripts to start
# @return [void]
def start_scripts(*script_names)
  script_names.flatten.each { |script_name|
    start_script(script_name)
    sleep 0.02
  }
end

# Forces the start of a script, even if it is already running.
#
# @param script_name [String] the name of the script to force start
# @param cli_vars [Array<String>] command line variables to pass to the script
# @param flags [Hash] additional flags for script execution
# @return [void]
def force_start_script(script_name, cli_vars = [], flags = {})
  flags = Hash.new unless flags.is_a?(Hash)
  flags[:force] = true
  start_script(script_name, cli_vars, flags)
end

# Starts scripts only if they are available and not already running.
#
# @param script_names [Array<String>] names of scripts to start
# @return [void]
def start_scripts_if_available(script_names)
  script_names = [script_names].flatten.compact
  return if script_names.empty?

  script_names.each do |script_name|
    next if Script.running?(script_name)
    next unless Script.exists?(script_name)

    start_script(script_name)
    pause 0.05
    snapshot = Time.now
    until !Script.running?(script_name) || Time.now - snapshot > 0.25
      pause 0.05
    end
  end
end

# Retrieves settings for the character based on suffixes.
#
# @param character_suffixes [Array<String>] suffixes to filter settings
# @return [OpenStruct] settings for the character
def get_settings(character_suffixes = [])
  $setupfiles ||= Lich::Common::SetupFiles.new
  $setupfiles.get_settings(character_suffixes)
end

# Retrieves data of a specified type.
#
# @param type [String] the type of data to retrieve
# @return [OpenStruct] the requested data
def get_data(type)
  $setupfiles ||= Lich::Common::SetupFiles.new
  $setupfiles.get_data(type)
end

# Parses command line arguments based on a definition.
#
# @param defn [String] the argument definition
# @param flex_args [Boolean] whether to allow flexible arguments
# @return [Hash] parsed arguments
def parse_args(defn, flex_args = false)
  Lich::Common::ArgParser.new.parse_args(defn, flex_args)
end

# Displays the arguments based on a definition.
#
# @param defn [String] the argument definition
# @return [void]
def display_args(defn)
  Lich::Common::ArgParser.new.display_args(defn)
end

# Registers a block of code to run before the script exits.
#
# @yield code to execute before dying
# @return [void]
def before_dying(&code)
  Script.at_exit(&code)
end

# Removes any previously registered exit procedures.
# @return [void]
def undo_before_dying
  Script.clear_exit_procs
end

# Aborts the current script execution.
# @return [void]
def abort!
  Script.exit!
end

# Stops a running script by name.
#
# @param target_names [Array<String>] names of scripts to stop
# @return [Integer, false] number of scripts killed or false if none were killed
def stop_script(*target_names)
  numkilled = 0
  target_names.each { |target_name|
    condemned = Script.list.find { |s_sock| s_sock.name =~ /^#{target_name}/i }
    if condemned.nil?
      respond("--- Lich: '#{Script.current}' tried to stop '#{target_name}', but it isn't running!")
    else
      if condemned.name =~ /^#{Script.current.name}$/i
        exit
      end
      condemned.kill
      respond("--- Lich: '#{condemned}' has been stopped by #{Script.current}.")
      numkilled += 1
    end
  }
  if numkilled == 0
    return false
  else
    return numkilled
  end
end

# Checks if specified scripts are currently running.
#
# @param snames [Array<String>] names of scripts to check
# @return [Boolean] true if all specified scripts are running
def running?(*snames)
  snames.each { |checking| (return false) unless (Script.running.find { |lscr| lscr.name =~ /^#{checking}$/i } || Script.running.find { |lscr| lscr.name =~ /^#{checking}/i } || Script.hidden.find { |lscr| lscr.name =~ /^#{checking}$/i } || Script.hidden.find { |lscr| lscr.name =~ /^#{checking}/i }) }
  true
end

# Starts an execution script with given command data.
#
# @param cmd_data [String] command data to execute
# @param options [Hash] options for execution
# @return [void]
def start_exec_script(cmd_data, options = Hash.new)
  ExecScript.start(cmd_data, options)
end

# Toggles the visibility of the current script.
# @return [void]
def hide_me
  Script.current.hidden = !Script.current.hidden
end

# Toggles the no-kill-all setting for the current script.
# @return [void]
def no_kill_all
  script = Script.current
  script.no_kill_all = !script.no_kill_all
end

# Toggles the no-pause-all setting for the current script.
# @return [void]
def no_pause_all
  script = Script.current
  script.no_pause_all = !script.no_pause_all
end

# Toggles the upstream listening setting for the current script.
# @return [void]
def toggle_upstream
  unless (script = Script.current) then echo 'toggle_upstream: cannot identify calling script.'; return nil; end
  script.want_upstream = !script.want_upstream
end

# Toggles the silence setting for the current script.
# @return [void]
def silence_me
  unless (script = Script.current) then echo 'silence_me: cannot identify calling script.'; return nil; end
  if script.safe? then echo("WARNING: 'safe' script attempted to silence itself.  Ignoring the request.")
                       sleep 1
                       return true
  end
  script.silent = !script.silent
end

# Toggles the echo setting for the current script.
# @return [void]
def toggle_echo
  unless (script = Script.current) then respond('--- toggle_echo: Unable to identify calling script.'); return nil; end
  script.no_echo = !script.no_echo
end

# Turns on the echo setting for the current script.
# @return [void]
def echo_on
  unless (script = Script.current) then respond('--- echo_on: Unable to identify calling script.'); return nil; end
  script.no_echo = false
end

# Turns off the echo setting for the current script.
# @return [void]
def echo_off
  unless (script = Script.current) then respond('--- echo_off: Unable to identify calling script.'); return nil; end
  script.no_echo = true
end

# Retrieves data from the upstream for the current script.
# @return [String, nil] data received from upstream or nil if none
def upstream_get
  unless (script = Script.current) then echo 'upstream_get: cannot identify calling script.'; return nil; end
  unless script.want_upstream
    echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)")
    sleep 0.3
    return false
  end
  script.upstream_gets
end

# Checks if there is data available from the upstream for the current script.
# @return [Boolean] true if data is available
def upstream_get?
  unless (script = Script.current) then echo 'upstream_get: cannot identify calling script.'; return nil; end
  unless script.want_upstream
    echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)")
    return false
  end
  script.upstream_gets?
end

# Sends a message to the script's output.
#
# @param messages [Array<String>] messages to send
# @return [void]
def echo(*messages)
  respond if messages.empty?
  if (script = Script.current)
    unless script.no_echo
      messages.each { |message| respond("[#{script.custom? ? 'custom/' : ''}#{script.name}: #{message.to_s.chomp}]") }
    end
  else
    messages.each { |message| respond("[(unknown script): #{message.to_s.chomp}]") }
  end
  nil
end

# Sends a message to the script's output without formatting.
#
# @param messages [Array<String>] messages to send
# @return [void]
def _echo(*messages)
  _respond if messages.empty?
  if (script = Script.current)
    unless script.no_echo
      messages.each { |message| _respond("[#{script.custom? ? 'custom/' : ''}#{script.name}: #{message.to_s.chomp}]") }
    end
  else
    messages.each { |message| _respond("[(unknown script): #{message.to_s.chomp}]") }
  end
  nil
end

# Jumps to a specified label in the current script.
#
# @param label [String] the label to jump to
# @return [void]
def goto(label)
  Script.current.jump_label = label.to_s
  raise Lich::Common::Script::JUMP
end

# Pauses the specified scripts.
#
# @param names [Array<String>] names of scripts to pause
# @return [void]
def pause_script(*names)
  names.flatten!
  if names.empty?
    Script.current.pause
    Script.current
  else
    names.each { |scr|
      fnd = Script.list.find { |nm| nm.name =~ /^#{scr}/i }
      fnd.pause unless (fnd.paused || fnd.nil?)
    }
  end
end

# Unpauses the specified scripts.
#
# @param names [Array<String>] names of scripts to unpause
# @return [void]
def unpause_script(*names)
  names.flatten!
  names.each { |scr|
    fnd = Script.list.find { |nm| nm.name =~ /^#{scr}/i }
    fnd.unpause if (fnd.paused and not fnd.nil?)
  }
end

# Ensures the injury mode is set correctly.
# @return [void]
def fix_injury_mode
  unless XMLData.injury_mode == 2
    Game._puts '_injury 2'
    150.times { sleep 0.05; break if XMLData.injury_mode == 2 }
  end
end

# Toggles the visibility of specified scripts.
#
# @param args [Array<String>] names of scripts to hide
# @return [void]
def hide_script(*args)
  args.flatten!
  args.each { |name|
    if (script = Script.running.find { |scr| scr.name == name })
      script.hidden = !script.hidden
    end
  }
end

# Parses a string into a list format.
#
# @param string [String] the string to parse
# @return [Array<String>] parsed list
def parse_list(string)
  string.split_as_list
end

# Waits for roundtime to complete.
# @return [void]
def waitrt
  wait_until { (XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f) > 0 }
  sleep checkrt
end

# Waits for casting roundtime to complete.
# @return [void]
def waitcastrt
  wait_until { (XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f) > 0 }
  sleep checkcastrt
end

# Checks the current roundtime.
# @return [Integer] current roundtime value
def checkrt
  [0, XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f].max
end

# Checks the current casting roundtime.
# @return [Integer] current casting roundtime value
def checkcastrt
  [0, XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f].max
end

# Checks if there is roundtime and waits if necessary.
# @return [Boolean] true if waiting was necessary
def waitrt?
  sleep checkrt
  return true if checkrt > 0.0
  return false if checkrt == 0
end

# Checks if there is casting roundtime and waits if necessary.
# @return [Boolean] true if waiting was necessary
def waitcastrt?
  #  sleep checkcastrt
  current_castrt = checkcastrt
  if current_castrt.to_f > 0.0
    sleep(current_castrt)
    return true
  else
    return false
  end
end

# Checks if the character is poisoned.
# @return [Boolean] true if poisoned
def checkpoison
  XMLData.indicator['IconPOISONED'] == 'y'
end

# Checks if the character is diseased.
# @return [Boolean] true if diseased
def checkdisease
  XMLData.indicator['IconDISEASED'] == 'y'
end

# Checks if the character is sitting.
# @return [Boolean] true if sitting
def checksitting
  XMLData.indicator['IconSITTING'] == 'y'
end

# Checks if the character is kneeling.
# @return [Boolean] true if kneeling
def checkkneeling
  XMLData.indicator['IconKNEELING'] == 'y'
end

# Checks if the character is stunned.
# @return [Boolean] true if stunned
def checkstunned
  XMLData.indicator['IconSTUNNED'] == 'y'
end

# Checks if the character is bleeding.
# @return [Boolean] true if bleeding
def checkbleeding
  XMLData.indicator['IconBLEEDING'] == 'y'
end

# Checks if the character is grouped.
# @return [Boolean] true if grouped
def checkgrouped
  XMLData.indicator['IconJOINED'] == 'y'
end

# Checks if the character is dead.
# @return [Boolean] true if dead
def checkdead
  XMLData.indicator['IconDEAD'] == 'y'
end

# Checks if the character is really bleeding (not affected by certain spells).
# @return [Boolean] true if really bleeding
def checkreallybleeding
  checkbleeding and !(Spell[9909].active? or Spell[9905].active?)
end

# Checks if the character is muckled.
# @return [Boolean] true if muckled
def muckled?
  # need a better DR solution
  if XMLData.game =~ /GS/
    return Status.muckled?
  else
    return checkdead || checkstunned || checkwebbed
  end
end

# Checks if the character is hidden.
# @return [Boolean] true if hidden
def checkhidden
  XMLData.indicator['IconHIDDEN'] == 'y'
end

# Checks if the character is invisible.
# @return [Boolean] true if invisible
def checkinvisible
  XMLData.indicator['IconINVISIBLE'] == 'y'
end

# Checks if the character is webbed.
# @return [Boolean] true if webbed
def checkwebbed
  XMLData.indicator['IconWEBBED'] == 'y'
end

# Checks if the character is prone.
# @return [Boolean] true if prone
def checkprone
  XMLData.indicator['IconPRONE'] == 'y'
end

# Checks if the character is not standing.
# @return [Boolean] true if not standing
def checknotstanding
  XMLData.indicator['IconSTANDING'] == 'n'
end

# Checks if the character is standing.
# @return [Boolean] true if standing
def checkstanding
  XMLData.indicator['IconSTANDING'] == 'y'
end

# Checks if the character's name matches any of the provided strings.
#
# @param strings [Array<String>] names to check against
# @return [Boolean, String] true if a match is found, or the character's name if no parameters are provided
def checkname(*strings)
  strings.flatten!
  if strings.empty?
    XMLData.name
  else
    XMLData.name =~ /^(?:#{strings.join('|')})/i
  end
end

# Checks the loot available to the character.
# @return [Array<String>] list of loot items
def checkloot
  GameObj.loot.collect { |item| item.noun }
end

# Toggles the stand-alone status of the current script.
# @return [Boolean] true if the script stands alone
def i_stand_alone
  unless (script = Script.current) then echo 'i_stand_alone: cannot identify calling script.'; return nil; end
  script.want_downstream = !script.want_downstream
  return !script.want_downstream
end

# Outputs debug information if debugging is enabled.
#
# @param args [Array] arguments to output
# @return [void]
def debug(*args)
  if $LICH_DEBUG
    if block_given?
      yield(*args)
    else
      echo(*args)
    end
  end
end

# Tests the execution time of provided code blocks.
#
# @param contestants [Array<Proc>] code blocks to test
# @return [Array<Float>] execution times for each block
def timetest(*contestants)
  contestants.collect { |code| start = Time.now; 5000.times { code.call }; Time.now - start }
end

# Converts a decimal number to binary string representation.
#
# @param n [Integer] the decimal number to convert
# @return [String] binary representation of the number
def dec2bin(n)
  "0" + [n].pack("N").unpack("B32")[0].sub(/^0+(?=\d)/, '')
end

# Converts a binary string representation to a decimal number.
#
# @param n [String] the binary string to convert
# @return [Integer] decimal representation of the number
def bin2dec(n)
  [("0" * 32 + n.to_s)[-32..-1]].pack("B32").unpack("N")[0]
end

# Checks if the character has been idle for a specified time.
#
# @param time [Integer] the idle time threshold
# @return [Boolean] true if idle
def idle?(time = 60)
  Time.now - $_IDLETIMESTAMP_ >= time
end

# Sends a command to the game and waits for a response matching success or failure patterns.
#
# @param string [String] command to send
# @param success [Array<String>] patterns for successful responses
# @param failure [Array<String>] patterns for failure responses
# @param timeout [Integer, nil] optional timeout for the operation
# @return [String, nil] response from the game or nil on timeout
def selectput(string, success, failure, timeout = nil)
  timeout = timeout.to_f if timeout and !timeout.kind_of?(Numeric)
  success = [success] if success.kind_of? String
  failure = [failure] if failure.kind_of? String
  if !string.kind_of?(String) or !success.kind_of?(Array) or !failure.kind_of?(Array) or timeout && !timeout.kind_of?(Numeric)
    raise ArgumentError, "usage is: selectput(game_command,success_array,failure_array[,timeout_in_secs])"
  end

  success.flatten!
  failure.flatten!
  regex = /#{(success + failure).join('|')}/i
  successre = /#{success.join('|')}/i
  thr = Thread.current

  timethr = Thread.new {
    timeout -= sleep("0.1".to_f) until timeout <= 0
    thr.raise(StandardError)
  } if timeout

  begin
    loop {
      fput(string)
      response = waitforre(regex)
      if successre.match(response.to_s)
        timethr.kill if timethr.alive?
        break(response.string)
      end
      yield(response.string) if block_given?
    }
  rescue
    nil
  end
end

# Toggles the unique setting for the current script.
# @return [void]
def toggle_unique
  unless (script = Script.current) then echo 'toggle_unique: cannot identify calling script.'; return nil; end
  script.want_downstream = !script.want_downstream
end

# Registers scripts to die when the current script dies.
#
# @param vals [Array<String>] names of scripts to register
# @return [void]
def die_with_me(*vals)
  unless (script = Script.current) then echo 'die_with_me: cannot identify calling script.'; return nil; end
  script.die_with.push vals
  script.die_with.flatten!
  echo("The following script(s) will now die when I do: #{script.die_with.join(', ')}") unless script.die_with.empty?
end

# Waits for a line from the upstream that matches specified strings.
#
# @param strings [Array<String>] strings to match
# @return [String, nil] matching line or nil if none found
def upstream_waitfor(*strings)
  strings.flatten!
  script = Script.current
  unless script.want_upstream then echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)"); return false end
  regexpstr = strings.join('|')
  while (line = script.upstream_gets)
    if line =~ /#{regexpstr}/i
      return line
    end
  end
end

# Sends values to a specified script.
#
# @param values [Array<String>] values to send
# @return [Boolean] true if successful, false otherwise
def send_to_script(*values)
  values.flatten!
  if (script = Script.list.find { |val| val.name =~ /^#{values.first}/i })
    if script.want_downstream
      values[1..-1].each { |val| script.downstream_buffer.push(val) }
    else
      values[1..-1].each { |val| script.unique_buffer.push(val) }
    end
    echo("Sent to #{script.name} -- '#{values[1..-1].join(' ; ')}'")
    return true
  else
    echo("'#{values.first}' does not match any active scripts!")
    return false
  end
end

# Sends unique values to a specified script.
#
# @param values [Array<String>] values to send
# @return [Boolean] true if successful, false otherwise
def unique_send_to_script(*values)
  values.flatten!
  if (script = Script.list.find { |val| val.name =~ /^#{values.first}/i })
    values[1..-1].each { |val| script.unique_buffer.push(val) }
    echo("sent to #{script}: #{values[1..-1].join(' ; ')}")
    return true
  else
    echo("'#{values.first}' does not match any active scripts!")
    return false
  end
end

# Waits for a unique line from the current script that matches specified strings.
#
# @param strings [Array<String>] strings to match
# @return [String] matching line
def unique_waitfor(*strings)
  unless (script = Script.current) then echo 'unique_waitfor: cannot identify calling script.'; return nil; end
  strings.flatten!
  regexp = /#{strings.join('|')}/
  while true
    str = script.unique_gets
    if str =~ regexp
      return str
    end
  end
end

# Retrieves a unique line from the current script.
# @return [String] the unique line retrieved
def unique_get
  unless (script = Script.current) then echo 'unique_get: cannot identify calling script.'; return nil; end
  script.unique_gets
end

# Checks if there is a unique line available from the current script.
# @return [Boolean] true if a unique line is available
def unique_get?
  unless (script = Script.current) then echo 'unique_get: cannot identify calling script.'; return nil; end
  script.unique_gets?
end

# Moves in multiple directions sequentially.
#
# @param dirs [Array<String>] directions to move
# @return [void]
def multimove(*dirs)
  dirs.flatten.each { |dir| move(dir) }
end

# Returns the string representation of the direction 'north'.
# @return [String] 'north'
def n;    'north';     end

# Returns the string representation of the direction 'northeast'.
# @return [String] 'northeast'
def ne;   'northeast'; end

# Returns the string representation of the direction 'east'.
# @return [String] 'east'
def e;    'east';      end

# Returns the string representation of the direction 'southeast'.
# @return [String] 'southeast'
def se;   'southeast'; end

# Returns the string representation of the direction 'south'.
# @return [String] 'south'
def s;    'south';     end

# Returns the string representation of the direction 'southwest'.
# @return [String] 'southwest'
def sw;   'southwest'; end

# Returns the string representation of the direction 'west'.
# @return [String] 'west'
def w;    'west';      end

# Returns the string representation of the direction 'northwest'.
# @return [String] 'northwest'
def nw;   'northwest'; end

# Returns the string representation of the direction 'up'.
# @return [String] 'up'
def u;    'up';        end

# Returns the string representation of the direction 'up'.
# @return [String] 'up'
def up;   'up'; end

# Returns the string representation of the direction 'down'.
# @return [String] 'down'
def down; 'down';      end

# Returns the string representation of the direction 'down'.
# @return [String] 'down'
def d;    'down';      end

# Returns the string representation of the direction 'out'.
# @return [String] 'out'
def o;    'out';       end

# Returns the string representation of the direction 'out'.
# @return [String] 'out'
def out;  'out';       end

# Moves the character in the specified direction.
#
# @param dir [String] direction to move
# @param giveup_seconds [Integer] seconds to wait before giving up
# @param giveup_lines [Integer] number of lines to wait before giving up
# @return [Boolean] true if the move was successful, false otherwise
def move(dir = 'none', giveup_seconds = 10, giveup_lines = 30)
  # [LNet]-[Private]-Casis: "You begin to make your way up the steep headland pathway.  Before traveling very far, however, you lose your footing on the loose stones.  You struggle in vain to maintain your balance, then find yourself falling to the bay below!"  (20:35:36)
  # [LNet]-[Private]-Casis: "You smack into the water with a splash and sink far below the surface."  (20:35:50)
  # You approach the entrance and identify yourself to the guard.  The guard checks over a long scroll of names and says, "I'm sorry, the Guild is open to invitees only.  Please do return at a later date when we will be open to the public."
  if dir == 'none'
    echo 'move: no direction given'
    return false
  end

  need_full_hands = false
  tried_open = false
  tried_fix_drag = false
  line_count = 0
  room_count = XMLData.room_count
  giveup_time = Time.now.to_i + giveup_seconds.to_i
  save_stream = Array.new

  put_dir = proc {
    if XMLData.room_count > room_count
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return true
    end
    waitrt?
    wait_while { stunned? }
    giveup_time = Time.now.to_i + giveup_seconds.to_i
    line_count = 0
    save_stream.push(clear)
    put dir
  }

  put_dir.call

  loop {
    line = get?
    unless line.nil?
      save_stream.push(line)
      line_count += 1
    end
    if line.nil?
      sleep 0.1
    elsif line =~ /^You realize that would be next to impossible while in combat.|^You can't do that while engaged!|^You are engaged to |^You need to retreat out of combat first!|^You try to move, but you're engaged|^While in combat\?  You'll have better luck if you first retreat/
      # DragonRealms
      fput 'retreat'
      fput 'retreat'
      put_dir.call
    elsif line =~ /^You can't enter .+ and remain hidden or invisible\.|if he can't see you!$|^You can't enter .+ when you can't be seen\.$|^You can't do that without being seen\.$|^How do you intend to get .*? attention\?  After all, no one can see you right now\.$/
      fput 'unhide'
      put_dir.call
    elsif (line =~ /^You (?:take a few steps toward|trudge up to|limp towards|march up to|sashay gracefully up to|skip happily towards|sneak up to|stumble toward) a rusty doorknob/) and (dir =~ /door/)
      which = ['first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eight', 'ninth', 'tenth', 'eleventh', 'twelfth']
      # avoid stomping the room for the entire session due to a transient failure
      dir = dir.to_s
      if dir =~ /\b#{which.join('|')}\b/
        dir.sub!(/\b(#{which.join('|')})\b/) { "#{which[which.index($1) + 1]}" }
      else
        dir.sub!('door', 'second door')
      end
      put_dir.call
    elsif line =~ /^You can't go there|^You can't (?:go|swim) in that direction\.|^Where are you trying to go\?|^What were you referring to\?|^I could not find what you were referring to\.|^How do you plan to do that here\?|^You take a few steps towards|^You cannot do that\.|^You settle yourself on|^You shouldn't annoy|^You can't go to|^That's probably not a very good idea|^Maybe you should look|^You are already(?! as far away as you can get)|^You walk over to|^You step over to|The [\w\s]+ is too far away|You may not pass\.|become impassable\.|prevents you from entering\.|Please leave promptly\.|is too far above you to attempt that\.$|^Uh, yeah\.  Right\.$|^Definitely NOT a good idea\.$|^Your attempt fails|^There doesn't seem to be any way to do that at the moment\.$/
      echo 'move: failed'
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return false
    elsif line =~ /^[A-z\s-] is unable to follow you\.$|^An unseen force prevents you\.$|^Sorry, you aren't allowed to enter here\.|^That looks like someplace only performers should go\.|^As you climb, your grip gives way and you fall down|^The clerk stops you from entering the partition and says, "I'll need to see your ticket!"$|^The guard stops you, saying, "Only members of registered groups may enter the Meeting Hall\.  If you'd like to visit, ask a group officer for a guest pass\."$|^An? .*? reaches over and grasps [A-Z][a-z]+ by the neck preventing (?:him|her) from being dragged anywhere\.$|^You'll have to wait, [A-Z][a-z]+ .* locker|^As you move toward the gate, you carelessly bump into the guard|^You attempt to enter the back of the shop, but a clerk stops you.  "Your reputation precedes you!|you notice that thick beams are placed across the entry with a small sign that reads, "Abandoned\."$|appears to be closed, perhaps you should try again later\?$/
      echo 'move: failed'
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      # return nil instead of false to show the direction shouldn't be removed from the map database
      return nil
    elsif line =~ /^You grab [A-Z][a-z]+ and try to drag h(?:im|er), but s?he (?:is too heavy|doesn't budge)\.$|^Tentatively, you attempt to swim through the nook\.  After only a few feet, you begin to sink!  Your lungs burn from lack of air, and you begin to panic!  You frantically paddle back to safety!$|^Guards(?:wo)?man [A-Z][a-z]+ stops you and says, "(?:Stop\.|Halt!)  You need to make sure you check in|^You step into the root, but can see no way to climb the slippery tendrils inside\.  After a moment, you step back out\.$|^As you start .*? back to safe ground\.$|^You stumble a bit as you try to enter the pool but feel that your persistence will pay off\.$|^A shimmering field of magical crimson and gold energy flows through the area\.$|^You attempt to navigate your way through the fog, but (?:quickly become entangled|get turned around)|^Trying to judge the climb, you peer over the edge\.\s*A wave of dizziness hits you, and you back away from the .*\.$|^You approach the .*, but the steepness is intimidating\.$|^You make your way (?:up|down) the .*\.\s*Partway (?:up|down), you make the mistake of looking down\. Struck by vertigo, you cling to the .* for a few moments, then slowly climb back (?:up|down)\.$|^You pick your way up the .*, but reach a point where your footing is questionable.\s*Reluctantly, you climb back down.$/
      sleep 1
      waitrt?
      put_dir.call
    elsif line =~ /^Climbing.*(?:plunge|fall)|^Tentatively, you attempt to climb.*(?:fall|slip)|^You start up the .* but slip after a few feet and fall to the ground|^You start.*but quickly realize|^You.*drop back to the ground|^You leap .* fall unceremoniously to the ground in a heap\.$|^You search for a way to make the climb .*? but without success\.$|^You start to climb .* you fall to the ground|^You attempt to climb .* wrong approach|^You run towards .*? slowly retreat back, reassessing the situation\.|^You attempt to climb down the .*, but you can't seem to find purchase\.|^You start down the .*, but you find it hard going.\s*Rather than risking a fall, you make your way back up\./
      sleep 1
      waitrt?
      fput 'stand' unless standing?
      waitrt?
      put_dir.call
    elsif line =~ /^(?:You swim .*, (?:cutting through|navigating)|You swim .*, struggling against|Your lungs burn and your muscles ache)/
      # swims in Sailor's Grief
      return true
    elsif line =~ /^You begin to climb up the silvery thread.* you tumble to the ground/
      sleep 0.5
      waitrt?
      fput 'stand' unless standing?
      waitrt?
      if checkleft or checkright
        need_full_hands = true
        empty_hands
      end
      put_dir.call
    elsif line == 'You are too injured to be doing any climbing!'
      if (resolve = Spell[9704]) and resolve.known?
        wait_until { resolve.affordable? }
        resolve.cast
        put_dir.call
      else
        return nil
      end
    elsif line =~ /^You(?:'re going to| will) have to climb that\./
      dir.gsub!('go', 'climb')
      put_dir.call
    elsif line =~ /^You can't climb that\./
      dir.gsub!('climb', 'go')
      put_dir.call
    elsif line =~ /^You can't drag/
      if tried_fix_drag
        fill_hands if need_full_hands
        Script.current.downstream_buffer.unshift(save_stream)
        Script.current.downstream_buffer.flatten!
        return false
      elsif (dir =~ /^(?:go|climb) .+$/) and (drag_line = reget.reverse.find { |l| l =~ /^You grab .*?(?:'s body)? and drag|^You are now automatically attempting to drag .*? when/ })
        tried_fix_drag = true
        name = (/^You grab (.*?)('s body)? and drag/.match(drag_line).captures.first || /^You are now automatically attempting to drag (.*?) when/.match(drag_line).captures.first)
        target = /^(?:go|climb) (.+)$/.match(dir).captures.first
        fput "drag #{name}"
        dir = "drag #{name} #{target}"
        put_dir.call
      else
        tried_fix_drag = true
        dir.sub!(/^climb /, 'go ')
        put_dir.call
      end
    elsif line =~ /^Maybe if your hands were empty|^You figure freeing up both hands might help\.|^You can't .+ with your hands full\.$|^You'll need empty hands to climb that\.$|^It's a bit too difficult to swim holding|^You will need both hands free for such a difficult task\./
      need_full_hands = true
      empty_hands
      put_dir.call
    elsif line =~ /(?:appears|seems) to be closed\.$|^You cannot quite manage to squeeze between the stone doors\.$/
      if tried_open
        fill_hands if need_full_hands
        Script.current.downstream_buffer.unshift(save_stream)
        Script.current.downstream_buffer.flatten!
        return false
      else
        tried_open = true
        fput dir.sub(/go|climb/, 'open')
        put_dir.call
      end
    elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
      if $2.to_i > 1
        sleep($2.to_i - "0.2".to_f)
      else
        sleep 0.3
      end
      put_dir.call
    elsif line =~ /will have to stand up first|must be standing first|^You'll have to get up first|^But you're already sitting!|^Shouldn't you be standing first|^That would be quite a trick from that position\.  Try standing up\.|^Perhaps you should stand up|^Standing up might help|^You should really stand up first|You can't do that while sitting|You must be standing to do that|You can't do that while lying down|^You must be standing/
      fput 'stand'
      waitrt?
      put_dir.call
    elsif line =~ /^You're still recovering from your recent/
      sleep 2
      put_dir.call
    elsif line =~ /^The ground approaches you at an alarming rate/
      sleep 1
      fput 'stand' unless standing?
      put_dir.call
    elsif line =~ /You go flying down several feet, landing with a/
      sleep 1
      fput 'stand' unless standing?
      put_dir.call
    elsif line =~ /^Sorry, you may only type ahead/
      sleep 1
      put_dir.call
    elsif line == 'You are still stunned.'
      wait_while { stunned? }
      put_dir.call
    elsif line =~ /you slip (?:on a patch of ice )?and flail uselessly as you land on your rear(?:\.|!)$|You wobble and stumble only for a moment before landing flat on your face!$|^You slip in the mud and fall flat on your back\!$/
      waitrt?
      fput 'stand' unless standing?
      waitrt?
      put_dir.call
    elsif line =~ /^You flick your hand (?:up|down)wards and focus your aura on your disk, but your disk only wobbles briefly\.$/
      put_dir.call
    elsif line =~ /^You dive into the fast-moving river, but the current catches you and whips you back to shore, wet and battered\.$|^Running through the swampy terrain, you notice a wet patch in the bog|^You flounder around in the water.$|^You blunder around in the water, barely able|^You struggle against the swift current to swim|^You slap at the water in a sad failure to swim|^You work against the swift current to swim/
      waitrt?
      put_dir.call
    elsif line =~ /^(You notice .* at your feet, and do not wish to leave it behind|As you prepare to move away, you remember)/
      fput "stow feet"
      sleep 1
      put_dir.call
    elsif line =~ /The electricity courses through you in a raging torrent, its power singing in your veins!  Spent, the boltstone apparatus shatters into glinting fragments\.|The lightning strikes you in an agonizing eruption of liquid radiance!/
      sleep(0.5)
      wait_while { stunned? }
      waitrt?
      fput 'stand' unless standing?
      waitrt?
      put_dir.call
    elsif line == "You don't seem to be able to move to do that."
      30.times {
        break if clear.include?('You regain control of your senses!')

        sleep 0.1
      }
      put_dir.call
    elsif line =~ /^It's pitch dark and you can't see a thing!/
      echo "You will need a light source to continue your journey"
      return true
    end
    if XMLData.room_count > room_count
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return true
    end
    if Time.now.to_i >= giveup_time
      echo "move: no recognized response in #{giveup_seconds} seconds.  giving up."
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return nil
    end
    if line_count >= giveup_lines
      echo "move: no recognized response after #{line_count} lines.  giving up."
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return nil
    end
  }
end

# Monitors the character's health and executes a block when health drops below a threshold.
#
# @param value [Integer] health threshold to monitor
# @param theproc [Proc, nil] optional procedure to execute
# @yield code to execute when health drops below the threshold
# @return [void]
def watchhealth(value, theproc = nil, &block)
  value = value.to_i
  if block.nil?
    if !theproc.respond_to? :call
      respond "`watchhealth' was not given a block or a proc to execute!"
      return nil
    else
      block = theproc
    end
  end
  Thread.new {
    wait_while { health(value) }
    block.call
  }
end

# Waits until a condition is met, optionally announcing the wait.
#
# @param announce [String, nil] optional message to announce
# @yield condition to check
# @return [void]
def wait_until(announce = nil)
  priosave = Thread.current.priority
  Thread.current.priority = 0
  unless announce.nil? or yield
    respond(announce)
  end
  until yield
    sleep 0.25
  end
  Thread.current.priority = priosave
end

# Waits while a condition is true, optionally announcing the wait.
#
# @param announce [String, nil] optional message to announce
# @yield condition to check
# @return [void]
def wait_while(announce = nil)
  priosave = Thread.current.priority
  Thread.current.priority = 0
  unless announce.nil? or !yield
    respond(announce)
  end
  while yield
    sleep 0.25
  end
  Thread.current.priority = priosave
end

# Checks available paths in the current room.
#
# @param dir [String] direction to check
# @return [Array<String>, Boolean] list of available paths or false if none
def checkpaths(dir = "none")
  if dir == "none"
    if XMLData.room_exits.empty?
      return false
    else
      return XMLData.room_exits.collect { |room_exits| SHORTDIR[room_exits] }
    end
  else
    XMLData.room_exits.include?(dir) || XMLData.room_exits.include?(SHORTDIR[dir])
  end
end

# Reverses the given direction.
#
# @param dir [String] direction to reverse
# @return [String, false] reversed direction or false if unrecognized
def reverse_direction(dir)
  if dir == "n" then 's'
  elsif dir == "ne" then 'sw'
  elsif dir == "e" then 'w'
  elsif dir == "se" then 'nw'
  elsif dir == "s" then 'n'
  elsif dir == "sw" then 'ne'
  elsif dir == "w" then 'e'
  elsif dir == "nw" then 'se'
  elsif dir == "up" then 'down'
  elsif dir == "down" then 'up'
  elsif dir == "out" then 'out'
  elsif dir == 'o' then out
  elsif dir == 'u' then 'down'
  elsif dir == 'd' then up
  elsif dir == n then s
  elsif dir == ne then sw
  elsif dir == e then w
  elsif dir == se then nw
  elsif dir == s then n
  elsif dir == sw then ne
  elsif dir == w then e
  elsif dir == nw then se
  elsif dir == u then d
  elsif dir == d then u
  else
    echo("Cannot recognize direction to properly reverse it!"); false
  end
end

# Walks in a direction until a condition is met.
#
# @param boundaries [Array<String>] optional boundaries to check
# @yield condition to check
# @return [void]
def walk(*boundaries, &block)
  boundaries.flatten!
  unless block.nil?
    until (val = yield)
      walk(*boundaries)
    end
    return val
  end
  if $last_dir and !boundaries.empty? and checkroomdescrip =~ /#{boundaries.join('|')}/i
    move($last_dir)
    $last_dir = reverse_direction($last_dir)
    return checknpcs
  end
  dirs = checkpaths
  return checknpcs if dirs.is_a?(FalseClass)
  dirs.delete($last_dir) unless dirs.length < 2
  this_time = rand(dirs.length)
  $last_dir = reverse_direction(dirs[this_time])
  move(dirs[this_time])
  checknpcs
end

# Runs the walk method in a loop until stopped.
# @return [void]
def run
  loop { break unless walk }
end

# Checks the character's mental state based on a string or value.
#
# @param string [String, nil] optional string to check against
# @return [Boolean, String] true if a match is found, or the character's mind text if no parameters are provided
def check_mind(string = nil)
  if string.nil?
    return XMLData.mind_text
  elsif (string.is_a?(String)) and (string.to_i == 0)
    if string =~ /#{XMLData.mind_text}/i
      return true
    else
      return false
    end
  elsif string.to_i.between?(0, 100)
    return string.to_i <= XMLData.mind_value.to_i
  else
    echo("check_mind error! You must provide an integer ranging from 0-100, the common abbreviation of how full your head is, or provide no input to have check_mind return an abbreviation of how filled your head is."); sleep 1
    return false
  end
end

# Checks the character's mental state based on a string or value.
#
# @param string [String, nil] optional string to check against
# @return [Boolean, String] true if a match is found, or the character's mind text if no parameters are provided
def checkmind(string = nil)
  if string.nil?
    return XMLData.mind_text
  elsif string.is_a?(String) and string.to_i == 0
    if string =~ /#{XMLData.mind_text}/i
      return true
    else
      return false
    end
  elsif string.to_i.between?(1, 8)
    mind_state = ['clear as a bell', 'fresh and clear', 'clear', 'muddled', 'becoming numbed', 'numbed', 'must rest', 'saturated']
    if mind_state.index(XMLData.mind_text)
      mind = mind_state.index(XMLData.mind_text) + 1
      return string.to_i <= mind
    else
      echo "Bad string in checkmind: mind_state"
      nil
    end
  else
    echo("Checkmind error! You must provide an integer ranging from 1-8 (7 is fried, 8 is 100% fried), the common abbreviation of how full your head is, or provide no input to have checkmind return an abbreviation of how filled your head is."); sleep 1
    return false
  end
end

# Checks the character's mind value against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if mind value is greater than or equal to num
def percentmind(num = nil)
  if num.nil?
    XMLData.mind_value
  else
    XMLData.mind_value >= num.to_i
  end
end

# Checks if the character is fried mentally.
# @return [Boolean] true if fried
def checkfried
  if XMLData.mind_text =~ /must rest|saturated/
    true
  else
    false
  end
end

# Checks if the character is saturated mentally.
# @return [Boolean] true if saturated
def checksaturated
  if XMLData.mind_text =~ /saturated/
    true
  else
    false
  end
end

# Checks the character's mana against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if mana is greater than or equal to num
def checkmana(num = nil)
  Lich.deprecated('checkmana', 'Char.mana')
  if num.nil?
    XMLData.mana
  else
    XMLData.mana >= num.to_i
  end
end

# Retrieves the maximum mana of the character.
# @return [Integer] maximum mana value
def maxmana
  Lich.deprecated('maxmana', 'Char.maxmana')
  XMLData.max_mana
end

# Checks the character's mana percentage against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if mana percentage is greater than or equal to num
def percentmana(num = nil)
  Lich.deprecated('percentmana', 'Char.percent_mana')
  if XMLData.max_mana == 0
    percent = 100
  else
    percent = ((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
  end
  if num.nil?
    percent
  else
    percent >= num.to_i
  end
end

# Checks the character's health against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if health is greater than or equal to num
def checkhealth(num = nil)
  Lich.deprecated('checkhealth', 'Char.health')
  if num.nil?
    XMLData.health
  else
    XMLData.health >= num.to_i
  end
end

# Retrieves the maximum health of the character.
# @return [Integer] maximum health value
def maxhealth
  Lich.deprecated('maxhealth', 'Char.max_health')
  XMLData.max_health
end

# Checks the character's health percentage against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if health percentage is greater than or equal to num
def percenthealth(num = nil)
  Lich.deprecated('percenthealth', 'Char.percent_health')
  if num.nil?
    ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i
  else
    ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i >= num.to_i
  end
end

# Checks the character's spirit against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if spirit is greater than or equal to num
def checkspirit(num = nil)
  Lich.deprecated('checkspirit', 'Char.spirit')
  if num.nil?
    XMLData.spirit
  else
    XMLData.spirit >= num.to_i
  end
end

# Retrieves the maximum spirit of the character.
# @return [Integer] maximum spirit value
def maxspirit
  Lich.deprecated('maxspirit', 'Char.max_spirit')
  XMLData.max_spirit
end

# Checks the character's spirit percentage against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if spirit percentage is greater than or equal to num
def percentspirit(num = nil)
  Lich.deprecated('percentspirit', 'Char.percent_spirit')
  if num.nil?
    ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i
  else
    ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i >= num.to_i
  end
end

# Checks the character's stamina against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if stamina is greater than or equal to num
def checkstamina(num = nil)
  Lich.deprecated('checkstamina', 'Char.stamina')
  if num.nil?
    XMLData.stamina
  else
    XMLData.stamina >= num.to_i
  end
end

# Retrieves the maximum stamina of the character.
# @return [Integer] maximum stamina value
def maxstamina()
  Lich.deprecated('maxstamina', 'Char.max_stamina')
  XMLData.max_stamina
end

# Checks the character's stamina percentage against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if stamina percentage is greater than or equal to num
def percentstamina(num = nil)
  Lich.deprecated('percentstamina', 'Char.percent_stamina')
  if XMLData.max_stamina == 0
    percent = 100
  else
    percent = ((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
  end
  if num.nil?
    percent
  else
    percent >= num.to_i
  end
end

# Retrieves the maximum concentration of the character.
# @return [Integer] maximum concentration value
def maxconcentration()
  XMLData.max_concentration
end

# Checks the character's concentration percentage against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if concentration percentage is greater than or equal to num
def percentconcentration(num = nil)
  if XMLData.max_concentration == 0
    percent = 100
  else
    percent = ((XMLData.concentration.to_f / XMLData.max_concentration.to_f) * 100).to_i
  end
  if num.nil?
    percent
  else
    percent >= num.to_i
  end
end

# Checks the character's stance against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if stance value matches num
def checkstance(num = nil)
  Lich.deprecated('checkstance', 'Char.stance')
  if num.nil?
    XMLData.stance_text
  elsif (num.is_a?(String)) and (num.to_i == 0)
    if num =~ /off/i
      XMLData.stance_value == 0
    elsif num =~ /adv/i
      XMLData.stance_value.between?(01, 20)
    elsif num =~ /for/i
      XMLData.stance_value.between?(21, 40)
    elsif num =~ /neu/i
      XMLData.stance_value.between?(41, 60)
    elsif num =~ /gua/i
      XMLData.stance_value.between?(61, 80)
    elsif num =~ /def/i
      XMLData.stance_value == 100
    else
      echo "checkstance: invalid argument (#{num}).  Must be off/adv/for/neu/gua/def or 0-100"
      nil
    end
  elsif (num.is_a?(Integer)) or (num =~ /^[0-9]+$/ and (num = num.to_i))
    XMLData.stance_value == num.to_i
  else
    echo "checkstance: invalid argument (#{num}).  Must be off/adv/for/neu/gua/def or 0-100"
    nil
  end
end

# Checks the character's stance percentage against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if stance percentage is greater than or equal to num
def percentstance(num = nil)
  Lich.deprecated('percentstance', 'Char.percent_stance')
  if num.nil?
    XMLData.stance_value
  else
    XMLData.stance_value >= num.to_i
  end
end

# Checks the character's encumbrance against a specified string or value.
#
# @param string [String, nil] optional string to check against
# @return [Boolean] true if encumbrance matches string
def checkencumbrance(string = nil)
  Lich.deprecated('checkencumbrance', 'Char.encumbrance')
  if string.nil?
    XMLData.encumbrance_text
  elsif (string.is_a?(Integer)) or (string =~ /^[0-9]+$/ and (string = string.to_i))
    string <= XMLData.encumbrance_value
  else
    # fixme
    if string =~ /#{XMLData.encumbrance_text}/i
      true
    else
      false
    end
  end
end

# Checks the character's encumbrance percentage against a specified number.
#
# @param num [Integer, nil] optional number to compare against
# @return [Boolean] true if encumbrance percentage is greater than or equal to num
def percentencumbrance(num = nil)
  Lich.deprecated('percentencumbrance', 'Char.percent_encumbrance')
  if num.nil?
    XMLData.encumbrance_value
  else
    num.to_i <= XMLData.encumbrance_value
  end
end

# Checks the current area against specified strings.
#
# @param strings [Array<String>] area names to check against
# @return [Boolean, String] true if a match is found, or the area title if no parameters are provided
def checkarea(*strings)
  strings.flatten!
  if strings.empty?
    XMLData.room_title.split(',').first.sub('[', '')
  else
    XMLData.room_title.split(',').first =~ /#{strings.join('|')}/i
  end
end

# Checks the current room against specified strings.
#
# @param strings [Array<String>] room names to check against
# @return [Boolean, String] true if a match is found, or the room title if no parameters are provided
def checkroom(*strings)
  strings.flatten!
  if strings.empty?
    XMLData.room_title.chomp
  else
    XMLData.room_title =~ /#{strings.join('|')}/i
  end
end

# Checks if the character is outside based on room exits.
# @return [Boolean] true if outside
def outside?
  if XMLData.room_exits_string =~ /Obvious paths:/
    true
  else
    false
  end
end

# Checks the familiar area against specified strings.
#
# @param strings [Array<String>] familiar area names to check against
# @return [Boolean, String] true if a match is found, or the familiar area title if no parameters are provided
def checkfamarea(*strings)
  strings.flatten!
  if strings.empty? then return XMLData.familiar_room_title.split(',').first.sub('[', '') end

  XMLData.familiar_room_title.split(',').first =~ /#{strings.join('|')}/i
end

# Checks the familiar room exits against a specified direction.
#
# @param dir [String] direction to check
# @return [Array<String>, Boolean] list of familiar paths or false if none
def checkfampaths(dir = "none")
  if dir == "none"
    if XMLData.familiar_room_exits.empty?
      return false
    else
      return XMLData.familiar_room_exits
    end
  else
    XMLData.familiar_room_exits.include?(dir)
  end
end

# Checks the familiar room against specified strings.
#
# @param strings [Array<String>] familiar room names to check against
# @return [Boolean, String] true if a match is found, or the familiar room title if no parameters are provided
def checkfamroom(*strings)
  strings.flatten!; if strings.empty? then return XMLData.familiar_room_title.chomp end

  XMLData.familiar_room_title =~ /#{strings.join('|')}/i
end

# Checks the familiar NPCs against specified strings.
#
# @param strings [Array<String>] NPC names to check against
# @return [Boolean, Array<String>] true if a match is found, or an array of familiar NPC names
def checkfamnpcs(*strings)
  parsed = Array.new
  XMLData.familiar_npcs.each { |val| parsed.push(val.split.last) }
  if strings.empty?
    if parsed.empty?
      return false
    else
      return parsed
    end
  else
    if (mtch = strings.find { |lookfor| parsed.find { |critter| critter =~ /#{lookfor}/ } })
      return mtch
    else
      return false
    end
  end
end

# Checks the familiar PCs against specified strings.
#
# @param strings [Array<String>] PC names to check against
# @return [Boolean, Array<String>] true if a match is found, or an array of familiar PC names
def checkfampcs(*strings)
  familiar_pcs = Array.new
  XMLData.familiar_pcs.to_s.gsub(/Lord |Lady |Great |High |Renowned |Grand |Apprentice |Novice |Journeyman /, '').split(',').each { |line| familiar_pcs.push(line.slice(/[A-Z][a-z]+/)) }
  if familiar_pcs.empty?
    return false
  elsif strings.empty?
    return familiar_pcs
  else
    regexpstr = strings.join('|\b')
    peeps = familiar_pcs.find_all { |val| val =~ /\b#{regexpstr}/i }
    if peeps.empty?
      return false
    else
      return peeps
    end
  end
end

# Checks the PCs in the game against specified strings.
#
# @param strings [Array<String>] PC names to check against
# @return [Boolean, Array<String>] true if a match is found, or an array of PC names
def checkpcs(*strings)
  pcs = GameObj.pcs.collect { |pc| pc.noun }
  if pcs.empty?
    if strings.empty? then return nil else return false end
  end
  strings.flatten!
  if strings.empty?
    pcs
  else
    regexpstr = strings.join(' ')
    pcs.find { |pc| regexpstr =~ /\b#{pc}/i }
  end
end

# Checks the NPCs in the game against specified strings.
#
# @param strings [Array<String>] NPC names to check against
# @return [Boolean, Array<String>] true if a match is found, or an array of NPC names
def checknpcs(*strings)
  npcs = GameObj.npcs.collect { |npc| npc.noun }
  if npcs.empty?
    if strings.empty? then return nil else return false end
  end
  strings.flatten!
  if strings.empty?
    npcs
  else
    regexpstr = strings.join(' ')
    npcs.find { |npc| regexpstr =~ /\b#{npc}/i }
  end
end

# Counts the number of NPCs in the game.
# @return [Integer] number of NPCs
def count_npcs
  checknpcs.length
end

# Checks the right hand for specified items.
#
# @param hand [Array<String>] optional items to check for
# @return [String, nil] item found or nil if empty
def checkright(*hand)
  if GameObj.right_hand.nil? then return nil end

  hand.flatten!
  if GameObj.right_hand.name == "Empty" or GameObj.right_hand.name.empty?
    nil
  elsif hand.empty?
    GameObj.right_hand.noun
  else
    hand.find { |instance| GameObj.right_hand.name =~ /#{instance}/i }
  end
end

# Checks the left hand for specified items.
#
# @param hand [Array<String>] optional items to check for
# @return [String, nil] item found or nil if empty
def checkleft(*hand)
  if GameObj.left_hand.nil? then return nil end

  hand.flatten!
  if GameObj.left_hand.name == "Empty" or GameObj.left_hand.name.empty?
    nil
  elsif hand.empty?
    GameObj.left_hand.noun
  else
    hand.find { |instance| GameObj.left_hand.name =~ /#{instance}/i }
  end
end

# Checks the room description against specified strings.
#
# @param val [Array<String>] strings to check against
# @return [Boolean, String] true if a match is found, or the room description if no parameters are provided
def checkroomdescrip(*val)
  val.flatten!
  if val.empty?
    return XMLData.room_description
  else
    return XMLData.room_description =~ /#{val.join('|')}/i
  end
end

# Checks the familiar room description against specified strings.
#
# @param val [Array<String>] strings to check against
# @return [Boolean, String] true if a match is found, or the familiar room description if no parameters are provided
def checkfamroomdescrip(*val)
  val.flatten!
  if val.empty?
    return XMLData.familiar_room_description
  else
    return XMLData.familiar_room_description =~ /#{val.join('|')}/i
  end
end

# Checks if specified spells are active.
#
# @param spells [Array<String>] spell names to check
# @return [Boolean] true if all specified spells are active
def checkspell(*spells)
  spells.flatten!
  return false if Spell.active.empty?

  spells.each { |spell| return false unless Spell[spell].active? }
  true
end

# Checks if a spell is prepared.
#
# @param spell [String, nil] optional spell name to check
# @return [Boolean] true if the spell is prepared
def checkprep(spell = nil)
  if spell.nil?
    XMLData.prepared_spell
  elsif !spell.is_a?(String)
    echo("Checkprep error, spell # not implemented!  You must use the spell name")
    false
  else
    XMLData.prepared_spell =~ /^#{spell}/i
  end
end

# Sets the priority of the current script.
#
# @param val [Integer, nil] optional priority value to set
# @return [Integer] current priority value
def setpriority(val = nil)
  if val.nil? then return Thread.current.priority end

  if val.to_i > 3
    echo("You're trying to set a script's priority as being higher than the send/recv threads (this is telling Lich to run the script before it even gets data to give the script, and is useless); the limit is 3")
    return Thread.current.priority
  else
    Thread.current.group.list.each { |thr| thr.priority = val.to_i }
    return Thread.current.priority
  end
end

# Checks if there is a bounty task assigned.
# @return [String, nil] the bounty task or nil if none
def checkbounty
  if XMLData.bounty_task
    return XMLData.bounty_task
  else
    return nil
  end
end

# Checks if the character is sleeping.
# @return [Boolean] true if sleeping
def checksleeping
  return Status.sleeping? if XMLData.game =~ /GS/
  fail "Error: toplevel checksleeping command not enabled in #{XMLData.game}"
end

# Checks if the character is sleeping.
# @return [Boolean] true if sleeping
def sleeping?
  return Status.sleeping? if XMLData.game =~ /GS/
  fail "Error: toplevel sleeping? command not enabled in #{XMLData.game}"
end

# Checks if the character is bound.
# @return [Boolean] true if bound
def checkbound
  return Status.bound? if XMLData.game =~ /GS/
  fail "Error: toplevel checkbound command not enabled in #{XMLData.game}"
end

# Checks if the character is bound.
# @return [Boolean] true if bound
def bound?
  return Status.bound? if XMLData.game =~ /GS/
  fail "Error: toplevel bound? command not enabled in #{XMLData.game}"
end

# Checks if the character is silenced.
# @return [Boolean] true if silenced
def checksilenced
  return Status.silenced? if XMLData.game =~ /GS/
  fail "Error: toplevel checksilenced command not enabled in #{XMLData.game}"
end

# Checks if the character is silenced.
# @return [Boolean] true if silenced
def silenced?
  return Status.silenced? if XMLData.game =~ /GS/
  fail "Error: toplevel silenced command not enabled in #{XMLData.game}"
end

# Checks if the character is calmed.
# @return [Boolean] true if calmed
def checkcalmed
  return Status.calmed? if XMLData.game =~ /GS/
  fail "Error: toplevel checkcalmed command not enabled in #{XMLData.game}"
end

# Checks if the character is calmed.
# @return [Boolean] true if calmed
def calmed?
  return Status.calmed? if XMLData.game =~ /GS/
  fail "Error: toplevel calmed? command not enabled in #{XMLData.game}"
end

# Checks if the character is cutthroat.
# @return [Boolean] true if cutthroat
def checkcutthroat
  return Status.cutthroat? if XMLData.game =~ /GS/
  fail "Error: toplevel checkcutthroat command not enabled in #{XMLData.game}"
end

# Checks if the character is cutthroat.
# @return [Boolean] true if cutthroat
def cutthroat?
  return Status.cutthroat? if XMLData.game =~ /GS/
  fail "Error: toplevel cutthroat? command not enabled in #{XMLData.game}"
end

# Retrieves the variables of the current script.
# @return [Hash] script variables
def variable
  unless (script = Script.current) then echo 'variable: cannot identify calling script.'; return nil; end
  script.vars
end

# Pauses execution for a specified duration.
#
# @param num [String] duration to pause (can include 'm' for minutes, 'h' for hours, 'd' for days)
# @return [void]
def pause(num = 1)
  if num.to_s =~ /m/
    sleep((num.sub(/m/, '').to_f * 60))
  elsif num.to_s =~ /h/
    sleep((num.sub(/h/, '').to_f * 3600))
  elsif num.to_s =~ /d/
    sleep((num.sub(/d/, '').to_f * 86400))
  else
    sleep(num.to_f)
  end
end

# Casts a spell on a target.
#
# @param spell [String, Integer, Spell] the spell to cast
# @param target [String, nil] optional target for the spell
# @param results_of_interest [String, nil] optional results to track
# @return [Boolean] true if the spell was cast successfully
def cast(spell, target = nil, results_of_interest = nil)
  if spell.is_a?(Spell)
    spell.cast(target, results_of_interest)
  elsif ((spell.is_a?(Integer)) or (spell.to_s =~ /^[0-9]+$/)) and (find_spell = Spell[spell.to_i])
    find_spell.cast(target, results_of_interest)
  elsif (spell.is_a?(String)) and (find_spell = Spell[spell])
    find_spell.cast(target, results_of_interest)
  else
    echo "cast: invalid spell (#{spell})"
    false
  end
end

# Clears the output buffer for the current script.
# @return [Array<String>] cleared output
def clear(_opt = 0)
  unless (script = Script.current) then respond('--- clear: Unable to identify calling script.'); return false; end
  to_return = script.downstream_buffer.dup
  script.downstream_buffer.clear
  to_return
end

# Matches a line from the script's input against specified patterns.
#
# @param label [String] label to match
# @param string [String] string to match
# @return [String, nil] matched string or nil if no match
def match(label, string)
  strings = [label, string]
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("Error! 'match' was given no strings to look for!"); sleep 1; return false end
  unless strings.length == 2
    while (line_in = script.gets)
      strings.each { |string|
        if line_in =~ /#{string}/ then return $~.to_s end
      }
    end
  else
    if script.respond_to?(:match_stack_add)
      script.match_stack_add(strings.first.to_s, strings.last)
    else
      script.match_stack_labels.push(strings[0].to_s)
      script.match_stack_strings.push(strings[1])
    end
  end
end

# Matches a line from the script's input against specified patterns with a timeout.
#
# @param secs [Integer] timeout duration in seconds
# @param strings [Array<String>] strings to match
# @return [String, nil] matched string or nil if no match within timeout
def matchtimeout(secs, *strings)
  unless (Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  unless (secs.is_a?(Float) || secs.is_a?(Integer))
    echo('matchtimeout error! You appear to have given it a string, not a #! Syntax:  matchtimeout(30, "You stand up")')
    return false
  end
  strings.flatten!
  if strings.empty?
    echo("matchtimeout without any strings to wait for!")
    sleep 1
    return false
  end
  regexpstr = strings.join('|')
  end_time = Time.now.to_f + secs
  loop {
    line = get?
    if line.nil?
      sleep 0.1
    elsif line =~ /#{regexpstr}/i
      return line
    end
    if (Time.now.to_f > end_time)
      return false
    end
  }
end

# Matches a line from the script's input before a specified pattern.
#
# @param strings [Array<String>] strings to match
# @return [String] matched string
def matchbefore(*strings)
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("matchbefore without any strings to wait for!"); return false end
  regexpstr = strings.join('|')
  loop { if (script.gets) =~ /#{regexpstr}/ then return $`.to_s end }
end

# Matches a line from the script's input after a specified pattern.
#
# @param strings [Array<String>] strings to match
# @return [String] matched string
def matchafter(*strings)
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("matchafter without any strings to wait for!"); return end
  regexpstr = strings.join('|')
  loop { if (script.gets) =~ /#{regexpstr}/ then return $'.to_s end }
end

# Matches a line from the script's input both before and after specified patterns.
#
# @param strings [Array<String>] strings to match
# @return [Array<String>] matched strings
def matchboth(*strings)
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("matchboth without any strings to wait for!"); return end
  regexpstr = strings.join('|')
  loop { if (script.gets) =~ /#{regexpstr}/ then break end }
  return [$`.to_s, $'.to_s]
end

# Waits for a line from the script's input that matches specified patterns.
#
# @param strings [Array<String>] strings to match
# @return [String] matched line
def matchwait(*strings)
  unless (script = Script.current) then respond('--- matchwait: Unable to identify calling script.'); return false; end
  strings.flatten!
  unless strings.empty?
    regexpstr = strings.collect { |str| str.kind_of?(Regexp) ? str.source : str }.join('|')
    regexobj = /#{regexpstr}/
    while (line_in = script.gets)
      return line_in if line_in =~ regexobj
    end
  else
    strings = script.match_stack_strings
    labels = script.match_stack_labels
    regexpstr = /#{strings.join('|')}/i
    while (line_in = script.gets)
      if (mdata = regexpstr.match(line_in))
        jmp = labels[strings.index(mdata.to_s) || strings.index(strings.find { |str| line_in =~ /#{str}/i })]
        script.match_stack_clear
        goto jmp
      end
    end
  end
end

# Waits for a line from the script's input that matches a regular expression.
#
# @param regexp [Regexp] regular expression to match
# @return [String] matched line
def waitforre(regexp)
  unless (script = Script.current) then respond('--- waitforre: Unable to identify calling script.'); return false; end
  unless regexp.is_a?(Regexp) then echo("Script error! You have given 'waitforre' something to wait for, but it isn't a Regular Expression! Use 'waitfor' if you want to wait for a string."); sleep 1; return nil end
  regobj = regexp.match(script.gets) until regobj
end

# Waits for a line from the script's input that matches specified strings.
#
# @param strings [Array<String>] strings to match
# @return [String] matched line
def waitfor(*strings)
  unless (script = Script.current) then respond('--- waitfor: Unable to identify calling script.'); return false; end
  strings.flatten!
  if (script.is_a?(WizardScript)) and (strings.length == 1) and (strings.first.strip == '>')
    return script.gets
  end

  if strings.empty?
    echo 'waitfor: no string to wait for'
    return false
  end
  regexpstr = strings.join('|')
  while true
    line_in = script.gets
    if (line_in =~ /#{regexpstr}/i) then return line_in end
  end
end

# Waits for a line from the script's input.
# @return [String] the line received
def wait
  unless (script = Script.current) then respond('--- wait: unable to identify calling script.'); return false; end
  script.clear
  return script.gets
end

# Retrieves a line from the script's input.
# @return [String] the line received
def get
  Script.current.gets
end

# Checks if there is a line available from the script's input.
# @return [Boolean] true if a line is available
def get?
  Script.current.gets?
end

# Retrieves lines from the server buffer based on specified criteria.
#
# @param lines [Array<String>] optional lines to filter
# @param core [Boolean] whether to allow core access
# @return [Array<String>, nil] filtered lines or nil if none
def reget(*lines, core: false)
  unless (script = Script.current) || core.eql?(true)
    respond('--- reget: Unable to identify calling script.')
    return false
  end
  lines.flatten!
  if caller.find { |c| c =~ /regetall/ }
    history = ($_SERVERBUFFER_.history + $_SERVERBUFFER_).join("\n")
  else
    history = $_SERVERBUFFER_.dup.join("\n")
  end
  unless script&.want_downstream_xml || core.eql?(true)
    history.gsub!(/<pushStream id=["'](?:spellfront|inv|bounty|society)["'][^>]*\/>.*?<popStream[^>]*>/m, '')
    history.gsub!(/<stream id="Spells">.*?<\/stream>/m, '')
    history.gsub!(/<(compDef|inv|component|right|left|spell|prompt)[^>]*>.*?<\/\1>/m, '')
    history.gsub!(/<[^>]+>/, '')
    history.gsub!('&gt;', '>')
    history.gsub!('&lt;', '<')
  end
  history = history.split("\n").delete_if { |line| line.nil? or line.empty? or line =~ /^[\r\n\s\t]*$/ }
  if lines.first.kind_of?(Numeric) or lines.first.to_i.nonzero?
    history = history[-([lines.shift.to_i, history.length].min)..-1]
  end
  unless lines.empty? or lines.nil?
    regex = /#{lines.join('|')}/i
    history = history.find_all { |line| line =~ regex }
  end
  if history.empty?
    nil
  else
    history
  end
end

# Retrieves all lines from the server buffer based on specified criteria.
# @param lines [Array<String>] optional lines to filter
# @return [Array<String>, nil] filtered lines or nil if none
def regetall(*lines)
  reget(*lines)
end

# Sends multiple commands to the game.
#
# @param cmds [Array<String>] commands to send
# @return [void]
def multifput(*cmds)
  cmds.flatten.compact.each { |cmd| fput(cmd) }
end

# Sends a command to the game and waits for a response matching success or failure patterns.
#
# @param message [String] command to send
# @param waitingfor [Array<String>] patterns for responses
# @return [String, nil] response from the game or nil on timeout
def fput(message, *waitingfor)
  unless (script = Script.current) then respond('--- waitfor: Unable to identify calling script.'); return false; end
  waitingfor.flatten!

  # Optional timeout via trailing Hash argument: fput('cmd', 'pattern', timeout: 30)
  # Default 60s prevents infinite hangs when the game stops responding.
  # Use timeout: 0 to disable (original behavior).
  options = (waitingfor.pop if waitingfor.last.is_a?(Hash)) || {}
  timeout = options[:timeout] || options['timeout'] || 60

  clear
  put(message)

  timer = Time.now
  loop do
    string = get?

    if string.nil?
      if timeout > 0 && (Time.now - timer > timeout)
        echo "fput: No game response for #{timeout}s to '#{message}'"
        return false
      end
      pause 0.1
      next
    end

    timer = Time.now # Reset timeout on any game response

    if string =~ /(?:\.\.\.wait |Wait )(?<wait_time>[0-9]+)/
      hold_up = Regexp.last_match[:wait_time].to_i
      sleep(hold_up) unless hold_up.nil?
      clear
      put(message)
      next
    elsif string =~ /^You.+struggle.+stand/
      clear
      fput 'stand'
      next
    elsif string =~ /stunned|can't do that while|cannot seem|^(?!You rummage).*can't seem|don't seem|Sorry, you may only type ahead/
      if dead?
        echo "You're dead...! You can't do that!"
        sleep 1
        script.downstream_buffer.unshift(string)
        return false
      elsif checkstunned
        while checkstunned
          sleep("0.25".to_f)
        end
      elsif checkwebbed
        while checkwebbed
          sleep("0.25".to_f)
        end
      elsif string =~ /Sorry, you may only type ahead/
        sleep 1
      else
        sleep 0.1
        script.downstream_buffer.unshift(string)
        return false
      end
      clear
      put(message)
      next
    else
      if waitingfor.empty?
        script.downstream_buffer.unshift(string)
        return string
      else
        if (foundit = waitingfor.find { |val| string =~ /#{val}/i })
          script.downstream_buffer.unshift(string)
          return foundit
        end
        sleep 1
        clear
        put(message)
        next
      end
    end
  end
end

# Sends messages to the game.
#
# @param messages [Array<String>] messages to send
# @return [void]
def put(*messages)
  messages.each { |message| Game.puts(message) }
end

# Toggles the quiet exit setting for the current script.
# @return [void]
def quiet_exit
  script = Script.current
  script.quiet = !(script.quiet)
end

# Matches a line from the script's input against specified patterns exactly.
#
# @param strings [Array<String>] strings to match
# @return [String, nil] matched string or nil if no match
def matchfindexact(*strings)
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("error! 'matchfind' with no strings to look for!"); sleep 1; return false end
  looking = Array.new
  strings.each { |str| looking.push(str.gsub('?', '(\b.+\b)')) }
  if looking.empty? then echo("matchfind without any strings to wait for!"); return false end
  regexpstr = looking.join('|')
  while (line_in = script.gets)
    if (gotit = line_in.slice(/#{regexpstr}/))
      matches = Array.new
      looking.each_with_index { |str, idx|
        if gotit =~ /#{str}/i
          strings[idx].count('?').times { |n| matches.push(eval("$#{n + 1}")) }
        end
      }
      break
    end
  end
  if matches.length == 1
    return matches.first
  else
    return matches.compact
  end
end

# Matches a line from the script's input against specified patterns.
#
# @param strings [Array<String>] strings to match
# @return [String, nil] matched string or nil if no match
def matchfind(*strings)
  regex = /#{strings.flatten.join('|').gsub('?', '(.+)')}/i
  unless (script = Script.current)
    respond "Unknown script is asking to use matchfind!  Cannot process request without identifying the calling script; killing this thread."
    Thread.current.kill
  end
  while true
    if (reobj = regex.match(script.gets))
      ret = reobj.captures.compact
      if ret.length < 2
        return ret.first
      else
        return ret
      end
    end
  end
end

# Matches a word from the script's input against specified patterns.
#
# @param strings [Array<String>] strings to match
# @return [String, nil] matched word or nil if no match
def matchfindword(*strings)
  regex = /#{strings.flatten.join('|').gsub('?', '([\w\d]+)')}/i
  unless (script = Script.current)
    respond "Unknown script is asking to use matchfindword!  Cannot process request without identifying the calling script; killing this thread."
    Thread.current.kill
  end
  while true
    if (reobj = regex.match(script.gets))
      ret = reobj.captures.compact
      if ret.length < 2
        return ret.first
      else
        return ret
      end
    end
  end
end

# Sends messages to multiple scripts.
#
# @param messages [Array<String>] messages to send
# @return [void]
def send_scripts(*messages)
  messages.flatten!
  messages.each { |message|
    Script.new_downstream(message)
  }
  true
end

# Toggles the status tags for the current script.
#
# @param onoff [String] 'on' or 'off' to set the status tags
# @return [void]
def status_tags(onoff = "none")
  script = Script.current
  if onoff == "on"
    script.want_downstream = false
    script.want_downstream_xml = true
    echo("Status tags will be sent to this script.")
  elsif onoff == "off"
    script.want_downstream = true
    script.want_downstream_xml = false
    echo("Status tags will no longer be sent to this script.")
  elsif script.want_downstream_xml
    script.want_downstream = true
    script.want_downstream_xml = false
  else
    script.want_downstream = false
    script.want_downstream_xml = true
  end
end

# Sends a response to the client.
#
# @param first [String, Array] first message or array of messages to send
# @param messages [Array<String>] additional messages to send
# @return [void]
def respond(first = "", *messages)
  str = ''
  begin
    if first.is_a?(Array)
      first.flatten.each { |ln| str += sprintf("%s\r\n", ln.to_s.chomp) }
    else
      str += sprintf("%s\r\n", first.to_s.chomp)
    end
    messages.flatten.each { |message| str += sprintf("%s\r\n", message.to_s.chomp) }
    str.split(/\r?\n/).each { |line| Script.new_script_output(line); Buffer.update(line, Buffer::SCRIPT_OUTPUT) }
    # str.gsub!(/\r?\n/, "\r\n") if $frontend == 'genie'
    if Frontend.supports_mono?
      str = "<output class=\"mono\"/>\r\n#{str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')}<output class=\"\"/>\r\n"
    elsif Frontend.client.eql?('profanity')
      str = str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    end
    # Double-checked locking to avoid interrupting a stream and crashing the client
    str_sent = false
    if $_CLIENT_
      until str_sent
        wait_while { !XMLData.safe_to_respond? }
        str_sent = $_CLIENT_.puts_if(str) { XMLData.safe_to_respond? }
      end
    end
    if $_DETACHABLE_CLIENT_
      str_sent = false
      until str_sent
        wait_while { !XMLData.safe_to_respond? }
        begin
          str_sent = $_DETACHABLE_CLIENT_.puts_if(str) { XMLData.safe_to_respond? }
        rescue
          break
        end
      end
    end
  rescue
    puts $!
    puts $!.backtrace.first
  end
end

# Sends a response to the client without formatting.
#
# @param first [String, Array] first message or array of messages to send
# @param messages [Array<String>] additional messages to send
# @return [void]
def _respond(first = "", *messages)
  str = ''
  begin
    if first.is_a?(Array)
      first.flatten.each { |ln| str += sprintf("%s\r\n", ln.to_s.chomp) }
    else
      str += sprintf("%s\r\n", first.to_s.chomp)
    end
    # str.gsub!(/\r?\n/, "\r\n") if $frontend == 'genie'
    messages.flatten.each { |message| str += sprintf("%s\r\n", message.to_s.chomp) }
    str.split(/\r?\n/).each { |line| Script.new_script_output(line); Buffer.update(line, Buffer::SCRIPT_OUTPUT) } # fixme: strip/separate script output?
    str_sent = false
    if $_CLIENT_
      until str_sent
        wait_while { !XMLData.safe_to_respond? }
        str_sent = $_CLIENT_.puts_if(str) { XMLData.safe_to_respond? }
      end
    end
    if $_DETACHABLE_CLIENT_
      str_sent = false
      until str_sent
        wait_while { !XMLData.safe_to_respond? }
        begin
          str_sent = $_DETACHABLE_CLIENT_.puts_if(str) { XMLData.safe_to_respond? }
        rescue
          break
        end
      end
    end
  rescue
    puts $!
    puts $!.backtrace.first
  end
end

# Calculates the pulse value for non-noded characters.
# @return [Integer] calculated pulse value
def noded_pulse
  unless XMLData.game =~ /DR/
    if Stats.prof =~ /warrior|rogue|sorcerer/i
      stats = [Skills.smc.to_i, Skills.emc.to_i]
    elsif Stats.prof =~ /empath|bard/i
      stats = [Skills.smc.to_i, Skills.mmc.to_i]
    elsif Stats.prof =~ /wizard/i
      stats = [Skills.emc.to_i, 0]
    elsif Stats.prof =~ /paladin|cleric|ranger/i
      stats = [Skills.smc.to_i, 0]
    else
      stats = [0, 0]
    end
    return (XMLData.max_mana * 25 / 100) + (stats.max / 10) + (stats.min / 20)
  else
    return 0 # this method is not used by DR
  end
end

# Calculates the pulse value for unnoded characters.
# @return [Integer] calculated pulse value
def unnoded_pulse
  unless XMLData.game =~ /DR/
    if Stats.prof =~ /warrior|rogue|sorcerer/i
      stats = [Skills.smc.to_i, Skills.emc.to_i]
    elsif Stats.prof =~ /empath|bard/i
      stats = [Skills.smc.to_i, Skills.mmc.to_i]
    elsif Stats.prof =~ /wizard/i
      stats = [Skills.emc.to_i, 0]
    elsif Stats.prof =~ /paladin|cleric|ranger/i
      stats = [Skills.smc.to_i, 0]
    else
      stats = [0, 0]
    end
    return (XMLData.max_mana * 15 / 100) + (stats.max / 10) + (stats.min / 20)
  else
    return 0 # this method is not used by DR
  end
end

require_relative File.join(LIB_DIR, "stash.rb")

# Empties the character's hand based on conditions.
# @return [void]
def empty_hands
  waitrt?
  Lich::Stash::stash_hands(both: true)
end

def empty_hand
  right_hand = GameObj.right_hand
  left_hand = GameObj.left_hand

  unless (right_hand.id.nil? and ([Wounds.rightArm, Wounds.rightHand, Scars.rightArm, Scars.rightHand].max < 3)) or (left_hand.id.nil? and ([Wounds.leftArm, Wounds.leftHand, Scars.leftArm, Scars.leftHand].max < 3))
    if right_hand.id and ([Wounds.rightArm, Wounds.rightHand, Scars.rightArm, Scars.rightHand].max < 3 or [Wounds.leftArm, Wounds.leftHand, Scars.leftArm, Scars.leftHand].max == 3)
      waitrt?
      Lich::Stash::stash_hands(right: true)
    else
      waitrt?
      Lich::Stash::stash_hands(left: true)
    end
  end
end

def empty_right_hand
  waitrt?
  Lich::Stash::stash_hands(right: true)
end

# Empties the character's left hand.
# @return [void]
def empty_left_hand
  waitrt?
  Lich::Stash::stash_hands(left: true)
end

# Fills the character's hand with items based on conditions.
# @return [void]
def fill_hands
  waitrt?
  Lich::Stash::equip_hands(both: true)
end

def fill_hand
  waitrt?
  Lich::Stash::equip_hands()
end

# Fills the character's right hand with items.
# @return [void]
def fill_right_hand
  waitrt?
  Lich::Stash::equip_hands(right: true)
end

# Fills the character's left hand with items.
# @return [void]
def fill_left_hand
  waitrt?
  Lich::Stash::equip_hands(left: true)
end

# Executes an action and waits for a success line.
#
# @param action [String] action to perform
# @param success_line [String] line indicating success
# @return [String] success line received
def dothis(action, success_line)
  loop {
    Script.current.clear
    put action
    loop {
      line = get
      if line =~ success_line
        return line
      elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
        if $2.to_i > 1
          sleep($2.to_i - "0.5".to_f)
        else
          sleep 0.3
        end
        break
      elsif line == 'Sorry, you may only type ahead 1 command.'
        sleep 1
        break
      elsif line == 'You are still stunned.'
        wait_while { stunned? }
        break
      elsif line == 'That is impossible to do while unconscious!'
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            break if line =~ /Your thoughts slowly come back to you as you find yourself lying on the ground\.  You must have been sleeping\.$|^You wake up from your slumber\.$/
          end
        }
        break
      elsif line == "You don't seem to be able to move to do that."
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            break if line == 'The restricting force that envelops you dissolves away.'
          end
        }
        break
      elsif line == "You can't do that while entangled in a web."
        wait_while { checkwebbed }
        break
      elsif line == 'You find that impossible under the effects of the lullabye.'
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            # fixme
            break if line == 'You shake off the effects of the lullabye.'
          end
        }
        break
      end
    }
  }
end

# Executes an action with a timeout and waits for a success line.
#
# @param action [String] action to perform
# @param timeout [Integer] timeout duration in seconds
# @param success_line [String] line indicating success
# @return [String, nil] success line received or nil on timeout
def dothistimeout(action, timeout, success_line)
  end_time = Time.now.to_f + timeout
  line = nil
  loop {
    Script.current.clear
    put action unless action.nil?
    loop {
      line = get?
      if line.nil?
        sleep 0.1
      elsif line =~ success_line
        return line
      elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
        if $2.to_i > 1
          sleep($2.to_i - "0.5".to_f)
        else
          sleep 0.3
        end
        end_time = Time.now.to_f + timeout
        break
      elsif line == 'Sorry, you may only type ahead 1 command.'
        sleep 1
        end_time = Time.now.to_f + timeout
        break
      elsif line == 'You are still stunned.'
        wait_while { stunned? }
        end_time = Time.now.to_f + timeout
        break
      elsif line == 'That is impossible to do while unconscious!'
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            break if line =~ /Your thoughts slowly come back to you as you find yourself lying on the ground\.  You must have been sleeping\.$|^You wake up from your slumber\.$/
          end
        }
        break
      elsif line == "You don't seem to be able to move to do that."
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            break if line == 'The restricting force that envelops you dissolves away.'
          end
        }
        break
      elsif line == "You can't do that while entangled in a web."
        wait_while { checkwebbed }
        break
      elsif line == 'You find that impossible under the effects of the lullabye.'
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            # fixme
            break if line == 'You shake off the effects of the lullabye.'
          end
        }
        break
      end
      if Time.now.to_f >= end_time
        return nil
      end
    }
  }
end

$link_highlight_start = ''
$link_highlight_end = ''
$speech_highlight_start = ''
$speech_highlight_end = ''

# Converts a line from the front buffer to a string format.
#
# @param line [String] line to convert
# @return [String, nil] converted line or nil if empty
def fb_to_sf(line)
  begin
    return line if line == "\r\n"

    line = line.gsub(/<c>/, "")
    return nil if line.gsub("\r\n", '').length < 1

    return line
  rescue
    $_CLIENT_.puts "--- Error: fb_to_sf: #{$!}"
    $_CLIENT_.puts "$_SERVERSTRING_: #{$_SERVERSTRING_}"
    Lich.log("--- Error: fb_to_sf: #{$!}\n\t#{$!.backtrace.join("\n\t")}")
    Lich.log("$_SERVERSTRING_: #{$_SERVERSTRING_}")
    Lich.log("Line: #{line}")
  end
end

# Converts a line from string format to wizard format.
#
# @param line [String] line to convert
# @param bypass_multiline [Boolean] whether to bypass multiline handling
# @return [String, nil] converted line or nil if empty
def sf_to_wiz(line, bypass_multiline: false)
  begin
    return line if line == "\r\n"

    unless bypass_multiline
      if $sftowiz_multiline
        $sftowiz_multiline = $sftowiz_multiline + line
        line = $sftowiz_multiline
      end
      if (line.scan(/<pushStream[^>]*\/>/).length > line.scan(/<popStream[^>]*\/>/).length)
        $sftowiz_multiline = line
        return nil
      end
      if (line.scan(/<style id="\w+"[^>]*\/>/).length > line.scan(/<style id=""[^>]*\/>/).length)
        $sftowiz_multiline = line
        return nil
      end
      $sftowiz_multiline = nil
    end
    if line =~ /<LaunchURL src="(.*?)" \/>/
      $_CLIENT_.puts "\034GSw00005\r\nhttps://www.play.net#{$1}\r\n"
    end
    if line =~ /<preset id='speech'>(.*?)<\/preset>/m
      line = line.sub(/<preset id='speech'>.*?<\/preset>/m, "#{$speech_highlight_start}#{$1}#{$speech_highlight_end}")
    end
    if line =~ /<pushStream id="thoughts"[^>]*>\[([^\\]+?)\]\s*(.*?)<popStream\/>/m
      thought_channel = $1
      msg = $2
      thought_channel.gsub!(' ', '-')
      msg.gsub!('<pushBold/>', '')
      msg.gsub!('<popBold/>', '')
      line = line.sub(/<pushStream id="thoughts".*<popStream\/>/m, "You hear the faint thoughts of [#{thought_channel}]-ESP echo in your mind:\r\n#{msg}")
    end
    if line =~ /<pushStream id="voln"[^>]*>\[Voln \- (?:<a[^>]*>)?([A-Z][a-z]+)(?:<\/a>)?\]\s*(".*")[\r\n]*<popStream\/>/m
      line = line.sub(/<pushStream id="voln"[^>]*>\[Voln \- (?:<a[^>]*>)?([A-Z][a-z]+)(?:<\/a>)?\]\s*(".*")[\r\n]*<popStream\/>/m, "The Symbol of Thought begins to burn in your mind and you hear #{$1} thinking, #{$2}\r\n")
    end
    if line =~ /<stream id="thoughts"[^>]*>([^:]+): (.*?)<\/stream>/m
      line = line.sub(/<stream id="thoughts"[^>]*>.*?<\/stream>/m, "You hear the faint thoughts of #{$1} echo in your mind:\r\n#{$2}")
    end
    if line =~ /<pushStream id="familiar"[^>]*>(.*)<popStream\/>/m
      line = line.sub(/<pushStream id="familiar"[^>]*>.*<popStream\/>/m, "\034GSe\r\n#{$1}\034GSf\r\n")
    end
    if line =~ /<pushStream id="death"\/>(.*?)<popStream\/>/m
      line = line.sub(/<pushStream id="death"\/>.*?<popStream\/>/m, "\034GSw00003\r\n#{$1}\034GSw00004\r\n")
    end
    if line =~ /<style id="roomName" \/>(.*?)<style id=""\/>/m
      line = line.sub(/<style id="roomName" \/>.*?<style id=""\/>/m, "\034GSo\r\n#{$1}\034GSp\r\n")
    end
    line.gsub!(/<style id="roomDesc"\/><style id=""\/>\r?\n/, '')
    if line =~ /<style id="roomDesc"\/>(.*?)<style id=""\/>/m
      desc = $1.gsub(/<a[^>]*>/, $link_highlight_start).gsub("</a>", $link_highlight_end)
      line = line.sub(/<style id="roomDesc"\/>.*?<style id=""\/>/m, "\034GSH\r\n#{desc}\034GSI\r\n")
    end
    line = line.gsub("</prompt>\r\n", "</prompt>")
    line = line.gsub("<pushBold/>", "\034GSL\r\n")
    line = line.gsub("<popBold/>", "\034GSM\r\n")
    line = line.gsub(/<pushStream id=["'](?:spellfront|inv|bounty|society|speech|talk)["'][^>]*\/>.*?<popStream[^>]*>/m, '')
    line = line.gsub(/<stream id="Spells">.*?<\/stream>/m, '')
    line = line.gsub(/<(compDef|inv|component|right|left|spell|prompt)[^>]*>.*?<\/\1>/m, '')
    line = line.gsub(/<[^>]+>/, '')
    line = line.gsub('&gt;', '>')
    line = line.gsub('&lt;', '<')
    line = line.gsub('&amp;', '&')
    return nil if line.gsub("\r\n", '').length < 1

    return line
  rescue
    $_CLIENT_.puts "--- Error: sf_to_wiz: #{$!}"
    $_CLIENT_.puts "$_SERVERSTRING_: #{$_SERVERSTRING_}"
    Lich.log("--- Error: sf_to_wiz: #{$!}\n\t#{$!.backtrace.join("\n\t")}")
    Lich.log("$_SERVERSTRING_: #{$_SERVERSTRING_}")
    Lich.log("Line: #{line}")
  end
end

# Strips XML tags from a line.
#
# @param line [String] line to strip
# @param type [String] type of stripping to perform
# @return [String, nil] stripped line or nil if empty
def strip_xml(line, type: 'main')
  return line if line == "\r\n"

  if $strip_xml_multiline[type]
    $strip_xml_multiline[type] = $strip_xml_multiline[type] + line
    line = $strip_xml_multiline[type]
  end
  if (line.scan(/<pushStream[^>]*\/>/).length > line.scan(/<popStream[^>]*\/>/).length)
    $strip_xml_multiline ||= {}
    $strip_xml_multiline[type] = line
    return nil
  end
  $strip_xml_multiline[type] = nil

  line = line.gsub(/<pushStream id=["'](?:spellfront|inv|bounty|society|speech|talk)["'][^>]*\/>.*?<popStream[^>]*>/m, '')
  line = line.gsub(/<stream id="Spells">.*?<\/stream>/m, '')
  line = line.gsub(/<(compDef|inv|component|right|left|spell|prompt)[^>]*>.*?<\/\1>/m, '')
  line = line.gsub(/<[^>]+>/, '')
  line = line.gsub('&gt;', '>')
  line = line.gsub('&lt;', '<')

  return nil if line.gsub("\n", '').gsub("\r", '').gsub(' ', '').length < 1

  return line
end

# Starts bold formatting for monster text.
# @return [String] formatting string for bold start
def monsterbold_start
  if Frontend.supports_gsl?
    "\034GSL\r\n"
  elsif Frontend.supports_xml?
    '<pushBold/>'
  else
    ''
  end
end

# Ends bold formatting for monster text.
# @return [String] formatting string for bold end
def monsterbold_end
  if Frontend.supports_gsl?
    "\034GSM\r\n"
  elsif Frontend.supports_xml?
    '<popBold/>'
  else
    ''
  end
end

# Processes a client command string and executes the appropriate action.
#
# @param client_string [String] command string from the client
# @return [void]
def do_client(client_string)
  client_string.strip!
  #   Buffer.update(client_string, Buffer::UPSTREAM)
  client_string = UpstreamHook.run(client_string)
  #   Buffer.update(client_string, Buffer::UPSTREAM_MOD)
  return nil if client_string.nil?

  if client_string =~ /^(?:<c>)?#{$lich_char_regex}(.+)$/
    cmd = $1
    if cmd =~ /^k$|^kill$|^stop$/
      if Script.running.empty?
        respond '--- Lich: no scripts to kill'
      else
        Script.running.last.kill
      end
    elsif cmd =~ /^p$|^pause$/
      if (s = Script.running.reverse.find { |s_check| not s_check.paused? })
        s.pause
      else
        respond '--- Lich: no scripts to pause'
      end
      nil
    elsif cmd =~ /^u$|^unpause$/
      if (s = Script.running.reverse.find { |s_check| s_check.paused? })
        s.unpause
      else
        respond '--- Lich: no scripts to unpause'
      end
      nil
    elsif cmd =~ /^ka$|^kill\s?all$|^stop\s?all$/
      did_something = false
      Script.running.find_all { |s_check| not s_check.no_kill_all }.each { |s_check| s_check.kill; did_something = true }
      respond('--- Lich: no scripts to kill') unless did_something
    elsif cmd =~ /^pa$|^pause\s?all$/
      did_something = false
      Script.running.find_all { |s_check| not s_check.paused? and not s_check.no_pause_all }.each { |s_check| s_check.pause; did_something = true }
      respond('--- Lich: no scripts to pause') unless did_something
    elsif cmd =~ /^ua$|^unpause\s?all$/
      did_something = false
      Script.running.find_all { |s_check| s_check.paused? and not s_check.no_pause_all }.each { |s_check| s_check.unpause; did_something = true }
      respond('--- Lich: no scripts to unpause') unless did_something
    elsif cmd =~ /^(k|kill|stop|p|pause|u|unpause)\s(.+)/
      action = $1
      target = $2
      script = Script.running.find { |s_running| s_running.name == target } || Script.hidden.find { |s_hidden| s_hidden.name == target } || Script.running.find { |s_running| s_running.name =~ /^#{target}/i } || Script.hidden.find { |s_hidden| s_hidden.name =~ /^#{target}/i }
      if script.nil?
        respond "--- Lich: #{target} does not appear to be running! Use '#{$clean_lich_char}list' or '#{$clean_lich_char}listall' to see what's active."
      elsif action =~ /^(?:k|kill|stop)$/
        script.kill
      elsif action =~ /^(?:p|pause)$/
        script.pause
      elsif action =~ /^(?:u|unpause)$/
        script.unpause
      end
      target = nil
    elsif cmd =~ /^list\s?(?:all)?$|^l(?:a)?$/i
      if cmd =~ /a(?:ll)?/i
        list = Script.running + Script.hidden
      else
        list = Script.running
      end
      if list.empty?
        respond '--- Lich: no active scripts'
      else
        respond "--- Lich: #{list.collect { |active| active.paused? ? "#{active.name} (paused)" : active.name }.join(", ")}"
      end
      nil
    elsif cmd =~ /^force\s+[^\s]+/
      if cmd =~ /^force\s+([^\s]+)\s+(.+)$/
        Script.start($1, $2, :force => true)
      elsif cmd =~ /^force\s+([^\s]+)/
        Script.start($1, :force => true)
      end
    elsif cmd =~ /^send |^s /
      if cmd.split[1] == "to"
        script = (Script.running + Script.hidden).find { |scr| scr.name == cmd.split[2].chomp.strip } || script = (Script.running + Script.hidden).find { |scr| scr.name =~ /^#{cmd.split[2].chomp.strip}/i }
        if script
          msg = cmd.split[3..-1].join(' ').chomp
          if script.want_downstream
            script.downstream_buffer.push(msg)
          else
            script.unique_buffer.push(msg)
          end
          respond "--- sent to '#{script.name}': #{msg}"
        else
          respond "--- Lich: '#{cmd.split[2].chomp.strip}' does not match any active script!"
        end
        nil
      else
        if Script.running.empty? and Script.hidden.empty?
          respond('--- Lich: no active scripts to send to.')
        else
          msg = cmd.split[1..-1].join(' ').chomp
          respond("--- sent: #{msg}")
          Script.new_downstream(msg)
        end
      end
    elsif cmd =~ /^(?:exec|e)(q)? (.+)$/
      cmd_data = $2
      ExecScript.start(cmd_data, { :quiet => $1 })
    elsif cmd =~ /^(?:execname|en) ([\w\d-]+) (.+)$/
      execname = $1
      cmd_data = $2
      ExecScript.start(cmd_data, { :name => execname })
    elsif cmd =~ /^trust\s+(.*)/i
      script_name = $1
      if RUBY_VERSION =~ /^2\.[012]\./
        if File.exist?("#{SCRIPT_DIR}/#{script_name}.lic")
          if Script.trust(script_name)
            respond "--- Lich: '#{script_name}' is now a trusted script."
          else
            respond "--- Lich: '#{script_name}' is already trusted."
          end
        else
          respond "--- Lich: could not find script: #{script_name}"
        end
      else
        respond "--- Lich: this feature isn't available in this version of Ruby "
      end
    elsif cmd =~ /^(?:dis|un)trust\s+(.*)/i
      script_name = $1
      if RUBY_VERSION =~ /^2\.[012]\./
        if Script.distrust(script_name)
          respond "--- Lich: '#{script_name}' is no longer a trusted script."
        else
          respond "--- Lich: '#{script_name}' was not found in the trusted script list."
        end
      else
        respond "--- Lich: this feature isn't available in this version of Ruby "
      end
    elsif cmd =~ /^list\s?(?:un)?trust(?:ed)?$|^lt$/i
      if RUBY_VERSION =~ /^2\.[012]\./
        list = Script.list_trusted
        if list.empty?
          respond "--- Lich: no scripts are trusted"
        else
          respond "--- Lich: trusted scripts: #{list.join(', ')}"
        end
        nil
      else
        respond "--- Lich: this feature isn't available in this version of Ruby "
      end
    elsif cmd =~ /^set\s(.+)\s(on|off)/
      toggle_var = $1
      set_state = $2
      did_something = false
      begin
        Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values(?,?);", [toggle_var.to_s.encode('UTF-8'), set_state.to_s.encode('UTF-8')])
        did_something = true
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      respond("--- Lich: toggle #{toggle_var} set #{set_state}") if did_something
      did_something = false
      nil
    elsif cmd =~ /^hmr\s+(?<pattern>.*)/i
      begin
        HMR.reload %r{#{Regexp.last_match[:pattern]}}
      rescue ArgumentError
        if $!.to_s == 'invalid Unicode escape'
          respond "--- Lich: error: invalid Unicode escape"
          respond "--- Lich:   cmd: #{cmd}"
          respond "--- Lich: \\u is unicode escape, did you mean to use a / instead?"
        else
          respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
          Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end
    elsif XMLData.game =~ /^GS/ && cmd =~ /^infomon sync/i
      ExecScript.start("Infomon.sync", { :quiet => true })
    elsif XMLData.game =~ /^GS/ && cmd =~ /^infomon (?:reset|redo)!?/i
      ExecScript.start("Infomon.redo!", { :quiet => true })
    elsif XMLData.game =~ /^GS/ && cmd =~ /^infomon show( full)?/i
      case Regexp.last_match(1)
      when 'full'
        Infomon.show(true)
      else
        Infomon.show(false)
      end
    elsif XMLData.game =~ /^GS/ && cmd =~ /^infomon effects?(?: (true|false))?/i
      new_value = !(Infomon.get_bool("infomon.show_durations"))
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Infomon's effect duration showing to #{new_value}"
      Infomon.set('infomon.show_durations', new_value)
    elsif XMLData.game =~ /^GS/ && cmd =~ /^sk\b(?: (add|rm|list|help)(?: ([\d\s]+))?)?/i
      SK.main(Regexp.last_match(1), Regexp.last_match(2))
    elsif XMLData.game =~ /^DR/ && cmd =~ /^display flaguid(?: (true|false))?/i
      new_value = !(Lich.hide_uid_flag)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to NOT display Room Title RealIDs while FLAG ShowRoomID ON to #{new_value}"
      Lich.hide_uid_flag = new_value
    elsif cmd =~ /^display lichid(?: (true|false))?/i
      new_value = !(Lich.display_lichid)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to display Lich ID#s to #{new_value}"
      Lich.display_lichid = new_value
    elsif cmd =~ /^display uid(?: (true|false))?/i
      new_value = !(Lich.display_uid)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to display RealID#s to #{new_value}"
      Lich.display_uid = new_value
    elsif cmd =~ /^display exits?(?: (true|false))?/i
      new_value = !(Lich.display_exits)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to display Room Exits of non-StringProc/Obvious exits to #{new_value}"
      Lich.display_exits = new_value
    elsif cmd =~ /^display stringprocs?(?: (true|false))?/i
      new_value = !(Lich.display_stringprocs)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to display Room Exits of StringProcs to #{new_value}"
      Lich.display_stringprocs = new_value
    elsif XMLData.game =~ /^DR/ && (expgains_match = cmd.match(/^display expgains?(?: (?<toggle>true|false|on|off))?$/i))
      if running?('exp-monitor')
        respond "Error: exp-monitor.lic script is currently running"
        respond "Stop it first with: #{$clean_lich_char}kill exp-monitor"
      else
        new_value = !Lich.display_expgains
        case expgains_match[:toggle]
        when 'true', 'on'
          new_value = true
        when 'false', 'off'
          new_value = false
        end
        Lich.display_expgains = new_value
        if new_value
          respond "Enabling real-time experience gain reporting"
          DRExpMonitor.start
        else
          respond "Disabling real-time experience gain reporting"
          DRExpMonitor.stop
        end
      end
    elsif XMLData.game =~ /^DR/ && (inlineexp_match = cmd.match(/^display inlineexp(?: (?<toggle>true|false|on|off))?$/i))
      new_value = !DRExpMonitor.inline_display?
      case inlineexp_match[:toggle]
      when 'true', 'on'
        new_value = true
      when 'false', 'off'
        new_value = false
      end
      DRExpMonitor.inline_display = new_value
      if new_value
        respond "Enabling inline experience display (gained ranks shown in exp window)"
      else
        respond "Disabling inline experience display"
      end
    elsif XMLData.game =~ /^DR/ && cmd =~ /^display exp-status$/i
      respond
      respond "DragonRealms Experience Monitor Status:"
      respond "  expgains:   #{Lich.display_expgains ? 'ON' : 'OFF'}  (real-time gain messages)"
      respond "  inlineexp:  #{DRExpMonitor.inline_display? ? 'ON' : 'OFF'}  (cumulative gains in EXP window)"
      respond "  reporter:   #{DRExpMonitor.active? ? 'RUNNING' : 'STOPPED'}"
      respond
      respond "Commands:"
      respond "  #{$clean_lich_char}display expgains [on|off]    toggle gain messages"
      respond "  #{$clean_lich_char}display inlineexp [on|off]   toggle inline display"
      respond
    elsif (debuglogs_match = cmd.match(/^debuglogs?\s+(?<val>\d+)$/i))
      new_limit = debuglogs_match[:val].to_i
      Lich.max_debug_logs = new_limit
      respond "--- Lich: debug log retention set to #{Lich.max_debug_logs} files"
    elsif cmd =~ /^debuglogs?$/i
      respond
      respond "--- Lich: Debug Log Retention ---"
      respond "  Current limit:  #{Lich.max_debug_logs} files"
      respond "  Default:        #{Lich::MAX_DEBUG_LOGS_DEFAULT} files"
      respond
      respond "Usage:"
      respond "  #{$clean_lich_char}debuglogs            show current setting"
      respond "  #{$clean_lich_char}debuglogs <number>   set retention limit"
      respond
    elsif cmd =~ /^debuglogs?\b/i
      respond "--- Lich: invalid argument. Usage: #{$clean_lich_char}debuglogs [number]"
    elsif cmd =~ /^(?:lich5-update|l5u)\s+(.*)/i
      update_parameter = $1.dup
      Lich::Util::Update.request("#{update_parameter}")
    elsif cmd =~ /^(?:lich5-update|l5u)/i
      Lich::Util::Update.request("--help")
    elsif cmd =~ /^banks$/ && XMLData.game =~ /^GS/
      Game._puts "<c>bank account"
      $_CLIENTBUFFER_.push "<c>bank account"
    elsif XMLData.game =~ /^DR/ && (banks_match = cmd.match(/^banks(?: (all|reset|reset all))?$/i))
      case banks_match[1]&.downcase
      when 'all'
        Lich::DragonRealms::DRBanking.display_banks_all
      when 'reset'
        Lich::DragonRealms::DRBanking.reset_character!
      when 'reset all'
        Lich::DragonRealms::DRBanking.reset_all!
      else
        Lich::DragonRealms::DRBanking.display_banks
      end
    elsif cmd =~ /^magic$/ && XMLData.game =~ /^GS/
      Effects.display
    elsif cmd =~ /^help$/i
      respond
      respond "Lich v#{LICH_VERSION}"
      respond
      respond 'built-in commands:'
      respond "   #{$clean_lich_char}<script name>             start a script"
      respond "   #{$clean_lich_char}force <script name>       start a script even if it's already running"
      respond "   #{$clean_lich_char}pause <script name>       pause a script"
      respond "   #{$clean_lich_char}p <script name>           ''"
      respond "   #{$clean_lich_char}unpause <script name>     unpause a script"
      respond "   #{$clean_lich_char}u <script name>           ''"
      respond "   #{$clean_lich_char}kill <script name>        kill a script"
      respond "   #{$clean_lich_char}k <script name>           ''"
      respond "   #{$clean_lich_char}pause                     pause the most recently started script that isn't aready paused"
      respond "   #{$clean_lich_char}p                         ''"
      respond "   #{$clean_lich_char}unpause                   unpause the most recently started script that is paused"
      respond "   #{$clean_lich_char}u                         ''"
      respond "   #{$clean_lich_char}kill                      kill the most recently started script"
      respond "   #{$clean_lich_char}k                         ''"
      respond "   #{$clean_lich_char}list                      show running scripts (except hidden ones)"
      respond "   #{$clean_lich_char}l                         ''"
      respond "   #{$clean_lich_char}pause all                 pause all scripts"
      respond "   #{$clean_lich_char}pa                        ''"
      respond "   #{$clean_lich_char}unpause all               unpause all scripts"
      respond "   #{$clean_lich_char}ua                        ''"
      respond "   #{$clean_lich_char}kill all                  kill all scripts"
      respond "   #{$clean_lich_char}ka                        ''"
      respond "   #{$clean_lich_char}list all                  show all running scripts"
      respond "   #{$clean_lich_char}la                        ''"
      respond
      respond "   #{$clean_lich_char}exec <code>               executes the code as if it was in a script"
      respond "   #{$clean_lich_char}e <code>                  ''"
      respond "   #{$clean_lich_char}execq <code>              same as #{$clean_lich_char}exec but without the script active and exited messages"
      respond "   #{$clean_lich_char}eq <code>                 ''"
      respond "   #{$clean_lich_char}execname <name> <code>    creates named exec (name#) and then executes the code as if it was in a script"
      respond
      if (RUBY_VERSION =~ /^2\.[012]\./)
        respond "   #{$clean_lich_char}trust <script name>       let the script do whatever it wants"
        respond "   #{$clean_lich_char}distrust <script name>    restrict the script from doing things that might harm your computer"
        respond "   #{$clean_lich_char}list trusted              show what scripts are trusted"
        respond "   #{$clean_lich_char}lt                        ''"
        respond
      end
      respond "   #{$clean_lich_char}send <line>               send a line to all scripts as if it came from the game"
      respond "   #{$clean_lich_char}send to <script> <line>   send a line to a specific script"
      respond
      respond "   #{$clean_lich_char}set <variable> [on|off]   set a global toggle variable on or off"
      respond "   #{$clean_lich_char}debuglogs                 show debug log retention setting"
      respond "   #{$clean_lich_char}debuglogs <number>        set how many debug logs to keep (default: #{Lich::MAX_DEBUG_LOGS_DEFAULT})"
      respond
      respond "   #{$clean_lich_char}lich5-update --<command>  Lich5 ecosystem management "
      respond "                              see #{$clean_lich_char}lich5-update --help"
      respond "   #{$clean_lich_char}hmr <regex filepath>      Hot module reload a Ruby or Lich5 file without relogging, uses Regular Expression matching"
      if XMLData.game =~ /^GS/
        respond
        respond "   #{$clean_lich_char}infomon sync              sends all the various commands to resync character data for infomon (fixskill)"
        respond "   #{$clean_lich_char}infomon reset             resets entire character infomon db table and then syncs data (fixprof)"
        respond "   #{$clean_lich_char}infomon effects           toggle display of effect durations"
        respond "   #{$clean_lich_char}infomon show              shows all current Infomon values for character"
        respond "   #{$clean_lich_char}sk help                   show information on modifying self-knowledge spells to be known"
      elsif XMLData.game =~ /^DR/
        respond "   #{$clean_lich_char}display flaguid           toggle display of RealID in Room Title with FLAG ShowRoomID (required for Lich5 to be ON)"
      end
      respond "   #{$clean_lich_char}display lichid            toggle display of Lich Map# when displaying room information"
      respond "   #{$clean_lich_char}display uid               toggle display of RealID Map# when displaying room information"
      respond "   #{$clean_lich_char}display exits             toggle display of non-StringProc/Obvious exits known for room in mapdb"
      respond "   #{$clean_lich_char}display stringprocs       toggle display of StringProc exits known for room in mapdb if timeto is valid"
      if XMLData.game =~ /^DR/
        respond "   #{$clean_lich_char}display expgains          toggle real-time experience gain reporting (DragonRealms only)"
        respond "   #{$clean_lich_char}display inlineexp         toggle inline exp display in EXP window (DragonRealms only)"
        respond "   #{$clean_lich_char}display exp-status        show experience monitor status (DragonRealms only)"
        respond "   #{$clean_lich_char}banks                     show your bank balances (DragonRealms only)"
        respond "   #{$clean_lich_char}banks all                 show bank balances for all characters (DragonRealms only)"
        respond "   #{$clean_lich_char}banks reset               clear your bank data (DragonRealms only)"
        respond "   #{$clean_lich_char}banks reset all           clear all characters' bank data (DragonRealms only)"
      end
      respond
      respond 'If you liked this help message, you might also enjoy:'
      respond "   #{$clean_lich_char}lnet help" if defined?(LNet)
      respond "   #{$clean_lich_char}go2 help"
      respond "   #{$clean_lich_char}repository help"
      respond "   #{$clean_lich_char}alias help"
      respond "   #{$clean_lich_char}vars help"
      respond "   #{$clean_lich_char}autostart help"
      respond
    else
      if cmd =~ /^([^\s]+)\s+(.+)/
        Script.start($1, $2)
      else
        Script.start(cmd)
      end
    end
  else
    if $offline_mode
      respond "--- Lich: offline mode: ignoring #{client_string}"
    else
      client_string = "#{$cmd_prefix}bbs" if Frontend.supports_gsl? and (client_string == "#{$cmd_prefix}\egbbk\n") # launch forum
      Game._puts client_string
    end
    $_CLIENTBUFFER_.push client_string
  end
  Script.new_upstream(client_string)
end

# Reports errors that occur during execution of a block.
#
# @yield block of code to execute
# @return [void]
def report_errors(&block)
  begin
    block.call
  rescue
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue SyntaxError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue SystemExit
    nil
  rescue SecurityError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue ThreadError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue SystemStackError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue StandardError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  #  rescue ScriptError
  #    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
  #    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue LoadError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue NoMemoryError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  end
end

# Handles deprecated alias commands.
# @return [void]
def alias_deprecated
  # todo: add command reference, possibly add calling script
  echo "The alias command you're attempting to use is deprecated.  Fix your script."
end

## Alias block from Lich (needs further cleanup)

undef :abort if respond_to?(:abort)
alias :mana :checkmana
alias :mana? :checkmana
alias :max_mana :maxmana
alias :health :checkhealth
alias :health? :checkhealth
alias :spirit :checkspirit
alias :spirit? :checkspirit
alias :stamina :checkstamina
alias :stamina? :checkstamina
alias :stunned? :checkstunned
alias :bleeding? :checkbleeding
alias :reallybleeding? :alias_deprecated
alias :poisoned? :checkpoison
alias :diseased? :checkdisease
alias :dead? :checkdead
alias :hiding? :checkhidden
alias :hidden? :checkhidden
alias :hidden :checkhidden
alias :checkhiding :checkhidden
alias :invisible? :checkinvisible
alias :standing? :checkstanding
alias :kneeling? :checkkneeling
alias :sitting? :checksitting
alias :stance? :checkstance
alias :stance :checkstance
alias :joined? :checkgrouped
alias :checkjoined :checkgrouped
alias :group? :checkgrouped
alias :myname? :checkname
alias :active? :checkspell
alias :righthand? :checkright
alias :lefthand? :checkleft
alias :righthand :checkright
alias :lefthand :checkleft
alias :mind? :checkmind
alias :checkactive :checkspell
alias :forceput :fput
alias :send_script :send_scripts
alias :stop_scripts :stop_script
alias :kill_scripts :stop_script
alias :kill_script :stop_script
alias :fried? :checkfried
alias :saturated? :checksaturated
alias :webbed? :checkwebbed
alias :pause_scripts :pause_script
alias :roomdescription? :checkroomdescrip
alias :prepped? :checkprep
alias :checkprepared :checkprep
alias :unpause_scripts :unpause_script
alias :priority? :setpriority
alias :checkoutside :outside?
alias :toggle_status :status_tags
alias :encumbrance? :checkencumbrance
alias :bounty? :checkbounty
