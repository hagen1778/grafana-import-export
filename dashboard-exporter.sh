#!/usr/bin/env bash
KEY=xxxxxxxxxx
HOST="http://your.grafana.host.com"
FILE_DIR=path/to/dashboards

if [ ! -d "$FILE_DIR" ] ; then
    mkdir -p "$FILE_DIR"
fi

for dash in $(curl -sSL -k -H "Authorization: Bearer $KEY" $HOST/api/search\?query\=\& | jq '.' |grep -i uri|awk -F '"uri": "' '{ print $2 }'|awk -F '"' '{print $1 }'); do
  DB=$(echo ${dash}|sed 's,db/,,g').json
  curl -k -H "Authorization: Bearer ${KEY}" "${HOST}/api/dashboards/${dash}" | jq '.dashboard.id = null' > "$FILE_DIR/$DB"
done