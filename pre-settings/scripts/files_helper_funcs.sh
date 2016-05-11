#!/bin/bash
set -e
FILES_HELPER_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$FILES_HELPER_PATH/error_handling_funcs.sh"

trap "trap_ctrlc" 2

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# These are a group of helper methods that will perform File
# modification
#

#	----------------------------------------------------------------
#	Function for finding and replacing a pattern found in a file
#		Accepts 4 argument:
#			string being replaced
#			string replacing the matching pattern
#			string of the filename
#     string of where to generate the log
#	----------------------------------------------------------------
function __find_and_replace
{
	__validate_num_arguments 4 $# "\"__find_and_replace()\" expected in order:  Pattern to find, String relacing the matching pattern, filename, path of where to generate log" "$FILES_HELPER_PATH/.."

	sed "s#$1#$2#" "$3" > "$3.tmp"
	if mv "$3.tmp" "$3"; then
		echo "Successfully ran sed command on file: \"$3\", replacing pattern: \"$1\", with: \"$2\""
	else
		__error_exit "Failed to modify the file: \"$3\"" "$4"
	fi
}

#	----------------------------------------------------------------
#	Function for finding and replacing a pattern found in a file
#		Accepts 4 argument:
#			string of the pattern
#			string content of the new line being appended to line matching pattern
#			string of the filename
#     string of where to generate the log
#	----------------------------------------------------------------
function __find_and_append_new_line
{
	__validate_num_arguments 4 $# "\"__find_and_append_new_line()\" expected in order:  Pattern to find, String of the new line being appended, filename, path of where to generate log" "$FILES_HELPER_PATH/.."

	awk '/'"$1"'/{print $0 RS "'"$2"'";next}1' "$3" > "$3.tmp"

	#sed -e "/$1/a\\
	#$2" "$3" > "$3.tmp"
	if mv "$3.tmp" "$3"; then
		echo "Successfully ran AWK command on file: \"$3\", appending new line to line matching pattern: \"$1\", with: \"$2\""
	else
		__error_exit "Failed to modify the file: \"$3\"" "$4"
	fi
}

#	----------------------------------------------------------------
#	Function for appending to a logfile
#		Accepts 2 argument:
#			string content of the new line being appended to line matching pattern
#     string of where to generate the log
#	----------------------------------------------------------------
function __append_new_line_log
{
	__validate_num_arguments 2 $# "\"__append_new_line_log()\" expected in order: String of the new line being appended, path of where to generate log" "$FILES_HELPER_PATH/.."
	echo " ### " "$1" " ###"
	echo $(timestamp): " --- " "$1"  >> "$2/quickstartlog.log"
}

#	----------------------------------------------------------------
#	Function for appending to a file
#		Accepts 2 argument:
#			string content of the new line being appended to line matching pattern
#			string of the filename
#	----------------------------------------------------------------
function __append_new_line
{
	__validate_num_arguments 2 $# "\"__append_new_line()\" expected in order: String of the new line being appended, filename" "$FILES_HELPER_PATH/.."
	echo -e "$1" >> "$2"
}

#Creating a timestamp for logging
timestamp() {
  date +"%Y-%m-%d  %H:%M:%S"
}
