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

# Creating a logfile if it doesn't exist

touch "$quickstartRootDir/quickstartlog.log"

# Login into Cloud Foundy using the user input or password entered on request
userSpace="`cf t | grep Space | awk '{print $2}'`"
echo "userSpace: $userSpace"
echo "CF_SPACE: $CF_SPACE"

if [[ "$userSpace" -ne "$CF_SPACE" ]] ; then
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
fi
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


# Create instance of Redis Service

if cf cs $REDIS_SERVICE_NAME $REDIS_SERVICE_PLAN $REDIS_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
	__append_new_line_log "Redis Service instance successfully created!" "$quickstartRootDir"
else
	if cf cs $REDIS_SERVICE_NAME $REDIS_SERVICE_PLAN $REDIS_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
    __append_new_line_log "Redis Service instance successfully created!" "$quickstartRootDir"
  else
    __error_exit "Couldn't create Redis service instance..." "$quickstartRootDir"
  fi
fi

# Bind Temp App to Redis Instance

if cf bs $TEMP_APP $REDIS_INSTANCE_NAME; then
	__append_new_line_log "Redis instance successfully binded to TEMP_APP!" "$quickstartRootDir"
else
	if cf bs $TEMP_APP $REDIS_INSTANCE_NAME; then
    __append_new_line_log "Redis instance successfully binded to TEMP_APP!" "$quickstartRootDir"
  else
    __error_exit "There was an error binding the Redis service instance to the $TEMP_APP!" "$quickstartRootDir"
  fi
fi


# Get the Zone ID and URIs from the enviroment variables (for use when querying and ingesting data)

if REDIS_ZONE_ID=$(cf env $TEMP_APP | grep -m 1 zone-http-header-value | sed 's/"zone-http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	echo "REDIS_ZONE_ID : $REDIS_ZONE_ID"
	__append_new_line_log "REDIS_ZONE_ID copied from enviromental variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting REDIS_ZONE_ID..." "$quickstartRootDir"
fi

if REDIS_INGEST_URI=$(cf env $TEMP_APP | grep -m 1 uri | sed 's/"uri": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	echo "REDIS_INGEST_URI : $REDIS_INGEST_URI"
	__append_new_line_log " REDIS_INGEST_URI copied from enviromental variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting REDIS_INGEST_URI..." "$quickstartRootDir"
fi

if REDIS_QUERY_URI=$(cf env $TEMP_APP | grep -m 2 uri | grep https | sed 's/"uri": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	__append_new_line_log "REDIS_QUERY_URI copied from enviromental variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting REDIS_QUERY_URI..." "$quickstartRootDir"
fi

# Create instance of IE Service

if cf cs $IE_SERVICE_NAME $IE_SERVICE_PLAN $IE_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
	__append_new_line_log "IE Service instance successfully created!" "$quickstartRootDir"
else
	if cf cs $IE_SERVICE_NAME $IE_SERVICE_PLAN $IE_INSTANCE_NAME -c "{\"trustedIssuerIds\":[\"$trustedIssuerID\"]}"; then
    __append_new_line_log "IE Service instance successfully created!" "$quickstartRootDir"
  else
    __error_exit "Couldn't create IE service instance..." "$quickstartRootDir"
  fi
fi

# Bind Temp App to IE Instance

if cf bs $TEMP_APP $IE_INSTANCE_NAME; then
	__append_new_line_log "IE instance successfully binded to $TEMP_APP!" "$quickstartRootDir"
else
	if cf bs $TEMP_APP $IE_INSTANCE_NAME; then
		__append_new_line_log "IE instance successfully binded to $TEMP_APP!" "$quickstartRootDir"
	else
		__error_exit "There was an error binding the IE service instance to the $TEMP_APP!" "$quickstartRootDir"
	fi
fi

# Get the Zone ID from the enviroment variables (for use when querying IE data)

if IE_ZONE_ID=$(cf env $TEMP_APP | grep -m 1 http-header-value | sed 's/"http-header-value": "//' | sed 's/",//' | tr -d '[[:space:]]'); then
	__append_new_line_log "IE_ZONE_ID copied from environment variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting IE_ZONE_ID..." "$quickstartRootDir"
fi

# Create client ID for generic use by applications - including redis and ie scope

__createUaaClient "$uaaURL" "$REDIS_ZONE_ID" "$IE_SERVICE_NAME" "$IE_ZONE_ID"

# Create a new user account

__addUaaUser "$uaaURL" "$REDIS_ZONE_ID" "$IE_SERVICE_NAME" "$IE_ZONE_ID"

# Get the IE URI and generate IE body from the enviroment variables (for use when querying and posting data)

if ieURI=$(cf env $TEMP_APP | grep url*| grep ie-traffic* | awk 'BEGIN {FS=":"}{print "https:"$3}' | awk 'BEGIN {FS="\","}{print $1}'); then
	__append_new_line_log "ieURI copied from environment variables!" "$quickstartRootDir"
else
	__error_exit "There was an error getting ieURI..." "$quickstartRootDir"
fi

# Call the correct zip depending on the OS... and get the base64 of the UAA base64ClientCredential
MYGENERICS_SECRET=$(echo -ne $UAA_CLIENTID_GENERIC:$UAA_CLIENTID_GENERIC_SECRET | base64)
# Build our application from the 'predix-nodejs-starter' repo, passing it our MS instances
echo "param string $FRONT_END_APP_NAME $UAA_CLIENTID_GENERIC $MYGENERICS_SECRET $uaaURL $REDIS_QUERY_URI $REDIS_ZONE_ID $ieURI  $IE_ZONE_ID"
echo "Predix Dev Bootstrap Configuration" > $quickstartRootDir/config.txt
echo "Authors SDLP v1 2015" >> $quickstartRootDir/config.txt
echo "UAA URL: $uaaURL" >> $quickstartRootDir/config.txt
sed -i -- "s@#UAAURI@$uaaURL@g" ../manifest.yml
echo "UAA Admin Client ID: admin" >> $quickstartRootDir/config.txt
echo "UAA Admin Client Secret: $UAA_ADMIN_SECRET" >> $quickstartRootDir/config.txt
echo "client secret base 64 encoded: $MYGENERICS_SECRET" >> $quickstartRootDir/config.txt
sed -i -- "s@#CLIENTSECRET@$MYGENERICS_SECRET@g" ../manifest.yml
echo "UAA Generic Client ID: $UAA_CLIENTID_GENERIC" >> $quickstartRootDir/config.txt
sed -i -- "s@#CLIENTID@$UAA_CLIENTID_GENERIC@g" ../manifest.yml
echo "UAA Generic Client Secret: $UAA_CLIENTID_GENERIC_SECRET" >> $quickstartRootDir/config.txt
echo "Redis Ingest URL:  $REDIS_INGEST_URI" >> $quickstartRootDir/config.txt
echo "Redis Query URL:  $REDIS_QUERY_URI" >> $quickstartRootDir/config.txt
echo "Redis ZoneID: $REDIS_ZONE_ID" >> $quickstartRootDir/config.txt
echo "IE URL:  $ieURI" >> $quickstartRootDir/config.txt
sed -i -- "s@#RESOURCEURL@$ieURI@g" ../manifest.yml
echo "IE Zone ID: $IE_ZONE_ID" >> $quickstartRootDir/config.txt
sed -i -- "s@#PREDIXZONEID@$IE_ZONE_ID@g" ../manifest.yml
echo "Front end App Name URL: https://`cf a | grep \"$FRONT_END_APP_NAME\" | awk '{print $6}'`" >> $quickstartRootDir/config.txt

echo -e "You can execute 'cf env "$FRONT_END_APP_NAME"' to view all this information\n" >> $quickstartRootDir/config.txt
echo -e "In your web browser, navigate to your front end application endpoint found below\n" >> $quickstartRootDir/config.txt

echo -e "pre-setup completed....."
