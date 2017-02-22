#!/usr/bin/env bash
ORGS=(
"org1:xxxxxxxxxx"
"org2:xxxxxxxxxx")
HOST="http://your.grafana.host"
FILE_DIR=path/to/dashboards

import_dashboard(){
	if [ -f "$1" ]
	then
		printf "Processing $1 file...\n"
		curl -k -XPOST "${HOST}/api/dashboards/db" --data-binary @./$1 -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer $2"
		printf "\n"
	else
		echo "$file not found."
	fi
}

if [[ -n "$1" ]]
	then
		for f in "$@"; do
			ARGORG=${f%%/*}
			if [ -d "$FILE_DIR/$ARGORG" ]
			then
				for row in "${ORGS[@]}" ; do
					ORG=${row%%:*}
					if [ $ARGORG == $ORG ]
					then
						KEY=${row#*:}
						DASH=${f#*/}

						for file in $FILE_DIR/$ORG/$DASH; do
							import_dashboard $file $KEY
						done
					fi
				done
			else
				echo "$FILE_DIR/$ARGORG does not exist."
			fi
		done
    else
    	echo "Importing all"
    	for row in "${ORGS[@]}" ; do
			ORG=${row%%:*}
			KEY=${row#*:}
			DIR="$FILE_DIR/$ORG"

			for file in $DIR/*.json; do
				import_dashboard $file $KEY
			done
		done

fi