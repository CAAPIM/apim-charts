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

---

## Post-Migration Validation

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

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-29 | Initial documentation for Minio to SeaweedFS migration |

---

**Note**: This migration is a one-time process per Portal deployment. Once completed and verified, ensure `enableDataMigration` is set to `false` to prevent unnecessary re-execution on future upgrades.
