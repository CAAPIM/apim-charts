# Gateway Chart - Kubernetes Gateway API Examples

These examples demonstrate how to configure the Layer7 API Gateway Helm Chart using the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/).

For full parameter reference, see the [Kubernetes Gateway API Configuration](../../../../charts/gateway/README.md#kubernetes-gateway-api-configuration) section in the Gateway chart README.

## Overview

The Gateway API provides a more expressive and extensible routing model than Ingress v1. The chart supports two routing modes:

```
HTTPRoute Mode (terminate + re-encrypt)
════════════════════════════════════════

 Client                  K8s Gateway                L7 Gateway Pod
 ──────                  ───────────                ──────────────
   │       TLS #1            │        TLS #2            │
   ├────────────────────────►├─────────────────────────►│
   │                         │                          │
   │  (gateway.tls           │  (backendTLSPolicy       │  Serves HTTPS
   │   listener cert)        │   .tls backend cert)     │  on 8443/9443
   │                         │                          │
   │  Gateway terminates     │  BackendTLSPolicy        │
   │  TLS here               │  validates backend CA    │

 Supports: path routing, header modification, request filters


TLSRoute Mode (passthrough)
════════════════════════════

 Client                  K8s Gateway                L7 Gateway Pod
 ──────                  ───────────                ──────────────
   │              TLS (end-to-end)                      │
   ├───────────────────────────────────────────────────►│
   │                         │                          │
   │  Gateway does NOT       │  Routes by SNI,          │  Terminates TLS
   │  terminate TLS          │  no termination          │  directly
   │                         │                          │

 Supports: hostname routing only (no path matching)
 No BackendTLSPolicy or backend certificate needed
```

**HTTPRoute** (default) -- TLS is terminated at the Kubernetes Gateway and re-encrypted to the Layer7 Gateway backend. The Kubernetes Gateway presents a frontend certificate to clients, then establishes a new TLS connection to the backend pod. A `BackendTLSPolicy` is required so the controller can validate the backend certificate. This mode supports path-based routing and header manipulation.

**TLSRoute** -- TLS passes through the Kubernetes Gateway untouched via SNI-based routing. The Layer7 Gateway pod terminates TLS directly. This mode is simpler (no backend certificate management) but only supports hostname-based routing -- no path matching or header modification.

## Prerequisites

1. **Gateway API CRDs** must be installed on the cluster
2. A **GatewayClass** must be available (see [GatewayClass](../../readme.md#gatewayclass))
3. A **Gateway controller** must be running (Contour or Envoy Gateway are examples covered here)

---

## Example 1: Default Configuration (no changes required)

When the chart is installed with defaults, no Gateway API resources are created. The existing Ingress v1 configuration continues to work unchanged.

```yaml
# Default values -- no Gateway API resources are deployed
kubernetesGateway:
  enabled: false   # default
```

This means existing deployments are not affected. You opt in to the Gateway API by setting `kubernetesGateway.enabled: true`.

---

## Example 2: Contour as a Gateway Controller (HTTPRoute)

This is the recommended configuration for Contour with TLS termination and re-encryption. The chart auto-generates the Gateway, listeners, backend certificate, and CA certificate.

```
 Client                  K8s Gateway (Contour)      L7 Gateway Pod
 ──────                  ─────────────────────      ──────────────
   │       TLS #1            │      TLS #2              │
   ├────────────────────────►├─────────────────────────►│
   │                         │                          │
   │  Listener cert:         │  Backend cert:           │
   │  gateway.tls secret     │  backendTLSPolicy.tls    │
   │  (auto-gen or custom)   │  secret (auto-gen or     │
   │                         │  custom), validated      │
   │                         │  via BackendTLSPolicy    │
```

### Minimal -- auto-generated certificates

```yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: true
    gatewayClassName: contour
  httpRoute:
    enabled: true
    rules:
      - hostname: dev.ca.com
        matches:
          - path:
              type: PathPrefix
              value: /
  backendTLSPolicy:
    enabled: true
```

**What happens automatically:**
- A **Gateway** resource is created with an HTTPS listener on port 443 for `dev.ca.com`
- A **listener TLS Secret** (`<release>-<chart>-gateway-tls`) is auto-generated with a self-signed certificate -- this is the certificate presented to clients
- A **backend TLS Secret** (`<release>-<chart>-backend-tls`) is auto-generated -- this certificate is loaded onto the Layer7 Gateway pod via a bootstrap script
- A **CA ConfigMap** (`<release>-<chart>-backend-ca`) is auto-generated containing the CA that signed the backend certificate
- A **BackendTLSPolicy** references the CA ConfigMap to validate the backend connection
- An **HTTPRoute** routes traffic from the Gateway to the Layer7 Gateway Service
- Both auto-generated secrets use **install-only generation** -- certificates are created on `helm install` and preserved across `helm upgrade` to avoid unnecessary pod restarts

### With management service routing

```yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: true
    gatewayClassName: contour
  httpRoute:
    enabled: true
    rules:
      - hostname: dev.ca.com
        matches:
          - path:
              type: PathPrefix
              value: /
      - hostname: dev-pm.ca.com
        backend: management     # routes to the management service
        matches:
          - path:
              type: PathPrefix
              value: /
  backendTLSPolicy:
    enabled: true
```

This creates separate HTTPRoutes per hostname. The `backend: management` field causes traffic for `dev-pm.ca.com` to be routed to the management service instead of the default service.

---

## Example 3: Envoy Gateway as a Gateway Controller (HTTPRoute)

The configuration is nearly identical to Contour -- only the `gatewayClassName` changes.

```yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: true
    gatewayClassName: eg        # Envoy Gateway's default GatewayClass
  httpRoute:
    enabled: true
    rules:
      - hostname: dev.ca.com
        matches:
          - path:
              type: PathPrefix
              value: /
  backendTLSPolicy:
    enabled: true
```

> **Note:** Envoy Gateway uses the GatewayClass name `eg` by default. Verify with `kubectl get gatewayclass`.

---

## Example 4: TLSRoute (TLS Passthrough)

TLS passthrough routes traffic directly to the Layer7 Gateway pod without terminating TLS at the Kubernetes Gateway. No backend certificate management is needed.

```
 Client                  K8s Gateway (Contour)      L7 Gateway Pod
 ──────                  ─────────────────────      ──────────────
   │          TLS (end-to-end, SNI routed)              │
   ├───────────────────────────────────────────────────►│
   │                         │                          │
   │  No listener cert       │  No backend cert         │
   │  needed (passthrough)   │  management needed       │
   │                         │                          │
   │                         │  Pod uses its own SSL    │
   │                         │  key (default or custom) │
```

```yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: true
    gatewayClassName: contour
  httpRoute:
    enabled: false              # disable HTTPRoute
  tlsRoute:
    enabled: true
    rules:
      - hostname: dev.ca.com
      - hostname: dev-pm.ca.com
        backend: management
  backendTLSPolicy:
    enabled: false              # not needed for passthrough
```

**What happens automatically:**
- A **Gateway** resource is created with TLS passthrough listeners (protocol `TLS`, mode `Passthrough`) for each hostname
- No listener TLS Secret is created -- the Gateway does not terminate TLS
- No backend certificate or BackendTLSPolicy is needed
- Separate **TLSRoute** resources are created per hostname

> **Note:** TLSRoute uses the `gateway.networking.k8s.io/v1alpha2` API. Ensure your cluster has the experimental Gateway API CRDs installed.

---

## Example 5: Using an Existing Gateway

When a Gateway resource already exists (e.g. shared across multiple charts), set `gateway.create: false` and provide a reference.

```yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: false
    existingRef:
      name: shared-gateway
      namespace: gateway-system
  httpRoute:
    enabled: true
    rules:
      - hostname: dev.ca.com
        matches:
          - path:
              type: PathPrefix
              value: /
  backendTLSPolicy:
    enabled: true
```

The chart does not create or manage the Gateway resource. Routes attach to the existing Gateway via `parentRefs`. Ensure the existing Gateway has:
- A listener that matches the route hostname
- `allowedRoutes` that permits routes from the chart's namespace

See [Shared Gateway](../../readme.md#shared-gateway) for a complete shared Gateway example.

---

## TLS Certificate Management

The chart manages two separate TLS certificates when using HTTPRoute mode:

```
TLS Certificate Architecture (HTTPRoute mode)
══════════════════════════════════════════════

              TLS #1                          TLS #2
 Client ◄────────────────► K8s Gateway ◄────────────────► L7 Gateway Pod
              │                                  │
              │                                  │
      ┌───────┴───────┐                 ┌────────┴────────┐
      │   Listener    │                 │    Backend      │
      │   TLS Secret  │    validates    │    TLS Secret   │
      │               │◄───────────────►│                 │
      └───────────────┘    using CA     └─────────────────┘
              │                │                 │
              │          ┌─────┴─────┐           │
              │          │    CA     │           │
              │          │ ConfigMap │           │
              │          └───────────┘           │
              │                                  │
              ▼                                  ▼
 Presented to clients              Served by the L7 Gateway
 by the K8s Gateway.              pod to the K8s Gateway
 This is the frontend             controller. Loaded onto the
 certificate.                     pod via a bootstrap script.

 Config: gateway.tls              Config: backendTLSPolicy.tls


 Provisioning modes (both secrets support the same three modes):

   1. Auto-generate  -- leave crt, key, existingSecretName empty
                        Helm generates a self-signed cert on install
                        and preserves it across upgrades (lookup)

   2. Provide values -- set crt and key with PEM-encoded content
                        For backend, also set caCrt on backendTLSPolicy

   3. Existing secret -- set existingSecretName to reference a
                         pre-existing kubernetes.io/tls Secret
                         (e.g. managed by cert-manager)

   4. CA-only         -- set backendTLSPolicy.caCrt (inline) or
                         existingCACertConfigMapName (reference)
                         No crt/key/existingSecretName needed.
                         Use when the Gateway manages its own keys.
```

### Mode 1: Auto-generated certificates (default)

Leave all TLS fields empty. The chart uses Helm's `genCA` and `genSelfSignedCert` functions to create self-signed certificates on `helm install`. These are persisted across `helm upgrade` using Helm's `lookup` function -- the chart checks for existing secrets before generating new ones, preventing unnecessary certificate rotation and pod restarts.

```yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: true
    gatewayClassName: contour
    tls:
      existingSecretName: ""    # empty = auto-generate
      crt: ""
      key: ""
  backendTLSPolicy:
    enabled: true
    tls:
      existingSecretName: ""    # empty = auto-generate
      crt: ""
      key: ""
```

The backend certificate is automatically loaded onto the Layer7 Gateway pod via a bootstrap script that converts the PEM certificate into a Graphman JSON bundle and writes it to the pod's bootstrap directory.

### Mode 2: Provide certificate values

Supply PEM-encoded certificate and key directly in values. For the backend certificate, also provide the CA certificate that signed it.

```yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: true
    gatewayClassName: contour
    tls:
      crt: |
        -----BEGIN CERTIFICATE-----
        <listener certificate PEM>
        -----END CERTIFICATE-----
      key: |
        -----BEGIN PRIVATE KEY-----
        <listener private key PEM>
        -----END PRIVATE KEY-----
  backendTLSPolicy:
    enabled: true
    caCrt: |
      -----BEGIN CERTIFICATE-----
      <CA certificate that signed the backend cert>
      -----END CERTIFICATE-----
    tls:
      crt: |
        -----BEGIN CERTIFICATE-----
        <backend certificate PEM>
        -----END CERTIFICATE-----
      key: |
        -----BEGIN PRIVATE KEY-----
        <backend private key PEM>
        -----END PRIVATE KEY-----
```

### Mode 3: Reference existing secrets

Reference secrets that already exist in the cluster (e.g. managed by cert-manager). The backendTLSPolicy keys are mounted to the Gateway, key rotation will only take effect after Gateway restart.

```yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: true
    gatewayClassName: contour
    tls:
      existingSecretName: my-listener-tls-secret
  backendTLSPolicy:
    enabled: true
    tls:
      existingSecretName: my-backend-tls-secret
    # When using an existing backend secret, provide the CA or configure
    # validation to use wellKnownCACertificates
    caCrt: |
      -----BEGIN CERTIFICATE-----
      <CA certificate>
      -----END CERTIFICATE-----
    # OR use system trust store (controller must support this):
    # validation:
    #   hostname: my-gateway.default.svc.cluster.local
    #   wellKnownCACertificates: System
```

> **Note:** When using `existingSecretName` for the backend, you must either provide the CA certificate via `caCrt` or configure a custom `validation` block with `wellKnownCACertificates: System` or appropriate `caCertificateRefs`.

### Mode 4: CA-only (customer-managed backend keys)

When the Layer7 Gateway manages its own SSL keys externally (e.g. via Policy Manager, Restman, or a CI/CD pipeline), provide only the CA certificate. The chart does not create a backend TLS secret or mount the bootstrap script.

**Inline CA certificate:**

```yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: true
    gatewayClassName: contour
    tls:
      existingSecretName: wildcard-example-com    # listener cert (frontend)
  httpRoute:
    enabled: true
    rules:
      - hostname: dev.ca.com
        matches:
          - path:
              type: PathPrefix
              value: /
  backendTLSPolicy:
    enabled: true
    caCrt: |
      -----BEGIN CERTIFICATE-----
      <CA certificate that signed the Gateway's backend cert>
      -----END CERTIFICATE-----
```

**Reference an existing CA ConfigMap:**

```yaml
  backendTLSPolicy:
    enabled: true
    existingCACertConfigMapName: my-ca-configmap    # must contain key: ca.crt
```

**What happens:**
- The **BackendTLSPolicy** is created, referencing the CA ConfigMap (auto-created from `caCrt`, or the existing one from `existingCACertConfigMapName`)
- **No backend TLS secret** is created -- the Gateway pod uses its own externally-managed keys
- **No bootstrap script** is mounted on the pod

---

## Complete Example: Production-like Configuration

A more complete example combining custom hostnames, management routing, Contour annotations, a static IP address, and existing certificates:

```yaml
service:
  type: ClusterIP
  annotations:
    projectcontour.io/upstream-protocol.tls: "8443"
  ports:
    - name: https
      internal: 8443
      external: 8443
      protocol: TCP

management:
  service:
    enabled: true
    annotations:
      projectcontour.io/upstream-protocol.tls: "9443"

ingress:
  enabled: false                # disable Ingress v1

kubernetesGateway:
  enabled: true
  gateway:
    create: true
    gatewayClassName: contour
    addresses:
      - type: IPAddress
        value: "10.0.0.100"     # request a specific load balancer IP
    tls:
      existingSecretName: wildcard-example-com    # cert-manager managed
  httpRoute:
    enabled: true
    rules:
      - hostname: dev.ca.com
        matches:
          - path:
              type: PathPrefix
              value: /
      - hostname: dev-pm.ca.com
        backend: management
        matches:
          - path:
              type: PathPrefix
              value: /
  backendTLSPolicy:
    enabled: true
    tls:
      existingSecretName: gateway-backend-cert    # cert-manager managed
    caCrt: |
      -----BEGIN CERTIFICATE-----
      <your CA certificate>
      -----END CERTIFICATE-----
```
