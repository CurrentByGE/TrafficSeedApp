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

# Trap ctrlc and exit if encountered

trap "trap_ctrlc" 2

# Clean input for machine type and tag, no spaces allowed

ASSET_TYPE="$(echo -e "${ASSET_TYPE}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TYPE_NOSPACE=${ASSET_TYPE// /_}
ASSET_TAG="$(echo -e "${ASSET_TAG}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TAG_NOSPACE=${ASSET_TAG// /_}

# Creating a logfile if it doesn't exist

touch "$quickstartRootDir/quickstartlog.log"

# Login into Cloud Foundy using the user input or password entered on request
userSpace="`cf t | grep Space | awk '{print $2}'`"
echo "userSpace: $userSpace"
echo "CF_SPACE: $CF_SPACE"

#if [[ "$userSpace" -ne "$CF_SPACE" ]] ; then
	__append_new_line_log "# quickstart.sh script started! #" "$quickstartRootDir"
	echo -e "Welcome to the Predix Quick start script!\n"
	echo -e "Be sure to set all your variables in the variables.sh file before you run quick start!\n"
	echo -e " ### Logging in to Cloud Foundry ### \n"

	if [[ "$#" -eq 1 ]] ; then
		__append_new_line_log "Using the provided authentication passed to the script..." "$quickstartRootDir"
		CF_PASSWORD="$1"
	else
		echo "ENTER YOUR PASSWORD NOW followed by ENTER"
		read -s CF_PASSWORD
	fi

	__append_new_line_log "Attempting to login user \"$CF_USERNAME\" to host \"$CF_HOST\" Cloud Foundry. Space: \"$CF_SPACE\" Org: \"$CF_ORG\"" "$quickstartRootDir"
	if cf login -a $CF_HOST -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORG -s $CF_SPACE --skip-ssl-validation; then
		__append_new_line_log "Successfully logged into CloudFoundry" "$quickstartRootDir"
	else
		__error_exit "There was an error logging into CloudFoundry. Is the password correct?" "$quickstartRootDir"
	fi
# fi
# Create instance of Predix UAA Service

if cf cs $UAA_SERVICE_NAME $UAA_PLAN $UAA_INSTANCE_NAME -c "{\"adminClientSecret\":\"$UAA_ADMIN_SECRET\"}"; then
	__append_new_line_log "UAA Service instance successfully created!" "$quickstartRootDir"
else
	__append_new_line_log "Couldn't create UAA service. Retrying..." "$quickstartRootDir"
	if cf cs $UAA_SERVICE_NAME $UAA_PLAN $UAA_INSTANCE_NAME -c "{\"adminClientSecret\":\"$UAA_ADMIN_SECRET\"}"; then
		__append_new_line_log "UAA Service instance successfully created!" "$quickstartRootDir"
	else
		__error_exit "Couldn't create UAA service instance..." "$quickstartRootDir"
	fi
fi


# Push a test app to get VCAP information for the Predix Services

echo -e "Pushing $TEMP_APP to initially create Predix Microservices ...\n"

if cf push $TEMP_APP -f $quickstartRootDir/testapp/manifest.yml --no-start --random-route; then
	__append_new_line_log "Temp app successfully pushed to CloudFoundry!" "$quickstartRootDir"
else
	__error_exit "There was an error pushing the TEMP_APP to CloudFoundry..." "$quickstartRootDir"
fi

# Bind Temp App to UAA instance

if cf bs $TEMP_APP $UAA_INSTANCE_NAME; then
	__append_new_line_log "UAA instance successfully binded to TEMP_APP!" "$quickstartRootDir"
else
	if cf bs $TEMP_APP $UAA_INSTANCE_NAME; then
    __append_new_line_log "UAA instance successfully binded to TEMP_APP!" "$quickstartRootDir"
  else
    __error_exit "There was an error binding the UAA service instance to the TEMP_APP!" "$quickstartRootDir"
  fi
fi

# Get the UAA enviorment variables (VCAPS)

if trustedIssuerID=$(cf env $TEMP_APP | grep predix-uaa* | grep issuerId*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
	echo "trustedIssuerID : $trustedIssuerID"
	__append_new_line_log "trustedIssuerID copied from enviromental variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting the UAA trustedIssuerID..." "$quickstartRootDir"
fi

if uaaURL=$(cf env $TEMP_APP | grep predix-uaa* | grep uri*| awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}' ); then
	__append_new_line_log "UAA URL copied from enviromental variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting the UAA URL..." "$quickstartRootDir"
fi


# Create instance of Predix TimeSeries Service

if cf cs $TIMESERIES_SERVICE_NAME $TIMESERIES_SERVICE_PLAN $TIMESERIES_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
	__append_new_line_log "Predix TimeSeries Service instance successfully created!" "$quickstartRootDir"
else
	if cf cs $TIMESERIES_SERVICE_NAME $TIMESERIES_SERVICE_PLAN $TIMESERIES_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
    __append_new_line_log "Predix TimeSeries Service instance successfully created!" "$quickstartRootDir"
  else
    __error_exit "Couldn't create Predix TimeSeries service instance..." "$quickstartRootDir"
  fi
fi

# Bind Temp App to TimeSeries Instance

if cf bs $TEMP_APP $TIMESERIES_INSTANCE_NAME; then
	__append_new_line_log "Predix TimeSeries instance successfully binded to TEMP_APP!" "$quickstartRootDir"
else
	if cf bs $TEMP_APP $TIMESERIES_INSTANCE_NAME; then
    __append_new_line_log "Predix TimeSeries instance successfully binded to TEMP_APP!" "$quickstartRootDir"
  else
    __error_exit "There was an error binding the Predix TimeSeries service instance to the $TEMP_APP!" "$quickstartRootDir"
  fi
fi


# Get the Zone ID and URIs from the enviroment variables (for use when querying and ingesting data)

if TIMESERIES_ZONE_ID=$(cf env $TEMP_APP | grep -m 1 zone-http-header-value | sed 's/"zone-http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	echo "TIMESERIES_ZONE_ID : $TIMESERIES_ZONE_ID"
	__append_new_line_log "TIMESERIES_ZONE_ID copied from enviromental variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting TIMESERIES_ZONE_ID..." "$quickstartRootDir"
fi

if TIMESERIES_INGEST_URI=$(cf env $TEMP_APP | grep -m 1 uri | sed 's/"uri": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	echo "TIMESERIES_INGEST_URI : $TIMESERIES_INGEST_URI"
	__append_new_line_log " TIMESERIES_INGEST_URI copied from enviromental variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting TIMESERIES_INGEST_URI..." "$quickstartRootDir"
fi

if TIMESERIES_QUERY_URI=$(cf env $TEMP_APP | grep -m 2 uri | grep https | sed 's/"uri": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	__append_new_line_log "TIMESERIES_QUERY_URI copied from enviromental variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting TIMESERIES_QUERY_URI..." "$quickstartRootDir"
fi

# Create instance of Predix Asset Service

if cf cs $ASSET_SERVICE_NAME $ASSET_SERVICE_PLAN $ASSET_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
	__append_new_line_log "Predix Asset Service instance successfully created!" "$quickstartRootDir"
else
	if cf cs $ASSET_SERVICE_NAME $ASSET_SERVICE_PLAN $ASSET_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
    __append_new_line_log "Predix Asset Service instance successfully created!" "$quickstartRootDir"
  else
    __error_exit "Couldn't create Predix Asset service instance..." "$quickstartRootDir"
  fi
fi

# Bind Temp App to Asset Instance

if cf bs $TEMP_APP $ASSET_INSTANCE_NAME; then
	__append_new_line_log "Predix Asset instance successfully binded to $TEMP_APP!" "$quickstartRootDir"
else
	if cf bs $TEMP_APP $ASSET_INSTANCE_NAME; then
		__append_new_line_log "Predix Asset instance successfully binded to $TEMP_APP!" "$quickstartRootDir"
	else
		__error_exit "There was an error binding the Predix Asset service instance to the $TEMP_APP!" "$quickstartRootDir"
	fi
fi

# Get the Zone ID from the enviroment variables (for use when querying Asset data)

if ASSET_ZONE_ID=$(cf env $TEMP_APP | grep -m 1 http-header-value | sed 's/"http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	__append_new_line_log "ASSET_ZONE_ID copied from environment variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting ASSET_ZONE_ID..." "$quickstartRootDir"
fi

# Create client ID for generic use by applications - including timeseries and asset scope

__createUaaClient "$uaaURL" "$TIMESERIES_ZONE_ID" "$ASSET_SERVICE_NAME" "$ASSET_ZONE_ID"

# Create a new user account

__addUaaUser "$uaaURL" "$TIMESERIES_ZONE_ID" "$ASSET_SERVICE_NAME" "$ASSET_ZONE_ID"

# Get the Asset URI and generate Asset body from the enviroment variables (for use when querying and posting data)

if assetURI=$(cf env $TEMP_APP | grep url*| grep ie-traffic* | awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}'); then
	__append_new_line_log "assetURI copied from environment variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting assetURI..." "$quickstartRootDir"
fi

if assetPostBody=$(printf '[{"uri": "%s", "tag": "%s", "description": "%s"}]%s' "/$ASSET_TYPE_NOSPACE/$ASSET_TAG_NOSPACE" "$ASSET_TAG_NOSPACE" "$ASSET_DESCRIPTION"); then
	__append_new_line_log "assetPostBody ok!" "$quickstartRootDir"
else
	__error_exit "There was an error getting assetPostBody..." "$quickstartRootDir"
fi

#if cd $quickstartRootDir/Asset-Post-Util-OS; then
#	__append_new_line_log "Calling the correct Asset-Post-Util depending on the OS" "$quickstartRootDir"
#else
#	__error_exit "Error changing directory" "$quickstartRootDir"
#fi

# Call the correct Asset-Post-Util depending on the OS in order to post the Asset data

# if [ "$(uname -s)" == "Darwin" ]
# then
# 	__append_new_line_log "Posting asset data to Predix Asset using OSx" "$quickstartRootDir"
# 	$quickstartRootDir/Asset-Post-Util-OS/OSx/Asset-Post-Util $uaaURL $assetURI/$ASSET_TYPE_NOSPACE $UAA_CLIENTID_GENERIC $UAA_CLIENTID_GENERIC_SECRET $ASSET_ZONE_ID "$assetPostBody"
# elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]
# then
# 	__append_new_line_log "Posting asset data to Predix Asset using Linux" "$quickstartRootDir"
# 	$quickstartRootDir/Asset-Post-Util-OS/Linux/Asset-Post-Util $uaaURL $assetURI/$ASSET_TYPE_NOSPACE $UAA_CLIENTID_GENERIC $UAA_CLIENTID_GENERIC_SECRET $ASSET_ZONE_ID "$assetPostBody"
# elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]
# then
# 	# First unzip the file to get the exe
#   unzip -o Asset-Post-Util.zip
# 	__append_new_line_log "Posting asset data to Predix Asset using Windows" "$quickstartRootDir"
#   $quickstartRootDir/Asset-Post-Util-OS/Win/Asset-Post-Util.exe $uaaURL $assetURI/$ASSET_TYPE_NOSPACE $UAA_CLIENTID_GENERIC $UAA_CLIENTID_GENERIC_SECRET $ASSET_ZONE_ID "$assetPostBody"
# fi

# __append_new_line_log "Deleting the $TEMP_APP" "$quickstartRootDir"
# if cf d $TEMP_APP -f -r; then
# 	__append_new_line_log "Successfully deleted $TEMP_APP" "$quickstartRootDir"
# else
# 	__append_new_line_log "Failed to delete $TEMP_APP. Retrying..." "$quickstartRootDir"
# 	if cf d $TEMP_APP -f -r; then
# 		__append_new_line_log "Successfully deleted $TEMP_APP" "$quickstartRootDir"
# 	else
# 		__append_new_line_log "Failed to delete $TEMP_APP. Last attempt..." "$quickstartRootDir"
# 		if cf d $TEMP_APP -f -r; then
# 			__append_new_line_log "Successfully deleted $TEMP_APP" "$quickstartRootDir"
# 		else
# 			__error_exit "Failed to delete $TEMP_APP. Giving up" "$quickstartRootDir"
# 		fi
# 	fi
# fi
# Call the correct zip depending on the OS... and get the base64 of the UAA base64ClientCredential
MYGENERICS_SECRET=$(echo -ne $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET | base64)
# Build our application from the 'predix-nodejs-starter' repo, passing it our MS instances
echo "param string $GIT_PREDIX_NODEJS_STARTER_URL $FRONT_END_APP_NAME $UAA_CLIENTID_GENERIC $MYGENERICS_SECRET $uaaURL $TIMESERIES_QUERY_URI $TIMESERIES_ZONE_ID $assetURI $ASSET_TYPE_NOSPACE $ASSET_TAG_NOSPACE $ASSET_ZONE_ID"
# $quickstartRootDir/scripts/build-basic-app.sh "$GIT_PREDIX_NODEJS_STARTER_URL" "$FRONT_END_APP_NAME" "$UAA_CLIENTID_GENERIC" "$MYGENERICS_SECRET" "$uaaURL" "$TIMESERIES_QUERY_URI" "$TIMESERIES_ZONE_ID" "$assetURI" "$ASSET_TYPE_NOSPACE" "$ASSET_TAG_NOSPACE" "$ASSET_ZONE_ID"

# if [ "$?" = "0" ]; then
# 	__append_new_line_log "Successfully built and pushed the front end application" "$quickstartRootDir"
# else
# 	__append_new_line_log "Build or Push of Basic Application Failed" "$quickstartRootDir" 1>&2
# 	exit 1
# fi
#
# if cf start $FRONT_END_APP_NAME; then
# 	printout="$FRONT_END_APP_NAME started!"
# 	__append_new_line_log "$printout" "$quickstartRootDir" 1>&2
# else
# 	__error_exit "Couldn't start $FRONT_END_APP_NAME" "$quickstartRootDir"
# fi

echo "Predix Dev Bootstrap Configuration" > $quickstartRootDir/config.txt
echo "Authors SDLP v1 2015" >> $quickstartRootDir/config.txt
echo "UAA URL: $uaaURL" >> $quickstartRootDir/config.txt
sed -i -- "s@#UAAURI@$uaaURL@g" ../manifest.yml
echo "UAA Admin Client ID: admin" >> $quickstartRootDir/config.txt
echo "UAA Admin Client Secret: $UAA_ADMIN_SECRET" >> $quickstartRootDir/config.txt
echo "UAA Generic Client ID: $UAA_CLIENTID_GENERIC" >> $quickstartRootDir/config.txt
echo "UAA Generic Client Secret: $UAA_CLIENTID_GENERIC_SECRET" >> $quickstartRootDir/config.txt
echo "TimeSeries Ingest URL:  $TIMESERIES_INGEST_URI" >> $quickstartRootDir/config.txt
echo "TimeSeries Query URL:  $TIMESERIES_QUERY_URI" >> $quickstartRootDir/config.txt
echo "TimeSeries ZoneID: $TIMESERIES_ZONE_ID" >> $quickstartRootDir/config.txt
echo "Asset URL:  $assetURI" >> $quickstartRootDir/config.txt
sed -i -- "s@#RESOURCEURL@$assetURI@g" ../manifest.yml
echo "Asset Zone ID: $ASSET_ZONE_ID" >> $quickstartRootDir/config.txt
sed -i -- "s@#PREDIXZONEID@$ASSET_ZONE_ID@g" ../manifest.yml
echo "Front end App Name URL: https://`cf a | grep \"$FRONT_END_APP_NAME\" | awk '{print $6}'`" >> $quickstartRootDir/config.txt

echo -e "You can execute 'cf env "$FRONT_END_APP_NAME"' to view all this information\n" >> $quickstartRootDir/config.txt
echo -e "In your web browser, navigate to your front end application endpoint found below\n" >> $quickstartRootDir/config.txt

# __append_new_line_log "Setting predix machine configurations" "$quickstartRootDir"

# $quickstartRootDir/scripts/machineconfig.sh $trustedIssuerID $TIMESERIES_INGEST_URI $TIMESERIES_ZONE_ID

echo -e "pre-setup completed....."
