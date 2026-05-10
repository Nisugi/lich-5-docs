LICH_DIR    ||= File.dirname(File.expand_path($PROGRAM_NAME))
TEMP_DIR    ||= File.join(LICH_DIR, "temp").freeze
DATA_DIR    ||= File.join(LICH_DIR, "data").freeze
SCRIPT_DIR  ||= File.join(LICH_DIR, "scripts").freeze
LIB_DIR     ||= File.join(LICH_DIR, "lib").freeze
MAP_DIR     ||= File.join(LICH_DIR, "maps").freeze
LOG_DIR     ||= File.join(LICH_DIR, "logs").freeze
BACKUP_DIR  ||= File.join(LICH_DIR, "backup").freeze

# Indicates whether the application is in testing mode.
#
# @return [Boolean] true if in testing mode, false otherwise
TESTING = false

# add this so that require statements can take the form 'lib/file'

$LOAD_PATH << "#{LICH_DIR}"

# deprecated
$lich_dir = "#{LICH_DIR}/"
$temp_dir = "#{TEMP_DIR}/"
$script_dir = "#{SCRIPT_DIR}/"
$data_dir = "#{DATA_DIR}/"

# transcoding migrated 2024-06-13
# A mapping of direction abbreviations to their corresponding codes.
#
# @example
#   DIRMAP["out"] # => "K"
#   DIRMAP["ne"]  # => "B"
# @see SHORTDIR
# @see LONGDIR
DIRMAP = {
  'out'  => 'K',
  'ne'   => 'B',
  'se'   => 'D',
  'sw'   => 'F',
  'nw'   => 'H',
  'up'   => 'I',
  'down' => 'J',
  'n'    => 'A',
  'e'    => 'C',
  's'    => 'E',
  'w'    => 'G',
}
# A mapping of full direction names to their abbreviations.
#
# @example
#   SHORTDIR["north"] # => "n"
#   SHORTDIR["southwest"] # => "sw"
# @see DIRMAP
# @see LONGDIR
SHORTDIR = {
  'out'       => 'out',
  'northeast' => 'ne',
  'southeast' => 'se',
  'southwest' => 'sw',
  'northwest' => 'nw',
  'up'        => 'up',
  'down'      => 'down',
  'north'     => 'n',
  'east'      => 'e',
  'south'     => 's',
  'west'      => 'w',
}
# A mapping of direction abbreviations to their full names.
#
# @example
#   LONGDIR["n"] # => "north"
#   LONGDIR["se"] # => "southeast"
# @see DIRMAP
# @see SHORTDIR
LONGDIR = {
  'out'  => 'out',
  'ne'   => 'northeast',
  'se'   => 'southeast',
  'sw'   => 'southwest',
  'nw'   => 'northwest',
  'up'   => 'up',
  'down' => 'down',
  'n'    => 'north',
  'e'    => 'east',
  's'    => 'south',
  'w'    => 'west',
}
# A mapping of mental state descriptions to their corresponding codes.
#
# @example
#   MINDMAP["clear as a bell"] # => "A"
#   MINDMAP["muddled"] # => "D"
MINDMAP = {
  'clear as a bell' => 'A',
  'fresh and clear' => 'B',
  'clear'           => 'C',
  'muddled'         => 'D',
  'becoming numbed' => 'E',
  'numbed'          => 'F',
  'must rest'       => 'G',
  'saturated'       => 'H',
}
# A mapping of icon names to their corresponding codes.
#
# @example
#   ICONMAP["IconKNEELING"] # => "GH"
#   ICONMAP["IconDEAD"] # => "B"
ICONMAP = {
  'IconKNEELING'  => 'GH',
  'IconPRONE'     => 'G',
  'IconSITTING'   => 'H',
  'IconSTANDING'  => 'T',
  'IconSTUNNED'   => 'I',
  'IconHIDDEN'    => 'N',
  'IconINVISIBLE' => 'D',
  'IconDEAD'      => 'B',
  'IconWEBBED'    => 'C',
  'IconJOINED'    => 'P',
  'IconBLEEDING'  => 'O',
}
