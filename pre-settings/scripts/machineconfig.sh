# Predix Machine Config Setup Script (used within quickstart.sh)
# Authors: GE SDLP 2015-2016
# Expected inputs:
# issuerId_under_predix_uaa
# Timeseries_ingest_uri
# Timeseries_zone_id
# uri_under_predix_uaa

quickstartRootDir=$(dirname $0)
source $quickstartRootDir/variables.sh

# Sets a property value in the provided config file
# Arguments:
#  $1 the full path to the property file
#  $2 the key of the property to replace
#  $3 the value of the property
set_property()
{
    sed -i '' -e "s;\($2 *= *\).*;\1$3;g" "$1"
}

ASSET_TYPE="$(echo -e "${ASSET_TYPE}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TYPE_NOSPACE=${ASSET_TYPE// /_}
ASSET_TAG="$(echo -e "${ASSET_TAG}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
ASSET_TAG_NOSPACE=${ASSET_TAG// /_}

echo "UAA Url : $1"
set_property $quickstartRootDir/../$PREDIXMACHINEHOME/configuration/machine/com.ge.dspmicro.predixcloud.identity.config "com.ge.dspmicro.predixcloud.identity.uaa.token.url" \"$1\"

set_property $quickstartRootDir/../$PREDIXMACHINEHOME/configuration/machine/com.ge.dspmicro.predixcloud.identity.config "com.ge.dspmicro.predixcloud.identity.uaa.clientid" \"$UAA_CLIENTID_GENERIC\"

set_property $quickstartRootDir/../$PREDIXMACHINEHOME/configuration/machine/com.ge.dspmicro.predixcloud.identity.config "com.ge.dspmicro.predixcloud.identity.uaa.clientsecret" \"$UAA_CLIENTID_GENERIC_SECRET\"


#sed "s#com.ge.dspmicro.predixcloud.identity.oauth.authorize.url=.*#com.ge.dspmicro.predixcloud.identity.oauth.authorize.url=\"$4\"#" com.ge.dspmicro.predixcloud.identity.config > com.ge.dspmicro.predixcloud.identity.config.tmp
#mv com.ge.dspmicro.predixcloud.identity.config.tmp com.ge.dspmicro.predixcloud.identity.config

#sed "s#com.ge.dspmicro.predixcloud.identity.uaa.enroll.url=.*#com.ge.dspmicro.predixcloud.identity.uaa.enroll.url=\"$1\"#" com.ge.dspmicro.predixcloud.identity.config > com.ge.dspmicro.predixcloud.identity.config.tmp
#mv com.ge.dspmicro.predixcloud.identity.config.tmp com.ge.dspmicro.predixcloud.identity.config
websocket_config_file="$quickstartRootDir/../$PREDIXMACHINEHOME/configuration/machine/com.ge.dspmicro.websocketriver.send-0.config"
echo "Updating websocket river parameters in $websocket_config_file"
websocket_headervalue_prop="com.ge.dspmicro.websocketriver.send.header.zone.value"
set_property $websocket_config_file $websocket_headervalue_prop \"$3\"

websocket_url_prop="com.ge.dspmicro.websocketriver.send.destination.url"

set_property $websocket_config_file $websocket_url_prop \"$2\"

#sed "s#<register name=.*dataType=.*address=.*registerType=.*description=.*/>#<register name=\"$ASSET_TAG_NOSPACE\" dataType=\"FLOAT\" address=\"0\" registerType=\"HOLDING\" description=\"temperature\"/>#" com.ge.dspmicro.machineadapter.modbus-0.xml > com.ge.dspmicro.machineadapter.modbus-0.xml.tmp
#mv com.ge.dspmicro.machineadapter.modbus-0.xml.tmp com.ge.dspmicro.machineadapter.modbus-0.xml

#sed "s#<nodeName>.*</nodeName>#<nodeName>$ASSET_TAG_NOSPACE</nodeName>#" com.ge.dspmicro.machineadapter.modbus-0.xml > com.ge.dspmicro.machineadapter.modbus-0.xml.tmp
#mv com.ge.dspmicro.machineadapter.modbus-0.xml.tmp com.ge.dspmicro.machineadapter.modbus-0.xml

if [[ ! -z $ALL_PROXY ]]
then
	myProxyHostValue=${ALL_PROXY%:*}
	myProxyPortValue=${ALL_PROXY##*:}
	myProxyEnabled="true"
else
	myProxyHostValue=""
	myProxyPortValue=""
	myProxyEnabled="false"
fi

set_property $quickstartRootDir/../$PREDIXMACHINEHOME/configuration/machine/org.apache.http.proxyconfigurator-0.config "proxy.host" \"$myProxyHostValue\"

set_property $quickstartRootDir/../$PREDIXMACHINEHOME/configuration/machine/org.apache.http.proxyconfigurator-0.config "proxy.port" \"$myProxyPortValue\"

set_property $quickstartRootDir/../$PREDIXMACHINEHOME/configuration/machine/org.apache.http.proxyconfigurator-0.config "proxy.enabled" B\"$myProxyEnabled\"

echo "Predix Machine configuration update complete"