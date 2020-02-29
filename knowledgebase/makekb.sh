#!/usr/bin/bash
#Small snippet to create a QnA knowledgebase
#From Microsofts DTO json format
#example: https://raw.githubusercontent.com/microsoft/botbuilder-tools/master/packages/QnAMaker/examples/QnADocumentsDTO.json
#https://github.com/microsoft/botbuilder-tools/tree/master/packages/QnAMaker/examples

kbase_file_path="kbase.json"
qna_subscription_key=""
kbase_name="srebotkb"
kb_id=""

function create_kb_from_json () {
  if [ -n "$kb_id" ]
  then
    echo "Knowledgebase ${kbase_name} exists as Id ${kb_id}"
  else
    echo "creating knowledge base ${kbase_name}"
    create_result=$(bf qnamaker:kb:create --name="${kbase_name}" --subscriptionKey=${qna_subscription_key} -i ${kbase_file_path})
    echo ${create_result}
  fi
}

function get_kb_id_by_name () {
  echo "checking if >>${kbase_name}<< exists ..."
  knowledgebases="\"knowledgebases\""
  kb_id=$(bf qnamaker:kb:list --subscriptionKey=${qna_subscription_key} |jq -r --arg kbase_name "$kbase_name" '.knowledgebases|.[]|select(.name==$kbase_name)|.id')
  if [ -n "$kb_id" ]
  then
    echo "kb exists as: ${kb_id}"
  else
    echo "kb ${kbase_name} does not exist"
  fi
  echo "${kb_id}"
}

function save_and_train_kb() {
  if [[ ${kb_id} ]]
  then
  #to be implemented in a future version
  echo "save and train not implemented yet ..."
  fi
}

function publish_kb () {
  if [[ ${kb_id} ]]
  then
    echo "publishing knowledgebase ${kbase_name}"
    echo bf qnamaker:kb:publish --subscriptionKey=${qna_subscription_key} --kbId="${kb_id}"
    publish_results=$(bf qnamaker:kb:publish --subscriptionKey=${qna_subscription_key} --kbId="${kb_id}" )
    echo "${publish_results}"
  fi
}

function get_kb_endpoint_key () {
  if [[ ${kb_id} ]]
  then
    echo "getting QnA KB configuration details ..."
    kb_endpoint_key=$(bf qnamaker:endpointkeys:list --subscriptionKey=${qna_subscription_key}|jq -r '.primaryEndpointKey')
    echo "${kb_endpoint_key}"
  fi
}

function get_kb_endpoint_host () {
  if [[ ${kb_id} ]]
  then
    echo "getting the configured endpoint host for knowledgebase ${kbase_name}"
    kb_host=$(bf qnamaker:kb:get --subscriptionKey=${qna_subscription_key} --kbId="${kb_id}" | jq -r '.hostName')
    echo "${kb_host}"
  fi
}

#check if the kb exists
get_kb_id_by_name

#create the kb IF NOT ALREADY THERE!
create_kb_from_json

#get the kb id if newly created
get_kb_id_by_name

#publish the kb
publish_kb

#get the QnAmaker KB connection parameters
get_kb_endpoint_key

#get the endpoint host for the kb
get_kb_endpoint_host
