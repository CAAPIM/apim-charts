#!/usr/bin/env bash
#
# Generate an image manifest for a given Portal version by resolving the
# chart version (appVersion match), pulling that chart, and extracting
# image refs from its values.yaml. Writes only image lines to a file
# (one full image reference per line) for use with pull-portal-images.sh.
#
# Prerequisites: Helm 3.
#
# Usage:
#   ./scripts/generate-portal-image-manifest.sh 5.4
#   ./scripts/generate-portal-image-manifest.sh 5.3.3.1
#   PORTAL_VERSION=5.4 ./scripts/generate-portal-image-manifest.sh
#   MANIFEST_OUTPUT=/path/to/my-manifest.txt ./scripts/generate-portal-image-manifest.sh 5.4
#
# Output: manifest file (default manifest-<version>.txt in current directory).
# All progress messages go to stderr so the file contains only image refs.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${HELM_REPO_NAME:=layer7}"
: "${HELM_REPO_URL:=https://caapim.github.io/apim-charts/}"
: "${CHART_BASE_DIR:=.}"

usage() {
  echo "Usage: $0 <portal-version> | PORTAL_VERSION=<version> $0" >&2
  echo "  Example: $0 5.4" >&2
  echo "  Writes manifest to manifest-<version>.txt (or MANIFEST_OUTPUT). Only image refs in file." >&2
  exit 1
}

PORTAL_VERSION="${1:-${PORTAL_VERSION:-}}"
if [[ -z "$PORTAL_VERSION" ]]; then
  usage
fi

# Output file: only image lines written here
: "${MANIFEST_OUTPUT:=manifest-${PORTAL_VERSION}.txt}"

# Ensure Helm repo (suppress all add/update output so nothing leaks to manifest)
helm repo add "${HELM_REPO_NAME}" "${HELM_REPO_URL}" >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

# Find chart version where APP VERSION equals requested Portal version (take first = highest chart)
chart_version=$(helm search repo "${HELM_REPO_NAME}/portal" --versions |
  awk -v pv="$PORTAL_VERSION" '$3 == pv { print $2; exit }')

if [[ -z "$chart_version" ]]; then
  echo "Error: No chart found with appVersion ${PORTAL_VERSION}. Run: helm search repo ${HELM_REPO_NAME}/portal --versions" >&2
  exit 1
fi

echo "Helm Chart version for Portal ${PORTAL_VERSION}: ${chart_version}" >&2

# Pull chart archive
mkdir -p "${CHART_BASE_DIR}"
tgz="${CHART_BASE_DIR}/portal-${chart_version}.tgz"
chart_dir="${CHART_BASE_DIR}/portal-${chart_version}"

if [[ ! -f "$tgz" ]]; then
  echo "Pulling ${chart_version} chart and expanding to: ${chart_dir}" >&2
  helm pull "${HELM_REPO_NAME}/portal" --version "${chart_version}" --destination "${CHART_BASE_DIR}"
fi
if [[ ! -f "$tgz" ]]; then
  echo "Error: chart archive not found at ${tgz}" >&2
  exit 1
fi

# Extract to versioned directory if needed
if [[ ! -f "${chart_dir}/values.yaml" ]]; then
  echo "Expanding chart to: ${chart_dir}" >&2
  mkdir -p "${chart_dir}"
  tar -xzf "$tgz" -C "${chart_dir}" --strip-components=1
fi

values_file="${chart_dir}/values.yaml"
if [[ ! -f "$values_file" ]]; then
  echo "Error: values.yaml not found at ${values_file}" >&2
  exit 1
fi

# Write only image refs (one per line) to manifest file
echo "Extracting image list from values.yaml..." >&2
"${SCRIPT_DIR}/extract-portal-images.sh" "$values_file" > "$MANIFEST_OUTPUT"
echo "Manifest written to ${MANIFEST_OUTPUT}" >&2
