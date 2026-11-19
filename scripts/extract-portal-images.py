#!/usr/bin/env python3
"""
Read a Portal chart values.yaml and print one full image reference per line
(portal core, RabbitMQ, Druid). Excludes MySQL. Used by pull-portal-images.sh.

Requires: PyYAML (pip install pyyaml).
"""
import sys
try:
    import yaml
except ImportError:
    print("Error: PyYAML required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

def main():
    if len(sys.argv) != 2:
        print("Usage: extract-portal-images.py <path-to-values.yaml>", file=sys.stderr)
        sys.exit(1)
    path = sys.argv[1]
    try:
        with open(path) as f:
            values = yaml.safe_load(f)
    except Exception as e:
        print(f"Error reading {path}: {e}", file=sys.stderr)
        sys.exit(1)
    if not values:
        sys.exit(0)

    prefix = (values.get("global") or {}).get("portalRepository") or "caapim/"
    if not prefix.endswith("/"):
        prefix = prefix + "/"

    refs = []

    # Portal core images (top-level image.*)
    image_block = values.get("image") or {}
    for _key, value in image_block.items():
        if isinstance(value, str) and value:
            refs.append(prefix + value)

    # RabbitMQ
    rmq = (values.get("rabbitmq") or {}).get("image") or {}
    if rmq:
        reg = rmq.get("registry") or "caapim"
        repo = rmq.get("repository") or "message-broker"
        tag = rmq.get("tag") or "latest"
        refs.append(f"{reg}/{repo}:{tag}")

    # Druid (only if enabled)
    druid = values.get("druid") or {}
    if druid.get("enabled", True):
        druid_images = druid.get("image") or {}
        for _key, value in druid_images.items():
            if isinstance(value, str) and value:
                refs.append(prefix + value)

    for r in refs:
        print(r)

if __name__ == "__main__":
    main()
