# MinIO to SeaweedFS Data Migration Guide

## Overview

Portal 5.4.2 fully removes MinIO as the Druid analytics deep storage backend. SeaweedFS
is now the only supported storage. Customers upgrading from earlier versions that used MinIO
must migrate their analytics data into SeaweedFS before MinIO resources are removed.

The migration approach uses a **sidecar MinIO server** inside the migration Job pod. This
works for **both** standalone (`replicaCount: 1`) and distributed (`replicaCount: 4`) MinIO
installations.

| Release | Migration approach | MinIO service required? |
|---------|-------------------|------------------------|
| 5.4 | rclone S3-to-S3 (external MinIO service → SeaweedFS) | Yes |
| **5.4.2** | **Sidecar MinIO SNMD + rclone S3-to-S3 (localhost → SeaweedFS)** | **No** |

See [APPROACH-1-PVC-FILESYSTEM-COPY.md](APPROACH-1-PVC-FILESYSTEM-COPY.md) and
[APPROACH-2-SIDECAR-MINIO.md](APPROACH-2-SIDECAR-MINIO.md) for full technical details
on how and why this approach was chosen.

---

## Release Upgrade Matrix

| Upgrading from | Action required |
|---------------|----------------|
| **5.3** (MinIO only, any replicaCount) | Full migration: follow the steps below |
| **5.4** (already migrated to SeaweedFS) | No data migration; ensure `enableDataMigration: false` |
| **5.4** (MinIO still active) | Follow the 5.3 → 5.4.2 path below |
| **Fresh 5.4.2 install** | No migration needed; `enableDataMigration: false` (default) |

---

## How the Migration Job Works

The migration Job is a Kubernetes Job rendered when `global.deepStorage.enableDataMigration: true`.
It runs three containers in a single pod:

```
init: wait-for-seaweedfs
  └─ TCP probe to seaweedfs-s3:9333 until ready

sidecar: minio-local
  └─ Starts MinIO binary in SNMD mode:
       minio server /mnt/minio-0 [/mnt/minio-1 /mnt/minio-2 /mnt/minio-3]
     All original MinIO PVCs are mounted. MinIO reconstructs erasure-coded objects
     and serves them via S3 at localhost:9000. Exits when /shared/migration-done appears.

main: data-copier
  └─ Step 0: Wait for localhost:9000 (local MinIO) to be healthy
     Step 1: rclone copy minio:/api-metrics → seaweedfs:/api-metrics
             --checksum --transfers 16 --retries 30
     Step 2: rclone check --one-way (verify all source objects exist in destination)
     Step 3: kubectl delete pvc minio-vol-claim-minio-{0..N} (auto-cleanup all PVCs)
     Step 4: touch /shared/migration-done (signal sidecar to stop)
```

**Why the sidecar instead of direct filesystem copy:**
MinIO in distributed mode (`replicaCount > 1`) stores objects as erasure-coded shards
across multiple drives. No single PVC holds a complete object. By starting MinIO itself
in SNMD (Single-Node Multi-Drive) mode with all drives, MinIO handles shard reconstruction
and serves complete objects via S3 — regardless of whether the original setup was standalone
or distributed.

---

## Key Values

| Value | Default | Description |
|-------|---------|-------------|
| `global.deepStorage.enableDataMigration` | `false` | Set `true` to render the migration Job during upgrade |
| `global.deepStorage.migrationInitialDelaySeconds` | `600` | Seconds to wait for SeaweedFS before timing out |
| `druid.minio.enabled` | `false` | Must be `false` so MinIO pods are not running (PVCs must be released) |
| `seaweedfs.minio.replicaCount` | `1` | **Operator-specified at upgrade time.** Set to match the original MinIO `replicaCount` (1=standalone, 4=distributed). Do NOT hardcode in values files — it is install-specific. |
| `seaweedfs.minio.image` | `minio:5.4.1` | MinIO image for the sidecar. Set in `values-production.yaml`; operators do not need to pass this on the command line. |
| `seaweedfs.minio.pvcBaseName` | `minio-vol-claim-minio` | Base name of the MinIO PVCs to mount and delete. The ordinal index (`-0`, `-1`, …) is appended automatically. Override only if the original MinIO StatefulSet used a custom name. |

---

## Upgrade Steps: 5.3 → 5.4.2

### Step 1 — Identify your MinIO replicaCount

Check your current running configuration:

```bash
kubectl get statefulset minio -n <namespace> -o jsonpath='{.spec.replicas}'
# OR check your installed Helm values:
helm get values <release> -n <namespace> | grep -A5 "minio:"
```

Note the `replicaCount` value — you will need it in Step 2.

### Step 2 — Upgrade with migration enabled

```bash
# Standalone MinIO (replicaCount was 1) — default; no replicaCount flag needed
helm upgrade <release> ./charts/portal \
  --set druid.minio.enabled=false \
  --set global.deepStorage.enableDataMigration=true

# Distributed MinIO (replicaCount was 4) — must be specified explicitly
helm upgrade <release> ./charts/portal \
  --set druid.minio.enabled=false \
  --set global.deepStorage.enableDataMigration=true \
  --set seaweedfs.minio.replicaCount=4
```

What happens during upgrade:
- `druid.minio.enabled=false` removes the MinIO StatefulSet → pods terminate → PVCs released
- SeaweedFS is deployed (if not already present)
- The migration Job is created and starts running

### Step 3 — Monitor the migration Job

```bash
# Check Job status
kubectl get job <release>-seaweedfs-data-copy-job -n <namespace>

# Watch SeaweedFS readiness (init container)
kubectl logs job/<release>-seaweedfs-data-copy-job -c wait-for-seaweedfs -n <namespace>

# Watch local MinIO sidecar startup
kubectl logs job/<release>-seaweedfs-data-copy-job -c minio-local -n <namespace>

# Watch data copy progress (main output)
kubectl logs job/<release>-seaweedfs-data-copy-job -c data-copier -n <namespace> -f
```

Expected output from `data-copier` on success:
```
Local MinIO is healthy.
========================================
  MinIO → SeaweedFS Migration
  Source : minio:/api-metrics (localhost:9000)
  Target : seaweedfs:/api-metrics
  Drives : 4 PVC(s)
========================================
--- Step 1: Copy ---
...Transferred: ...
--- Step 2: Verify (one-way check) ---
...
--- Step 3: Delete MinIO PVC(s) ---
Deleted minio-vol-claim-minio-0.
Deleted minio-vol-claim-minio-1.
Deleted minio-vol-claim-minio-2.
Deleted minio-vol-claim-minio-3.
--- Step 4: Signalling minio-local sidecar to exit ---
========================================
  Migration completed successfully!
  Run: helm upgrade <release> <chart>
    --set global.deepStorage.enableDataMigration=false
========================================
```

### Step 4 — Disable migration after completion

```bash
helm upgrade <release> ./charts/portal \
  --set global.deepStorage.enableDataMigration=false
```

This removes the migration Job (it is no longer rendered by Helm).
From this point, Druid uses SeaweedFS exclusively.

---

## Upgrade Steps: 5.4 → 5.4.2 (MinIO already migrated)

If you completed the 5.4 S3-to-S3 migration and Druid is already pointing at SeaweedFS:

```bash
helm upgrade <release> ./charts/portal \
  --set druid.minio.enabled=false \
  --set global.deepStorage.enableDataMigration=false
```

If any leftover MinIO PVCs exist, delete them manually:

```bash
kubectl delete pvc minio-vol-claim-minio-0 -n <namespace> --ignore-not-found
# (repeat for minio-1, minio-2, minio-3 if replicaCount was 4)
```

---

## Troubleshooting

### MinIO sidecar fails to start

Check logs:
```bash
kubectl logs job/<release>-seaweedfs-data-copy-job -c minio-local -n <namespace>
```

If MinIO logs a format mismatch error, it may have detected that the drives were
originally from a distributed cluster. As a workaround, try setting the environment
variable `MINIO_FORMAT_UPGRADE=on` in the sidecar container via Helm values override:

```yaml
# values-override.yaml
seaweedfs:
  # ... other values ...
```

Then manually patch the Job or recreate it with the extra env var set.

### rclone reports missing objects after copy

Re-run the migration Job by deleting the failed Job pod (the Job controller will restart it):

```bash
kubectl delete pod -l job-name=<release>-seaweedfs-data-copy-job -n <namespace>
```

rclone's `--checksum` and `--retries 30` flags handle transient errors automatically.

### Druid coordinator does not load segments after migration

Confirm the `druid.extensions.deepStorage` configuration points to SeaweedFS (not MinIO).
Check that `global.deepStorage.minio` is unset (falsy) and SeaweedFS credentials are present:

```bash
kubectl get secret seaweedfs-s3-secret -n <namespace>
kubectl get configmap <release>-druid-coordinator-config -n <namespace> -o yaml | grep storage
```

---

## New Values Reference (5.4.2)

```yaml
# --- Already set in values-production.yaml (no operator action needed) ---
global:
  deepStorage:
    enableDataMigration: false    # set true only during upgrade window
    migrationInitialDelaySeconds: 600

druid:
  minio:
    enabled: false                # MinIO fully removed in 5.4.2

seaweedfs:
  minio:
    image: minio:5.4.1            # sidecar image; pre-set in values-production.yaml

# --- Operator passes on the helm upgrade command line during migration only ---
# seaweedfs.minio.replicaCount   default is 1 (standalone); pass 4 for distributed MinIO
```
