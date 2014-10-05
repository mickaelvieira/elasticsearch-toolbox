#!/bin/bash

es_host="localhost"
es_port="9200";

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
    help+=" -i \t Provide the index name\n"
    help+=" -a \t Provide the alias name\n"
    help+=" -h \t Provide the server name, default localhost\n"
    help+=" -p \t Provide the server port, default 9200\n"
    echo -e ${help} 1>&2;
    exit 1;
}

while getopts ":i:a:h:p" o; do
  case "${o}" in
    i)
      es_index=${OPTARG}
      ;;
    a)
      es_alias=${OPTARG}
      ;;
    h)
      es_host=${OPTARG}
      ;;
    p)
      es_port=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [[ -z ${es_index} ]]; then
  echo 'You must specify an index name with option -i [index name]!'
  exit 1
fi
if [[ -z ${es_alias} ]]; then
  es_alias=${es_index}"-"$(date +%Y-%m-%d-%H-%M-%S)
fi

es_domain="${es_host}:${es_port}"
es_alias_url="${es_domain}/_aliases"

echo "Checking index:"
curl -v -XHEAD ${es_domain}"/"${es_index}
echo
echo
echo "You're about to create a new alias:"
echo " Host: "${es_host}
echo " Port: "${es_port}
echo " Index: "${es_index}
echo " Alias: "${es_alias}
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
curl -s -XPOST ${es_alias_url} -d "
{
    \"actions\" : [
        {
            \"add\": {
                \"index\": \"${es_index}\",
                \"alias\": \"${ES_ALIAS}\"
            }
        }
    ]
}" | jq .

echo
echo
echo "Fetching existing aliases..."
echo
curl -s -XGET ${es_alias_url} | jq .
echo

