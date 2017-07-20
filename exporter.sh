#!/usr/bin/env bash
ORGS=(
"org1:xxxxxxxxxx"
"org2:xxxxxxxxxx")
HOST="http://your.grafana.host"
FILE_DIR=path/to/export

fetch_fields() {
    echo $(curl -sSL -f -k -H "Authorization: Bearer ${1}" "${HOST}/api/${2}" | jq -r "if type==\"array\" then .[] else . end| .${3}")
}

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

	if [ ! -d "$DIR/dashboards" ] ; then
	    mkdir -p "$DIR/dashboards"
	fi

	if [ ! -d "$DIR/datasources" ] ; then
    	    mkdir -p "$DIR/datasources"
    	fi

    for dash in $(fetch_fields $KEY 'search?query=&' 'uri'); do
        DB=$(echo ${dash}|sed 's,db/,,g').json
        echo $DB
    	curl -f -k -H "Authorization: Bearer ${KEY}" "${HOST}/api/dashboards/${dash}" | jq '.dashboard.id = null' > "$DIR/dashboards/$DB"
    done

	for id in $(fetch_fields $KEY 'datasources' 'id'); do
       DS=$(echo $(fetch_fields $KEY "datasources/${id}" 'name')|sed 's/ /-/g').json
       echo $DS
   	   curl -f -k -H "Authorization: Bearer ${KEY}" "${HOST}/api/datasources/${id}" | jq '.id = null' | jq '.orgId = null' > "$DIR/datasources/$DS"
    done

done