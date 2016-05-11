#!/bin/bash
set -e
buildBasicAppRootDir=$(dirname $0)

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# Welcome new Predix Developers! Run this script to clone the predix-nodejs-starter repo,
# edit the manifest.yml file, build the application, and push the application to cloud foundry
#

# Be sure to set all your variables in the variables.sh file before you run quick start!
source "$buildBasicAppRootDir/variables.sh"
source "$buildBasicAppRootDir/error_handling_funcs.sh"
source "$buildBasicAppRootDir/files_helper_funcs.sh"

trap "trap_ctrlc" 2

PROGNAME=$(basename $0)
GIT_FRONT_END_FILENAME="predix-nodejs-starter"
GIT_BRANCH_RASPBERRY_PI="merge_with_master"
BUILD_APP_TEXTFILE="build-basic-app-summary.txt"


# ********************************** MAIN **********************************

# Validate the number of arguments
__validate_num_arguments 11 $# "\"build-basic-app.sh\" expected in order:  GitHub URL to clone, Application Name, UAA Client ID, UAA base64 authentication, UAA URI, TimeSeries URI to query data, the TimeSeries Zone ID, the Asset URI to query assets, the Asset Machine name, the tagname(s) to query, and the Asset Zone ID" "$buildBasicAppRootDir/.."

echo "********************************************"
echo "Building and Deploying Front End Application"
echo "********************************************"
cd ..

# Checkout the repo

if [ -d "$GIT_FRONT_END_FILENAME" ]
then
    echo "Deleting existing directory \"$GIT_FRONT_END_FILENAME\"..."
		if rm -rf "$GIT_FRONT_END_FILENAME"; then
			echo "Successfully deleted"
		else
			__error_exit "There was an error deleting the directory: \"$GIT_FRONT_END_FILENAME\"" "$buildBasicAppRootDir/.."
		fi
fi

if git clone "$1" "$GIT_FRONT_END_FILENAME"; then
	cd "$GIT_FRONT_END_FILENAME"
	if git checkout "$GIT_BRANCH_RASPBERRY_PI"; then
		echo "Successfully cloned \"$GIT_FRONT_END_FILENAME\" and checkout the branch \"$GIT_BRANCH_RASPBERRY_PI\""
	else
		cd ..
		__error_exit "There was an error checking out the branch \"$GIT_BRANCH_RASPBERRY_PI\"" "$buildBasicAppRootDir/.."
	fi
else
	__error_exit "There was an error cloning the repo \"$GIT_FRONT_END_FILENAME\". Be sure to have permissions to the repo, or SSH keys created for your account" "$buildBasicAppRootDir/.."
fi

# Edit the manifest.yml files

#		a) Modify the name of the applications
__find_and_replace "- name: .*" "- name: $2" "manifest.yml" "$buildBasicAppRootDir/.."

#		b) Add the services to bind to the application
__find_and_replace "\#services:" "services:" "manifest.yml" "$buildBasicAppRootDir/.."
__find_and_append_new_line "services:" "- $UAA_INSTANCE_NAME" "manifest.yml" "$buildBasicAppRootDir/.."
__find_and_append_new_line "services:" "- $TIMESERIES_INSTANCE_NAME" "manifest.yml" "$buildBasicAppRootDir/.."
__find_and_append_new_line "services:" "- $ASSET_INSTANCE_NAME" "manifest.yml" "$buildBasicAppRootDir/.."

#		c) Set the clientid and base64ClientCredentials
__find_and_replace "\#clientId: .*" "clientId: $3" "manifest.yml" "$buildBasicAppRootDir/.."
__find_and_replace "\#base64ClientCredential: .*" "base64ClientCredential: $4" "manifest.yml" "$buildBasicAppRootDir/.."

#		d) Set the timeseries and asset information to query the services
__find_and_replace "\#assetMachine: .*" "assetMachine: $9" "manifest.yml" "$buildBasicAppRootDir/.."
__find_and_replace "\#tagname: .*" "tagname: ${10}" "manifest.yml" "$buildBasicAppRootDir/.."

# Edit the applications config.json file

__find_and_replace ".*uaaUri\":.*" "    \"uaaURL\": \"$5\"," "config.json" "$buildBasicAppRootDir/.."
__find_and_replace ".*timeseries_zone\":.*" "    \"timeseries_zone\": \"$7\"" "config.json" "$buildBasicAppRootDir/.."
__find_and_replace ".*assetZoneId\":.*" "    \"assetZoneId\": \"${11}\"," "config.json" "$buildBasicAppRootDir/.."
__find_and_replace ".*tagname\":.*" "    \"tagname\": \"${10}\"," "config.json" "$buildBasicAppRootDir/.."
__find_and_replace ".*clientId\":.*" "    \"clientId\": \"$3\"," "config.json" "$buildBasicAppRootDir/.."
__find_and_replace ".*base64ClientCredential\":.*" "    \"base64ClientCredential\": \"$4\"," "config.json" "$buildBasicAppRootDir/.."

# Add the required Timeseries and Asset URIs
__find_and_append_new_line ".*\"windServiceUrl\":.*" "    timeseriesURL: $6," "config.json" "$buildBasicAppRootDir/.."
__find_and_append_new_line ".*\"windServiceUrl\":.*" "    assetURL: $8/$9," "config.json" "$buildBasicAppRootDir/.."
__find_and_replace "    timeseriesURL: $6," "    \"timeseriesURL\": \"$6\"," "config.json" "$buildBasicAppRootDir/.."
__find_and_replace "    assetURL: $8/$9," "    \"assetURL\": \"$8/$9\"," "config.json" "$buildBasicAppRootDir/.."

# Edit the /public/secure.html file
cd public
__find_and_replace "<\!--" "" "secure.html" "$buildBasicAppRootDir/.."
__find_and_replace "-->" "" "secure.html" "$buildBasicAppRootDir/.."
cd ..

# Build the application

echo "Building the application \"$2\"..."
if npm install; then
	echo "Succesfully built!"
else
	__error_exit "There was an error building the app with: \"npm install\"" "$buildBasicAppRootDir/.."
fi

# Push the application
echo "`pwd`"
echo "Pushing the application \"$2\" to Cloud Foundry..."
if cf push $2; then
	echo "Succesfully pushed the application!"
else
	echo "Failed to push application. Retrying..."
	if cf push $2; then
		echo "Succesfully pushed the application!"
	else
		__error_exit "There was an error pushing using: \"cf push\"" "$buildBasicAppRootDir/.."
	fi
fi

# Generate the build-basic-app-summary.txt

cd ..
if [ -f "$BUILD_APP_TEXTFILE" ]
then
    echo "Deleting existing summary file \"$BUILD_APP_TEXTFILE\"..."
		if rm -f "$BUILD_APP_TEXTFILE"; then
			echo "Successfully deleted"
		else
			__error_exit "There was an error deleting the file: \"$BUILD_APP_TEXTFILE\"" "$buildBasicAppRootDir/.."
		fi
fi

MY_FRONTAPP_URL=$(cf a | grep predix-ref-app-frontend | awk '{print $(NF)}')
echo "Application URL:	$MY_FRONTAPP_URL" > "$BUILD_APP_TEXTFILE"
echo "GitHub URL to Clone:	$1" >> "$BUILD_APP_TEXTFILE"
echo "Application Name:	$2" >> "$BUILD_APP_TEXTFILE"
echo "UAA URI: $5" >> "$BUILD_APP_TEXTFILE"
echo "UAA Cliend ID:	$3" >> "$BUILD_APP_TEXTFILE"
echo "TimeSeries URI to query data:	$6" >> "$BUILD_APP_TEXTFILE"
echo "TimeSeries Zone ID:	$7" >> "$BUILD_APP_TEXTFILE"
echo "Asset URI to query assets:	$8" >> "$BUILD_APP_TEXTFILE"
echo "The tagname to query for:	$9" >> "$BUILD_APP_TEXTFILE"
echo "Asset Zone ID:	${10}" >> "$BUILD_APP_TEXTFILE"

echo "********************************************"
echo "Successfully Built and Deployed Front End App"
echo "********************************************"
