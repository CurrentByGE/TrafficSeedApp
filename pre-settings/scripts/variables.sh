# Predix Cloud Foundry Credentials
# Keep all values inside double quotes

#########################################################
# Mandatory User configurations that need to be updated
#########################################################

############## Proxy Configurations #############

# If proxy is needed, proxy settings in format http://proxy_host:proxy_port
ALL_PROXY=""

############## Front End Configurations #############

# Name for your Predix Cloud Front End Application - must be unique across whole cloud
FRONT_END_APP_NAME="predix-node-js-starter-anshulbakliwal"

########### Predix Cloud (CF) Configurations ###########

# Cloud Foundry Host Domain Name - Predix Basic already set, change if in another cloud
CF_HOST="api.system.aws-usw02-pr.ice.predix.io"

# Predix Cloud Organization
CF_ORG="anshul.bakliwal@ge.com"

# Could Foundry Space - default already set
CF_SPACE="dev"

# Predix.io Username
CF_USERNAME="anshul.bakliwal@ge.com"

############### UAA Configurations ###############
# The name of the UAA service you are binding to - default already set
UAA_SERVICE_NAME="predix-uaa"

# Name of the UAA plan (eg: Free) - default already set
UAA_PLAN="Tiered"

# Name of your UAA instance - default already set
UAA_INSTANCE_NAME="ie-predix-uaa"

# The username of the new user to authenticate with the application
UAA_USER_NAME="hacker1"

# The email address of username above
UAA_USER_EMAIL="hacker1@ge.com"

# The password of the user above
UAA_USER_PASSWORD="hacker1"

# The secret of the UAA Admin ID (Administrator Credentails)
UAA_ADMIN_SECRET="adminpassword"

# The client ID that will be created with necessary UAA scope/authorities
UAA_CLIENTID_GENERIC="ui_client1"

# The generic client ID password
UAA_CLIENTID_GENERIC_SECRET="ui_client1"

############# Predix Asset Configurations #############

# Name of the "Asset" that is recorded to Predix Asset
ASSET_TYPE="/asset/mydevice1"

# Name of the tag (Asset name ex: Wind Turbine) you want to ingest to timeseries with. NO SPACES
ASSET_TAG="mydevice1.temperature"

#Description of the Machine that is recorded to Predix Asset
ASSET_DESCRIPTION="My Device"

###############################
# Optional configurations
###############################

# GITHUB repo to pull predix-nodejs-starter
GIT_PREDIX_NODEJS_STARTER_URL="https://github.com/PredixDev/predix-nodejs-starter.git"

# Name for the temp_app application used for binding and retrieving VCAP environment variable information
TEMP_APP="test-app"


############# Predix TimeSeries Configurations ##############

#The name of the TimeSeries service you are binding to - default already set
TIMESERIES_SERVICE_NAME="redis-1"

#Name of the TimeSeries plan (eg: Free) - default already set
TIMESERIES_SERVICE_PLAN="shared-vm"

#Name of your TimeSeries instance - default already set
TIMESERIES_INSTANCE_NAME="event-service-redis"

############# Predix Asset Configurations ##############

#The name of the Asset service you are binding to - default already set
ASSET_SERVICE_NAME="ie-traffic"

#Name of the Asset plan (eg: Free) - default already set
ASSET_SERVICE_PLAN="Beta"

#Name of your Asset instance - default already set
ASSET_INSTANCE_NAME="ie-traffic-service"

#Target Device to transfer the Predix Machine, e.g. edison, raspberrypi, etc
TARGETDEVICE="edison"

#Target Device IP, at command line on device, use ifconfig to get ip adress
TARGETDEVICEIP="192.168.1.229"

#Target Device User
TARGETDEVICEUSER="root"

#Predix Machine Home Dir
PREDIXMACHINEHOME=PredixMachine
