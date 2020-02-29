#!/usr/bin/bash
#save current IFS
CURRENTIFS=$IFS
FILE=$(cat data.txt)
IFS=$'\n'
kbkeys=($FILE)
#restore IFS
IFS=CURRENTIFS

echo "first entry" ${kbkeys[0]}

for (( key=0; key<${#kbkeys[@]}; key++ ))
do
    echo "$key: ${kbkeys[$key]}"
done
