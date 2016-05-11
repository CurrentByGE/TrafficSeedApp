#!/bin/bash
set -e

ERROR_HANDLING_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# These are a group of helper methods that will all for error handling
#

# ********************************** HELPER FUNCTIONS **********************************
#
#	----------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 2 argument:
#			string containing descriptive error message
#     string containing the root path of where the log will output
#	----------------------------------------------------------------
function __error_exit
{
	echo "********************************************"
	echo "Failure to run quickstart script"
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	echo "********************************************"
	echo -e $(timestamp): " --- ERROR:" "$1"  >> "$2/quickstartlog.log"
	echo -e $(timestamp): " --- Running the clean up script..." "$1"  >> "$2/quickstartlog.log"
	"$ERROR_HANDLING_PATH/cleanup.sh"
	exit 1
}

#	----------------------------------------------------------------
#	Function for checking the expected number of arguments
#		Accepts 4 argument:
#			string containing the expected number
#			string of the actual number of arguments
#			string explaining the expected arguments
#     string containing the root path of where the log will output
#	----------------------------------------------------------------
function __validate_num_arguments
{
	if [[ "$#" -ne 4 ]] ; then

		ERRORMSG="__validate_num_arguments() - Expected (4), Actual($#) arguments. Expected in order: number of arguments, actual number of arguments, explaination of required arguments, path to where log will be generated"
		echo "********************************************"
		echo "Failure to run quickstart script"
		echo "${PROGNAME}: ${ERRORMSG:-"Unknown Error"}" 1>&2
		echo "********************************************"
		echo -e $(timestamp): " --- ERROR:" "$ERRORMSG"  >> "$ERROR_HANDLING_PATH/../quickstartlog.log"
		exit 1
	fi

	if [[ "$1" -ne "$2" ]]; then
		ERRORMSG="Expected ($1), Actual($2) arguments. $3"
		echo "********************************************"
		echo "Failure to run quickstart script"
		echo "${PROGNAME}: ${ERRORMSG:-"Unknown Error"}" 1>&2
		echo "********************************************"
		echo -e $(timestamp): " --- ERROR:" "$ERRORMSG"  >> "$ERROR_HANDLING_PATH/../quickstartlog.log"
		exit 1
	fi
}

# this function is called when Ctrl-C is sent
function trap_ctrlc ()
{
    # perform cleanup here
    echo $(date +"%Y-%m-%d  %H:%M:%S") ": --- Ctrl-C caught...exiting script" >> "$ERROR_HANDLING_PATH/../quickstartlog.log"
		exit 1
}
