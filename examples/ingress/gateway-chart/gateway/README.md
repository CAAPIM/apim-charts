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

1. **Gateway API CRDs** must be installed on the cluster. These are typically installed by your Gateway controller. If you need to install them separately, see the [Gateway API releases](https://github.com/kubernetes-sigs/gateway-api/releases)
2. A **GatewayClass** must be available (see [GatewayClass](../../readme.md#gatewayclass))
3. A **Gateway controller** must be running (any controller implementing the Gateway API specification works -- Contour and Envoy Gateway are the examples used here)

> **Controller Compatibility:** The Gateway chart produces standard Gateway API resources and is controller-agnostic. The default `HTTPRoute` mode works with any Gateway API controller. The `TLSRoute` (passthrough) mode requires controller support for `protocol: TLS` / `mode: Passthrough` and is in the Experimental channel. Choosing a controller without TLS passthrough support does not affect HTTPRoute, but limits future use of the passthrough option. See [TLS Passthrough Requirements](../../readme.md#tls-passthrough-requirements) for details.

---

## Example 1: Default Configuration (no changes required)

When the chart is installed with defaults, no Gateway API resources are created. The existing Ingress v1 configuration continues to work unchanged.

```yaml
# Default values -- no Gateway API resources are deployed
kubernetesGateway:
  enabled: false   # default
```

This means existing deployments are not affected. You opt in to the Gateway API by setting `kubernetesGateway.enabled: true`.

> **Staged migration:** `ingress.enabled` can remain `true` while enabling Gateway API. Both create independent resources and load balancer endpoints, so you can verify the new Gateway API endpoint and migrate DNS before disabling Ingress. Note that switching ingress controllers (changing `ingressClassName`) uses a load balancer with a different address -- this is a hard cutover, not a coexistence scenario, and should be planned for a maintenance window. See [Migration](../../readme.md#migration) for details.

---

## Example 2: Contour as a Gateway Controller (HTTPRoute)

This example uses Contour with TLS termination and re-encryption. The chart auto-generates the Gateway, listeners, backend certificate, and CA certificate.

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
        port: 8443
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
        port: 8443
        matches:
          - path:
              type: PathPrefix
              value: /
      - hostname: dev-pm.ca.com
        port: 9443
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
        port: 8443
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
        port: 8443
      - hostname: dev-pm.ca.com
        port: 9443
        backend: management
  backendTLSPolicy:
    enabled: false              # not needed for passthrough
```

**What happens automatically:**
- A **Gateway** resource is created with TLS passthrough listeners (protocol `TLS`, mode `Passthrough`) for each hostname
- No listener TLS Secret is created -- the Gateway does not terminate TLS
- No backend certificate or BackendTLSPolicy is needed
- Separate **TLSRoute** resources are created per hostname

> **Note:** TLSRoute is GA as of Gateway API v1.5.0 (`gateway.networking.k8s.io/v1`). The chart defaults to `v1alpha2`. Set `kubernetesGateway.tlsRoute.apiVersion: gateway.networking.k8s.io/v1` when your CRDs include TLSRoute at v1.

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
        port: 8443
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


 Listener TLS provisioning modes:

   1. Auto-generate    -- leave existingSecretName empty
                          Helm generates a self-signed cert on install
                          and preserves it across upgrades (lookup)

   2. Existing secret  -- set existingSecretName to reference a
                          pre-existing kubernetes.io/tls Secret
                          (e.g. managed by cert-manager)


 Backend TLS provisioning modes:

   1. Auto-generate    -- leave existingSecretName empty (default)
                          Helm generates a self-signed cert + CA on
                          install and preserves across upgrades.
                          CA exported as ConfigMap for validation.

   2. Existing secret  -- set existingSecretName to reference a
                          pre-existing kubernetes.io/tls Secret.
                          You must also set validation.caCertificateRefs
                          or validation.wellKnownCACertificates.

 Validation defaults (apply to all modes):

   validation.hostname             -- auto: <fullname>.<ns>.svc.cluster.local
   validation.caCertificateRefs    -- auto: the chart's CA ConfigMap
                                      (only created in auto-generate mode)
   validation.wellKnownCACertificates -- set to "System" to skip CA refs
                                        (mutually exclusive with caCertificateRefs)
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
  backendTLSPolicy:
    enabled: true
    tls:
      existingSecretName: ""    # empty = auto-generate
```

The backend certificate is automatically loaded onto the Layer7 Gateway pod via a bootstrap script that converts the PEM certificate into a Graphman JSON bundle and writes it to the pod's bootstrap directory.

### Mode 2: Reference existing secrets

Reference secrets that already exist in the cluster (e.g. managed by cert-manager). The backendTLSPolicy keys are mounted to the Gateway pod; key rotation takes effect after Gateway restart.

When using existing secrets, you must tell the chart how to validate the backend certificate by setting `validation.caCertificateRefs` or `validation.wellKnownCACertificates`.

**Reference a CA ConfigMap:**

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
    validation:
      caCertificateRefs:
        - name: my-ca-configmap       # must contain key: ca.crt
          group: ""
          kind: ConfigMap
```

**Use system trust store:**

```yaml
  backendTLSPolicy:
    enabled: true
    tls:
      existingSecretName: my-backend-tls-secret
    validation:
      wellKnownCACertificates: System
```

**Custom hostname and Secret-based CA:**

```yaml
  backendTLSPolicy:
    enabled: true
    tls:
      existingSecretName: my-backend-tls-secret
    validation:
      hostname: custom-hostname.default.svc.cluster.local
      caCertificateRefs:
        - name: my-ca-secret
          group: ""
          kind: Secret
```

> **Note:** When using `existingSecretName` for the backend, you **must** set `validation.caCertificateRefs` or `validation.wellKnownCACertificates`. The auto-generated CA ConfigMap is only created when the backend TLS secret is also auto-generated.

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
        port: 8443
        matches:
          - path:
              type: PathPrefix
              value: /
      - hostname: dev-pm.ca.com
        port: 9443
        backend: management
        matches:
          - path:
              type: PathPrefix
              value: /
  backendTLSPolicy:
    enabled: true
    tls:
      existingSecretName: gateway-backend-cert    # cert-manager managed
    validation:
      caCertificateRefs:
        - name: gateway-ca-cert                   # externally managed ConfigMap
          group: ""
          kind: ConfigMap
```
