#!/bin/bash

##################################################
## Run this script on a machine that has access ##
## to the Kubernetes Cluster you intend to      ##
## deploy the Broadcom APIM Portal into.        ##
## Make sure you set namespace with             ##
## -n <namespace>                               ##
##################################################

# Set paths
internal_cert_location="certificates/internal"
internal_secretname="portal-internal-secret"
external_cert_location="certificates/external"
external_secretname="portal-external-secret"
certs=(apim-datalake.p12 apim-dssg.p12 apim-solr.p12 apim-tps.p12 pssg-ssl.p12 tps.p12 apim-ssl.p12 dispatcher-ssl.p12)
###############################################
# Function to create corresponding secret Object in Kubernetes
function create_k8s_secrets() {
  FILES=$1/*
  secretname=$2
  fromfiles=""
  tmp=$(mktemp -d)
  for f in $FILES; do
    if [[ $f == "$1/keypass.txt" ]]; then
      certfile=$(cat ${f})
      printf ${certfile} >$tmp/${f##*/}
      fromfiles="${fromfiles} --from-file=$tmp/${f##*/}"
    else
      certfile=$(cat ${f} | base64)
      printf ${certfile} >$tmp/${f##*/}
      fromfiles="${fromfiles} --from-file=$tmp/${f##*/}"
    fi
  done

  secretsExist=$(kubectl get secrets $secretname -n $namespace 2>&1)

  if [[ "$secretsExist" == *"(NotFound)"* ]]; then
    kubectl create secret generic $secretname $fromfiles -n $namespace
  else
    kubectl create secret generic $secretname $fromfiles -n $namespace -o yaml --dry-run=client | kubectl replace -f -
  fi
}

function prepare_helm2_certs() {
  echo "Preparing Certificates..."
  mkdir -p $internal_cert_location
  mkdir -p $external_cert_location

  for c in ${certs[@]}; do
    if [[ $c == "dispatcher-ssl.p12" ]] || [[ $c == "apim-ssl.p12" ]]; then
      cp $helm2_cert_path/$c $external_cert_location/
    else
      cp $helm2_cert_path/$c $internal_cert_location/
    fi
  done
}

function update_keypass() {
  openssl pkcs12 -in $3/$4.p12 -nocerts -nodes -passin pass:$1 | openssl pkcs8 -nocrypt -out $3/$4.key
  openssl pkcs12 -in $3/$4.p12 -nokeys -nodes -passin pass:$1 | openssl x509 -out $3/$4.crt
  openssl pkcs12 -export -out $3/$4.p12 -in $3/$4.crt -inkey $3/$4.key -passout pass:$2
}

function format_certs() {
  echo "Formatting Certificates..."
  internalKeyPass=$(openssl rand -base64 18)
  externalKeyPass=$(openssl rand -base64 18)

  for c in ${certs[@]}; do
    c=$(echo "$c" | cut -f 1 -d '.')
    if [[ $c == "dispatcher-ssl" ]] || [[ $c == "apim-ssl" ]]; then
      update_keypass $1 $externalKeyPass $external_cert_location $c &>/dev/null
    else
      update_keypass $1 $internalKeyPass $internal_cert_location $c &>/dev/null
    fi
  done
  echo $internalKeyPass >$internal_cert_location/keypass.txt
  echo $externalKeyPass >$external_cert_location/keypass.txt
}

# Check parameters
while getopts "n:p:k:" OPTION; do
  case $OPTION in
  n)
    namespace=$OPTARG
    ;;
  p)
    helm2_cert_path=$(echo $OPTARG | sed 's:/*$::')
    ;;
  k)
    keypass=$OPTARG
    ;;
  esac
done

if [[ -z $namespace ]]; then
  echo "Please set the namespace you intend to deploy the Portal into"
  echo "-n <namespace>"
  exit 1
fi

if [[ -z $helm2_cert_path ]]; then
  echo ""
  echo "If you wish to migrate from the old Helm Chart you will need to set a path to portal-helm-charts/files"
  echo "-p /path/to/portal-helm-charts/files -k <keypass>"
  echo ""
  if [ -s $PWD/certificates.tar.gz ]; then
    echo "Preparing Certificates..."
    # Create migration folder
    tar -xvf $PWD/certificates.tar.gz &>/dev/null
  else
    echo ""
    echo "Please retrieve your certificates.tar.gz file from your Docker Swarm node and place it here"
    echo "$PWD/certificates.tar.gz"
    echo ""
    exit 1
  fi
else
  if [ -s $helm2_cert_path/apim-ssl.p12 ] && ! [ -z $keypass ]; then
    prepare_helm2_certs
    format_certs $keypass
  else
    echo ""
    echo "Please check your cert path and key and try again"
    echo "-p /path/to/portal-helm-charts/files -k <keypass>"
    echo ""
    exit 1
  fi
fi

create_k8s_secrets $internal_cert_location $internal_secretname
create_k8s_secrets $external_cert_location $external_secretname
