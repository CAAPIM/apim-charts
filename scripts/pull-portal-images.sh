#!/usr/bin/env bash
#
# Pull Portal images listed in a manifest file. Each line is one image reference:
# - Full ref: registry/repo/name:tag (used as-is for pull).
# - Simple ref: name:tag (prefixed with SOURCE_REGISTRY/SOURCE_REPO, or caapim/ if unset).
# Optionally tag and push to an internal registry.
#
# Prerequisites: Docker (or Podman). Login to source registry; if PUSH_INTERNAL=1, login to internal registry.
#
# Usage:
#   ./scripts/pull-portal-images.sh manifest.txt
#   ./scripts/pull-portal-images.sh <(./scripts/generate-portal-image-manifest.sh 5.4)
#   MANIFEST_FILE=manifest.txt SOURCE_REGISTRY=myreg.com SOURCE_REPO=portal ./scripts/pull-portal-images.sh
#   MANIFEST_FILE=manifest.txt INTERNAL_REGISTRY=myreg.com/portal PUSH_INTERNAL=1 ./scripts/pull-portal-images.sh
#

set -e

# Manifest file (path as first argument or MANIFEST_FILE env)
MANIFEST_FILE="${1:-${MANIFEST_FILE:-}}"

# Optional: prefix for simple refs (name:tag). If unset, "caapim/" is used for Docker Hub.
: "${SOURCE_REGISTRY:=}"
: "${SOURCE_REPO:=}"

# Optional: push to internal registry after pull
: "${PUSH_INTERNAL:=0}"
: "${INTERNAL_REGISTRY:=}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pull_count=0
fail_count=0

usage() {
  echo "Usage: $0 <manifest-file> | MANIFEST_FILE=<path> $0" >&2
  echo "  Manifest: one image ref per line (full ref or name:tag)." >&2
  echo "  Generate manifest: ./scripts/generate-portal-image-manifest.sh 5.4 > manifest.txt" >&2
  exit 1
}

# Resolve ref for pull: if line contains "/", use as-is; else prefix with SOURCE_REGISTRY/SOURCE_REPO or caapim/
resolve_ref() {
  local line="$1"
  line=$(echo "$line" | tr -d '\r')
  if [[ -z "$line" ]]; then
    return
  fi
  if [[ "$line" == */* ]]; then
    echo "$line"
    return
  fi
  # Simple ref (name:tag)
  if [[ -n "$SOURCE_REGISTRY" && -n "$SOURCE_REPO" ]]; then
    echo "${SOURCE_REGISTRY}/${SOURCE_REPO}/${line}"
  else
    echo "caapim/${line}"
  fi
}

pull_one() {
  local ref="$1"
  local pull_ref
  pull_ref="$(resolve_ref "$ref")"
  [[ -z "$pull_ref" ]] && return
  if docker pull "$pull_ref" 2>/dev/null; then
    echo "[OK] $pull_ref"
    (( pull_count++ )) || true
    if [[ "$PUSH_INTERNAL" == "1" && -n "$INTERNAL_REGISTRY" ]]; then
      local name_tag="${pull_ref##*/}"
      local internal_ref="${INTERNAL_REGISTRY}/${name_tag}"
      docker tag "$pull_ref" "$internal_ref"
      if docker push "$internal_ref" 2>/dev/null; then
        echo "[PUSHED] $internal_ref"
      else
        echo "[WARN] Push failed: $internal_ref"
        (( fail_count++ )) || true
      fi
    fi
  else
    echo "[FAIL] $pull_ref"
    (( fail_count++ )) || true
  fi
}

# --- Main ---
if [[ -z "$MANIFEST_FILE" ]]; then
  usage
fi

if [[ ! -f "$MANIFEST_FILE" && ! -p "$MANIFEST_FILE" ]]; then
  echo "Error: manifest file not found: ${MANIFEST_FILE}" >&2
  exit 1
fi

echo "Portal image pull (manifest=${MANIFEST_FILE})"
echo "SOURCE_REGISTRY=${SOURCE_REGISTRY:-<default: caapim/>} SOURCE_REPO=${SOURCE_REPO:-}"
echo "PUSH_INTERNAL=${PUSH_INTERNAL} INTERNAL_REGISTRY=${INTERNAL_REGISTRY}"
echo "---"

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$(echo "$line" | tr -d '\r')" ]] && continue
  pull_one "$line"
done < "$MANIFEST_FILE"

echo "--- Done: $pull_count pulled, $fail_count failures ---"
exit $fail_count
