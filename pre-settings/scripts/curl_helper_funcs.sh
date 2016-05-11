#!/bin/bash
set -e
CURL_HELPER_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURL_HELPER_LOG_PATH="$CURL_HELPER_PATH/.."

source "$CURL_HELPER_PATH/variables.sh"
source "$CURL_HELPER_PATH/error_handling_funcs.sh"
source "$CURL_HELPER_PATH/files_helper_funcs.sh"

trap "trap_ctrlc" 2

# Predix Dev Bootstrap Script
# Authors: GE SDLP 2015
#
# These are a group of helper methods that will perform CURL commands
#

#	----------------------------------------------------------------
#	Function for finding an attribute value in a JSON string
#		Accepts 2 argument:
#			string of the JSON
#     string of what property to look for
#  Returns:
#     String of the JSON attribute value
#	----------------------------------------------------------------

function __jsonval {
    __validate_num_arguments 2 $# "\"curl_helper_funcs:__jsonval\" expected in order: String of JSON, String of property to look for" "$CURL_HELPER_LOG_PATH"

    temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
    echo ${temp##*|}
}

#	----------------------------------------------------------------
#	Function for finding and replacing a pattern found in a file
#		Accepts 1 argument:
#			string of UAA URL
#  Returns:
#     String of the the UAA Admin Token
#	----------------------------------------------------------------
function __getUaaAdminToken
{
  if [[ "1" -ne "$#" ]]; then
		echo ""
  else
    UAA_ADMIN_BASE64=$(echo -ne admin:$UAA_ADMIN_SECRET | base64)
    responseCurl=`curl -X GET "$1/oauth/token?grant_type=client_credentials" -H "Authorization: Basic $UAA_ADMIN_BASE64" -H "Content-Type: application/x-www-form-urlencoded"`

    tokenType=$( __jsonval "$responseCurl" "token_type" )
    accessToken=$( __jsonval "$responseCurl" "access_token" )

    echo "$tokenType $accessToken"
	fi
}


#	----------------------------------------------------------------
#	Function for processing a UAA Client ID
#		Accepts 4 argument:
#			string of UAA URI
#     string of the TIMESERIES_ZONE_ID
#     string of the IE_SERVICE_NAME
#     string of the ASSET_ZONE_ID
#
#	----------------------------------------------------------------
function __createUaaClient
{
  __validate_num_arguments 4 $# "\"curl_helper_funcs:__createUaaClient\" expected in order: UAA URI, Time Series Zone ID, Asset Service Name, and Asset Service Zone ID" "$CURL_HELPER_LOG_PATH"

  __append_new_line_log "Making CURL GET request to get UAA Admin Token..." "$CURL_HELPER_LOG_PATH"

  adminUaaToken=$( __getUaaAdminToken "$1" )
  if [ ${#adminUaaToken} -lt 3 ]; then
    __error_exit "Failed to get a token from \"$1\"" "$CURL_HELPER_LOG_PATH"
  else
    __append_new_line_log "Got UAA admin token" "$CURL_HELPER_LOG_PATH"
    __append_new_line_log "Making CURL GET request to create UAA Client ID \"$UAA_CLIENTID_GENERIC\"..." "$CURL_HELPER_LOG_PATH"
    responseCurl=`curl "$1/oauth/clients" -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $adminUaaToken" --data-binary '{"client_id":"'$UAA_CLIENTID_GENERIC'","client_secret":"'$UAA_CLIENTID_GENERIC_SECRET'","scope":["'$3.zones.$4.user'","uaa.none","openid"],"authorized_grant_types":["client_credentials","authorization_code","refresh_token","password"],"authorities":["openid","uaa.none","uaa.resource","'$3.zones.$4.user'"],"autoapprove":["openid"]}'`
    if [ ${#responseCurl} -lt 3 ]; then
      __error_exit "Failed to make request to create UAA User to \"$1\"" "$CURL_HELPER_LOG_PATH"
    else
      # If the response has a attribute for "error" ,
      # AND not a value of "Client already exists: $UAA_CLIENTID_GENERIC" for attribute "error_description" then fail
      errorAttribute=$( __jsonval "$responseCurl" "error" )
      errorDescriptionAttribute=$( __jsonval "$responseCurl" "error_description" )

      if [ ${#errorAttribute} -gt 3 ]; then
        if [ "$errorDescriptionAttribute" != "Client already exists: $UAA_CLIENTID_GENERIC" ]; then
          __error_exit "The request failed to successfully create or reuse the Client ID" "$CURL_HELPER_LOG_PATH"
        else
          __append_new_line_log "Successfully re-using existing Client ID: \"$UAA_CLIENTID_GENERIC\"" "$CURL_HELPER_LOG_PATH"
        fi
      else
        __append_new_line_log "Successfully created new Client ID: \"$UAA_CLIENTID_GENERIC\"" "$CURL_HELPER_LOG_PATH"
      fi
    fi
  fi

}

#	----------------------------------------------------------------
#	Function for processing a UAA Client ID
#		Accepts 1 argument:
#			string of UAA URI
#	----------------------------------------------------------------
function __addUaaUser
{
  echo "1: $1, 2: $2, 3: $3, 4: $4"
  __validate_num_arguments 4 $# "\"curl_helper_funcs:__addUaaUser\" expected in order: UAA URI, Time Series Zone ID, Asset Service Name, and Asset Service Zone ID" "$CURL_HELPER_LOG_PATH"
  __append_new_line_log "Making CURL GET request to get UAA Admin Token..." "$CURL_HELPER_LOG_PATH"

  adminUaaToken=$( __getUaaAdminToken "$1" )
  if [ ${#adminUaaToken} -lt 3 ]; then
    __error_exit "Failed to get a token from \"$1\"" "$CURL_HELPER_LOG_PATH"
  else
    __append_new_line_log "Got UAA admin token" "$CURL_HELPER_LOG_PATH"
    __append_new_line_log "Making CURL GET request to create UAA user \"$UAA_USER_NAME\"..." "$CURL_HELPER_LOG_PATH"
    responseCurl=`curl "$1/Users" -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $adminUaaToken" --data-binary '{"userName":"'$UAA_USER_NAME'","password":"'$UAA_USER_PASSWORD'","emails":[{"value":"'$UAA_USER_EMAIL'"}]}'`
    echo "responseCurl: $responseCurl"
    userId=$( __jsonval "$responseCurl" "id" )
    echo "userId: $userId"

    createGroup=`curl "$1/Groups" -H "Pragma: no-cache" -H "content-type: application/json" -H "Cache-Control: no-cache" -H "authorization: $adminUaaToken" --data-binary '{"displayName":"'$3.zones.$4.user'"}'`
    groupId=$( __jsonval "$createGroup" "id" )
    echo "groupId: $groupId"
    groupId=$(echo "$groupId"|tr -d "]")
    echo "groupId after change: $groupId"

    addUserToGroup=`curl "$1/Groups/$groupId" -X PUT -H "Pragma: no-cache" -H "content-type: application/json" -H "Cache-Control: no-cache" -H "authorization: $adminUaaToken" -H 'if-match: *' --data-binary '{"id":"'$groupId'","displayName":"'$3.zones.$4.user'","members":["'$userId'"]}'`
    echo "addUserToGroup: $addUserToGroup"



    #echo "'if-match: *' --data-binary '{\"id\":'$groupId','\"displayName\":'$3.zones.$4.user',\"members\":['$userId']}'"
    #groupCurl3=`curl "$1/Groups/$groupId" -X PUT -H "Pragma: no-cache" -H "content-type: application/json" -H "Cache-Control: no-cache" -H "authorization: $adminUaaToken" -H 'if-match: *' --data-binary '{"id":"'$groupId'","displayName":"'$3.zones.$4.user'","members":["'$userId'"]}'`
    #'{"meta":{"version":0,"created":"2016-05-10T19:06:10.261Z","lastModified":"2016-05-10T19:06:10.261Z"},"id":"30a00190-151e-4b3b-aab4-d47dbd97e83d","displayName":"ie-traffic.zones.51cce74b-8701-404e-91f1-703d5363c044.user","schemas":["urn:scim:schemas:core:1.0"],"members":["5a66cdd7-9ef1-4658-92f6-efacce108700"]}'
    #groupResponseCurl=`curl "$1/Groups" -H "Pragma: no-cache" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Authorization: $adminUaaToken" --data-binary '{"displayName":"'$3.zones.$4.user'"}'`


    #echo "groupCurl3: $groupCurl3"

    if [ ${#responseCurl} -lt 3 ]; then
      __error_exit "Failed to make request to create UAA User to \"$1\"" "$CURL_HELPER_LOG_PATH"
    else
      # If the response has a attribute for "error" ,
      # AND not a value of "Username already in use: $UAA_USER_NAME" for attribute "error_description" then fail
      errorAttribute=$( __jsonval "$responseCurl" "error" )
      errorDescriptionAttribute=$( __jsonval "$responseCurl" "error_description" )

      if [ ${#errorAttribute} -gt 3 ]; then
        if [ "$errorDescriptionAttribute" != "Username already in use: $UAA_USER_NAME" ]; then
          __error_exit "The request failed to successfully create or reuse the UAA User \"$UAA_USER_NAME\"" "$CURL_HELPER_LOG_PATH"
        else
          __append_new_line_log "Successfully re-using existing UAA User: \"$UAA_USER_NAME\"" "$CURL_HELPER_LOG_PATH"
        fi
      else
        __append_new_line_log "Successfully created new UAA User: \"$UAA_USER_NAME\"" "$CURL_HELPER_LOG_PATH"
      fi
    fi
  fi
}
