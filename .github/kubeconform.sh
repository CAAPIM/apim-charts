#!/bin/bash
set -euo pipefail

CHART_DIRS=(gateway portal)
KUBECONFORM_VERSION="v0.6.4"


KUBERNETES_VERSIONS=$(curl -s https://kubernetes.io/releases/ | grep -o "Complete 1.*" | cut -d " " -f 2)
DEFAULT_KUBERNETES_VERSIONS=""
KUBERNETES_VERSION_MATRIX=()
LATEST=false

if [ -z "${KUBERNETES_VERSIONS}" ]; then
  echo "no versions found"
  DEFAULT_KUBERNETES_VERSIONS="1.28 1.27 1.26"
fi

if [ -z "${DEFAULT_KUBERNETES_VERSIONS}" ]; then
  echo running tests with latest Kubernetes Versions ${KUBERNETES_VERSIONS}
  KUBERNETES_VERSION_MATRIX=($KUBERNETES_VERSIONS)
  LATEST=true
else
  echo falling back to default list ${DEFAULT_KUBERNETES_VERSIONS}
  KUBERNETES_VERSION_MATRIX=($DEFAULT_KUBERNETES_VERSIONS)
fi

SCHEMA_LOCATION="https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master"

curl --silent --show-error --fail --location --output /tmp/kubeconform.tar.gz https://github.com/yannh/kubeconform/releases/download/"${KUBECONFORM_VERSION}"/kubeconform-linux-amd64.tar.gz
tar -xvf /tmp/kubeconform.tar.gz kubeconform

# validate charts
for CHART_DIR in ${CHART_DIRS[@]}; do
  for KUBERNETES_VERSION in ${!KUBERNETES_VERSION_MATRIX[@]}; do

    if $LATEST; then
      if [ ${KUBERNETES_VERSION} == 0 ]; then
         echo "*****************************************************************"
         echo "Latest version ${KUBERNETES_VERSION_MATRIX[$KUBERNETES_VERSION]}"
         echo "*****************************************************************"   
         echo "-----------------------------------------------------------------"
         helm template --values ./charts/"${CHART_DIR}"/ci/ci-values.yaml ./charts/"${CHART_DIR}" | ./kubeconform -summary -strict -schema-location ${SCHEMA_LOCATION} -kubernetes-version "${KUBERNETES_VERSION_MATRIX[$KUBERNETES_VERSION]#v}.0" || true
         echo "-----------------------------------------------------------------"
         echo "*****************************************************************"
      fi
    fi
    echo "-----------------------------------------------------------------"
    echo "Validating ${CHART_DIR} Chart with Kubernetes ${KUBERNETES_VERSION_MATRIX[$KUBERNETES_VERSION]}"
    helm template --values ./charts/"${CHART_DIR}"/ci/ci-values.yaml ./charts/"${CHART_DIR}" | ./kubeconform -summary -strict -schema-location ${SCHEMA_LOCATION} -kubernetes-version "${KUBERNETES_VERSION_MATRIX[$KUBERNETES_VERSION]#v}.0"
    echo "-----------------------------------------------------------------"
  done
done