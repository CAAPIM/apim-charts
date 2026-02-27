# Scripts

Scripts for API Portal Helm charts, including image manifest generation and pulling images when the cluster cannot access Docker Hub (e.g. behind a firewall).

## Scripts

| Script | Purpose |
|--------|---------|
| **generate-portal-image-manifest.sh** | Given a Portal version (e.g. `5.4`), resolves the Helm chart version from the repo, pulls that chart, and extracts the image list from its `values.yaml`. Writes a manifest file (image refs only, one per line) for use with `pull-portal-images.sh`. |
| **pull-portal-images.sh** | Reads a manifest file and pulls each image. Supports simple refs (`name:tag`) or full refs (`registry/repo/name:tag`). Optionally pushes to an internal registry. |
| **extract-portal-images.py** | Used by the generator: reads a chart `values.yaml` and prints one full image reference per line (portal core, RabbitMQ, Druid; excludes MySQL). |

## Requirements

- **Helm 3** – for `generate-portal-image-manifest.sh`
- **Python 3** and **PyYAML** – for the generator and `extract-portal-images.py`  
  Install: `pip install pyyaml` or `pip install -r scripts/requirements.txt`  
  If your environment requires an activated virtualenv, create one first:  
  `python3 -m venv .venv` then `source .venv/bin/activate` (Linux/macOS)
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
