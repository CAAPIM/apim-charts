# MinIO to SeaweedFS Data Migration Guide

## Overview

Portal 5.4.2 fully removes MinIO as the Druid analytics deep storage backend. SeaweedFS
is now the only supported storage. Customers upgrading from earlier versions that used MinIO
must migrate their analytics data into SeaweedFS before the MinIO resources are removed.

The migration approach changed between Portal 5.4 and 5.4.2:

| Release | Migration approach | MinIO service required? |
|---------|-------------------|------------------------|
| 5.4 | rclone S3-to-S3 (MinIO endpoint → SeaweedFS endpoint) | Yes |
| **5.4.2** | **rclone filesystem-to-S3 (MinIO PVC mount → SeaweedFS)** | **No** |

The 5.4.2 approach mounts the old MinIO PVC (`minio-vol-claim-minio-0`) directly into the
migration Job as a read-only volume, copies its data into SeaweedFS, verifies integrity,
then automatically deletes the PVC — no MinIO service required.

---

## Release Upgrade Matrix

| Upgrading from | Action required |
|---------------|----------------|
| **5.3** (MinIO only) | Full migration: set `druid.minio.enabled=false` + `enableDataMigration=true` |
| **5.4** (already migrated to SeaweedFS) | No data migration; ensure `enableDataMigration=false` |
| **5.4** (MinIO still active / not yet migrated) | Standalone MinIO: follow the 5.3→5.4.2 path below. Distributed MinIO (replicaCount > 1): see [Distributed MinIO](#distributed-minio-replicacount--1) |
| **Fresh 5.4.2 install** | No migration needed; `enableDataMigration=false` (default) |

---

## Prerequisites

- The MinIO StatefulSet (`druid.minio.enabled`) **must be disabled** before running the
  migration so the RWO PVC is unbound and can be mounted by the Job.
- This approach works for **standalone MinIO** (`replicaCount: 1`, the default). See
  [Distributed MinIO](#distributed-minio-replicacount--1) for the 4-replica case.
- Adequate cluster resources: the migration Job requests 4 Gi memory.

---

## Upgrade Path: 5.3 → 5.4.2 (or 5.4 with MinIO data)

### Step 1: Helm upgrade with migration enabled

```bash
helm upgrade <release-name> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml \
  --set druid.minio.enabled=false \
  --set global.deepStorage.enableDataMigration=true
```

What happens during the upgrade:
1. `druid.minio.enabled=false` — MinIO StatefulSet is no longer rendered; MinIO pod
   terminates and the PVC (`minio-vol-claim-minio-0`) is released from its RWO bind.
2. SeaweedFS is deployed (or already running from a previous 5.4 install).
3. The migration Job is created. It:
   - Waits for SeaweedFS master to be reachable on port `9333`.
   - Checks if `/mnt/minio-old/<bucket>` contains data; exits cleanly if empty.
   - Runs `rclone copy` with `--checksum --transfers 16` from the PVC mount to SeaweedFS.
   - Runs `rclone check --one-way` to verify all files are present and intact.
   - Deletes `minio-vol-claim-minio-0` on success.

### Step 2: Monitor migration progress

```bash
# Watch Job status
kubectl get job <release>-seaweedfs-data-copy-job -n <namespace> -w

# Init container logs (SeaweedFS wait + empty-check)
kubectl logs job/<release>-seaweedfs-data-copy-job \
  -n <namespace> -c wait-for-seaweedfs -f

# Main migration logs (copy, verify, cleanup)
kubectl logs job/<release>-seaweedfs-data-copy-job \
  -n <namespace> -c data-copier -f
```

Expected final output in data-copier logs:
```
========================================
  Migration completed successfully!
  Set global.deepStorage.enableDataMigration=false
  in your values file for future upgrades.
========================================
```

### Step 3: Verify analytics data in SeaweedFS

```bash
# Port-forward SeaweedFS S3 gateway
kubectl port-forward -n <namespace> svc/seaweedfs-s3 8333:8333

# List bucket contents with AWS CLI
aws s3 ls s3://api-metrics/ \
  --endpoint-url http://localhost:8333 \
  --no-verify-ssl
```

### Step 4: Disable migration for future upgrades

After the migration Job completes successfully, update your values file:

```yaml
global:
  deepStorage:
    enableDataMigration: false   # prevents re-run on every helm upgrade
```

Then apply:
```bash
helm upgrade <release-name> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml
```

---

## Upgrade Path: 5.4 → 5.4.2 (already migrated)

If you already ran the 5.4 migration Job (S3-to-S3) and your data is in SeaweedFS:

1. Ensure `druid.minio.enabled: false` and `enableDataMigration: false`.
2. If the MinIO PVC still exists (it is not automatically cleaned up by the 5.4 Job),
   delete it manually:
   ```bash
   kubectl delete pvc minio-vol-claim-minio-0 -n <namespace> --ignore-not-found
   ```
3. Perform the helm upgrade normally.

---

## Distributed MinIO (replicaCount > 1)

The production values previously set `druid.minio.replicaCount: 4`. This runs MinIO in
**distributed erasure-coding mode**, where data is spread across 4 PVCs
(`minio-vol-claim-minio-{0..3}`) in a non-filesystem-readable format.

The PVC-mount migration approach in 5.4.2 **does not work** for distributed MinIO, because
rclone cannot read the XL erasure-coded files directly from the filesystem.

**Recommended path for distributed MinIO customers:**

1. **While still on 5.4**, re-enable the S3-to-S3 migration Job temporarily:
   ```yaml
   global:
     deepStorage:
       enableDataMigration: true
   druid:
     minio:
       enabled: true    # keep MinIO running for the S3-to-S3 copy
   ```
   Deploy this 5.4 configuration and wait for the migration Job to complete.

2. **Verify** that data is accessible in SeaweedFS (see Step 3 above).

3. **Upgrade to 5.4.2** with MinIO disabled:
   ```yaml
   global:
     deepStorage:
       enableDataMigration: false
   druid:
     minio:
       enabled: false
   ```

4. Manually delete the MinIO PVCs:
   ```bash
   for i in 0 1 2 3; do
     kubectl delete pvc "minio-vol-claim-minio-${i}" -n <namespace> --ignore-not-found
   done
   ```

---

## Troubleshooting

### Job pod is Pending (volume mount failure)

**Symptom**: Pod stuck in `Pending` state; `kubectl describe pod` shows a volume attach error.

**Cause**: `minio-vol-claim-minio-0` does not exist (fresh install or already deleted)
or MinIO StatefulSet is still running and holds the RWO PVC.

**Fix**:
- If MinIO is still running: ensure `druid.minio.enabled=false` and re-run the upgrade.
- If PVC does not exist: set `enableDataMigration=false` (no data to migrate).

### Migration Job times out waiting for SeaweedFS

**Symptom**: Init container exits with `SeaweedFS did not become ready`.

**Fix**: Increase the timeout:
```yaml
global:
  deepStorage:
    migrationInitialDelaySeconds: 1200  # 20 minutes
```

### rclone copy fails midway

**Symptom**: `data-copier` container exits non-zero before the cleanup step.

**Fix**: The Job has `backoffLimit: 5`, so Kubernetes restarts it automatically.
rclone's `--retries 30` and `--low-level-retries 10` also handle transient errors.
If the Job exhausts retries, check logs for the specific error, fix the root cause, then
delete the failed Job and re-run:
```bash
kubectl delete job <release>-seaweedfs-data-copy-job -n <namespace>
helm upgrade <release> ./charts/portal -n <namespace> -f values-production.yaml \
  --set global.deepStorage.enableDataMigration=true
```

### PVC not deleted after successful migration

**Symptom**: Job completed but `kubectl get pvc` still shows `minio-vol-claim-minio-0`.

**Fix**: Delete it manually:
```bash
kubectl delete pvc minio-vol-claim-minio-0 -n <namespace> --ignore-not-found
```

---

## Configuration Reference

| Parameter | Default (5.4.2) | Description |
|-----------|----------------|-------------|
| `druid.minio.enabled` | `false` | Deploy the MinIO StatefulSet. Must be `false` for PVC-based migration. |
| `global.deepStorage.enableDataMigration` | `false` | Create the migration Job. Set `true` only when migrating from 5.3/5.4. |
| `global.deepStorage.migrationInitialDelaySeconds` | `600` | Seconds to wait for SeaweedFS before starting the copy. |
| `global.deepStorage.auth.secretName` | `seaweedfs-s3-secret` | Secret containing SeaweedFS admin credentials. |
| `global.deepStorage.analytics.bucketName` | `api-metrics` | Target bucket in SeaweedFS. |
| `seaweedfs.minio.bucketName` | `api-metrics` | Source bucket name in the MinIO PVC filesystem path. |

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2026-05-15 | 5.4.2: PVC-based migration (no MinIO service); auto-cleanup of MinIO PVC; distributed MinIO guidance |
| 1.0 | 2026-01-29 | 5.4: Initial S3-to-S3 migration documentation |
