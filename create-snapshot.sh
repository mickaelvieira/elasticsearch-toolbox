#!/bin/bash


ES_HOST="localhost"
ES_PORT="9200";

if ! type "curl" > /dev/null; then
    echo "Curl does not seem to be installed."
    exit 1
fi

if ! type "jq" > /dev/null; then
    echo "does not seem to be installed."
    exit 1
fi

usage() {
    HELP="\n"
    HELP+="Usage:\n"
    HELP+=" $0 [options]\n"
    HELP+="\n"
    HELP+="Options:\n"
    HELP+=" -i \t Provide the index name\n"
    HELP+=" -a \t Provide the alias name\n"
    HELP+=" -h \t Provide the server name, default localhost\n"
    HELP+=" -p \t Provide the server port, default 9200\n"
    echo -e ${HELP} 1>&2;
    exit 1;
}

while getopts ":i:a:h:p" o; do
  case "${o}" in
    i)
      ES_INDEX=${OPTARG}
      ;;
    a)
      ES_ALIAS=${OPTARG}
      ;;
    h)
      ES_HOST=${OPTARG}
      ;;
    p)
      ES_PORT=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

ES_DOMAIN="${ES_HOST}:${ES_PORT}"
ES_SNAPSHOT_URL="${ES_DOMAIN}/_snapshot"

ES_REPOSITORY="mickael_backup"
ES_SNAPSHOT="mickael_snapshot"

RESPONSE=$(curl -s -XGET "${ES_SNAPSHOT_URL}/${ES_REPOSITORY}")
STATUS=$(echo ${RESPONSE} | jq .status)

if [[ -n ${STATUS} ]]; then

    if [[ ${STATUS} == '404' ]]; then

        echo
        read -e -p "Repository [${ES_REPOSITORY}] does not exist. Would you like to create it? [Y/n]: " confirminfo
        echo

        if [[ ${confirminfo} == "n" ]]; then
            echo "Interrupted!"
            exit
        fi

        echo
        read -e -p "Enter the backup location: " location
        echo

        if [[ -n ${location} ]]; then
            curl -XPUT "${ES_SNAPSHOT_URL}/${ES_REPOSITORY}" -d "{
                \"type\": \"fs\",
                \"settings\": {
                    \"location\": \"${location}\",
                    \"compress\": true
                }
            }" | jq .
        fi
    fi
fi


curl -s -XPUT "${ES_SNAPSHOT_URL}/${ES_REPOSITORY}/${ES_SNAPSHOT}?wait_for_completion=true" | jq .



