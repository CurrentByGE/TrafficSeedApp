#!/bin/bash
set -e
# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Be sure to set all your variables in the variables.sh file before you run quick start!

quickstartRootDir=$(dirname $0)
source "$quickstartRootDir/scripts/variables.sh"
source "$quickstartRootDir/scripts/error_handling_funcs.sh"
source "$quickstartRootDir/scripts/files_helper_funcs.sh"
source "$quickstartRootDir/scripts/curl_helper_funcs.sh"


CWD="`pwd`"
cd ../predix-edge-starter
if [ "$(uname -s)" == "Darwin" ]
then
	__append_new_line_log "Zipping up the configured Predix Machine..." "$quickstartRootDir"
	rm -rf $quickstartRootDir/PredixMachineContainer.zip
	if zip -r $quickstartRootDir/PredixMachineContainer.zip $PREDIXMACHINEHOME > zipoutput.log; then
		__append_new_line_log "Zipped up the configured Predix Machine and storing in $quickstartRootDir/PredixMachineContainer.zip" "$quickstartRootDir"
		#scp $quickstartRootDir/PredixMachineContainer.zip $TARGETDEVICEUSER@$TARGETDEVICEIP:PredixMachineContainer.zip
	else
		__error_exit "Failed to zip up PredixMachine_16.1.0" "$quickstartRootDir"
	fi
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]
then
	__append_new_line_log "You must manually zip of PredixMachine_16.1.0 to port it to the Raspberry Pi" "$quickstartRootDir"
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]
then
	__append_new_line_log "You must manually zip of PredixMachine_16.1.0 to port it to the Raspberry Pi" "$quickstartRootDir"
fi

cat $quickstartRootDir/config.txt
