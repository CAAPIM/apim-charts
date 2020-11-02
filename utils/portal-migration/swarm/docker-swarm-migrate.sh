#!/bin/bash

##################################################
## Run this script on your docker swarm node    ##
## It produces migration.tar.gz which should be ##
## moved onto a machine that has access to      ##
## the Kubernetes cluster you intend to deploy  ##
## the Broadcom APIM Portal onto.               ##
##################################################

function copy_certs() {

    if [[ -z $SWARM_CERT_PATH ]]; then
        echo "Please set path to existing the certs folder in your Swarm install"
        echo "-p /path/to/certs"
        exit 1
    fi

    if [ -s $SWARM_CERT_PATH/apim.pem ]; then
        echo "Preparing Certificates..."
    else

        echo "Please check your cert path and try again"
        exit 1
    fi

    folder=certificates
    internal_path=$folder/internal
    external_path=$folder/external
    /bin/cp -r $SWARM_CERT_PATH $folder

    mkdir $folder/internal
    mkdir $folder/external

    rm $folder/*.crt

    rm $folder/*.p8
    rm $folder/smtp-internal.*
    rm $folder/solr*
    rm $folder/analytics*

    mv $folder/apim.pem $internal_path/apim-tps.pem
    rm $folder/apim.*

    mv $folder/datalake.p12 $internal_path/apim-datalake.p12
    mv $folder/dssg.p12 $internal_path/apim-dssg.p12
    mv $folder/pssg.p12 $internal_path/pssg-ssl.p12
    mv $folder/tps.p12 $internal_path/tps.p12

    mv $folder/dispatcher.p12 $external_path/dispatcher-ssl.p12
    mv $folder/tssg.p12 $external_path/apim-ssl.p12
}

function format_certs() {
    echo "Formatting Certificates..."
    docker inspect portal_apim | grep KEY_PASS | tr -d \",' ' | sed 's/\<SSG_SSL_KEY_PASS\>/APIM_SSL_KEY_PASS/g' >$folder/.env
    docker inspect portal_dispatcher | grep KEY_PASS | tr -d \",' ' >>$folder/.env
    docker inspect portal_tenant-provisioner | grep KEY_PASS | tr -d \",' ' >>$folder/.env

    passArr=$(cat $folder/.env)
    internalKeyPass=$(openssl rand -base64 18)
    externalKeyPass=$(openssl rand -base64 18)

    convert_mtls_key $internalKeyPass
    gen_solr_cert $internalKeyPass
    for pass in $passArr; do
        pass=(${pass//=/ })
        case $pass in
        DATALAKE_SSL_KEY_PASS)
            update_keypass ${pass[1]} $internalKeyPass $internal_path apim-datalake
            ;;
        PSSG_SSL_KEY_PASS)
            update_keypass ${pass[1]} $internalKeyPass $internal_path pssg-ssl
            ;;
        APIM_SSL_KEY_PASS)
            update_keypass ${pass[1]} $externalKeyPass $external_path apim-ssl
            ;;
        HTTPD_SSL_KEY_PASS)
            update_keypass ${pass[1]} $externalKeyPass $external_path dispatcher-ssl
            ;;
        TPS_SSL_KEY_PASS)
            update_keypass ${pass[1]} $internalKeyPass $internal_path tps
            ;;
        DSSG_SSL_KEY_PASS)
            update_keypass ${pass[1]} $internalKeyPass $internal_path apim-dssg
            ;;
        esac

        echo $internalKeyPass >$internal_path/keypass.txt
        echo $externalKeyPass >$external_path/keypass.txt
    done
}

function update_keypass() {
    openssl pkcs12 -in $3/$4.p12 -nocerts -nodes -passin pass:$1 | openssl pkcs8 -nocrypt -out $3/$4.key
    openssl pkcs12 -in $3/$4.p12 -nokeys -nodes -passin pass:$1 | openssl x509 -out $3/$4.crt
    openssl pkcs12 -export -out $3/$4.p12 -in $3/$4.crt -inkey $3/$4.key -passout pass:$2
}

function convert_mtls_key() {
    openssl pkcs12 -export -out $internal_path/apim-tps.p12 -in $internal_path/apim-tps.pem -passout pass:$1
    openssl pkcs12 -in $internal_path/apim-tps.p12 -nocerts -nodes -passin pass:$1 | openssl pkcs8 -nocrypt -out $internal_path/apim-tps.key
    openssl pkcs12 -in $internal_path/apim-tps.p12 -nokeys -nodes -passin pass:$1 | openssl x509 -out $internal_path/apim-tps.crt
    rm $internal_path/apim-tps.pem
}

function gen_solr_cert() {
    openssl genrsa -des3 -out "$internal_path/apim-solr.key" -passout pass:"$1" 2048 &>/dev/null

    openssl req -new -x509 -key "$internal_path/apim-solr.key" \
        -subj "/CN=apim-solr" \
        -out "$internal_path/apim-solr.crt" \
        -passin pass:"$1" -days $((365 * 3)) &>/dev/null

    openssl pkcs12 -export -inkey "$internal_path/apim-solr.key" -in "$internal_path/apim-solr.crt" \
        -out "$internal_path/apim-solr.p12" -passin pass:"$1" -passout pass:"$1" &>/dev/null
}

function retrieve_minio_bucket() {
    folder=analytics
    mkdir $PWD/$folder
    echo "Retrieving analytics data..."
    minio_container=$(docker ps -q --filter "name=portal_minio")
    docker cp $minio_container:/opt/data/api-metrics $PWD/$folder/bucket
}

function zip_migration() {
    echo "Cleaning up.."
    rm $folder/.env &>/dev/null
    echo "Compressing to $folder.tar.gz"
    tar -cvzf $folder.tar.gz $folder/ &>/dev/null
    rm -r $folder
    echo "Success! Take $PWD/$folder.tar.gz to your Kubernetes environment and proceed with the next step."
}

function remove_ingestion_server() {
    echo "Removing Ingestion Server"
    docker service rm portal_ingestion-server &>/dev/null
}

# Check parameters
while getopts "p:a:" OPTION; do
    case $OPTION in
    p)
        SWARM_CERT_PATH=$(echo $OPTARG | sed 's:/*$::')
        ;;
    a)
        ACTION=$OPTARG
        ;;
    esac
done

#ensure script is running with root permissions
if [[ $EUID != 0 ]]; then
    echo "You need to be root to perform this command."
    exit 1
fi

if [[ -z $ACTION ]]; then
    echo "Please specify an action"
    echo "-a certificates|analytics"
    exit 1
else
    case $ACTION in
    "certs")
        copy_certs
        format_certs
        zip_migration
        ;;

    "analytics")
        remove_ingestion_server
        sleep 5
        retrieve_minio_bucket
        zip_migration
        echo ""
        echo "You can now proceed with installing the Portal in Kubernetes."
        ;;

    *)
        echo "Please specify an action"
        echo "-a certificates|analytics"
        exit 1
        ;;
    esac
fi
