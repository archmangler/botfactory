#!/usr/bin/bash
#Small snippet to create a QnA knowledgebase
#From Microsofts DTO json format
#example: https://raw.githubusercontent.com/microsoft/botbuilder-tools/master/packages/QnAMaker/examples/QnADocumentsDTO.json
#https://github.com/microsoft/botbuilder-tools/tree/master/packages/QnAMaker/examples

kbase_file_path="kbase.json"
qna_subscription_key="b4dfa57e1bb04710b85bb257779d55d3"
kbase_name="srebotkb"
kb_id=""

function get_kb_id_by_name () {
  knowledgebases="\"knowledgebases\""
  bf qnamaker:kb:list --subscriptionKey=${qna_subscription_key}
  kb_id=$(bf qnamaker:kb:list --subscriptionKey=${qna_subscription_key} |jq -r --arg kbase_name "$kbase_name" '.knowledgebases|.[]|select(.name==$kbase_name)|.id')
  echo "checking if >>${kb_id}<< exists ..."
  if [ -n "$kb_id" ]
  then
    echo "kb exists as: ${kb_id}"
  else
    echo "kb ${kbase_name} does not exist"
  fi
  echo "${kb_id}"
}

function create_kb_from_json () {
  if [ -n "$kb_id" ]
  then
    echo "Knowledgebase ${kbase_name} exists as Id ${kb_id}"
  else
    echo "creating knowledge base ${kbase_name}"
    create_result=$(bf qnamaker:kb:create --save --name="${kbase_name}" --subscriptionKey=${qna_subscription_key} -i kbase.json)
  fi
}

get_kb_id_by_name
create_kb_from_json
