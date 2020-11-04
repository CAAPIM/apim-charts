#!/bin/bash

function usage() {
    echo "
    Usage:
    -h <mysql-host> REQUIRED
    -p <mysql-password> PROMPTED
    -P <mysql-port> REQUIRED
    -u <mysql-username> REQUIRED
    -d <druid-database-name> OPTIONAL default [druid]
    -b <bucket-name> REQUIRED
    "
    exit 1
}

while getopts "h:p:P:u:d:b:" OPTION; do
    case $OPTION in
    h)
        MYSQL_HOST=$OPTARG
        echo "MySQL Host: $MYSQL_HOST"
        ;;
    p)
        MYSQL_PASSWORD=$OPTARG
        ;;
    P)
        MYSQL_PORT=$OPTARG
        echo "MySQL Port: $MYSQL_PORT"
        ;;
    u)
        MYSQL_USERNAME=$OPTARG
        echo "MySQL Username: $MYSQL_USERNAME"
        ;;
    d)
        DATABASE_NAME=$OPTARG
        echo "Druid Database: $DATABASE_NAME"
        if [ -z $DATABASE_NAME ]; then
            echo "Setting DB Name to default [druid]"
            echo "override this with -d <druid-database-name>"
            DATABASE_NAME="druid"
        fi
        ;;
    b)
        BUCKET_NAME=$OPTARG
        echo "bucket: $BUCKET_NAME"
        if [[ "$BUCKET_NAME" == "api-metrics" ]]; then
            echo "This script only needs to be run if you plan to move analytics to a Cloud Storage Provider"
            exit 0
        fi
        ;;
    *)
        usage
        ;;
    esac
done

function check_inputs(){
    inputs=(
        "MYSQL_HOST::${MYSQL_HOST}"
        "MYSQL_PASSWORD::${MYSQL_PASSWORD}"
        "MYSQL_PORT::${MYSQL_PORT}"
        "MYSQL_USERNAME::${MYSQL_USERNAME}"
        "DATABASE_NAME::${DATABASE_NAME}"
        "BUCKET_NAME::${BUCKET_NAME}"
        )

    for i in "${!inputs[@]}"
do
    input_arr=($(echo ${inputs[$i]} | tr "::" "\n"))
    if ! [[ ${input_arr[0]} == MYSQL_PASSWORD ]];then
     if [ -z ${input_arr[1]} ]; then
      echo "Missing ${input_arr[0]}"
      usage
     fi
    fi
done
}

function get_mysql_pass {
if [ -z $MYSQL_PASSWORD ]; then
    echo -n "Enter MySQL Password : "
    stty -echo
    #read password
    charcount=0
    while IFS= read -p "$prompt" -r -s -n 1 ch; do
        # Enter - accept password
        if [[ $ch == $'\0' ]]; then
            break
        fi
        # Backspace
        if [[ $ch == $'\177' ]]; then
            if [ $charcount -gt 0 ]; then
                charcount=$((charcount - 1))
                prompt=$'\b \b'
                MYSQL_PASSWORD="${password%?}"
            else
                PROMPT=''
            fi
        else
            charcount=$((charcount + 1))
            prompt='*'
            MYSQL_PASSWORD+="$ch"
        fi
    done
    stty echo
fi
}

function retrieve_build_files() {
 echo "Retrieving build files"
   if [ -s $PWD/resources.tar.gz ]; then
     echo "Resources available locally"
   else
     echo "Getting resources from GitHub"
     curl -s https://github.com/CAAPIM/apim-charts/blob/stable/utils/portal-migration/druid-meta-update/resources.tar.gz?raw=true -o $PWD/resources.tar.gz
   fi
     tar -xvf $PWD/resources.tar.gz &>/dev/null
}

function build() {
 echo "Building Image.."
 docker build -t druid-meta-update $PWD/resources &>/dev/null
}

function run() {
    docker run --env MYSQL_USERNAME=$MYSQL_USERNAME --env MYSQL_PASSWORD=$MYSQL_PASSWORD --env MYSQL_HOST=$MYSQL_HOST --env MYSQL_PORT=$MYSQL_PORT --env DATABASE_NAME=$DATABASE_NAME --env BUCKET_NAME=$BUCKET_NAME druid-meta-update
}

check_inputs
get_mysql_pass
retrieve_build_files
build
run
