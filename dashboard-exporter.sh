#!/usr/bin/env bash
ORGS=(
"org1:xxxxxxxxxx"
"org2:xxxxxxxxxx")
HOST="http://your.grafana.host"
FILE_DIR=path/to/dashboards

if [ ! -d "$FILE_DIR" ] ; then
    mkdir -p "$FILE_DIR"
fi


for row in "${ORGS[@]}" ; do
    ORG=${row%%:*}
    KEY=${row#*:}
    DIR="$FILE_DIR/$ORG"

    if [ ! -d "$DIR" ] ; then
    	mkdir -p "$DIR"
	fi

	for dash in $(curl -sSL -k -H "Authorization: Bearer $KEY" "{$HOST}/api/search?query=&" | jq '.' |grep -i uri|awk -F '"uri": "' '{ print $2 }'|awk -F '"' '{print $1 }'); do
	  DB=$(echo ${dash}|sed 's,db/,,g').json
	  curl -k -H "Authorization: Bearer ${KEY}" "${HOST}/api/dashboards/${dash}" | jq '.dashboard.id = null' > "$DIR/$DB"
	done
done