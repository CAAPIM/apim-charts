#!/bin/bash
set -euxo pipefail

CHART_DIRS=(portal gateway)
KUBEVAL_VERSION="v0.16.1"

SCHEMA_LOCATION="https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master"

curl --silent --show-error --fail --location --output /tmp/kubeval.tar.gz https://github.com/instrumenta/kubeval/releases/download/"${KUBEVAL_VERSION}"/kubeval-linux-amd64.tar.gz
tar -xvf /tmp/kubeval.tar.gz kubeval

# validate charts
for CHART_DIR in ${CHART_DIRS[@]}; do
   helm template --values charts/"${CHART_DIR}"/ci/ci-values.yaml charts/"${CHART_DIR}" | ./kubeval --strict --schema-location ${SCHEMA_LOCATION} --kubernetes-version "${KUBERNETES_VERSION#v}"
done

