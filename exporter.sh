#!/usr/bin/env bash
. "$(dirname "$0")/config.sh"

fetch_fields() {
    curl -sSL -f -k -H "Authorization: Bearer ${1}" "${HOST}/api/${2}" | jq -r "if type==\"array\" then .[] else . end| .${3}"
}

for row in "${ORGS[@]}" ; do
    ORG=${row%%:*}
    KEY=${row#*:}
    DIR="$FILE_DIR/$ORG"

    mkdir -p "$DIR/dashboards"
    mkdir -p "$DIR/datasources"
    mkdir -p "$DIR/alert-notifications"

    for dash in $(fetch_fields $KEY 'search?query=&' 'uri'); do
        DB=$(echo ${dash}|sed 's,db/,,g').json
        echo $DB
        curl -f -k -H "Authorization: Bearer ${KEY}" "${HOST}/api/dashboards/${dash}" | jq '.dashboard.id = null' | jq '.overwrite = true' > "$DIR/dashboards/$DB"
    done

    for id in $(fetch_fields $KEY 'datasources' 'id'); do
        DS=$(echo $(fetch_fields $KEY "datasources/${id}" 'name')|sed 's/ /-/g').json
        echo $DS
        curl -f -k -H "Authorization: Bearer ${KEY}" "${HOST}/api/datasources/${id}" | jq '.id = null' | jq '.orgId = null' > "$DIR/datasources/$DS"
    done

    for id in $(fetch_fields $KEY 'alert-notifications' 'id'); do
        FILENAME=${id}.json
        echo $FILENAME
        curl -f -k -H "Authorization: Bearer ${KEY}" "${HOST}/api/alert-notifications/${id}" > "$DIR/alert-notifications/$FILENAME"
    done
done
