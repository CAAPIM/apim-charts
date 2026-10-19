# Portal Chart - Ingress v1 Examples

These examples demonstrate how to configure the Layer7 API Developer Portal Helm Chart using standard Kubernetes [Ingress v1](https://kubernetes.io/docs/concepts/services-networking/ingress/) resources and Contour [HTTPProxy](https://projectcontour.io/docs/1.33/config/fundamentals/) resources.

For full parameter reference, see the [Ingress Options](../../../../charts/portal/README.md#ingress-options) section in the Portal chart README.

## Overview

The Portal requires **SSL/TLS passthrough** for all ingress traffic. Portal backends terminate TLS themselves, so the ingress controller must pass TLS connections through without termination. This is true for both Ingress v1 and Contour HTTPProxy configurations.

```
 Client                  Ingress Controller       Portal Services
 ──────                  ──────────────────       ───────────────
   │         TLS (end-to-end, passthrough)            │
   ├─────────────────────────────────────────────────►│
   │                         │                        │
   │  Ingress controller     │  Portal backends       │
   │  passes TLS through     │  terminate TLS         │
   │  without termination    │  directly              │
```

The chart supports two ingress controller types:
- **Standard Ingress** -- uses `nginx.ingress.kubernetes.io/ssl-passthrough: "true"` annotation (enabled via `ingress.type.kubernetes: true`)
- **Contour HTTPProxy** -- enabled via `ingress.type.contour: true` when Contour CRDs are present. Uses `tcpproxy` with `tls.passthrough: true`

Both types can be enabled simultaneously, allowing a gradual DNS migration between ingress solutions without downtime.

---

> **Ingress NGINX Deprecation Notice**
>
> The Kubernetes project has announced the [retirement of Ingress NGINX](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/). Best-effort maintenance continues until **March 2026**, after which there will be no further releases, bug fixes, or security patches.
>
> The default `ingress.class.name` in the Portal chart is `nginx`. Existing configurations will continue to work, but migrating to the [Kubernetes Gateway API](../gateway/) or Contour is recommended.

---

## Tenant IDs

The `ingress.tenantIds` list is used by **all** ingress configurations -- Ingress v1, Contour HTTPProxy, and Kubernetes Gateway API. Each tenant ID generates ingress rules/routes for `<tenantId>.<portal.domain>`, routing to the dispatcher service on port 443.

```yaml
ingress:
  tenantIds:
    - tenant1
    - tenant2
```

When you add a tenant to this list, the corresponding ingress rule (or HTTPProxy resource, or TLSRoute) is automatically created regardless of which ingress approach is active.

---

## Example 1: Default Configuration (nginx)

The chart ships with a default nginx Ingress v1 configuration using SSL passthrough.

```yaml
ingress:
  class:
    name: nginx
    enabled: true
  type:
    kubernetes: true
    openshift: false
  secretName: dispatcher-tls
  create: true
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
  tenantIds:
    - tenant1
```

**Key points:**
- `ssl-passthrough: "true"` is **required** -- portal backends must terminate TLS directly
- `backend-protocol: "HTTPS"` tells nginx the backend speaks HTTPS
- `ingress.secretName` references the TLS certificate secret used by the portal dispatcher
- `ingress.tenantIds` generates additional ingress rules for each tenant hostname

---

## Example 2: Contour as an Ingress Controller (HTTPProxy)

When `ingress.type.contour` is set to `true` and the Contour CRDs (`projectcontour.io/v1`) are detected on the cluster, the chart deploys **Contour HTTPProxy** resources using `tcpproxy` with `tls.passthrough: true` for native TLS passthrough support.

```yaml
ingress:
  class:
    name: contour
    enabled: true
  type:
    kubernetes: false
    openshift: false
    contour: true
  secretName: dispatcher-tls
  create: false
  annotations: {}
  tenantIds:
    - tenant1
    - tenant2
```

**What happens automatically:**
- Separate **HTTPProxy** resources are created for each fixed portal service (default tenant, tssg-public, analytics, pssg-enroll, pssg-sync, pssg-sso, broker)
- Additional **HTTPProxy** resources are created for each entry in `ingress.tenantIds`
- Each HTTPProxy uses `virtualhost.tls.passthrough: true` and `tcpproxy` to route to the correct backend service and port
- No SSL-passthrough annotations are needed -- Contour handles this natively via `tcpproxy`

### Coexistence During Migration

Both `ingress.type.kubernetes` and `ingress.type.contour` can be `true` at the same time. This creates both standard Ingress and Contour HTTPProxy resources, allowing you to migrate DNS gradually without a hard cutover:

```yaml
ingress:
  class:
    name: nginx
    enabled: true
  type:
    kubernetes: true
    contour: true
  secretName: dispatcher-tls
  create: true
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
  tenantIds:
    - tenant1
```

Once DNS has been migrated to the Contour endpoints, set `ingress.type.kubernetes: false` to remove the standard Ingress objects.

---

## Example 3: OpenShift Routes

For OpenShift environments, Routes can be used instead of Ingress:

```yaml
ingress:
  class:
    name: nginx
    enabled: true
  type:
    kubernetes: false
    openshift: true
  secretName: dispatcher-tls
  create: false
  tenantIds:
    - tenant1
```

---

## Example 4: Custom Routes

Custom routes allow routing additional hostnames to specific portal backend services. They are supported in all ingress modes.

```yaml
ingress:
  class:
    name: contour
    enabled: true
  type:
    kubernetes: true
    contour: true
  create: true
  tenantIds:
    - tenant1
  customRoutes:
    - subdomain: custom-app
      service: dispatcher
      port: 443
```

This creates an additional ingress rule (or HTTPProxy, or TLSRoute when using Gateway API) for `custom-app.<portal.domain>`.

---

## Migrating to Gateway API

All ingress types (`ingress.type.kubernetes`, `ingress.type.contour`, and `ingress.type.gatewayAPI`) can coexist simultaneously, allowing a gradual migration without a hard DNS cutover.

If you are planning to migrate from Ingress v1 to the Kubernetes Gateway API, see the [Gateway API examples](../gateway/). The Portal migration is straightforward because all configurations use TLS passthrough:

| Feature                  | Ingress v1 / Contour HTTPProxy     | Gateway API (TLSRoute)             |
|--------------------------|------------------------------------|------------------------------------|
| TLS mode                 | Passthrough                        | Passthrough                        |
| Route generation         | Auto from `ingress.tenantIds`      | Auto from `ingress.tenantIds`      |
| Custom routes            | Auto from `ingress.customRoutes`   | Auto from `ingress.customRoutes`   |
| Certificate management   | None (backends terminate TLS)      | None (backends terminate TLS)      |
| Configuration complexity | Annotations required (nginx)       | No annotations needed              |

The `ingress.tenantIds` and `ingress.customRoutes` lists are shared across all ingress approaches -- switching from Ingress v1 to Gateway API does not require changes to these values.
