#!/usr/bin/bash
#test script for developing Chat bots based on Azure's
#conversational bot framework
#
#Most of the configuration via cli was obtained from these issues: 
#
#https://github.com/Azure/azure-cli/issues/6888
#https://github.com/Azure/azure-cli/issues/11433

#NOTE: order of declaration of the variables 
#here is important as interpolation takes
#place
code_directory="code"
bot_service_location="westus"
subscription_id="xxxxxxxxx"
resource_group_name="rsg-sea-ubot-westus"
tenant_id="xxxxxxxxx"

#a differently permissioned set of keys for API queries
api_query_appid="xxxxxxxx"
api_query_password="xxxxxxxxx"

#knowledgebase specific variables 
kbase_file_path="knowledgebase/kbase.json"
qna_subscription_key=""
kbase_name="srebotkb"
kb_id=""
#chatbot specific variables
chatbot_application_name="ubot"
chatbot_resource_group="rsg-sea-${chatbot_application_name}-${bot_service_location}"
chatbot_sku="S1"
chatbot_app_serviceplan_name="${chatbot_application_name}-service-plan"
chatbot_bot_name="${chatbot_application_name}-bot"
chatbot_bot_display_name="${chatbot_bot_name}"
chatbot_display_name="${chatbot_bot_display_name}"
chatbot_application_webapp_name="${chatbot_bot_name}-webapp"
chatbot_application_display_name="${chatbot_application_webapp_name}"
chatbot_appid="xxxxxxxx"
chatbot_application_password="xxxxxxxx"
available_to_other_tenants="true"
chatbot_application_language="CSharp"
chatbot_arm_template_file="templates/template.json"
chatbot_location="westus"
qnaservice_startup_delay="10"
qnamaker_search_service_name="${chatbot_application_name}-search"
qnamaker_search_service_sku="Standard"
qnamaker_account_name="${chatbot_application_name}-account"
qnamaker_account_sku="S0"
qnamaker_account_location="${bot_service_location}" #or "westus"
qnamaker_extension_version="latest"
qnamaker_resource_group="${chatbot_resource_group}"
#PLEASE DOUBLECHECK IF THIS ENDPOINT IS WHAT YOU THNK IT IS!!!
qna_runtime_endpoint="https://${chatbot_application_webapp_name}.azurewebsites.net"
#QNA Maker Knowledge Base Credentials
qnamaker_endpoint_hostname=""
qnamaker_knowledgebase_id=""
qnamaker_auth_key=""
primary_search_endpoint_key=""
secondary_search_endpoint_key=""
app_service_plan_name=""
web_app_name=""
#App insights parameters
app_insights_location="${chatbot_location}"
use_app_insights="true"

#the server farm id depends on the following resource id to 
#be correctly built up. The service plan name must be correct
#to match the service plan.
server_farm_id="/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers/Microsoft.Web/serverfarms/${chatbot_app_serviceplan_name}"
server_farm_location="${chatbot_location}"
server_farm_sku="S1"

function create_resource_group () {

 echo "================= Create chatbot resource group ===================="
 echo ""
  echo az group create --location ${bot_service_location} \
                            --name ${chatbot_resource_group} \
                            --subscription ${subscription_id}

  chatbot_resource_group=$( az group create \
                            --location ${bot_service_location} \
                            --name ${chatbot_resource_group} \
                            --subscription ${subscription_id} | jq -r '.name')

  echo "Created resource group: ${chatbot_resource_group}"
 echo "================= Created chatbot resource group ===================="
 echo ""

}

function deploy_search_service () {

 echo "================= Deploy search service ===================="
 echo ""
 echo az search service create --resource-group "${chatbot_resource_group}" --name "${qnamaker_search_service_name}" --sku "${qnamaker_search_service_sku}"

 search_service_name=$(az search service create \
   --resource-group "${chatbot_resource_group}" \
   --name "${qnamaker_search_service_name}" \
   --sku "${qnamaker_search_service_sku}"|jq -r '.name')

 echo "Search service create result:  ${search_service_name}"
 echo az search admin-key show --resource-group "${chatbot_resource_group}" --service-name "${qnamaker_search_service_name}"

 search_service_key_data=$(az search admin-key show --resource-group "${chatbot_resource_group}" --service-name "${qnamaker_search_service_name}")

 primary_search_endpoint_key=$(echo ${search_service_key_data} | jq -r '.primaryKey')
 secondary_search_endpoint_key=$(echo ${search_service_key_data} | jq -r '.secondaryKey')

 echo "Search Service Primary Endpoint Key = ${primary_search_endpoint_key}"
 echo "Search Service Secondary Endpoint Key = ${secondary_search_endpoint_key}"
 echo "================= Deployed search service ===================="
 echo ""

}

function create_app_service_plan () {

 echo "================= Create Cognitive Services Service Plan ===================="
 echo ""
  echo "CREATING appservice plan"
  echo az appservice plan create --resource-group "${chatbot_resource_group}" --name "${chatbot_app_serviceplan_name}" --sku "${chatbot_sku}"

  app_service_plan_name=$(az appservice plan create \
    --resource-group "${chatbot_resource_group}" \
    --name "${chatbot_app_serviceplan_name}" \
    --sku "${chatbot_sku}" | jq -r '.name')
  echo "App Service Plan: ${app_service_plan_name}"
  echo "DONE CREATING appservice plan"
 echo "================= Created Cognitive Services Service Plan ===================="
 echo ""

}

function create_chatbot_webapp () {

 echo "================= Create Web app for Cognitive Services ===================="
 echo ""
  #create a web app service for the bot
  echo "Creating required webapp "
  echo "az webapp create \
    --resource-group "${chatbot_resource_group}" \
    --name "${chatbot_application_webapp_name}" \
    --plan "${chatbot_app_serviceplan_name}" | jq -r '.name'"

  web_app_name=$(az webapp create \
    --resource-group "${chatbot_resource_group}" \
    --name "${chatbot_application_webapp_name}" \
    --plan "${chatbot_app_serviceplan_name}" | jq -r '.name')

   echo "${web_app_name}"
 echo "================= Done Creating Web app for Cognitive Services ===================="
 echo ""
}


function configure_search_service () {

 echo "================= Configure search service ===================="
 echo ""
  echo az webapp config appsettings set --resource-group "${chatbot_resource_group}" --name "${chatbot_application_webapp_name}"  --settings AzureSearchName="${qnamaker_search_service_name}" AzureSearchAdminKey="${primary_search_endpoint_key}" PrimaryEndpointKey="${chatbot_application_webapp_name}-PrimaryEndpointKey" SecondaryEndpointKey="${chatbot_application_webapp_name}-SecondaryEndpointKey" QNAMAKER_EXTENSION_VERSION="${qnamaker_extension_version}"

  web_app_config_results=$(az webapp config appsettings set \
   --resource-group "${chatbot_resource_group}" \
   --name "${chatbot_application_webapp_name}" \
   --settings AzureSearchName="${qnamaker_search_service_name}" \
   PrimaryEndpointKey="${chatbot_application_webapp_name}-PrimaryEndpointKey" \
   SecondaryEndpointKey="${chatbot_application_webapp_name}-SecondaryEndpointKey" \
   AzureSearchAdminKey="${primary_search_endpoint_key}" \
   DefaultAnswer="No good match found in KB." \
   QNAMAKER_EXTENSION_VERSION="${qnamaker_extension_version}")
   echo "${web_app_config_results}"
   
   #NOT LIKE THIS!!!
   #PrimaryEndpointKey="${primary_search_endpoint_key}" \
   #SecondaryEndpointKey="${secondary_search_endpoint_key}" \
 echo "================= Configured search service ===================="
 echo ""
}

function enable_webapp_cors () {

 echo "================= Enable CORS for Webapp ===================="
 echo ""
  echo az webapp cors add \
    --resource-group "${chatbot_resource_group}" \
    --name "${chatbot_application_webapp_name}" -a "*"

  cors_registration_result=$(az webapp cors add \
    --resource-group "${chatbot_resource_group}" \
    --name "${chatbot_application_webapp_name}" -a "*") 

  echo "CORS configuration: ${cors_registration_result}"
 echo "================= Done Enabling CORS for Webapp ===================="
 echo ""
}

function update_serviceplan_sku () {
 echo "================= Update SKU Service Plan ===================="
 echo ""
  #update the app service-plan sku for the chat bot
  echo az appservice plan update \
     --resource-group "${chatbot_resource_group}" \
     --name "${chatbot_app_serviceplan_name}" \
     --sku "${chatbot_sku}"

  az appservice plan update \
     --resource-group "${chatbot_resource_group}" \
     --name "${chatbot_app_serviceplan_name}" \
     --sku "${chatbot_sku}"
 echo "================= Updated SKU Service Plan ===================="
 echo ""
}


function create_qnamaker_account () {

 echo "================= Create QnA Maker Account ===================="
 echo ""
    
    echo "az cognitiveservices account create \
      --resource-group ${qnamaker_resource_group} \
      --name ${qnamaker_account_name} \
      --kind QnAMaker \
      --sku ${qnamaker_account_sku} \
      --location ${qnamaker_account_location} \
      --api-properties qnaRuntimeEndpoint=${qna_runtime_endpoint}"

    qnamaker_account_create_results=$(az cognitiveservices account create \
      --resource-group "${qnamaker_resource_group}" \
      --name "${qnamaker_account_name}" \
      --kind QnAMaker \
      --sku "${qnamaker_account_sku}" \
      --location "${qnamaker_account_location}" \
      --api-properties qnaRuntimeEndpoint="${qna_runtime_endpoint}" | jq -r '.id')

    #we need a delay loop here to be more sure cognitive services has time
    #to come up. See this issue: https://github.com/OfficeDev/microsoft-teams-faqplusplus-app/issues/71
    for (( count=0; count<${qnaservice_startup_delay}; count++ ))
    do 
      echo "$count > QnAMaker Details: ${qnamaker_account_create_results}"
      sleep 30
    done
 echo "================= Created QnA Maker Account ===================="
 echo ""
}

function get_qnamaker_account_key () {

 echo "================= Get QnA Maker Account Maker ===================="
 echo ""
  echo "getting a bearer token to query api directly ..."
  bearer_auth_token=$(curl -s -X POST -d "grant_type=client_credentials&client_id=${api_query_appid}&client_secret=${api_query_password}&resource=https%3A%2F%2Fmanagement.azure.com%2F" https://login.microsoftonline.com/${tenant_id}/oauth2/token | jq -r '.access_token')

  echo "Got bearer token: ${bearer_auth_token}"

  echo "get qnamaker cognitive service account keys, qna_subscription_key"
  target_resource_endpoint="https://management.azure.com/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers/Microsoft.CognitiveServices/accounts/${qnamaker_account_name}/listKeys?api-version=2017-04-18"

  echo "Querying ${target_resource_endpoint}"

  #The primary QnAmaker account key is the QnA subscription key used to create the QnAmaker Kbase
  qna_subscription_key=$(curl -s -X POST -H "Authorization: Bearer ${bearer_auth_token}" -H "Content-Length:0" "${target_resource_endpoint}" | jq -r '."key1"')

  echo ${qna_subscription_key}
 echo "================= Got QnA Maker Account Maker ===================="
 echo ""
}

function create_kb_from_json () {
 echo "================= Create QnA Knowledgebase from JSON document ===================="
 echo ""
  if [ -n "${qnamaker_knowledgebase_id}" ]
  then
    echo "knowledge base ${kbase_name} exists as id ${qnamaker_knowledgebase_id}"
  else
    echo "creating knowledge base ${kbase_name}"
    echo bf qnamaker:kb:create --save --name="${kbase_name}" --subscriptionKey=${qna_subscription_key} -i ${kbase_file_path}
    create_result=$(bf qnamaker:kb:create --save --name="${kbase_name}" --subscriptionKey=${qna_subscription_key} -i ${kbase_file_path})
    echo "${create_result}"
  fi
 echo "================= Done create QnA Knowledgebase from JSON document  ===================="
 echo ""
}

function get_kb_id_by_name () {
 echo "================= Get the knowledgebase Id ===================="
 echo ""
  knowledgebases="\"knowledgebases\""
  qnamaker_knowledgebase_data=$(bf qnamaker:kb:list --subscriptionKey=${qna_subscription_key} |jq -r --arg kbase_name "$kbase_name" '.knowledgebases|.[]|select(.name==$kbase_name)|.id')

  #we take care to select only one entry if
  #there are duplicate knowledgebases.
  #unfortunately there is no way to tell
  #which duplicate knowledgebase is the
  #right one ...

  CURRENTIFS=$IFS
  IFS=$'\n'
  kbkeys=($qnamaker_knowledgebase_data)
  #restore IFS
  IFS=CURRENTIFS

  echo "first matching entry" ${kbkeys[0]}
  qnamaker_knowledgebase_id=${kbkeys[0]}
  echo "checking for duplicate knowledgebases ..."

  #loop through any duplicates for user inspection
  for (( key=0; key<${#kbkeys[@]}; key++ ))
  do
    echo "$key: ${kbkeys[$key]}"
  done
  echo "Knowledgebase Id is ${qnamaker_knowledgebase_id}"

  if [ -n "${qnamaker_knowledgebase_id}" ]
  then
    echo "kb ${kbase_name} exists as: ${qnamaker_knowledgebase_id}"
  else
    echo "kb ${kbase_name} does not exist"
  fi
  echo "${qnamaker_knowledgebase_id}"
 echo "================= Got the knowledgebase Id ===================="
 echo ""
}

function save_and_train_kb() {
  #to be implemented in a future version
  if [ -n "${qnamaker_knowledgebase_id}" ]
  then
    echo "save and train not implemented yet ..."
  else
    echo "kb ${kbase_name} does not exist"
  fi
}

function publish_kb () {
 echo "================= Publish knowledgebase ===================="
 echo ""
  if [ -n "${qnamaker_knowledgebase_id}" ]
  then
    echo "publishing knowledgebase ${kbase_name}"
    publish_results=$(bf qnamaker:kb:publish --subscriptionKey=${qna_subscription_key} --kbId="${qnamaker_knowledgebase_id}" )
    echo "${publish_results}"
  else
    echo "kb ${kbase_name} does not exist"
  fi
 echo "================= Published knowledgebase ===================="
 echo ""
}

function get_kb_endpoint_key () {
 echo "================= Get KB endpoint key ===================="
 echo ""
  if [ -n "${qnamaker_knowledgebase_id}" ]
  then
    echo "getting QnA KB endpoint key for ${kbase_name} ..."
    qnamaker_auth_key=$(bf qnamaker:endpointkeys:list --subscriptionKey=${qna_subscription_key}|jq -r '.primaryEndpointKey')
    echo "Knowledgebase auth key is ${qnamaker_auth_key}"
  else
    echo "kb ${kbase_name} does not exist"
  fi
 echo "================= Got KB endpoint key  ===================="
 echo ""
}

function get_kb_endpoint_host () {
 echo "================= Get KB endpoint host ===================="
 echo ""
  if [ -n "${qnamaker_knowledgebase_id}" ]
  then
    echo "getting the configured endpoint host for knowledgebase ${kbase_name}"
    qnamaker_endpoint_hostname=$(bf qnamaker:kb:get --subscriptionKey=${qna_subscription_key} --kbId="${kb_id}" | jq -r '.hostName')
    echo "Knowledgebase host is ${qnamaker_endpoint_hostname}"
  else
    echo "kb ${kbase_name} does not exist"
  fi
 echo "================= Done Getting KB endpoint host ===================="
 echo ""
}

function connect_to_qnamaker_kbase () {

 echo "================= Connect Webapp to QnAmaker Webapp ===================="
 echo ""
  echo az webapp config appsettings set \
    -g "${chatbot_resource_group}" \
    -n "${chatbot_application_webapp_name}" \
    --settings \
    DisplayName="${chatbot_display_name}" \
    QnAAuthKey="${qnamaker_auth_key}" \
    QnAEndpointHostName="${qnamaker_endpoint_hostname}" \
    QnAKnowledgebaseId="${qnamaker_knowledgebase_id}"

  config_qnamaker_kbase_result=$(az webapp config appsettings set \
    -g "${chatbot_resource_group}" \
    -n "${chatbot_application_webapp_name}" \
    --settings \
    DisplayName="${chatbot_display_name}" \
    QnAAuthKey="${qnamaker_auth_key}" \
    QnAEndpointHostName="${qnamaker_endpoint_hostname}" \
    QnAKnowledgebaseId="${qnamaker_knowledgebase_id}")

  echo "connect QnAMaker to cognitive services webapp: " ${config_qnamaker_kbase_results}
 echo "================= Connected Webapp to QnAmaker Webapp ===================="
 echo ""
}

function create_bot_app_registration () {

 echo "================= Configure bot app registration ===================="
 echo ""
  echo az ad app create --display-name "${chatbot_application_name}" --password "REDACTED" --available-to-other-tenants "${available_to_other_tenants}"

  chatbot_app_reg_result=$(az ad app create --display-name "${chatbot_application_name}" --password "${chatbot_application_password}" --available-to-other-tenants "${available_to_other_tenants}")

  echo "AppId request ${chatbot_app_reg_result}"
 echo "================= Configured bot app registration ===================="
 echo ""

}

function configure_bot_webapp () {

 echo "================= Configure bot webapp  ===================="
 echo ""
  web_app_config_results=$(az webapp config appsettings set \
   --resource-group "${chatbot_resource_group}" \
   --name "${chatbot_bot_name}" \
   --settings AzureSearchName="${qnamaker_search_service_name}" \
   PrimaryEndpointKey="${chatbot_application_webapp_name}-PrimaryEndpointKey" \
   SecondaryEndpointKey="${chatbot_application_webapp_name}-SecondaryEndpointKey" \
   AzureSearchAdminKey="${primary_search_endpoint_key}" \
   DefaultAnswer="No good match found in KB." \
   QnAAuthKey="${qnamaker_auth_key}" \
   QnAEndpointHostName="${qnamaker_endpoint_hostname}" \
   QnAKnowledgebaseId="${qnamaker_knowledgebase_id}"
   QNAMAKER_EXTENSION_VERSION="${qnamaker_extension_version}")
   echo "${web_app_config_results}"
 echo "================= Done Configuring bot webapp  ===================="
 echo ""
}

function create_chat_bot_arm () {
 echo "================= Creating bot from ARM template  ===================="
 echo ""
 az group deployment create \
  --resource-group "${chatbot_resource_group}" \
  --template-file "${chatbot_arm_template_file}" \
  --parameters templates/parameters.json \
  QnAAuthKey="${qnamaker_auth_key}" \
  QnAEndpointHostName="${qnamaker_endpoint_hostname}" \
  QnAKnowledgebaseId="${qnamaker_knowledgebase_id}" \
  appId="${chatbot_appid}" \
  appSecret="${chatbot_application_password}" \
  siteName="${chatbot_application_name}-webapp" \
  botId="${chatbot_application_name}-bot" \
  sku="${chatbot_sku}" \
  appInsightsLocation="\"${app_insights_location}\"" \
  useAppInsights="${use_app_insights}" \
  location="${chatbot_location}" \
  serverFarmId="${server_farm_id}" \
  serverFarmLocation="${server_farm_location}" \
  --name "${chatbot_bot_name}-deployment"

 echo "================= Created bot from ARM template  ===================="
 echo ""
}

function connect_bot_to_qnamaker_kbase () {

    echo "================= Connect Bot to QnAmaker Knowledgebase  ===================="
    echo ""
  echo az webapp config appsettings set \
    --resource-group "${chatbot_resource_group}" \
    --name "${chatbot_bot_name}" \
    --settings \
    QnAAuthKey="${qnamaker_auth_key}" \
    QnAEndpointHostName="${qnamaker_endpoint_hostname}" \
    QnAKnowledgebaseId="${qnamaker_knowledgebase_id}"

  config_qnamaker_kbase_result=$(az webapp config appsettings set \
    --resource-group "${chatbot_resource_group}" \
    --name "${chatbot_bot_name}" \
    --settings \
    QnAAuthKey="${qnamaker_auth_key}" \
    QnAEndpointHostName="${qnamaker_endpoint_hostname}" \
    QnAKnowledgebaseId="${qnamaker_knowledgebase_id}")

  echo "connect QnAMaker to cognitive services webapp: " ${config_qnamaker_kbase_results}
    echo "================= Connected Bot to QnAmaker Knowledgebase  ===================="
    echo ""
}

function prepare_bot_user_code () {

    echo "================= Begin Preparing Bot user source code ===================="
    echo ""
  echo "preparing bot code deployment ..."
  echo az bot prepare-deploy --lang Csharp --code-dir "code" --proj-file-path "./QnABot.csproj"

  prepare=$(az bot prepare-deploy \
              --lang Csharp \
              --code-dir "${code_directory}" \
              --proj-file-path QnABot.csproj)

  echo "Bot code prepare results ..."
  echo $prepare
    echo "================= End Preparing Bot user source code ===================="
    echo ""

}

function upload_bot_user_code () {

    cd "${code_directory}"
    rm -rf .deployment
    rm -rf bot.zip 
    zip -f bot.zip
    zip -r bot.zip *

    echo "================= Begin Uploading Bot user source code ===================="
    echo ""

    echo az webapp deployment source config-zip --resource-group "${chatbot_resource_group}" --name "${chatbot_application_webapp_name}" --src "bot.zip"

    deploy=$(az webapp deployment source config-zip \
      --resource-group "${chatbot_resource_group}" \
      --name "${chatbot_application_webapp_name}" \
      --src "bot.zip")

    echo "${deploy}"
    cd ..
    echo "================= End Uploading Bot user source code ===================="
    echo ""
}

#1. Create a resource group to contain the project
create_resource_group

#2. Deploy a search service for cognitive services
deploy_search_service

#3. Create an app service plan
create_app_service_plan

#4. create chatbot web app
create_chatbot_webapp

#5. Configure the web app with search service parameters 
configure_search_service

#6. Enable CORS  
enable_webapp_cors

#8. Create the QnAmaker Account
create_qnamaker_account

#9. A QnA Maker account key must be available
#before the knowledgebase can be created.
get_qnamaker_account_key

#10. create knowledgebase
get_kb_id_by_name
create_kb_from_json
get_kb_id_by_name
save_and_train_kb
publish_kb
get_kb_endpoint_key
get_kb_endpoint_host

#11. Connect the web app to the QnA knowledgebase 
connect_to_qnamaker_kbase

#12. Create bot app Id
#NEED TO WORK ON PERMISSIONS HERE
create_bot_app_registration

#13. Creating the chatbot and chatbot's webservice 
create_chat_bot_arm

#14. Prepare the sample code.
prepare_bot_user_code

#15. Upload the prepared code
upload_bot_user_code
