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

if [[ -z ${ES_INDEX} ]]; then
  echo 'You must specify an index name with option -i [index name]!'
  exit 1
fi
if [[ -z ${ES_ALIAS} ]]; then
  ES_ALIAS=${ES_INDEX}"-"$(date +%Y-%m-%d-%H-%M-%S)
fi

ES_DOMAIN="${ES_HOST}:${ES_PORT}"
ES_ALIAS_URL="${ES_DOMAIN}/_aliases"

echo "Checking index:"
curl -v -XHEAD ${ES_DOMAIN}"/"${ES_INDEX}
echo
echo
echo "You're about to create a new alias:"
echo " Host: "${ES_HOST}
echo " Port: "${ES_PORT}
echo " Index: "${ES_INDEX}
echo " Alias: "${ES_ALIAS}
echo
echo
read -e -p "Do you want to carry on? [Y/n]: " confirminfo

if [[ ${confirminfo} == "n" ]]; then
    echo "Interrupted!"
    exit
fi

echo
echo "Creating alias..."
echo
curl -s -XPOST ${ES_ALIAS_URL} -d "
{
    \"actions\" : [
        {
            \"add\": {
                \"index\": \"${ES_INDEX}\",
                \"alias\": \"${ES_ALIAS}\"
            }
        }
    ]
}" | jq .

echo
echo
echo "Fetching existing aliases..."
echo
curl -s -XGET ${ES_ALIAS_URL} | jq .
echo

