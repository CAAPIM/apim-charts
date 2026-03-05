# Scripts

Scripts for API Portal Helm charts, including image manifest generation and pulling images when the cluster cannot access Docker Hub (e.g. behind a firewall).

## Scripts

| Script | Purpose |
|--------|---------|
| **generate-portal-image-manifest.sh** | Given a Portal version (e.g. `5.4`), resolves the Helm chart version from the repo, pulls that chart, and extracts the image list from its `values.yaml`. Writes a manifest file whose first line identifies Portal appVersion and Helm chart version (comment), followed by image refs (one per line) for use with `pull-portal-images.sh`. |
| **pull-portal-images.sh** | Reads a manifest file and pulls each image. Supports simple refs (`name:tag`) or full refs (`registry/repo/name:tag`). Optionally pushes to an internal registry. |
| **extract-portal-images.sh** | Used by the generator: reads a chart `values.yaml` and prints one full image reference per line (portal core, RabbitMQ, Druid; excludes MySQL). No Python or pip required. If `druid.enabled` is false in your values, ignore the druid lines in the list. |
| **extract-portal-images.py** | Optional Python alternative to the shell extractor; same output format. Requires PyYAML (`pip install pyyaml`). |

## Requirements

- **Helm 3** – for `generate-portal-image-manifest.sh` (image extraction uses the shell script; no Python or pip required)
- **Docker** (or Podman) – for `pull-portal-images.sh`; log in to the source registry (and internal registry if pushing)

## Quick start (firewall / internal registry)

1. **Generate a manifest** for the target Portal version (e.g. 5.4):
   ```bash
   ./scripts/generate-portal-image-manifest.sh 5.4
   ```
   This writes `manifest-5.4.txt` in the current directory (override with `MANIFEST_OUTPUT=/path/to/file.txt`).

2. **Pull images** from that manifest:
   ```bash
   ./scripts/pull-portal-images.sh manifest-5.4.txt
   ```

3. **Optional:** Pull from a different source or push to an internal registry:
   ```bash
   SOURCE_REGISTRY=myreg.com SOURCE_REPO=portal ./scripts/pull-portal-images.sh manifest-5.4.txt
   INTERNAL_REGISTRY=myreg.com/portal PUSH_INTERNAL=1 ./scripts/pull-portal-images.sh manifest-5.4.txt
   ```

One-liner (generate then pull):
```bash
./scripts/generate-portal-image-manifest.sh 5.4 && ./scripts/pull-portal-images.sh manifest-5.4.txt
```

## Upgrade path

For the supported Portal upgrade path (5.1 → 5.2 → 5.3 → 5.4) and when to use these scripts, see [PORTAL_5.1_TO_5.4_UPGRADE_STEPS.md](../PORTAL_5.1_TO_5.4_UPGRADE_STEPS.md).
