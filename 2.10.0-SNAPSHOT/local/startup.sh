#!/bin/bash

HIGHLIGHT='\033[92m'
FAIL='\033[91m'
NOCOLOR='\033[0m\n'
BOLD='\033[1m'

brokers="kafka rabbitmq"
databases="postgres mariadb mysql"
monitors="prometheus influxdb wavefront"
tracers="zipkin wavefront"
baseurl="https://raw.githubusercontent.com/spring-cloud/spring-cloud-dataflow/main/src/docker-compose/"
configs=""

# Function that will get executed when the user presses Ctrl+C
function shutdown() {
    echo
    printf "${BOLD}${HIGHLIGHT}*** Processing graceful shutdown using Ctrl+C${NOCOLOR}"
    docker-compose down --remove-orphans
}

function download() {
    if [ ${4} = true ] || [ ${3} != "none" ]; then
        echo ${2} | grep -w -q ${3}
        rc=$?
        if [ $rc -ne 0 ] ; then
            printf "${BOLD}${FAIL}Unsupported ${1} [${3}], available options: [${2}]${NOCOLOR}"
            exit $rc
        fi
        if [ ${3} != "none" ] && [ ! -f docker-compose-${3}.yml ]; then
            printf "${BOLD}${HIGHLIGHT}*** Downloading docker-compose files for ${1}${NOCOLOR}"
            wget -O docker-compose-${3}.yml ${baseurl}/docker-compose-${3}.yml >> /dev/null 2>&1
        fi
        configs="${configs} -f docker-compose-${3}.yml"
    fi
}

for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)
   VALUE=$(echo $ARGUMENT | cut -f2 -d=)
   export "$KEY"="$VALUE"
done

if [ ! -f docker-compose.yml ]; then
    printf "${BOLD}${HIGHLIGHT}*** Downloading base docker-compose${NOCOLOR}"
    wget -O docker-compose.yml ${baseurl}/docker-compose.yml >> /dev/null 2>&1
fi

download "Broker" "$brokers" ${broker:-kafka} true
download "Database" "$databases" ${database:-mariadb} true
download "Monitor" "$monitors" ${monitor:-none} false
download "Tracer" "$tracers" ${tracer:-none} false

# Assign the handler function to the SIGINT signal
trap shutdown SIGINT

printf "${BOLD}${HIGHLIGHT}*** Executing 'docker-compose -f docker-compose.yml ${configs} up'${NOCOLOR}"

export DATAFLOW_VERSION=2.10.0-SNAPSHOT
export SKIPPER_VERSION=2.9.0-SNAPSHOT
docker-compose -f docker-compose.yml ${configs} up --force-recreate
