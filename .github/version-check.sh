#!/bin/bash
set -e pipefail
#### Pre-flight script to ensure that CAAPIM Charts have been versioned correctly before the release pipeline gets run.

# Check if Charts have Changed
charts=(gateway portal gateway-otk druid)

# Get latest available versions
l7json=$(helm search repo layer7/ -o json)
err=()
for chart in ${charts[@]}; do
  changed=$(git diff --quiet HEAD "$(git describe --tags --abbrev=0 HEAD)" -- ./charts/${chart} || echo true)
  if [[ -n ${changed} ]]; then
    echo "changes detected in ${chart} chart, determining version increment"
    remote=$(echo $l7json | jq -r --arg chart "layer7/$chart" '.[] | select(.name==$chart) | .version')
    commit=$(cat ./charts/${chart}/Chart.yaml | grep -e ^version: | awk '{print $2}' | cut -d ':' -f 2)
    echo "remote: $remote commit: $commit"
    if [[ "${remote}" == "${commit}" ]]; then
      err+=(${chart})
    fi
  fi
done

if [ -z $err ]; then
  echo "completed with no errors"
  exit 0
else
  echo "error: ${err[@]} chart(s) version have not been incremented"
  exit 1
fi
