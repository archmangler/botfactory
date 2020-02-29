#!/usr/bin/bash

kbase_name="srebotkb"
knowledgebases="\"knowledgebases\""

cat list.json |jq -r --arg kbase_name "$kbase_name" '.knowledgebases|.[]|select(.name==$kbase_name)|.id'

