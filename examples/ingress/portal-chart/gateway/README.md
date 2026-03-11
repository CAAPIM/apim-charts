# Portal Chart - Kubernetes Gateway API Examples

These examples demonstrate how to configure the Layer7 API Developer Portal Helm Chart using the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/).

For full parameter reference, see the [Kubernetes Gateway API Configuration](../../../../charts/portal/README.md#kubernetes-gateway-api-configuration) section in the Portal chart README.

## Overview

The Portal requires **TLS passthrough** for all ingress traffic -- portal backends terminate TLS themselves. Because of this, the Portal chart exclusively uses `TLSRoute` (SNI-based routing) and does not support `HTTPRoute` or `BackendTLSPolicy`.

```
Portal Gateway API Routing (TLS passthrough only)
══════════════════════════════════════════════════

 Client                  K8s Gateway              Portal Services
 ──────                  ───────────              ───────────────
   │         TLS (end-to-end, SNI routed)             │
   ├─────────────────────────────────────────────────►│
   │                         │                        │
   │  Gateway does NOT       │  Routes by hostname    │  dispatcher:443
   │  terminate TLS          │  (SNI) to the correct  │  apim:8443
   │                         │  portal backend        │  apim:9449
   │  No listener cert       │                        │  apim:9446
   │  management needed      │                        │  apim:9448
   │                         │                        │  apim:1885
```

Compared to the [Gateway chart](../../../ingress/gateway-chart/gateway/), the Portal Gateway API configuration is simpler:
- **No `httpRoute`** -- only `tlsRoute` (passthrough)
- **No `backendTLSPolicy`** -- not needed for passthrough
- **No TLS certificate management** -- no listener or backend secrets to configure
- **All routes are auto-generated** -- no manual rule configuration needed; routes are derived from the portal hostname helpers, `ingress.tenantIds`, and `ingress.customRoutes`

## Prerequisites

1. **Gateway API CRDs** must be installed: `gateway.networking.k8s.io/v1` (Gateway) and `gateway.networking.k8s.io/v1alpha2` (TLSRoute)
2. A **GatewayClass** must be available (see [GatewayClass](../../readme.md#gatewayclass))
3. A **Gateway controller** must be running (Contour or Envoy Gateway)

---

## Example 1: Default Configuration (no changes required)

When the chart is installed with defaults, no Gateway API resources are created. The existing Ingress v1 / Contour HTTPProxy configuration continues to work unchanged.

```yaml
# Default values -- no Gateway API resources are deployed
ingress:
  type:
    gatewayAPI: false   # default
```

---

## Example 2: Create a Gateway (Contour)

The chart creates a Gateway with TLS passthrough listeners and auto-generates all TLSRoutes.

```yaml
ingress:
  type:
    gatewayAPI: true
  tenantIds:
    - tenant1
    - tenant2
  gatewayAPI:
    create: true
    gatewayClassName: contour
```

To request a specific load balancer IP, use the `addresses` field:

```yaml
ingress:
  type:
    gatewayAPI: true
  gatewayAPI:
    create: true
    gatewayClassName: contour
    addresses:
      - type: IPAddress
        value: "10.0.0.100"
```

**What happens automatically:**
- A **Gateway** resource is created with a TLS passthrough listener (protocol `TLS`, port 443, mode `Passthrough`) for every unique portal hostname
- A separate **TLSRoute** is created for each fixed portal service (default tenant, tssg-public, analytics, pssg-enroll, pssg-sync, pssg-sso, broker)
- Additional **TLSRoutes** are created for each entry in `ingress.tenantIds` -- each one routes `<tenantId>.<portal.domain>` to `dispatcher:443`
- Kubernetes Ingress and Contour HTTPProxy resources can coexist alongside Gateway API resources for gradual migration

The `ingress.tenantIds` list is shared between all ingress types. When you add a tenant to this list, the corresponding TLSRoute (or Ingress rule, or HTTPProxy) is automatically created regardless of which ingress approaches are active.

---

## Example 3: Create a Gateway (Envoy Gateway)

```yaml
ingress:
  type:
    gatewayAPI: true
  tenantIds:
    - tenant1
  gatewayAPI:
    create: true
    gatewayClassName: eg
```

The configuration is identical to Contour -- only the `gatewayClassName` changes.

---

## Example 4: Using an Existing Gateway

When a Gateway resource already exists (e.g. shared with the Gateway chart), set `gatewayAPI.create: false` and provide a reference.

```yaml
ingress:
  type:
    gatewayAPI: true
  tenantIds:
    - tenant1
    - tenant2
  gatewayAPI:
    create: false
    existingRef:
      name: shared-gateway
      namespace: gateway-system
```

The chart does not create or manage the Gateway resource. All TLSRoutes attach to the existing Gateway via `parentRefs`. Ensure the existing Gateway has:
- TLS passthrough listeners that match the portal hostnames (e.g. `hostname: "*.example.com"`)
- `allowedRoutes` that permits routes from the Portal namespace

See [Shared Gateway](../../readme.md#shared-gateway) for a complete shared Gateway example.

---

## Example 5: With Custom Routes

Custom routes allow routing additional hostnames to specific portal backend services.

```yaml
ingress:
  type:
    gatewayAPI: true
  tenantIds:
    - tenant1
  customRoutes:
    - subdomain: custom-app
      service: dispatcher
      port: 443
  gatewayAPI:
    create: true
    gatewayClassName: contour
```

This creates an additional TLSRoute for `custom-app.<portal.domain>` routing to `dispatcher:443`, alongside all the standard auto-generated routes.

---

## Example 6: Coexistence During Migration

All ingress types can be enabled simultaneously. This allows a gradual DNS migration without a hard cutover:

```yaml
ingress:
  type:
    kubernetes: true
    contour: true
    gatewayAPI: true
  tenantIds:
    - tenant1
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
  gatewayAPI:
    create: true
    gatewayClassName: contour
```

Once DNS has been migrated to the Gateway API endpoints, disable the old ingress types:

```yaml
ingress:
  type:
    kubernetes: false
    contour: false
    gatewayAPI: true
```

> **Note:** Switching between ingress controllers (e.g. changing `ingressClassName` from `nginx` to `contour`) uses a different load balancer with a different address. Unlike enabling an additional ingress type (which coexists), changing the `ingressClassName` is a hard cutover. Plan this change for a maintenance window and update DNS records accordingly. See [Migration](../../readme.md#migration) for details.

---

## Auto-generated Routes

The chart auto-generates all TLSRoutes from portal hostname helpers. No manual route configuration is needed.

**Fixed routes** (always created):

| Route                     | Hostname Helper        | Backend Service | Port |
|---------------------------|------------------------|-----------------|------|
| default-tenant            | `default-tenant-host`  | dispatcher      | 443  |
| tssg-public               | `tssg-public-host`     | apim            | 8443 |
| analytics                 | `analytics-host`       | apim            | 9449 |
| pssg-enroll               | `pssg-enroll-host`     | apim            | 9446 |
| pssg-sync                 | `pssg-sync-host`       | apim            | 9446 |
| pssg-sso                  | `pssg-sso-host`        | apim            | 9448 |
| broker                    | `broker-host`          | apim            | 1885 |

**Dynamic routes** (from `ingress.tenantIds`):

Each entry creates a TLSRoute for `<tenantId>.<portal.domain>` routed to `dispatcher:443`.

**Custom routes** (from `ingress.customRoutes`):

Each entry creates a TLSRoute for `<subdomain>.<portal.domain>` routed to the specified service and port.

