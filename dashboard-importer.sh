#!/usr/bin/env bash
KEY=xxxxxxxxxx
HOST="http://your.grafana.host.com"
FILE_DIR=path/to/dashboards

import_dashboard(){
	printf "Processing $1 file...\n"
	curl -XPOST "${HOST}/api/dashboards/db" --data-binary @./$1 \
			-H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KEY}"
	printf "\n"
}

if [[ -n "$1" ]]
	then
		for file in "$@"; do
			file="$FILE_DIR/$file"
			if [ -f "$file" ]
			then
				import_dashboard "$file"
			else
				echo "$file not found."
			fi
		done
    else
    	echo "Importing all"
    	for file in $FILE_DIR/*.json; do
			import_dashboard "$file"
		done
fi