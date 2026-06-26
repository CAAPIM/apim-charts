<<<<<<< HEAD
# Minio to SeaweedFS Data Migration Guide

## Overview

Starting from Portal version 5.4, the Portal Helm chart has transitioned from using Minio to SeaweedFS as the deep storage solution for analytics data. SeaweedFS provides improved performance, scalability, and S3-compatible object storage capabilities for the Druid analytics stack.

This document provides guidance on the automated data migration process that occurs during Helm upgrade operations.

---

## Background

### What Changed?

- **Previous Architecture**: Portal used Minio as the S3-compatible object storage backend for Druid's deep storage
- **New Architecture**: Portal now uses SeaweedFS as the S3-compatible object storage backend for Druid's deep storage
- **Impact**: Existing analytics data stored in Minio needs to be migrated to SeaweedFS to maintain historical data continuity

### What is Migrated?

The migration process transfers all analytics data from the Minio `api-metrics` bucket to the SeaweedFS `api-metrics` bucket, ensuring that:
- Historical analytics data remains accessible
- Druid can continue to query past data segments
- No data loss occurs during the transition

---

## Automated Migration Process

### How It Works

The Portal Helm chart includes an automated migration mechanism that is controlled by the `global.deepStorage.enableDataMigration` property in your values files.

**Key Configuration Files:**
- `charts/portal/values.yaml` (development/default configuration)
- `charts/portal/values-production.yaml` (production configuration)

**Migration Configuration:**

```yaml
global:
  deepStorage:
    seaweedfs: true
    # Set to true to create a data migration Job from Minio to SeaweedFS
    # The Job runs independently and will not block helm operations
    # Rclone will automatically retry if services are not ready
    # Set to false to remove the Job resource
    enableDataMigration: true
    # Maximum time in seconds to wait for services to become ready (default: 600 = 10 minutes)
    # The Job will check service accessibility every 10 seconds until ready or timeout
    migrationInitialDelaySeconds: 600
    auth:
      secretName: seaweedfs-s3-secret
    analytics:
      bucketName: api-metrics
```

### Migration Job Characteristics

1. **Non-Blocking**: The migration Job runs independently and does not block Helm upgrade operations
2. **Automatic Retry**: Uses Rclone with built-in retry logic to handle service readiness delays
3. **Service Wait**: Waits up to 10 minutes (configurable via `migrationInitialDelaySeconds`) for both Minio and SeaweedFS services to become ready
4. **Idempotent**: Safe to run multiple times; only copies data that doesn't already exist in the destination
5. **Kubernetes Job**: Deployed as a Kubernetes Job resource that can be monitored using standard kubectl commands

---

## Upgrade Instructions

### Step 1: Perform Helm Upgrade

When upgrading your Portal deployment to version 5.4 or later, the migration will be automatically triggered if `enableDataMigration` is set to `true` (which is the default).

```bash
# Upgrade the Portal Helm chart
helm upgrade <release-name> <chart-path> \
  -n <namespace> \
  -f values.yaml \
  --wait
```

**Example:**
```bash
helm upgrade portal ./charts/portal \
  -n portal-namespace \
  -f values-production.yaml \
  --wait
```

### Step 2: Monitor Migration Progress

After the Helm upgrade completes, monitor the migration Job:

```bash
# Check the migration Job status
kubectl get jobs -n <namespace> | grep migration

# View migration Job details
kubectl describe job <migration-job-name> -n <namespace>

# Check migration logs
kubectl logs -n <namespace> job/<migration-job-name> -f
```

**Example:**
```bash
# List all jobs
kubectl get jobs -n portal-namespace

# Follow migration logs
kubectl logs -n portal-namespace job/portal-minio-to-seaweedfs-migration -f
```

### Step 3: Verify Migration Completion

Check that the migration Job has completed successfully:

```bash
# Check Job completion status
kubectl get job <migration-job-name> -n <namespace>
```

**Expected Output:**
```
NAME                                    COMPLETIONS   DURATION   AGE
portal-minio-to-seaweedfs-migration    1/1           5m30s      10m
```

**Verify data in SeaweedFS:**
```bash
# Port-forward to SeaweedFS S3 service
kubectl port-forward -n <namespace> svc/seaweedfs 8333:8333

# Use AWS CLI or s3cmd to list bucket contents
aws s3 ls s3://api-metrics/ \
  --endpoint-url http://localhost:8333 \
  --no-verify-ssl
```

### Step 4: Disable Migration for Future Upgrades

**IMPORTANT**: After the migration completes successfully, you **MUST** manually update your values file to prevent unnecessary re-migration on subsequent Helm upgrades.

Edit your values file (`values.yaml` or `values-production.yaml`):

```yaml
global:
  deepStorage:
    seaweedfs: true
    # Set to false after initial migration completes
    enableDataMigration: false  # Change from true to false
    migrationInitialDelaySeconds: 600
    auth:
      secretName: seaweedfs-s3-secret
    analytics:
      bucketName: api-metrics
```

**Apply the updated configuration:**
```bash
# Upgrade with the updated values file
helm upgrade <release-name> <chart-path> \
  -n <namespace> \
  -f values.yaml
```

This step is crucial because:
- Prevents redundant migration attempts on every upgrade
- Reduces unnecessary resource consumption
- Speeds up future Helm upgrade operations
- Avoids potential data synchronization issues

---

## Migration Scenarios

### Scenario 1: Fresh Installation (No Migration Needed)

If you're installing Portal for the first time on version 5.4 or later:
- No migration is necessary
- SeaweedFS will be used from the start
- You can set `enableDataMigration: false` before installation

### Scenario 2: Upgrade from Pre-5.4.1 with Minio Data

If you're upgrading from a version that used Minio:
1. Leave `enableDataMigration: true` (default)
2. Perform the Helm upgrade
3. Monitor the migration Job
4. Set `enableDataMigration: false` after completion

### Scenario 3: Upgrade from 5.4.1+ (Already Migrated)

If you've already migrated to SeaweedFS:
1. Ensure `enableDataMigration: false` in your values file
2. Perform the Helm upgrade normally
3. No migration Job will be created

---

## Troubleshooting

### Migration Job Fails to Start

**Symptoms:**
- Job is created but no pods are running
- Job shows 0/1 completions

**Possible Causes & Solutions:**
1. **Image pull issues**: Verify image pull secrets are configured correctly
   ```bash
   kubectl describe job <migration-job-name> -n <namespace>
   ```

2. **Resource constraints**: Check if the cluster has sufficient resources
   ```bash
   kubectl describe nodes
   ```

### Migration Job Times Out

**Symptoms:**
- Job pod shows "Init:Error" or "Error" status
- Logs indicate timeout waiting for services

**Possible Causes & Solutions:**
1. **Services not ready**: Increase `migrationInitialDelaySeconds`
   ```yaml
   global:
     deepStorage:
       migrationInitialDelaySeconds: 1200  # Increase to 20 minutes
   ```

2. **Network issues**: Verify service connectivity
   ```bash
   kubectl get svc -n <namespace> | grep -E 'minio|seaweedfs'
   ```

### Partial Data Migration

**Symptoms:**
- Job completes but not all data is transferred
- Missing analytics data in SeaweedFS

**Possible Causes & Solutions:**
1. **Rclone errors**: Check Job logs for specific errors
   ```bash
   kubectl logs -n <namespace> job/<migration-job-name>
   ```

2. **Credential issues**: Verify secrets are correctly configured
   ```bash
   kubectl get secret minio-secret -n <namespace> -o yaml
   kubectl get secret seaweedfs-s3-secret -n <namespace> -o yaml
   ```

3. **Re-run migration**: Delete the Job and upgrade again with `enableDataMigration: true`
   ```bash
   kubectl delete job <migration-job-name> -n <namespace>
   helm upgrade <release-name> <chart-path> -n <namespace> -f values.yaml
   ```

### Migration Job Stuck in Running State

**Symptoms:**
- Job shows 0/1 completions for extended period
- Pod is running but not completing

**Possible Causes & Solutions:**
1. **Large data transfer**: Be patient; large datasets take time
   - Monitor logs to see progress
   - Check network bandwidth

2. **Pod issues**: Check pod status and logs
   ```bash
   kubectl get pods -n <namespace> | grep migration
   kubectl logs -n <namespace> <migration-pod-name> -f
   ```

### Accessing Migration Logs After Job Completion

```bash
# Get the completed pod name
kubectl get pods -n <namespace> | grep migration

# View logs from completed pod
kubectl logs -n <namespace> <migration-pod-name>
```

=======
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

>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
---

## Post-Migration Validation

<<<<<<< HEAD
### Verify Analytics Data Availability

1. **Access Portal UI**: Navigate to your Portal analytics dashboard
2. **Check Historical Data**: Verify that historical analytics data is visible
3. **Query Druid**: Confirm Druid can access data from SeaweedFS

### Verify Druid Configuration

Check that Druid components are using SeaweedFS:

```bash
# Check coordinator logs
kubectl logs -n <namespace> deployment/druid-coordinator | grep -i seaweedfs

# Check historical logs
kubectl logs -n <namespace> deployment/druid-historical | grep -i seaweedfs
```

### Optional: Decommission Minio

Once you've verified that:
- Migration completed successfully
- Analytics data is accessible in Portal
- Druid is functioning correctly with SeaweedFS
- You've updated `enableDataMigration: false`

You can optionally scale down or remove Minio resources to free up cluster resources:

```bash
# Scale down Minio (if deployed as part of Druid subchart)
kubectl scale statefulset minio -n <namespace> --replicas=0

# Or disable Minio in your values file for future upgrades
# Note: Check your chart version's documentation for the correct approach
```

**Warning**: Only decommission Minio after thorough validation. Keep backups of critical data.

---

## Best Practices

1. **Test in Non-Production First**: Always test the migration in a development or staging environment before production
2. **Backup Data**: Take backups of your Minio data before starting the migration
3. **Monitor Resources**: Ensure adequate cluster resources during migration
4. **Plan Maintenance Window**: Schedule the upgrade during a maintenance window to minimize user impact
5. **Document Configuration**: Keep track of your `enableDataMigration` setting changes
6. **Verify Before Disabling**: Only set `enableDataMigration: false` after confirming successful migration
7. **Keep Migration Logs**: Save migration Job logs for troubleshooting and audit purposes

---

## Configuration Reference

### Key Configuration Parameters

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `global.deepStorage.seaweedfs` | values.yaml | `true` | Enable SeaweedFS as deep storage backend |
| `global.deepStorage.enableDataMigration` | values.yaml | `true` | Enable/disable migration Job creation |
| `global.deepStorage.migrationInitialDelaySeconds` | values.yaml | `600` | Maximum wait time for services (seconds) |
| `global.deepStorage.auth.secretName` | values.yaml | `seaweedfs-s3-secret` | Secret containing SeaweedFS credentials |
| `global.deepStorage.analytics.bucketName` | values.yaml | `api-metrics` | Target bucket name in SeaweedFS |

### Related Secrets

- **minio-secret**: Contains Minio access credentials (source)
- **seaweedfs-s3-secret**: Contains SeaweedFS S3 credentials (destination)

Both secrets should contain:
- `access_key` or `accesskey`
- `secret_key` or `secretkey`

---

## Additional Resources

- [Portal Helm Chart Documentation](../../charts/portal/README.md)
- [SeaweedFS Documentation](https://github.com/seaweedfs/seaweedfs)
- [Rclone Documentation](https://rclone.org/docs/)
- [Broadcom API Portal Documentation](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-developer-portal/5-3/)

---

## Support

For issues or questions related to the migration process:
1. Check the troubleshooting section above
2. Review migration Job logs for specific error messages
3. Consult the Portal Helm chart issues on GitHub
4. Contact Broadcom support with relevant logs and configuration details
=======
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
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
<<<<<<< HEAD
| 1.0 | 2026-01-29 | Initial documentation for Minio to SeaweedFS migration |

---

**Note**: This migration is a one-time process per Portal deployment. Once completed and verified, ensure `enableDataMigration` is set to `false` to prevent unnecessary re-execution on future upgrades.
=======
| 2.0 | 2026-05-27 | Rewrote for 5.4.2: four-step upgrade procedure, flag state table for all paths, credential rotation warning, intelligence bucket, --timeout guidance |
| 1.0 | 2026-01-29 | Initial documentation for MinIO to SeaweedFS migration |
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
