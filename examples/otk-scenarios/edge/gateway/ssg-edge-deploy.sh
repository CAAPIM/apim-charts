#!/bin/bash

# prerequisite: openssl command utility
# script summary:
#    1. setup key and ssl certificates for Gateway
#    2. make copy of value file (so we can repeatably run this script)
#    3. configure Gateways using string substitution
#    3. install Gateway

# setup STS (secure token store) Gateway key and ssl certificates
# WARNING The example .p12 certificate-key file used is for DEVELOPMENT ONLY. For production, create a unique .p12 file for your server.
STS_RELEASE_NAME="ssg-sts"
STS_KEY=$(base64 ./ssg-sts.p12 --wrap=0)
STS_KEY_ISSUER=$(openssl pkcs12 -in ./ssg-sts.p12 -nodes -passin pass:"mypassword" | openssl x509 -noout -issuer | cut -b 13-)
STS_KEY_SERIAL_HEX=$(openssl pkcs12 -in ./ssg-sts.p12 -nodes -passin pass:"mypassword" | openssl x509 -noout -serial | cut -b 8-)
STS_KEY_SERIAL=$((16#$STS_KEY_SERIAL_HEX))
STS_KEY_SUBJECT=$(openssl pkcs12 -in ./ssg-sts.p12 -nodes -passin pass:"mypassword" | openssl x509 -noout -subject | cut -b 14-)
STS_KEY_CERT=$(openssl pkcs12 -in ./ssg-sts.p12 -nodes -passin pass:"mypassword" | openssl x509 | tr -d '\n' | cut -b 28- | rev | cut -b 26- | rev)
STS_KEY_CERT_ESCAPED=$( echo "$STS_KEY_CERT" | sed -e 's/[\/&]/\\&/g')

# setup edge Gateway key and ssl certificates
# WARNING The example .p12 certificate-key file used is for DEVELOPMENT ONLY. For production, create a unique .p12 file for your server.
EDGE_RELEASE_NAME="ssg-edge"
EDGE_KEY=$(base64 ./ssg-edge.p12 --wrap=0)
EDGE_KEY_ISSUER=$(openssl pkcs12 -in ./ssg-edge.p12 -nodes -passin pass:"mypassword" | openssl x509 -noout -issuer | cut -b 13-)
EDGE_KEY_SERIAL_HEX=$(openssl pkcs12 -in ./ssg-edge.p12 -nodes -passin pass:"mypassword" | openssl x509 -noout -serial | cut -b 8-)
EDGE_KEY_SERIAL=$((16#$EDGE_KEY_SERIAL_HEX))
EDGE_KEY_SUBJECT=$(openssl pkcs12 -in ./ssg-edge.p12 -nodes -passin pass:"mypassword" | openssl x509 -noout -subject | cut -b 14-)
EDGE_KEY_CERT=$(openssl pkcs12 -in ./ssg-edge.p12 -nodes -passin pass:"mypassword" | openssl x509 | tr -d '\n' | cut -b 28- | rev | cut -b 26- | rev)
EDGE_KEY_CERT_ESCAPED=$( echo "$EDGE_KEY_CERT" | sed -e 's/[\/&]/\\&/g')

# make copy of value file to set configuration with string substitution (using sed command utility)
# PRODUCTION 1
EDGE_VALUES_YAML_FILE_REPLACED=./ssg-edge-values-env-01-replaced.yaml
cp ./ssg-edge-values-env-01.yaml $EDGE_VALUES_YAML_FILE_REPLACED

echo "Install using:"
echo " - STS_RELEASE_NAME"=$STS_RELEASE_NAME
echo " - STS_KEY_ISSUER"=$STS_KEY_ISSUER
echo " - STS_KEY_SERIAL"=$STS_KEY_SERIAL
echo " - STS_KEY_SUBJECT"=$STS_KEY_SUBJECT
echo " - STS_KEY_CERT"=$STS_KEY_CERT
echo " - EDGE_RELEASE_NAME"=$EDGE_RELEASE_NAME
echo " - EDGE_KEY_ISSUER"=$EDGE_KEY_ISSUER
echo " - EDGE_KEY_SERIAL"=$EDGE_KEY_SERIAL
echo " - EDGE_KEY_SUBJECT"=$EDGE_KEY_SUBJECT
echo " - EDGE_KEY_CERT"=$EDGE_KEY_CERT
echo

# helm install edge Gateway - configure using sed command utility for string substitution
sed -i "s/####edge-release-name/$EDGE_RELEASE_NAME/g" $EDGE_VALUES_YAML_FILE_REPLACED
sed -i "s/####edge-key-issuer/$EDGE_KEY_ISSUER/g" $EDGE_VALUES_YAML_FILE_REPLACED
sed -i "s/####edge-key-serial/$EDGE_KEY_SERIAL/g" $EDGE_VALUES_YAML_FILE_REPLACED
sed -i "s/####edge-key-subject/$EDGE_KEY_SUBJECT/g" $EDGE_VALUES_YAML_FILE_REPLACED
sed -i "s/####edge-key-cert/$EDGE_KEY_CERT_ESCAPED/g" $EDGE_VALUES_YAML_FILE_REPLACED
sed -i "s/####sts-release-name/$STS_RELEASE_NAME/g" $EDGE_VALUES_YAML_FILE_REPLACED
sed -i "s/####sts-key-issuer/$STS_KEY_ISSUER/g" $EDGE_VALUES_YAML_FILE_REPLACED
sed -i "s/####sts-key-serial/$STS_KEY_SERIAL/g" $EDGE_VALUES_YAML_FILE_REPLACED
sed -i "s/####sts-key-subject/$STS_KEY_SUBJECT/g" $EDGE_VALUES_YAML_FILE_REPLACED
sed -i "s/####sts-key-cert/$STS_KEY_CERT_ESCAPED/g" $EDGE_VALUES_YAML_FILE_REPLACED
helm install -f $EDGE_VALUES_YAML_FILE_REPLACED $EDGE_RELEASE_NAME ../../../../charts/gateway-otk --set-file "ssg.license.value=./LICENSE.xml" --set "ssg.tls.customDefaultSslKey.key=$EDGE_KEY" --set "ssg.license.accept=true"
