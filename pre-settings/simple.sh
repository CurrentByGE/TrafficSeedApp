#!/bin/bash

source variables.sh

cat << EOF
Welcome new Predix Developers!

Time to build out our first Predix Application from the command line.
Do not worry, we will explain everything as we execute each command, so
you will not need to worry if you know nothing about Predix or Cloud Foundry.

The goal of this script is to help you understand how to set up a new Predix App,
including UAA, TimeSeries, Asset and Views. Lastly, we will configure Predix Machine
for your Raspberry Pi.

Now it is time to log into our Predix Account.  Throughout this script we will be storing
your answers in variables.sh, so that you could execute this script headless in future
executions.

Please set the following variables to do this:

1) Predix API endpoint, which is your Cloud Foundry host domain name.

Right now there are two main endpoints:
A) Predix Basic Account : api.system.aws-usw02-pr.ice.predix.io
B) Predix Select Account : api.system.asv-pr.ice.predix.io

For this tutorial, we are assuming you are using a Predix Basic Account.

Therefore, we are setting your API endpoint to "api.system.aws-usw02-pr.ice.predix.io"

EOF

A=api.system.aws-usw02-pr.ice.predix.io
B=api.system.asv-pr.ice.predix.io

CF_HOST=$A

cat << EOF

2) Predix Username

"my.predix.account.email@myorg.com"

TYPE your Predix username in the above format followed by ENTER
EOF

read CF_USERNAME

cat << EOF

3) Predix Password

Now TYPE your Predix password followed by ENTER. Do not worry, we are not storing this.
EOF

read -s CF_PASSWORD

cat << EOF

4) Predix Organization, which is your Cloud Foundry Organization.

For this tutorial, we are assuming you are using a Predix Basic Account.

Therefore, we are setting your organization to the default "$CF_USERNAME"

Press any key when you are ready to proceed...

EOF

CF_ORG=$CF_USERNAME

read -n 1 -s

cat << EOF

5) Predix Space, which is your Cloud Foundry Space.

For this tutorial, we are assuming you are using a Predix Basic Account.

Therefore, we are setting your space to the default "dev"

Press any key when you are ready to proceed...

EOF

CF_SPACE=dev

read -n 1 -s

cat << EOF

Now that we have your variables set, it is time to execute the Predix Login command.

You will notice that Cloud Foundry terminal commands all start with "cf", which stands for Cloud Foundry.  Predix
uses Cloud Foundry to develope, manage and host Predix Microservices in our cloud. 

cf login -a $CF_HOST -u $CF_USERNAME -p <hidden> -o $CF_ORG -s $CF_SPACE --skip-ssl-validation

EOF

cf login -a $CF_HOST -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORG -s $CF_SPACE --skip-ssl-validation

cat << EOF

The "cf login" command uses the following parameters, which you can explicitly set in the command.
-a: Predix Cloud Foundry API endpoint
-u: Predix Username
-p: Predix PASSWORD
-o: Predix Cloud Foundry Organization
-s: Predix Cloud Foundry Space
--skip-ssl-validation: WHAT DOES THIS DO???

If you don't put these parameters inline with the command, don't worry.  If
you only typed "cf login" for your command, then it will ask you for each of these parameters
one-by-one. We use the full command to script the process, so it can be run with minimal manual
command line interaction.

Press any key when you are ready to proceed...

EOF

read -n 1 -s

cat << EOF

Great! Now we are logged in and we can begin creating Predix Services in our Predix Space.

First, let us take a look at all the available services in our Predix Cloud Foundry Marketplace.

The command "cf marketplace" or "cf m" outputs this in terminal for us.

cf m

EOF

cf m

cat << EOF

GREP and auto set the variables for each service :)!

As you can see above, it lists the service name, what plans your Predix account has access to,
and a simple description of the Predix Services.

Press any key when you are ready to proceed...

EOF

read -n 1 -s


###### WILL EVENTUALLY BE HANDLED BY GREP #######################################
#Name for your Reference Application Front End
FRONT_END_APP_NAME=predix-ref-app-frontend

#Name for the temp_app application
TEMP_APP=my-temp-app

#Predix UAA Credentails
#The name of the UAA service you are binding to
UAA_SERVICE_NAME=predix-uaa
#Name of the UAA plan (eg: Free)
UAA_PLAN=Tiered
#Name of your UAA instance (Can be anything you want)
UAA_INSTANCE_NAME=predix-ref-app-uaa
#The secret of the Admin client ID (Administrator Credentails)
UAA_ADMIN_SECRET=secret

#Predix TimeSeries Credentials
#The name of the TimeSeries service you are binding to
TIMESERIES_SERVICE_NAME=predix-timeseries
#Name of the TimeSeries plan (eg: Free)
TIMESERIES_SERVICE_PLAN=Bronze
#Name of your TimeSeries instance (Can be anything you want)
TIMESERIES_INSTANCE_NAME=predix-ref-app-timeseries
#Client ID to query and ingest to Time Series
TIMESERIES_CLIENT_ID=ts-client
#Secret for the client ID above
TIMESERIES_CLIENT_SECRET=secret

#Predix Asset Credentials
#The name of the Asset service you are binding to
ASSET_SERVICE_NAME=predix-asset
#Name of the Asset plan (eg: Free)
ASSET_SERVICE_PLAN=Tiered
#Name of your Asset instance (Can be anything you want)
ASSET_INSTANCE_NAME=predix-ref-app-asset
#Client ID to Post and query Asset service
ASSET_CLIENT_ID=asset-client
#Secret for the client ID above
ASSET_CLIENT_SECRET=secret
##############################################################################

cat << EOF

The first Predix Service that we instantiate is almost always the UAA Service.

User Account and Authentication (UAA) is a web service provided by Cloud Foundry to manage users
and OAuth2 clients. Its primary role is as an OAuth2 provider, issuing tokens for client applications
to use when they act on behalf of Cloud Foundry users. In collaboration with the login server, it can
authenticate users with their Predix Cloud Foundry credentials, and can act as an SSO service using those
credentials (or others). The service provides endpoints for managing user accounts and for registering
OAuth2 clients.

The Predix platform provides UAA as a service for developers to authenticate their application users.
As a Predix platform user, you can secure access to your application by obtaining a UAA instance from
the Cloud Foundry marketplace and configuring it to authenticate trusted users.

All Predix platform services require a UAA instance to ensure secure use of each service.

cf cs $UAA_SERVICE_NAME $UAA_PLAN $UAA_INSTANCE_NAME -c "{\"adminClientSecret\":\"hidden-secret\"}"

EOF

cf cs $UAA_SERVICE_NAME $UAA_PLAN $UAA_INSTANCE_NAME -c "{\"adminClientSecret\":\"$UAA_ADMIN_SECRET\"}"

cat << EOF

The command that we just ran deserves some explanation.

"cf create-service" or "cf cs" creates a new service instance in our Predix Space that we are logged into.

The first parameter for "cf cs" is the service name.  This matches the name of you see outputted in "cf m".
For the UAA service, it is $UAA_SERVICE_NAME.

Then, we state the Plan used for the Service, also matching the output from "cf m".
For your UAA service, it is $UAA_PLAN.

Next, we state the unique name used for the Service, which you can specify as anything.
For your UAA service, it is $UAA_INSTANCE_NAME, which we set for you.

Finally, -c "{\"adminClientSecret\":\"$UAA_ADMIN_SECRET\"}"
PLEASE EXPLAIN THIS!!!

In summary, the create service command always has the format:
"cf cs <service_name> <plan_type> <unique_instance_name> -c <specific_to_service>"

Press any key when you are ready to proceed...

EOF

read -n 1 -s
