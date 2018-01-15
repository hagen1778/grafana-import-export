#!/usr/bin/env bash
. "$(dirname "$0")/config.sh"

import_file(){
    if ! [ -f "$1" ]
    then
        echo "$file not found."
        return
    fi

    echo "Processing $1 file..."
    curl -k -XPOST "${HOST}/api/$3" --data-binary @./$1 -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer $2"
    echo
}

if [[ -n "$1" ]]; then
    for f in "$@"; do
        IFS='/' read -r -a args <<< "$f"
        if ! [ ${#args[@]} == 3 ]; then
            echo "Wrong param $f. Must be `organization/type/file`"
        fi

        ARGORG=${args[0]}
        if [ -d "$FILE_DIR/$ARGORG" ]; then
            for row in "${ORGS[@]}"; do
                ORG=${row%%:*}
                if [ $ARGORG == $ORG ]; then
                    KEY=${row#*:}
                    TYPE=${args[1]}
                    FILE=${args[2]}

                    for file in $FILE_DIR/$ORG/$TYPE/$FILE; do
                        if [ $TYPE == 'dashboards' ]; then
                            import_file $file $KEY 'dashboards/db'
                        else
                            import_file $file $KEY 'datasources'
                        fi
                    done
                fi
            done
        else
            echo "$FILE_DIR/$ARGORG does not exist."
        fi
    done
else
    printf "Importing all"
    for row in "${ORGS[@]}" ; do
        ORG=${row%%:*}
        KEY=${row#*:}
        DIR="$FILE_DIR/$ORG"

        printf "Datasources..."
        for file in $DIR/datasources/*.json; do
            import_file $file $KEY 'datasources'
        done

        printf "Dashboards..."
        for file in $DIR/dashboards/*.json; do
            import_file $file $KEY 'dashboards/db'
        done
    done
fi
