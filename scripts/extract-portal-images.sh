#!/usr/bin/env bash
#
# Read a Portal chart values.yaml and print one full image reference per line
# (portal core, RabbitMQ, Druid). Excludes MySQL. No Python or pip required.
# Alternative to extract-portal-images.py for sites where Python/PyYAML is not available.
#
# Usage: extract-portal-images.sh <path-to-values.yaml>
#
# Output format matches extract-portal-images.py so it can be used interchangeably.
# Two awk passes: (1) portal images, (2) RabbitMQ + Druid together. This avoids
# state interactions that on some systems prevent druid from outputting.
#

set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: extract-portal-images.sh <path-to-values.yaml>" >&2
  exit 1
fi

VALUES_FILE="$1"
if [[ ! -f "$VALUES_FILE" ]]; then
  echo "Error: file not found: $VALUES_FILE" >&2
  exit 1
fi

# Prefix (global.portalRepository); default caapim/
PREFIX="caapim/"
found=$(grep -E '[[:space:]]*portalRepository:' "$VALUES_FILE" | grep -v '^[[:space:]]*#' | head -1)
if [[ -n "$found" ]]; then
  PREFIX=$(echo "$found" | sed -E 's/^[[:space:]]*portalRepository:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d '\n\r')
fi
[[ "$PREFIX" =~ /$ ]] || PREFIX="${PREFIX}/"

# Pass 1: Portal core images only (top-level image block)
awk -v prefix="$PREFIX" '
  /^image:[[:space:]]*$/ { in_block=1; next }
  in_block && (/^[a-zA-Z]/ || /^#/) { in_block=0 }
  in_block && /^  [a-zA-Z0-9_-]+:[[:space:]]+.+:.+/ {
    sub(/^  [a-zA-Z0-9_-]+:[[:space:]]+/, "")
    if ($0 != "" && $0 !~ /^#/) print prefix $0
  }
' < "$VALUES_FILE"

# Pass 2: RabbitMQ only
awk '
  /^rabbitmq:[[:space:]]*$/ { in_rmq=1; reg="caapim"; repo="message-broker"; tag="latest"; next }
  in_rmq && /^[a-zA-Z]/ { in_rmq=0 }
  in_rmq && /^[[:space:]]+image:[[:space:]]*$/ { in_rmq_img=1; next }
  in_rmq && in_rmq_img && /^[[:space:]]+[a-zA-Z]+:[[:space:]]*$/ && $0 !~ /image/ { print reg "/" repo ":" tag; in_rmq_img=0 }
  in_rmq && in_rmq_img && /^[[:space:]]+registry:[[:space:]]/ { sub(/^[[:space:]]+registry:[[:space:]]*/, ""); gsub(/["'\'']/, ""); reg=$0 }
  in_rmq && in_rmq_img && /^[[:space:]]+repository:[[:space:]]/ { sub(/^[[:space:]]+repository:[[:space:]]*/, ""); gsub(/["'\'']/, ""); repo=$0 }
  in_rmq && in_rmq_img && /^[[:space:]]+tag:[[:space:]]/ { sub(/^[[:space:]]+tag:[[:space:]]*/, ""); gsub(/["'\'']/, ""); tag=$0 }
  END { if (in_rmq && in_rmq_img) print reg "/" repo ":" tag }
' < "$VALUES_FILE"

# Pass 3: Druid only (if druid.enabled is false in your values, ignore the druid lines in the list)
awk -v prefix="$PREFIX" '
  /^druid:[[:space:]]*$/ { in_druid=1; next }
  in_druid && /^[a-zA-Z]/ { in_druid=0 }
  in_druid && /^  image:[[:space:]]*$/ { in_druid_img=1; next }
  in_druid && in_druid_img && /^  [a-zA-Z]+:[[:space:]]*$/ && $0 !~ /image/ { in_druid_img=0 }
  in_druid && in_druid_img && /^    [a-zA-Z0-9_-]+:[[:space:]]+.+:.+/ {
    sub(/^[[:space:]]+[a-zA-Z0-9_-]+:[[:space:]]+/, "")
    if ($0 != "" && $0 !~ /^#/) print prefix $0
  }
' < "$VALUES_FILE"
