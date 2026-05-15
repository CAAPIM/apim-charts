# Approach 1 — PVC Filesystem Copy (Standalone MinIO Only)

## Summary

The migration Job mounts the old MinIO Persistent Volume Claim (PVC) directly as a read-only
volume inside the Job pod. `rclone` then copies the bucket contents from the local filesystem
path into SeaweedFS over the S3 API. No MinIO service, credentials, or network connectivity
to MinIO is required.

This approach mirrors what the `portal-dist` branch `sm_no_minio` does for Docker Swarm
deployments (see `portal-dist/src/migrate-minio-data.sh`).

---

## Why We Chose This First

### The Problem with the 5.4 Approach

Portal 5.4 introduced a migration Job that copied data S3-to-S3:

```bash
# 5.4 approach (seaweedfs-data-copy-job.yaml, original)
rclone copy minio:/api-metrics seaweedfs:/api-metrics
```

This required:
- The MinIO Kubernetes Service (`minio:9000`) to be **live and reachable** during the Job
- The `minio-secret` (access key + secret) to be present and mounted
- Coordination between MinIO StatefulSet pod readiness and Job timing

In 5.4.2, MinIO is **fully removed**. Setting `druid.minio.enabled: false` means the
MinIO StatefulSet, Service, Secret, and ConfigMap are all not rendered by Helm. There is
no MinIO service to point rclone at.

### The Swarm Reference Implementation

The `portal-dist` `sm_no_minio` branch solved this for Docker Swarm by mounting the old
`minio-volume` (a Docker named volume) read-only into the SeaweedFS service and using:

```bash
rclone copy /mnt/minio-old/${bucket} seaweedfs:/${bucket} \
  --checksum --transfers 16 --stats 5s --stats-one-line -v --progress
rclone check /mnt/minio-old/${bucket} seaweedfs:/${bucket} --one-way
```

No MinIO process needed. No credentials needed. The approach is simple and direct.

### Why a Direct Kubernetes Port Works (for Standalone)

In Docker Swarm, MinIO always runs in **standalone mode** (single replica, `command: server /opt/data`).
In standalone MinIO, objects are stored on the filesystem as a directory per object key:

```
/opt/data/api-metrics/
  some-datasource/2024-01-01T00:00:00.000Z_2024-01-02T00:00:00.000Z/v1/0/
    xl.meta         ← metadata + full object data (small) or part references
    part.1          ← actual object content (for larger objects)
```

When `replicaCount: 1` and the MinIO pod is scaled down (PVC released), mounting the PVC
and running `rclone copy /mnt/minio-old/api-metrics seaweedfs:/api-metrics` copies the
directory tree into SeaweedFS as correctly named objects. `rclone` treats each leaf file
path as the S3 object key.

This is the Kubernetes equivalent of the Swarm approach: **mount the volume, copy the files**.

---

## How It Works

### Pod Structure

```
Migration Job Pod
│
├── initContainer: wait-for-seaweedfs
│     Waits for TCP connection to seaweedfs-s3:8333 (configurable timeout)
│     Also checks if /mnt/minio-old/<bucket> is empty → exits 0 if nothing to migrate
│
└── container: data-copier
      Image:   seaweedfs image (already has rclone installed)
      Mounts:  minio-vol-claim-minio-0 → /mnt/minio-old (read-only)
      Step 1:  rclone copy /mnt/minio-old/api-metrics → seaweedfs:/api-metrics
               --checksum --transfers 16 --retries 30
      Step 2:  rclone check --one-way (verify all source files exist in destination)
      Step 3:  kubectl delete pvc minio-vol-claim-minio-0 (automatic cleanup)
```

### Prerequisite: PVC Must Be Released

A `ReadWriteOnce` PVC can only be mounted by one pod at a time. The MinIO StatefulSet pod
holds the PVC while it is running. For the migration Job to mount the same PVC, the MinIO
pod must be terminated first.

Setting `druid.minio.enabled: false` removes the MinIO StatefulSet from the rendered Helm
templates. During `helm upgrade`, Kubernetes deletes the MinIO StatefulSet and its pod,
releasing the PVC. The migration Job is then free to mount and read it.

### RBAC

The migration Job needs permission to delete the PVC after copying. A dedicated Role and
RoleBinding are created in the seaweedfs chart, scoped to the release namespace, granting
the seaweedfs service account `get` and `delete` on `persistentvolumeclaims`.

### Values Used

```yaml
# Operator sets these during upgrade from 5.3 (standalone MinIO only)
druid:
  minio:
    enabled: false            # Removes MinIO StatefulSet → releases PVC
    replicaCount: 1           # MUST be 1 for this approach to work

global:
  deepStorage:
    enableDataMigration: true # Renders the migration Job
```

---

## Files Changed

| File | Change |
|------|--------|
| `charts/druid/values.yaml` | Added `minio.enabled: false` as default |
| `charts/druid/templates/minio/minio-statefulset.yaml` | Added `minio.enabled` guard |
| `charts/druid/templates/minio/minio-deployment.yaml` | Added `minio.enabled` guard |
| `charts/druid/templates/minio/minio-service.yaml` | Added `minio.enabled` guard |
| `charts/druid/templates/minio/minio-config.yaml` | Added `minio.enabled` guard |
| `charts/druid/templates/minio/minio-secret.yaml` | Added `minio.enabled` guard |
| `charts/seaweedfs/templates/.../migration-role.yaml` | New: RBAC Role for PVC delete |
| `charts/seaweedfs/templates/.../migration-rolebinding.yaml` | New: binds Role to seaweedfs SA |
| `charts/seaweedfs/templates/.../seaweedfs-data-copy-job.yaml` | Rewritten: filesystem copy |
| `charts/portal/values-production.yaml` | `minio.enabled: false`, `enableDataMigration: false` |
| `charts/druid/ci/ci-values.yaml` | `minio.enabled: false` |

---

## Why This Approach Was Superseded

### The Fundamental Problem: MinIO Erasure Coding

The approach **only works when `replicaCount: 1`** (standalone MinIO).

The production `values-production.yaml` historically set `druid.minio.replicaCount: 4`.
When `replicaCount > 1`, the MinIO StatefulSet command becomes:

```
minio server http://minio-{0...3}.minio.<namespace>.svc.cluster.local/opt/data
```

This is MinIO's **distributed mode**. In this mode, objects are erasure-coded using
Reed-Solomon and split into shards across all 4 nodes. On disk, each node stores only
its own shard — not the complete object:

```
Node 0's PVC (/opt/data/api-metrics/segment-uuid/):
  xl.meta   ← erasure metadata (knows about all 4 drives)
  part.1    ← this node's shard ONLY (1/4 of the data + parity)

Node 1's PVC (/opt/data/api-metrics/segment-uuid/):
  xl.meta   ← same metadata
  part.1    ← different shard

... (nodes 2 and 3 similarly)
```

Mounting only `minio-vol-claim-minio-0` (node 0's PVC) and running `rclone copy` copies
raw shard directories into SeaweedFS. The result is **not a valid object** — Druid would
be unable to load any segments from SeaweedFS because the data is incomplete and in the
wrong format.

Additionally, mounting all 4 PVCs and copying all shard files via `rclone` would still
produce unusable data in SeaweedFS — each "file" would be an internal MinIO shard
(`segment-uuid/part.1`) rather than the actual object (`segment-uuid`).

### The Conclusion

Approach 1 is valid and correct **only for `replicaCount: 1`**.
For `replicaCount > 1` (distributed MinIO), a different approach is required.

See [APPROACH-2-SIDECAR-MINIO.md](APPROACH-2-SIDECAR-MINIO.md) for the unified solution.

---

## Diagram

```
                        Approach 1 — PVC Filesystem Copy (Standalone only)

 ┌─────────────────────────────────────────────────────────────────┐
 │  Migration Job Pod                                              │
 │                                                                 │
 │  ┌─────────────────────────┐   ┌─────────────────────────────┐ │
 │  │  init: wait-for-sfs     │   │  main: data-copier          │ │
 │  │                         │   │                             │ │
 │  │  TCP probe               │   │  rclone copy                │ │
 │  │  seaweedfs-s3:8333      │──▶│  /mnt/minio-old/api-metrics │ │
 │  │                         │   │  → seaweedfs:/api-metrics   │ │
 │  │  Check /mnt/minio-old   │   │                             │ │
 │  │  not empty              │   │  rclone check --one-way     │ │
 │  └─────────────────────────┘   │                             │ │
 │                                │  kubectl delete pvc          │ │
 │                                │  minio-vol-claim-minio-0    │ │
 │                                └────────────┬────────────────┘ │
 └─────────────────────────────────────────────┼─────────────────-┘
                                               │
          ┌────────────────────────────────────┤
          │  Volume mount (read-only)          │
          ▼                                    │
 ┌─────────────────────┐              ┌────────▼───────────┐
 │  minio-vol-claim-   │              │  SeaweedFS S3      │
 │  minio-0  (PVC)     │              │  seaweedfs-s3:8333 │
 │                     │              └────────────────────┘
 │  /opt/data/         │
 │    api-metrics/     │   ← Works: standalone stores full object
 │      segment-uuid/  │     content (xl.meta + part.1) per key
 │        xl.meta      │
 │        part.1       │
 └─────────────────────┘
```
