# The base directory for the Lich5 project.
# @return [String] The directory path.
LICH_DIR    ||= File.dirname(File.expand_path($PROGRAM_NAME))
# The temporary directory for the Lich5 project.
# @return [String] The path to the temporary directory.
TEMP_DIR    ||= File.join(LICH_DIR, "temp").freeze
# The data directory for the Lich5 project.
# @return [String] The path to the data directory.
DATA_DIR    ||= File.join(LICH_DIR, "data").freeze
# The scripts directory for the Lich5 project.
# @return [String] The path to the scripts directory.
SCRIPT_DIR  ||= File.join(LICH_DIR, "scripts").freeze
# The library directory for the Lich5 project.
# @return [String] The path to the library directory.
LIB_DIR     ||= File.join(LICH_DIR, "lib").freeze
# The maps directory for the Lich5 project.
# @return [String] The path to the maps directory.
MAP_DIR     ||= File.join(LICH_DIR, "maps").freeze
# The logs directory for the Lich5 project.
# @return [String] The path to the logs directory.
LOG_DIR     ||= File.join(LICH_DIR, "logs").freeze
# The backup directory for the Lich5 project.
# @return [String] The path to the backup directory.
BACKUP_DIR  ||= File.join(LICH_DIR, "backup").freeze

# Indicates whether the project is in testing mode.
# @return [Boolean] Always returns false.
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
# @return [Hash] A hash mapping direction strings to codes.
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
# A mapping of full direction names to their short forms.
# @return [Hash] A hash mapping full direction names to short forms.
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
# A mapping of short direction names to their full forms.
# @return [Hash] A hash mapping short direction names to full forms.
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
# A mapping of mental states to their corresponding codes.
# @return [Hash] A hash mapping mental state descriptions to codes.
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
# @return [Hash] A hash mapping icon names to codes.
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
