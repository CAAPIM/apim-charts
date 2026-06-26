# MinIO to SeaweedFS Data Migration Guide

## Overview

Starting from Portal version **5.4.1**, the Portal Helm chart transitioned from MinIO to SeaweedFS as the deep storage backend for Druid analytics data. This guide covers all upgrade paths to 5.4.2.

> **When was SeaweedFS introduced?**
> SeaweedFS was added in **5.4.1**. Releases 5.3.3 and 5.4.0 used MinIO only. If you are upgrading from 5.3.3 or 5.4.0, follow the pre-5.4.1 upgrade path below.

---

## Credential Rotation Warning (5.4.1.x users)

If you are currently on any 5.4.1.x release and analytics have been broken since a recent patch upgrade, this is a known issue: every `helm upgrade` in 5.4.1 regenerated random SeaweedFS S3 credentials, which SeaweedFS hot-reloaded within ~60 seconds, breaking all Druid → SeaweedFS authentication silently.

**Before upgrading to 5.4.2**, verify your credentials are in sync:

```bash
# Get the current secret credentials
kubectl get secret seaweedfs-s3-secret -n <namespace> \
  -o jsonpath='{.data.admin_access_key_id}' | base64 -d

# Check what SeaweedFS is actually using (from the running pod's mounted file)
kubectl exec -n <namespace> seaweedfs-s3-0 -- \
  cat /etc/sw/s3/seaweedfs_s3_config | python3 -m json.tool
```

If the `accessKey` in the config file does not match the secret, SeaweedFS needs to be restarted once to reload the correct credentials before you upgrade.

The 5.4.2 upgrade fixes this permanently via a `lookup` guard that preserves existing credentials on every subsequent `helm upgrade`.

---

## Control Flags

Three flags in `global.deepStorage` govern the migration. The 5.4.2 defaults are:

| Flag | Default | Purpose |
|---|---|---|
| `global.deepStorage.minio` | `true` | Controls which S3 backend Druid uses (`true`=MinIO, `false`=SeaweedFS) |
| `global.deepStorage.enableDataMigration` | `false` | Creates the migration Job as a Helm post-upgrade hook when `true` |
| `global.deepStorage.minioRemoved` | `false` | Removes MinIO StatefulSet, Service, and ConfigMap when `true` |

The `minio: true` default ensures that all pre-5.4.1 customers upgrading without overrides keep Druid on MinIO — no analytics outage.

---

## Upgrade Paths

### Path 0: Fresh Install of 5.4.2

No migration needed. Override the `minio: true` default so MinIO is never created:

```bash
helm install <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml \
  --set global.deepStorage.minio=false
```

---

### Path 1: 5.3.3 → 5.4.2 and Path 2: 5.4.0 → 5.4.2

Both 5.3.3 and 5.4.0 are MinIO-only releases (SeaweedFS did not exist). Use the four-step procedure:

#### Step 1 — Upgrade and install SeaweedFS alongside MinIO

> **REQUIRED FLAG — do not skip:** The 5.4.2 chart defaults to `global.deepStorage.minio=false`
> (SeaweedFS). You must pass `--set global.deepStorage.minio=true` in this step or Druid will
> immediately switch to an empty SeaweedFS and analytics will go dark.

```bash
helm upgrade <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml \
  --set global.deepStorage.minio=true \        # REQUIRED — keeps Druid on MinIO
  --set global.deepStorage.enableDataMigration=false \
  --set global.deepStorage.minioRemoved=false
```

Verify both services are running:

```bash
kubectl get pods -n <namespace> | grep -E 'minio|seaweedfs'
```

#### Step 2 — Trigger migration (helm blocks until complete)

> **Important:** Use `--timeout 3h` or longer for large datasets. The default 5-minute timeout will cause helm to report failure while the job continues running in the background.

```bash
helm upgrade <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml \
  --set global.deepStorage.minio=true \
  --set global.deepStorage.enableDataMigration=true \
  --set global.deepStorage.minioRemoved=false \
  --timeout 3h
```

Monitor progress in a separate terminal:

```bash
kubectl logs -n <namespace> -f \
  job/<release>-seaweedfs-data-copy-job -c data-copier
```

Expected final output:

```
✓ Copy complete for api-metrics
✓ Integrity check passed for api-metrics
=== Migration complete. All buckets copied and verified. ===
```

#### Step 3 — Switch Druid to SeaweedFS

Drop the `minio=true` override. The chart default of `false` now takes effect automatically:

```bash
helm upgrade <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml
  # No --set global.deepStorage.minio needed — chart default false switches Druid to SeaweedFS
```

Verify analytics data is accessible in the Portal UI.

#### Step 4 — Remove MinIO (optional, after thorough validation)

> **Warning:** Only perform this step after confirming analytics data is fully accessible from SeaweedFS. The MinIO PVC is NOT deleted automatically — remove it manually after validation.

```bash
helm upgrade <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml \
  --set global.deepStorage.minio=false \
  --set global.deepStorage.enableDataMigration=false \
  --set global.deepStorage.minioRemoved=true
```

Delete the PVC manually after the StatefulSet is removed:

```bash
kubectl delete pvc minio-vol-claim-minio-0 -n <namespace>
```

---

### Path 3: 5.4.1 → 5.4.2 (already migrated to SeaweedFS)

Single step. The credential rotation fix is applied automatically.

```bash
helm upgrade <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml
```

Your existing overrides (`minio=false`, `enableDataMigration=false`) are preserved. After upgrading, credentials will never rotate on future upgrades.

Optionally clean up MinIO if you haven't already:

```bash
helm upgrade <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml \
  --set global.deepStorage.minioRemoved=true
```

---

### Path 4: 5.4.1 → 5.4.2 (still on MinIO, migration not yet complete)

#### Step 1 — Upgrade and migrate

```bash
helm upgrade <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml \
  --set global.deepStorage.minio=true \
  --set global.deepStorage.enableDataMigration=true \
  --timeout 3h
```

#### Step 2 — Switch Druid to SeaweedFS

```bash
helm upgrade <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml \
  --set global.deepStorage.minio=false \
  --set global.deepStorage.enableDataMigration=false
```

#### Step 3 — Remove MinIO (optional)

```bash
helm upgrade <release> ./charts/portal \
  -n <namespace> \
  -f values-production.yaml \
  --set global.deepStorage.minioRemoved=true
```

---

## Flag State Reference

Chart default for `minio` is **`false`** (SeaweedFS). `(default)` = no flag needed. `*` = must be set explicitly.

| Scenario | Step | minio | enableDataMigration | minioRemoved |
|---|---|---|---|---|
| Fresh 5.4.2 install | Install | `false` (default) | `false` (default) | `false` (default) |
| Pre-5.4.1 → 5.4.2 | 1 — Upgrade | `true` **REQUIRED \*** | `false` (default) | `false` (default) |
| Pre-5.4.1 → 5.4.2 | 2 — Migrate | `true` **REQUIRED \*** | `true` * | `false` (default) |
| Pre-5.4.1 → 5.4.2 | 3 — Switch | `false` (default) | `false` (default) | `false` (default) |
| Pre-5.4.1 → 5.4.2 | 4 — Cleanup | `false` (default) | `false` (default) | `true` * |
| 5.4.1 → 5.4.2 (on SeaweedFS) | Upgrade | `false` (default) | `false` (default) | `false` (default) |
| 5.4.1 → 5.4.2 (on MinIO) | 1 — Migrate | `true` (existing override) | `true` * | `false` (default) |
| 5.4.1 → 5.4.2 (on MinIO) | 2 — Switch | `false` (default) | `false` (default) | `false` (default) |
| 5.4.1 → 5.4.2 (on MinIO) | 3 — Cleanup | `false` (default) | `false` (default) | `true` * |

---

## Intelligence Bucket (apim-patches)

If `portal.intelligence.enabled: true`, the migration Job also copies the `apim-patches` bucket from MinIO to SeaweedFS automatically. No additional flags are required.

---

## Post-Migration Validation

1. Open the Portal analytics dashboard and verify historical data is visible.
2. Check Druid coordinator is reading from SeaweedFS:
   ```bash
   kubectl logs -n <namespace> statefulset/coordinator | grep -i seaweedfs
   ```
3. Confirm no 403 errors in ingestion server logs:
   ```bash
   kubectl logs -n <namespace> deployment/ingestion-server | grep -i "403\|Forbidden\|access denied"
   ```

---

## Troubleshooting

### Migration Job times out

Increase `migrationInitialDelaySeconds` and use a longer `--timeout`:

```yaml
global:
  deepStorage:
    migrationInitialDelaySeconds: 1800  # 30 minutes
```

```bash
helm upgrade ... --timeout 6h
```

### Partial migration / data missing after switch

Re-run the migration. The Job is idempotent — rclone only copies objects not already in the destination:

```bash
helm upgrade <release> ./charts/portal \
  --set global.deepStorage.minio=true \
  --set global.deepStorage.enableDataMigration=true \
  --timeout 3h
```

### Analytics broken after 5.4.1.x patch upgrade (credential mismatch)

See the **Credential Rotation Warning** section at the top of this guide.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2026-05-27 | Rewrote for 5.4.2: four-step upgrade procedure, flag state table for all paths, credential rotation warning, intelligence bucket, --timeout guidance |
| 1.0 | 2026-01-29 | Initial documentation for MinIO to SeaweedFS migration |
