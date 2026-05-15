# US1094641 — Druid Deep Storage Migration: MinIO to SeaweedFS

## The Problem

Portal uses Apache Druid for analytics. Druid requires an S3-compatible object store as
its "deep storage" — the place where it persists segment data long-term.

Before Portal 5.4, **MinIO** was the only supported deep storage backend. It was deployed
as a Kubernetes StatefulSet alongside Druid, storing all segment data in Persistent Volume
Claims (PVCs).

In Portal 5.4, **SeaweedFS** was introduced as a replacement. Both MinIO and SeaweedFS
could coexist, and a migration Job was provided to copy data from one to the other.

In Portal **5.4.2**, **MinIO is fully removed**. SeaweedFS is the only supported backend.

This creates a problem for customers upgrading from 5.3 (or 5.4 with MinIO still active):
their Druid segment data lives in MinIO PVCs that must be moved into SeaweedFS before
MinIO is deleted — otherwise analytics data is permanently lost.

### Release Context

| Version | Deep Storage | Migration support |
|---------|-------------|-------------------|
| 5.3 | MinIO only | None |
| 5.4 | MinIO + SeaweedFS (toggle) | S3-to-S3 Job (required live MinIO service) |
| **5.4.2** | **SeaweedFS only** | **Sidecar MinIO SNMD Job (no live MinIO needed)** |

---

## What Changed in the Helm Charts

### 1. MinIO is disabled by default (`druid.minio.enabled: false`)

All MinIO Kubernetes resources (StatefulSet, Deployment, Service, ConfigMap, Secret) are
now wrapped in `{{- if .Values.minio.enabled }}`. The default is `false`.

This means a fresh 5.4.2 install does not create any MinIO resources at all. Operators
upgrading from 5.3 can temporarily re-enable MinIO for the migration window if needed,
but the Job approach described below does not require it.

**Files changed:**
- `charts/druid/values.yaml` — added `minio.enabled: false`
- `charts/druid/templates/minio/minio-statefulset.yaml` — added `minio.enabled` guard
- `charts/druid/templates/minio/minio-deployment.yaml` — added `minio.enabled` guard
- `charts/druid/templates/minio/minio-service.yaml` — added `minio.enabled` guard
- `charts/druid/templates/minio/minio-config.yaml` — added `minio.enabled` guard
- `charts/druid/templates/minio/minio-secret.yaml` — added `minio.enabled` guard

### 2. Migration Job added to the SeaweedFS chart

A Kubernetes Job is rendered when `global.deepStorage.enableDataMigration: true`. It
copies all Druid segment data from MinIO into SeaweedFS, verifies integrity, and
auto-deletes the MinIO PVCs on success.

**Files changed/added:**
- `charts/seaweedfs/templates/seaweedfs/seaweedfs-data-copy-job.yaml` — migration Job
- `charts/seaweedfs/templates/seaweedfs/service-accounts/migration-role.yaml` — RBAC Role
- `charts/seaweedfs/templates/seaweedfs/service-accounts/migration-rolebinding.yaml` — RBAC RoleBinding
- `charts/seaweedfs/values.yaml` — added `minio.replicaCount`, `minio.image`, and `minio.pvcBaseName`
- `charts/portal/values-production.yaml` — added `seaweedfs.minio.replicaCount` and `seaweedfs.minio.image`

---

## Approach 1 — PVC Filesystem Copy (Why It Doesn't Work for Distributed MinIO)

The first approach we considered mirrors what the `portal-dist` Docker Swarm branch
`sm_no_minio` does: mount the old MinIO PVC as a read-only volume in the migration Job,
then use rclone to copy the contents from the filesystem path into SeaweedFS:

```bash
rclone copy /mnt/minio-old/api-metrics seaweedfs:/api-metrics --checksum --transfers 16
```

This requires no running MinIO service or credentials. It looks simple.

### Why it works for standalone MinIO (`replicaCount: 1`)

In standalone mode, MinIO stores each object as a directory on its single drive:

```
/opt/data/api-metrics/
  some-datasource/2024-01-01/v1/0/
    xl.meta        ← metadata + full object content (small objects inline, large as part.N)
    part.1         ← full object data for larger objects
```

rclone copies these files as S3 objects into SeaweedFS. The paths translate correctly and
Druid can find its segments.

### Why it fails for distributed MinIO (`replicaCount: 4`)

In `charts/druid/templates/minio/minio-statefulset.yaml`:

```yaml
{{ if gt (.Values.minio.replicaCount | int) 1 }}
- /usr/bin/docker-entrypoint.sh minio server http://minio-{0...3}{{ $address }}
```

When `replicaCount > 1`, MinIO starts in **distributed mode**. Every object is
Reed-Solomon **erasure-coded** and split into shards across all 4 nodes. Each node
stores only its own shard — not the complete object:

```
PVC minio-vol-claim-minio-0:          PVC minio-vol-claim-minio-1:
  /opt/data/api-metrics/seg-uuid/       /opt/data/api-metrics/seg-uuid/
    xl.meta  ← erasure metadata           xl.meta  ← same metadata
    part.1   ← shard 1/4 ONLY            part.1   ← shard 2/4 ONLY
```

Mounting only one PVC and running `rclone copy /mnt/minio-old ...` copies raw shard
directories into SeaweedFS. The result is not valid objects — Druid will be unable to
load any segments.

Mounting all 4 PVCs and copying the raw filesystem still fails: each "file" would be
an internal MinIO shard (`segment-uuid/part.1`) rather than the actual S3 object
(`segment-uuid`). SeaweedFS would hold garbage.

**Approach 1 was implemented for `replicaCount: 1` only and works correctly in that
case, but production environments historically used `replicaCount: 4`.**

---

## Approach 2 — Sidecar MinIO Server (What We Implemented)

### The Core Insight

Only MinIO itself knows how to reconstruct objects from XL-format erasure-coded shards.
The fix: **start the MinIO binary inside the migration Job pod** in Single-Node Multi-Drive
(SNMD) mode, pointing at all original PVCs. MinIO handles reconstruction internally and
serves complete objects via its S3 API on `localhost:9000`. rclone then copies S3-to-S3
— format-agnostic, works for any replicaCount.

### Why SNMD Mode Works With Distributed Drives

MinIO's SNMD mode (single node, multiple local drives) uses the **identical XL V2
erasure-code format** as distributed mode. The on-disk layout is the same:

| Mode | Nodes | Drives | On-disk format |
|------|-------|--------|----------------|
| Standalone | 1 | 1 | XL V2 (full object, no erasure) |
| SNMD | 1 | N | XL V2 with erasure across N local drives |
| Distributed | N | 1 each | XL V2 with erasure across N drives on N nodes |

When all 4 original drives are mounted in one pod and MinIO is started as:
```
minio server /mnt/minio-0 /mnt/minio-1 /mnt/minio-2 /mnt/minio-3
```
MinIO reads the `format.json` from each drive, detects the 4-drive erasure configuration,
assembles shards, and serves fully reconstructed objects via S3.

### Why No Original Credentials Are Needed

MinIO reads `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` from **environment variables at
startup**. These are not stored on the drives. The sidecar sets its own fresh credentials:

```yaml
env:
  - name: MINIO_ACCESS_KEY
    value: migration-user
  - name: MINIO_SECRET_KEY
    value: migration-pass-tmp
```

rclone uses the same values to connect to `localhost:9000`. No reference to the original
`minio-secret` Kubernetes Secret is needed — which is important because `minio.enabled: false`
means that Secret is not rendered in 5.4.2.

### How the Job Is Structured

```
Migration Job Pod  (shared network namespace: localhost)
│
├── init: wait-for-seaweedfs
│     TCP probe to seaweedfs-s3:9333 until ready (configurable timeout).
│
├── sidecar: minio-local
│     Image: minio:5.4.1  (same as druid.image.minio)
│     Command:
│       COUNT=$(seaweedfs.minio.replicaCount)
│       minio server /mnt/minio-0 [/mnt/minio-1 /mnt/minio-2 /mnt/minio-3]
│     Env: MINIO_ACCESS_KEY=migration-user, MINIO_SECRET_KEY=migration-pass-tmp
│     Mounts: all MinIO PVCs at /mnt/minio-{0..N-1}
│     Exits when: /shared/migration-done file appears
│
└── main: data-copier
      Image: seaweedfs:5.4.1  (has rclone installed)
      Step 0: curl localhost:9000/minio/health/live — wait for MinIO ready (max 5 min)
      Step 1: rclone copy minio:/api-metrics → seaweedfs:/api-metrics
              --checksum --transfers 16 --retries 30
      Step 2: rclone check --one-way  (verify all source objects present in destination)
      Step 3: kubectl delete pvc minio-vol-claim-minio-{0..N}  (auto-cleanup all PVCs)
      Step 4: touch /shared/migration-done  (signals sidecar to exit → Job completes)
```

A shared `emptyDir` volume at `/shared` carries the exit signal between containers,
solving the "sidecar keeps a Job alive forever" problem.

### Key Values

| Value | Where set | Purpose |
|-------|-----------|---------|
| `druid.minio.enabled` | `values-production.yaml` (default `false`) | Removes MinIO StatefulSet; PVCs are released for the Job to mount |
| `global.deepStorage.enableDataMigration` | operator sets `true` at upgrade time | Renders the migration Job |
| `seaweedfs.minio.replicaCount` | **operator-specified on CLI, not in values files** | Controls how many MinIO PVCs the Job mounts; default is `1` (standalone); pass `4` for distributed MinIO |
| `seaweedfs.minio.image` | `values-production.yaml` (`minio:5.4.1`) | Image for the minio-local sidecar; pre-set so operators do not need to pass it |
| `seaweedfs.minio.pvcBaseName` | `minio-vol-claim-minio` | Base name for MinIO PVCs (`-0`, `-1`, … appended). Override only if the original MinIO StatefulSet used a custom name. |

> `seaweedfs.minio.replicaCount` is intentionally **not** set in `values-production.yaml`
> because its correct value depends on each customer's install history. Hardcoding `4` would
> cause the Job to fail for customers who had standalone MinIO (only 1 PVC exists).

---

## Testing the Migration

### Pre-requisites

- A running Kubernetes cluster (minikube, kind, or cloud)
- Helm 3
- `kubectl` with access to the cluster

### Step 1 — Simulate the 5.3 State (MinIO running with data)

Install with MinIO enabled to replicate a customer's pre-upgrade state:

```bash
helm install portal ./charts/portal \
  --set druid.minio.enabled=true \
  --set druid.minio.replicaCount=1 \       # or 4 for distributed
  --set global.deepStorage.enableDataMigration=false \
  -n portal-test --create-namespace
```

Wait for MinIO to be ready, then seed test data:

```bash
# Port-forward MinIO
kubectl port-forward svc/minio 9000:9000 -n portal-test &

# Upload test segment data using mc (MinIO Client) or rclone
mc alias set local http://localhost:9000 <access-key> <secret-key>
mc mb local/api-metrics
# Create a dummy Druid segment file (or use a real one)
echo "test segment data" > test-segment.bin
mc cp test-segment.bin local/api-metrics/test-datasource/2024-01-01/v1/0/
mc ls local/api-metrics --recursive
```

### Step 2 — Simulate the 5.4.2 Upgrade

```bash
# Standalone MinIO (replicaCount: 1) — default; no replicaCount flag needed
helm upgrade portal ./charts/portal \
  --set druid.minio.enabled=false \
  --set global.deepStorage.enableDataMigration=true \
  -n portal-test

# Distributed MinIO (replicaCount: 4) — must be explicitly specified
helm upgrade portal ./charts/portal \
  --set druid.minio.enabled=false \
  --set global.deepStorage.enableDataMigration=true \
  --set seaweedfs.minio.replicaCount=4 \
  -n portal-test
```

### Step 3 — Watch the Migration Job

```bash
# Wait for Job to start
kubectl get job portal-seaweedfs-data-copy-job -n portal-test -w

# Monitor SeaweedFS readiness (init container)
kubectl logs job/portal-seaweedfs-data-copy-job -c wait-for-seaweedfs -n portal-test -f

# Monitor MinIO sidecar startup
kubectl logs job/portal-seaweedfs-data-copy-job -c minio-local -n portal-test -f

# Watch rclone copy progress (main output)
kubectl logs job/portal-seaweedfs-data-copy-job -c data-copier -n portal-test -f
```

Expected final output from `data-copier`:
```
Local MinIO is healthy.
========================================
  MinIO → SeaweedFS Migration
  Source : minio:/api-metrics (localhost:9000)
  Target : seaweedfs:/api-metrics
  Drives : 1 PVC(s)
========================================
--- Step 1: Copy ---
Transferred:   18 B / 18 B, 100%, 0 B/s, ETA -
--- Step 2: Verify (one-way check) ---
2024/xx/xx INFO  : No error
--- Step 3: Delete MinIO PVC(s) ---
Deleted minio-vol-claim-minio-0.
--- Step 4: Signalling minio-local sidecar to exit ---
========================================
  Migration completed successfully!
========================================
```

### Step 4 — Verify Data in SeaweedFS

```bash
# Port-forward SeaweedFS S3
kubectl port-forward svc/seaweedfs-s3 8333:8333 -n portal-test &

# Check objects exist
SEAWEEDFS_KEY=$(kubectl get secret seaweedfs-s3-secret -n portal-test \
  -o jsonpath='{.data.admin_access_key_id}' | base64 -d)
SEAWEEDFS_SECRET=$(kubectl get secret seaweedfs-s3-secret -n portal-test \
  -o jsonpath='{.data.admin_secret_access_key}' | base64 -d)

mc alias set sfs http://localhost:8333 $SEAWEEDFS_KEY $SEAWEEDFS_SECRET
mc ls sfs/api-metrics --recursive
# Should list: test-datasource/2024-01-01/v1/0/test-segment.bin
```

### Step 5 — Verify MinIO PVC Was Deleted

```bash
kubectl get pvc -n portal-test | grep minio
# Should return no results
```

### Step 6 — Verify Druid Uses SeaweedFS

```bash
# Check coordinator config
kubectl get configmap portal-druid-coordinator-config -n portal-test -o yaml | grep storage
# Should show seaweedfs, not minio
```

### Step 7 — Disable Migration After Completion

```bash
helm upgrade portal ./charts/portal \
  --set global.deepStorage.enableDataMigration=false \
  -n portal-test
# Migration Job is no longer rendered by Helm
```

---

## Testing Distributed MinIO (replicaCount: 4)

For distributed MinIO, the key validation is that the `minio-local` sidecar starts
successfully in SNMD mode with 4 drives previously written by a distributed cluster.

```bash
# Install with distributed MinIO
helm install portal ./charts/portal \
  --set druid.minio.enabled=true \
  --set druid.minio.replicaCount=4 \
  --set global.deepStorage.enableDataMigration=false \
  -n portal-dist-test --create-namespace

# Wait for 4 MinIO pods: minio-0, minio-1, minio-2, minio-3
kubectl get pods -n portal-dist-test | grep minio

# Seed data (port-forward to any one MinIO pod)
kubectl port-forward pod/minio-0 9000:9000 -n portal-dist-test &
mc alias set distlocal http://localhost:9000 <access-key> <secret-key>
mc cp test-segment.bin distlocal/api-metrics/datasource/segment/

# Upgrade: trigger migration with 4 PVCs
helm upgrade portal ./charts/portal \
  --set druid.minio.enabled=false \
  --set global.deepStorage.enableDataMigration=true \
  --set seaweedfs.minio.replicaCount=4 \
  -n portal-dist-test

# Critical check: did the MinIO sidecar start correctly with 4 drives?
kubectl logs job/portal-seaweedfs-data-copy-job -c minio-local -n portal-dist-test
# Expected: "All drives formatted and ready"
# Expected: "MinIO Object Storage Server" listening on localhost:9000
```

---

## Troubleshooting

### MinIO sidecar does not become healthy

**Symptom:** `data-copier` times out waiting for `localhost:9000` and exits with:
```
ERROR: Local MinIO did not become healthy within 300s.
```

**Check minio-local logs:**
```bash
kubectl logs job/<release>-seaweedfs-data-copy-job -c minio-local -n <namespace>
```

**Common causes:**

| Log message | Cause | Fix |
|-------------|-------|-----|
| `command not found: minio` | Wrong image for sidecar | Set `seaweedfs.minio.image` to match `druid.image.minio` |
| `Format file not found` | PVCs are empty or wrong PVCs mounted | Verify `seaweedfs.minio.replicaCount` matches original MinIO `replicaCount`; also verify `seaweedfs.minio.pvcBaseName` matches the actual PVC name prefix |
| `Drives in different format versions` | Format.json mismatch | See SNMD compatibility note below |
| `Unable to initialize backend` | PVC still bound by MinIO pod | Ensure `druid.minio.enabled=false` before enabling migration |

**SNMD compatibility note:**
If MinIO refuses to start because it detects the drives were originally from a distributed
cluster, try setting the environment variable `MINIO_FORMAT_UPGRADE=on` in the sidecar.
You can patch the Job directly:
```bash
kubectl set env job/<release>-seaweedfs-data-copy-job MINIO_FORMAT_UPGRADE=on \
  -c minio-local -n <namespace>
```

### PVC is still bound (minio-local cannot mount it)

**Symptom:** Pod stays in `Pending` state with event:
```
Multi-Attach error for volume "minio-vol-claim-minio-0" — volume is already used by pod minio-0
```

**Cause:** `druid.minio.enabled=true` or the MinIO pod has not fully terminated yet.

**Fix:**
```bash
# Verify MinIO pods are gone
kubectl get pods -n <namespace> | grep minio

# If stuck in Terminating, force-delete
kubectl delete pod minio-0 --force --grace-period=0 -n <namespace>
```

### rclone copy fails with authentication error

**Symptom:** rclone logs show `AccessDenied` or `SignatureDoesNotMatch`.

**Check:** The `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` env vars in the sidecar must exactly
match the `RCLONE_CONFIG_MINIO_ACCESS_KEY_ID` / `RCLONE_CONFIG_MINIO_SECRET_ACCESS_KEY`
in the data-copier. Both are hardcoded to `migration-user` / `migration-pass-tmp` in the
Job template — if they were modified, they must match.

### rclone check finds missing objects after copy

**Symptom:** Step 2 reports objects missing in destination.

**Fix:** Delete the failed Job pod to trigger a retry (the Job's `backoffLimit: 5` allows
up to 5 retries). rclone's `--retries 30` and `--checksum` flags handle partial
transfers gracefully across retries.

```bash
kubectl delete pod -l job-name=<release>-seaweedfs-data-copy-job -n <namespace>
```

### PVC deletion fails (kubectl RBAC error)

**Symptom:** Step 3 logs show `Error from server (Forbidden): persistentvolumeclaims is forbidden`.

**Fix:** Verify the migration Role and RoleBinding were rendered:
```bash
kubectl get role -n <namespace> | grep migration
kubectl get rolebinding -n <namespace> | grep migration
```

If missing, re-run the helm upgrade with `global.deepStorage.enableDataMigration=true`
and ensure no Helm errors occurred during rendering.

### Druid coordinator does not load segments after migration

**Symptom:** Druid coordinator logs show segment load errors pointing to MinIO.

**Check the Druid runtime config:**
```bash
kubectl get configmap <release>-druid-coordinator-config -n <namespace> -o yaml | grep -A5 deepStorage
```

The config should reference `s3.endpoint=http://seaweedfs-s3:8333`, not `http://minio:9000`.
If it still shows MinIO, verify that `global.deepStorage.minio` is unset (falsy) in your
values and re-run `helm upgrade`.

---

## Summary of All Chart Changes

| File | Change |
|------|--------|
| `charts/druid/values.yaml` | Added `minio.enabled: false` (new default for 5.4.2) |
| `charts/druid/templates/minio/minio-statefulset.yaml` | Wrapped in `{{- if and .Values.minio.enabled (not .Values.minio.cloudStorage) }}` |
| `charts/druid/templates/minio/minio-deployment.yaml` | Wrapped in `{{- if and .Values.minio.enabled .Values.minio.cloudStorage }}` |
| `charts/druid/templates/minio/minio-service.yaml` | Wrapped in `{{- if .Values.minio.enabled }}` |
| `charts/druid/templates/minio/minio-config.yaml` | Wrapped in `{{- if .Values.minio.enabled }}` |
| `charts/druid/templates/minio/minio-secret.yaml` | Wrapped in `{{- if .Values.minio.enabled }}` |
| `charts/druid/ci/ci-values.yaml` | Added `minio.enabled: false` |
| `charts/seaweedfs/values.yaml` | Added `minio.replicaCount: 1` and `minio.image: minio:5.4.1` |
| `charts/seaweedfs/templates/.../seaweedfs-data-copy-job.yaml` | Full rewrite: sidecar MinIO SNMD + S3-to-S3 + dynamic PVC volumes + signal-based exit |
| `charts/seaweedfs/templates/.../migration-role.yaml` | New: RBAC Role (`get`, `list`, `delete` on PVCs) |
| `charts/seaweedfs/templates/.../migration-rolebinding.yaml` | New: binds Role to seaweedfs service account |
| `charts/portal/values-production.yaml` | `druid.minio.enabled: false`; added `seaweedfs.minio.image: minio:5.4.1`; `seaweedfs.minio.replicaCount` is NOT hardcoded — operators pass it on the upgrade command line |
| `charts/seaweedfs/templates/.../seaweedfs-data-copy-job.yaml` | PVC names templated via `seaweedfs.minio.pvcBaseName` (replaces hardcoded `minio-vol-claim-minio`) |
| `utils/MINIO-TO-SEAWEEDFS-MIGRATION.md` | Updated: operator upgrade steps for sidecar approach |
| `utils/APPROACH-1-PVC-FILESYSTEM-COPY.md` | New: technical deep-dive into Approach 1 and why it was superseded |
| `utils/APPROACH-2-SIDECAR-MINIO.md` | New: technical deep-dive into Approach 2 design |
