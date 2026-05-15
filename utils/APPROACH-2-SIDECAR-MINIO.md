# Approach 2 — Sidecar MinIO Server (Standalone + Distributed)

## Summary

The migration Job starts the **MinIO binary itself** as a sidecar container inside the
Job pod, with all original MinIO PVCs mounted. MinIO runs in Single-Node Multi-Drive
(SNMD) mode, which uses the identical on-disk XL format as distributed mode and can
reconstruct erasure-coded objects from the original drive set. `rclone` then copies
**S3-to-S3** from `localhost:9000` (local MinIO) to `seaweedfs-s3:8333` — the same
approach as the 5.4 migration Job, but with a local MinIO process instead of the external
Kubernetes service.

This approach works for **both** standalone (`replicaCount: 1`) and distributed MinIO
(`replicaCount: 4`).

---

## Why Approach 1 Is Not Enough

See [APPROACH-1-PVC-FILESYSTEM-COPY.md](APPROACH-1-PVC-FILESYSTEM-COPY.md) for the full
explanation. In brief:

- Approach 1 (rclone filesystem copy) works for `replicaCount: 1` (standalone MinIO).
- The production `values-production.yaml` historically set `druid.minio.replicaCount: 4`.
- `replicaCount: 4` means MinIO runs in distributed mode, where each object is
  erasure-coded across 4 drives. No single drive holds a complete object.
- Mounting any one (or all four) PVCs and running `rclone copy` from the filesystem
  copies raw XL shard files into SeaweedFS — not reconstructable objects.

The root issue: **only MinIO itself knows how to reconstruct objects from XL-format
erasure-coded shards**. The solution is to let MinIO do that work.

---

## How Erasure Coding Was Inferred from the Helm Template

In `charts/druid/templates/minio/minio-statefulset.yaml`:

```yaml
{{ if gt (.Values.minio.replicaCount | int) 1 }}
- /usr/bin/docker-entrypoint.sh minio server http://minio-{0...3}{{ $address }}
{{ else }}
- /usr/bin/docker-entrypoint.sh minio server /opt/data
{{ end }}
```

When `replicaCount > 1`, the command uses MinIO's distributed mode syntax
(`http://minio-{0...3}...`). In this mode:

- 4 MinIO pods run, each with its own PVC (`minio-vol-claim-minio-{0..3}`)
- Every object uploaded to MinIO is erasure-coded into N data shards + N parity shards
- One shard lands on each pod's drive
- The on-disk layout is:

```
Each PVC (/opt/data/api-metrics/<object-key>/):
    xl.meta    ← erasure metadata (stripe width, algorithm, all disk IDs)
    part.1     ← this pod's shard ONLY
```

No single PVC contains a full object. Reconstruction requires all 4 drives and MinIO's
own erasure decoding logic.

---

## The Core Insight: SNMD Mode Uses the Same On-Disk Format

MinIO's Single-Node Multi-Drive (SNMD) mode and distributed multi-node mode both store
data using the **same XL V2 erasure-code format**:

| Mode | Nodes | Drives per node | On-disk format |
|------|-------|-----------------|----------------|
| Standalone | 1 | 1 | XL V2 (no erasure, full object inline or part.1) |
| SNMD | 1 | N | XL V2 with erasure across N local drives |
| Distributed | N | 1 each | XL V2 with erasure across N drives on different nodes |

When MinIO starts in SNMD mode with all 4 original drives, it:
1. Reads `format.json` from each drive to detect the erasure configuration
2. Locates each object's `xl.meta` metadata across all drives
3. Assembles the erasure shards and decodes the full object
4. Serves the reconstructed object via S3 API

This is the same reconstruction path MinIO uses when serving normal reads in production.
The migration Job simply starts the MinIO process locally and then reads from it via S3.

---

## Why No Original Credentials Are Needed

MinIO reads its `MINIO_ACCESS_KEY` and `MINIO_SECRET_KEY` (or modern `MINIO_ROOT_USER`/
`MINIO_ROOT_PASSWORD`) from **environment variables at startup**. These are NOT stored on
disk alongside the object data. The PVC contains only object data and erasure metadata —
no credential information.

This means the sidecar can be started with any fresh credentials:

```yaml
env:
  - name: MINIO_ACCESS_KEY
    value: migration-user
  - name: MINIO_SECRET_KEY
    value: migration-pass-tmp
```

rclone is configured to use the same credentials when connecting to `localhost:9000`. The
original `minio-secret` Kubernetes Secret is not needed. This matters because with
`minio.enabled: false`, the `minio-secret` is not rendered by Helm in 5.4.2.

---

## How It Works

### Pod Structure

```
Migration Job Pod (shared network namespace → localhost shared between containers)
│
├── initContainer: wait-for-seaweedfs
│     TCP probe to seaweedfs-s3:8333 (configurable timeout)
│     Ensures SeaweedFS is ready before migration starts
│
├── sidecar container: minio-local   (NEW in Approach 2)
│     Image:   minio:5.4  (same image as druid.image.minio)
│     Command: minio server /mnt/minio-0 [/mnt/minio-1 /mnt/minio-2 /mnt/minio-3]
│              (number of drives = seaweedfs.minio.replicaCount)
│     Env:     MINIO_ACCESS_KEY=migration-user
│              MINIO_SECRET_KEY=migration-pass-tmp
│     Mounts:  all minio-vol-claim-minio-{i} PVCs
│     Network: listens on localhost:9000 (shared with data-copier)
│
└── main container: data-copier
      Image:   seaweedfs image (has rclone)
      Step 0:  Wait for localhost:9000/minio/health/live
      Step 1:  rclone copy minio:/api-metrics → seaweedfs:/api-metrics
               (S3-to-S3, --checksum --transfers 16 --retries 30)
      Step 2:  rclone check --one-way (verify all objects in destination)
      Step 3:  kubectl delete pvc minio-vol-claim-minio-{0..N-1}
               (N = seaweedfs.minio.replicaCount, all PVCs cleaned up)
```

### Why Sidecar and Not Init Container for MinIO

An `initContainer` exits before the main container starts. If MinIO were started as an
init container, its process would be gone by the time `data-copier` tried to connect.
A **sidecar container** runs concurrently with the main container, sharing the pod's
network namespace (`localhost`).

### Dynamic Volume Mounting (Helm Template)

The number of PVCs to mount is driven by `seaweedfs.minio.replicaCount`:

```yaml
# seaweedfs-data-copy-job.yaml volumes
volumes:
  {{- range $i := until (int .Values.minio.replicaCount) }}
  - name: minio-data-{{ $i }}
    persistentVolumeClaim:
      claimName: minio-vol-claim-minio-{{ $i }}
  {{- end }}
```

```yaml
# minio-local sidecar volumeMounts
volumeMounts:
  {{- range $i := until (int .Values.minio.replicaCount) }}
  - name: minio-data-{{ $i }}
    mountPath: /mnt/minio-{{ $i }}
  {{- end }}
```

```bash
# minio server command in sidecar (built at template render time)
minio server \
  {{- range $i := until (int .Values.minio.replicaCount) }}
  /mnt/minio-{{ $i }} \
  {{- end }}
```

### Multi-PVC Cleanup (Helm Template)

The data-copier's cleanup step deletes all MinIO PVCs after successful copy+verify:

```bash
{{- $root := . }}
{{- range $i := until (int .Values.minio.replicaCount) }}
kubectl delete pvc minio-vol-claim-minio-{{ $i }} -n {{ $root.Release.Namespace }} --ignore-not-found
{{- end }}
```

---

## Files Changed (Delta from Approach 1)

The following changes are **in addition to** the Approach 1 file changes (MinIO enabled
guards, RBAC files, ci-values, production values for `minio.enabled`).

| File | Change |
|------|--------|
| `charts/seaweedfs/values.yaml` | Add `minio.replicaCount: 1`, `minio.image: minio:5.4.1`, and `minio.pvcBaseName: minio-vol-claim-minio` (configurable PVC base name) |
| `charts/seaweedfs/templates/.../seaweedfs-data-copy-job.yaml` | Add `minio-local` sidecar; dynamic multi-PVC volumes; S3-to-S3 via localhost:9000 |
| `charts/seaweedfs/templates/.../migration-role.yaml` | Add `list` verb for multi-PVC kubectl delete |
| `charts/portal/values-production.yaml` | `druid.minio.enabled: false`; add `seaweedfs.minio.image: minio:5.4.1`; `seaweedfs.minio.replicaCount` is NOT set here — it is install-specific |
| `utils/MINIO-TO-SEAWEEDFS-MIGRATION.md` | Updated operator upgrade steps for sidecar approach |

---

## Values Configuration

### `charts/seaweedfs/values.yaml` additions

```yaml
minio:
  bucketName: api-metrics    # existing
  replicaCount: 1            # NEW default: standalone. Operator overrides for distributed.
  image: minio:5.4.1         # NEW: must match druid.image.minio
  pvcBaseName: minio-vol-claim-minio  # NEW: configurable base name; override if StatefulSet used a custom name
```

These values are used **only** when `global.deepStorage.enableDataMigration: true`.

### `charts/portal/values-production.yaml`

```yaml
druid:
  minio:
    enabled: false            # MinIO removed in 5.4.2

seaweedfs:
  minio:
    image: minio:5.4.1        # Pre-set; operators do not need to pass this on CLI
    # replicaCount is intentionally NOT set here.
    # It depends on each customer's original install and must be passed explicitly:
    #   --set seaweedfs.minio.replicaCount=4   (for distributed MinIO)
    # Standalone MinIO uses the default of 1 from seaweedfs/values.yaml.

global:
  deepStorage:
    enableDataMigration: false  # Operator sets true only during upgrade window
```

---

## Operator Upgrade Steps

### Upgrading from 5.3 (standalone MinIO, replicaCount: 1)

```bash
# Step 1: Upgrade and trigger migration (replicaCount defaults to 1 — no extra flag needed)
helm upgrade <release> ./charts/portal \
  --set druid.minio.enabled=false \
  --set global.deepStorage.enableDataMigration=true

# Step 2: Monitor the migration Job
kubectl get job <release>-seaweedfs-data-copy-job -n <namespace>
kubectl logs job/<release>-seaweedfs-data-copy-job -c minio-local -n <namespace>
kubectl logs job/<release>-seaweedfs-data-copy-job -c data-copier -n <namespace>

# Step 3: After Job completes, disable migration
helm upgrade <release> ./charts/portal \
  --set global.deepStorage.enableDataMigration=false
```

### Upgrading from 5.3 (distributed MinIO, replicaCount: 4)

```bash
# Step 1: Upgrade and trigger migration — replicaCount must be explicitly specified
helm upgrade <release> ./charts/portal \
  --set druid.minio.enabled=false \
  --set global.deepStorage.enableDataMigration=true \
  --set seaweedfs.minio.replicaCount=4

# Step 2: Verify the minio-local sidecar started correctly
kubectl logs job/<release>-seaweedfs-data-copy-job -c minio-local -n <namespace>
# Expected: "All drives formatted and ready"
# Expected: "MinIO Object Storage Server" + endpoint at localhost:9000

# Step 3: Monitor data copy progress
kubectl logs job/<release>-seaweedfs-data-copy-job -c data-copier -n <namespace> -f

# Step 4: After Job completes, disable migration
helm upgrade <release> ./charts/portal \
  --set global.deepStorage.enableDataMigration=false
```

---

## SNMD Compatibility Validation (Required Before Release)

The critical assumption is that MinIO can start in SNMD mode with drives that were
originally written by a distributed 4-node cluster. Before shipping, validate:

1. Deploy a 4-node distributed MinIO cluster (replicaCount: 4) and upload test objects.
2. Scale the StatefulSet to 0 replicas (simulate 5.4.2 upgrade).
3. Start a single MinIO container with all 4 PVCs mounted:
   ```bash
   minio server /mnt/minio-0 /mnt/minio-1 /mnt/minio-2 /mnt/minio-3
   ```
4. Confirm the MinIO process reaches `/minio/health/live` without errors.
5. Use `mc ls local/api-metrics` to verify all expected objects are listed.
6. Run the full `rclone copy` + `rclone check` and confirm object integrity.

**Expected outcome**: MinIO reads the `format.json` from each drive, detects the 4-drive
erasure configuration, and reconstructs objects correctly. If MinIO rejects the format
(logs a fatal error about endpoint mismatch), the `--anonymous` flag or the
`MINIO_ERASURE_SET_DRIVE_COUNT` environment variable may help override the check.

---

## Diagram

```
                        Approach 2 — Sidecar MinIO (Standalone + Distributed)

 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │  Migration Job Pod                                                               │
 │                                                                                  │
 │  ┌──────────────────┐   ┌──────────────────────────┐  ┌────────────────────────┐│
 │  │ init:            │   │ sidecar: minio-local      │  │ main: data-copier      ││
 │  │ wait-for-sfs     │   │                           │  │                        ││
 │  │                  │   │ minio server              │  │ wait localhost:9000    ││
 │  │ TCP probe        │──▶│   /mnt/minio-0            │  │ healthy                ││
 │  │ seaweedfs:8333   │   │   /mnt/minio-1 (if N=4)  │  │                        ││
 │  │                  │   │   /mnt/minio-2 (if N=4)  │  │ rclone copy            ││
 │  └──────────────────┘   │   /mnt/minio-3 (if N=4)  │  │ minio:/api-metrics     ││
 │                          │                           │◀─│   → seaweedfs:/...    ││
 │                          │ localhost:9000 (S3 API)   │  │ (S3-to-S3)            ││
 │                          │ Reconstructs XL objects   │  │                        ││
 │                          └───────────┬───────────────┘  │ rclone check --oneway ││
 │                                      │                   │                        ││
 │                                      │ volumeMounts      │ kubectl delete pvc     ││
 │                                      │                   │ minio-vol-claim-{0..N} ││
 │                                      │                   └────────────────────────┘│
 └──────────────────────────────────────┼──────────────────────────────────────────-─┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
   ┌──────────▼──────┐      ┌──────────▼──────┐      ┌──────────▼──────┐
   │ minio-vol-claim │      │ minio-vol-claim │      │ minio-vol-claim │  ...
   │ -minio-0 (PVC)  │      │ -minio-1 (PVC)  │      │ -minio-2 (PVC)  │
   │                 │      │                 │      │                 │
   │ xl.meta + shard │      │ xl.meta + shard │      │ xl.meta + shard │
   │ (1/4 of object) │      │ (2/4 of object) │      │ (3/4 of object) │
   └─────────────────┘      └─────────────────┘      └─────────────────┘

              MinIO SNMD assembles all shards → full S3 object at localhost:9000
                                      │
                                      ▼
                           ┌─────────────────────┐
                           │  SeaweedFS S3        │
                           │  seaweedfs-s3:8333   │
                           │  api-metrics bucket  │
                           └─────────────────────┘
```
