#!/bin/bash

ES_HOST="localhost"
ES_PORT="9200";

if ! type "curl" > /dev/null; then
    echo "Curl does not seem to be installed."
    exit 1
fi

if ! type "jq" > /dev/null; then
    echo "jq does not seem to be installed."
    exit 1
fi

usage() {
    help="\n"
    help+="Usage:\n"
    help+=" $0 [options]\n"
    help+="\n"
    help+="Options:\n"
    help+=" -r \t Provide the repository name\n"
    help+=" -s \t Provide the snapshot name\n"
    help+=" -i \t Provide the indices names (comma separated)\n"
    help+=" -h \t Provide the server name [localhost]\n"
    help+=" -p \t Provide the server port [9200]\n"
    echo -e ${help} 1>&2;
    exit 1;
}

while getopts "r:s:i:h:p" o; do
  case "${o}" in
    r)
      es_repository=${OPTARG}
      ;;
    s)
      es_snapshot=${OPTARG}
      ;;
    i)
      es_indices=${OPTARG}
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

if [[ -z ${es_repository} ]]; then
  echo 'You must specify a repository name with option -r [repository name]!'
  exit 1
fi
if [[ -z ${es_snapshot} ]]; then
  echo 'You must specify a snapshot name with option -s [snapshot name]!'
  exit 1
fi
if [[ -z ${es_indices} ]]; then
  echo 'You must specify at one index with option -i [index1,index2]!'
  exit 1
fi

es_domain="${ES_HOST}:${ES_PORT}"
es_snapshot_url="${es_domain}/_snapshot"

backup_response=$(curl -s -XGET "${es_snapshot_url}/${es_repository}")
backup_status=$(echo ${backup_response} | jq .status)

if [[ -n ${backup_status} ]]; then

    if [[ ${backup_status} == '404' ]]; then

        echo
        read -e -p "Repository [${es_repository}] does not exist. Would you like to create it? [Y/n]: " confirminfo
        echo

        if [[ ${confirminfo} == "n" ]]; then
            echo "Interrupted!"
            exit
        fi

        echo
        read -e -p "Enter the backup location: " location
        echo

        if [[ -n ${location} ]]; then

            echo
            echo "Creating Snapshot repository"
            echo

            curl -s -XPUT "${es_snapshot_url}/${es_repository}" -d "{
                \"type\": \"fs\",
                \"settings\": {
                    \"location\": \"${location}\",
                    \"compress\": true
                }
            }" | jq .
        fi
    fi
fi

echo
echo "Creating Snapshot"
echo

curl -s -XPUT "${es_snapshot_url}/${es_repository}/${es_snapshot}?wait_for_completion=true" -d "{
    \"indices\": \"${es_indices}\",
    \"ignore_unavailable\": \"true\",
    \"include_global_state\": false
}" | jq .

echo
echo "done"
echo
