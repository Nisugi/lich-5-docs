# The base directory for the Lich5 project
# This directory is determined by the location of the running script.
LICH_DIR    ||= File.dirname(File.expand_path($PROGRAM_NAME))
# The temporary directory for the Lich5 project
# This directory is used to store temporary files.
TEMP_DIR    ||= File.join(LICH_DIR, "temp").freeze
# The data directory for the Lich5 project
# This directory is used to store data files.
DATA_DIR    ||= File.join(LICH_DIR, "data").freeze
# The scripts directory for the Lich5 project
# This directory contains script files.
SCRIPT_DIR  ||= File.join(LICH_DIR, "scripts").freeze
# The library directory for the Lich5 project
# This directory contains library files.
LIB_DIR     ||= File.join(LICH_DIR, "lib").freeze
# The maps directory for the Lich5 project
# This directory is used to store map files.
MAP_DIR     ||= File.join(LICH_DIR, "maps").freeze
# The logs directory for the Lich5 project
# This directory is used to store log files.
LOG_DIR     ||= File.join(LICH_DIR, "logs").freeze
# The backup directory for the Lich5 project
# This directory is used to store backup files.
BACKUP_DIR  ||= File.join(LICH_DIR, "backup").freeze

# Indicates whether the project is in testing mode
# @return [Boolean] false if not in testing mode.
TESTING = false

# add this so that require statements can take the form 'lib/file'

# Adds the LICH_DIR to the load path
# This allows require statements to take the form 'lib/file'.
$LOAD_PATH << "#{LICH_DIR}"

# deprecated
$lich_dir = "#{LICH_DIR}/"
$temp_dir = "#{TEMP_DIR}/"
$script_dir = "#{SCRIPT_DIR}/"
$data_dir = "#{DATA_DIR}/"

# transcoding migrated 2024-06-13
# A mapping of direction abbreviations to single-character codes
# @example
#   DIRMAP['out'] # => 'K'
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
# A mapping of full direction names to their abbreviations
# @example
#   SHORTDIR['northeast'] # => 'ne'
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
# A mapping of abbreviation codes to full direction names
# @example
#   LONGDIR['ne'] # => 'northeast'
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
# A mapping of mental states to single-character codes
# @example
#   MINDMAP['clear as a bell'] # => 'A'
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
# A mapping of icon names to their corresponding codes
# @example
#   ICONMAP['IconKNEELING'] # => 'GH'
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
