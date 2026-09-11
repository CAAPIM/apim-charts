#!/bin/bash
# Copyright (c) 2026 Broadcom Inc. and its subsidiaries. All Rights Reserved.
set -euo pipefail
#### Pre-flight script to ensure that CAAPIM Charts have been versioned
#### correctly before they can be published.
#
# Artifactory OCI registries don't support listing/searching all versions of
# a chart the way a classic index.yaml-based helm repo does (there's no
# `helm search repo` equivalent for `oci://` refs), so this checks one
# version at a time instead: for each chart that changed vs. the target
# branch, if its current Chart.yaml version already exists at the
# destination, that means the version wasn't bumped.
#
# Usage: version-check.sh <target-branch> <helm-repo-host>
# Example: version-check.sh stable apim-docker-release-local.usw1.packages.broadcom.com

TARGET_BRANCH=${1:?"Usage: $0 <target-branch> <helm-repo-host>"}
HELM_REPO=${2:?"Usage: $0 <target-branch> <helm-repo-host>"}

charts=(gateway portal druid seaweedfs kafka)
err=()

for chart in "${charts[@]}"; do
  changed=$(git diff --quiet "origin/${TARGET_BRANCH}" -- "./charts/${chart}" || echo true)
  if [[ -n "${changed}" ]]; then
    version=$(grep -e '^version:' "./charts/${chart}/Chart.yaml" | awk '{print $2}')
    echo "changes detected in ${chart} chart (current version: ${version}), checking if already published"
    if helm pull "oci://${HELM_REPO}/${chart}" --version "${version}" -d "$(mktemp -d)" >/dev/null 2>&1; then
      err+=("${chart}")
    fi
  fi
done

if [ ${#err[@]} -eq 0 ]; then
  echo "completed with no errors"
  exit 0
else
  echo "error: ${err[*]} chart(s) version have not been incremented"
  exit 1
fi
