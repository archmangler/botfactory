#!/usr/bin/bash
#Get the resource details via the AzureRM REST API
#traiano@gmail.com
#
#References
#=========
#1. https://medium.com/@mauridb/calling-azure-rest-api-via-curl-eb10a06127
#2. https://docs.microsoft.com/en-us/rest/api/appservice/webapps/getconfiguration
#3. https://help.canary.tools/help/azure-troubleshooting 

subscription_id=""
resource_group_name="rsg-sea-ubot-westus"
app_id=""
password=""
tenant_id=""

target_resource_endpoint="https://management.azure.com/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers/Microsoft.Web/sites/${web_app_name}/config/web?api-version=2019-08-01"


function get_auth_token () { 

  bearer_auth_token=$(curl -s -X POST -d "grant_type=client_credentials&client_id=${app_id}&client_secret=${password}&resource=https%3A%2F%2Fmanagement.azure.com%2F" https://login.microsoftonline.com/${tenant_id}/oauth2/token | jq -r '.access_token')

  echo ${bearer_auth_token}  
}

function query_resource_endpoint () {

  echo "querying resource with curl -H Authorization: Bearer ${bearer_auth_token} ${target_resource_endpoint}"

  result=$(curl -H "Authorization: Bearer ${bearer_auth_token}" "${target_resource_endpoint}")

  echo ${result}
}

get_auth_token

query_resource_endpoint

