#!/usr/bin/bash
#Get the resource details via the AzureRM REST API
#traiano@gmail.com
#
#References
#=========
#1. https://medium.com/@mauridb/calling-azure-rest-api-via-curl-eb10a06127
#2. https://docs.microsoft.com/en-us/rest/api/appservice/webapps/getconfiguration
#3. https://help.canary.tools/help/azure-troubleshooting 

subscription_id="4decbd3a-55d4-453f-a7ad-17327cff8f01"
resource_group_name="rsg-sea-ubot-westus"

app_id=""
password=""

tenant_id=""
cognitive_services_account_name="ubot-account"

#target_resource_endpoint="https://management.azure.com/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers/Microsoft.CognitiveServices/accounts/${cognitive_services_account_name}?api-version=2017-04-18"

target_resource_endpoint="https://management.azure.com/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers/Microsoft.CognitiveServices/accounts/${cognitive_services_account_name}/listKeys?api-version=2017-04-18"

function get_auth_token () { 

  bearer_auth_token=$(curl -s -X POST -d "grant_type=client_credentials&client_id=${app_id}&client_secret=${password}&resource=https%3A%2F%2Fmanagement.azure.com%2F" https://login.microsoftonline.com/${tenant_id}/oauth2/token | jq -r '.access_token')

  echo ${bearer_auth_token}  
}

function query_resource_endpoint () {

  echo "querying resource with curl ..." 

  echo ${target_resource_endpoint}
  result=$(curl -s -X POST -H "Authorization: Bearer ${bearer_auth_token}" -H "Content-Length:0" "${target_resource_endpoint}" | jq -r '."key1"')

  echo ${result}
}

get_auth_token

query_resource_endpoint

