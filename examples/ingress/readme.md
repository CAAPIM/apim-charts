## Ingress v1 / Gateway API v1 Examples
The Layer7 API Management Helm Charts support multiple ingress strategies for routing external traffic to the Gateway and Portal services. A controller agnostic approach has been taken in providing support for both ingress v1 and gateway v1. The controllers that are referenced in these examples have minimal configuration applied to them. These examples are limited to Contour and Envoy-Gateway, please refer to the relevant documentation for more information about additional options.

> **Ingress NGINX Retirement Notice**
>
> The Kubernetes project has announced the [retirement of Ingress NGINX](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/). Best-effort maintenance continues until **March 2026**, after which there will be no further releases, bug fixes, or security updates. Existing deployments will continue to function, but no new vulnerabilities will be patched.
>
> The default `ingressClassName` in the Gateway chart is `nginx`. Existing configurations will continue to work, but migrating to the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io) or an alternative Ingress controller such as [Contour](https://projectcontour.io/) is recommended.

### Supported Approaches

| Approach | API Version | Description |
|---|---|---|
| **Ingress v1** | `networking.k8s.io/v1` | Standard Kubernetes Ingress resources. Supported by most ingress controllers (e.g. nginx, Contour). |
| **Gateway API v1** | `gateway.networking.k8s.io/v1` / `v1alpha2` | The newer Kubernetes Gateway API. Provides more granular routing via Gateway, HTTPRoute, and TLSRoute resources. |

### Examples

- **Gateway Chart**
  - [Ingress v1 examples](./gateway-chart/ingress/) -- default configuration, Contour as an ingress controller, management routing, OpenShift routes
  - [Gateway API examples](./gateway-chart/gateway/) -- Contour/Envoy Gateway controllers, HTTPRoute and TLSRoute modes, TLS certificate management, existing Gateway references
- **Portal Chart**
  - [Ingress v1 examples](./portal-chart/ingress/) -- standard Ingress and Contour HTTPProxy resources
  - [Gateway API examples](./portal-chart/gateway/) -- TLSRoute (TLS passthrough) with auto-generated routes

### Chart Configuration

- **Gateway Chart** -- [charts/gateway](../../charts/gateway)
  - [Ingress Configuration](../../charts/gateway/README.md#ingress-configuration) -- Ingress v1 parameter reference
  - [Kubernetes Gateway API Configuration](../../charts/gateway/README.md#kubernetes-gateway-api-configuration) -- Gateway API parameter reference
- **Portal Chart** -- [charts/portal](../../charts/portal)
  - [Ingress Options](../../charts/portal/README.md#ingress-options) -- Ingress v1 parameter reference
  - [Kubernetes Gateway API Configuration](../../charts/portal/README.md#kubernetes-gateway-api-configuration) -- Gateway API parameter reference

The implementation is controller-agnostic. The following controllers have been tested:

### Contour
Contour can be deployed as either an ingress controller or a Gateway API controller.

**Ingress Controller Deployment**

See [Advanced deployment options](https://projectcontour.io/docs/1.33/deploy-options/) for more detail.

```bash
helm repo add contour https://projectcontour.github.io/helm-charts/
helm install my-release contour/contour --namespace projectcontour --create-namespace
```

Set `ingress.ingressClassName` to `contour` in your Gateway chart values. For the Portal chart, set `ingress.type.contour: true` to deploy Contour-specific `HTTPProxy` resources. Both `ingress.type.kubernetes` and `ingress.type.contour` can be `true` simultaneously in the Portal chart for gradual migration.

**Gateway API Controller Deployment (contour-gateway-provisioner)**

```bash
kubectl apply -f https://projectcontour.io/quickstart/contour-gateway-provisioner.yaml
```

Use `gatewayClassName: contour` in your Gateway API configuration.

### Envoy Gateway
Envoy Gateway is a Gateway API-native controller.

See the [Envoy Gateway quickstart](https://gateway.envoyproxy.io/docs/tasks/quickstart/#installation) for more detail.

```bash
helm install envoygateway oci://docker.io/envoyproxy/gateway-helm --version v1.7.0 -n envoy-gateway-system --create-namespace
```

Use `gatewayClassName: eg` in your Gateway API configuration.

### Controller-Specific Configuration (Policy Attachment)

The Gateway API core resources (`Gateway`, `HTTPRoute`, `TLSRoute`) intentionally cover only portable routing semantics -- host matching, path matching, TLS modes (`Terminate` / `Passthrough`), and backend references. Settings like timeouts, buffer sizes, header limits, rate limiting, and retries are **not** part of the core spec.

Instead, the Gateway API uses a pattern called **[Policy Attachment](https://gateway-api.sigs.k8s.io/reference/policy-attachment/)** -- each controller defines its own typed CRDs that attach to Gateway or Route resources via a `targetRef` field:

```yaml
# Example: attaching a policy to a Gateway or Route
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway          # or HTTPRoute, TLSRoute, etc.
    name: my-gateway
```

This replaces the annotation-based approach used by Ingress v1 (e.g. `nginx.ingress.kubernetes.io/proxy-body-size`), giving you schema-validated, controller-specific configuration as separate Kubernetes resources.

These charts do **not** template controller-specific policies -- they are managed independently by the cluster operator. The charts focus on the portable core (`Gateway`, `HTTPRoute`, `TLSRoute`, `BackendTLSPolicy`), and vendor-specific tuning is applied as separate Policy resources that target the Gateway or Route resources the charts create.

#### Contour

Contour uses `ContourDeployment` (attached via `GatewayClass.parametersRef`) for global settings and `HTTPProxy` features for route-level configuration. Key configuration areas:

| Area | Documentation |
|---|---|
| Gateway API support overview | [Gateway API](https://projectcontour.io/docs/1.33/config/gateway-api/) |
| GatewayClass parameters (`ContourDeployment`) | [API Reference](https://projectcontour.io/docs/1.33/config/api/#projectcontour.io/v1alpha1.ContourDeployment) |
| Rate limiting | [Rate Limiting](https://projectcontour.io/docs/1.33/config/rate-limiting/) |
| TLS termination & upstream TLS | [TLS Termination](https://projectcontour.io/docs/1.33/config/tls-termination/), [Upstream TLS](https://projectcontour.io/docs/1.33/config/upstream-tls/) |
| Timeouts & retries | [Contour Configuration](https://projectcontour.io/docs/1.33/configuration/) |
| Health checks | [Upstream Health Checks](https://projectcontour.io/docs/1.33/config/health-checks/) |
| IP filtering | [IP Filtering](https://projectcontour.io/docs/1.33/config/ip-filtering/) |
| Overload manager (connection/request limits) | [Overload Manager](https://projectcontour.io/docs/1.33/config/overload-manager/) |
| Resource limits (Envoy memory/connections) | [Resource Limits](https://projectcontour.io/docs/1.33/guides/resource-limits/) |

**Global defaults** are set on the `ContourDeployment` resource referenced by the GatewayClass:

```yaml
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller
  parametersRef:
    kind: ContourDeployment
    group: projectcontour.io
    name: contour-params
    namespace: projectcontour
---
kind: ContourDeployment
apiVersion: projectcontour.io/v1alpha1
metadata:
  name: contour-params
  namespace: projectcontour
spec:
  envoy:
    workloadType: Deployment
  runtimeSettings:
    enableExternalNameService: true
```

#### Envoy Gateway

Envoy Gateway uses dedicated Policy CRDs that attach to Gateway or Route resources via `targetRef`. Key policy types:

| Policy CRD | Scope | Documentation |
|---|---|---|
| `ClientTrafficPolicy` | Gateway | Client-facing settings: timeouts, HTTP/1 and HTTP/2 tuning, connection buffer limits, header settings, keep-alive, PROXY protocol |
| `BackendTrafficPolicy` | Gateway or Route | Backend-facing settings: retries, circuit breakers, timeouts, load balancing, rate limiting, fault injection |
| `SecurityPolicy` | Gateway or Route | Authentication (JWT, OIDC, basic auth), authorization, CORS, ExtAuth |

Full reference: [Envoy Gateway API Extension Types](https://gateway.envoyproxy.io/docs/api/extension_types/)

**Example -- setting client-side timeouts and buffer limits:**

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: ClientTrafficPolicy
metadata:
  name: client-settings
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: my-gateway
  http:
    requestTimeout: 60s
  connection:
    bufferLimit: 32768
```

**Example -- setting retries and circuit breakers per route:**

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: backend-settings
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: my-route
  retry:
    numRetries: 3
    perRetry:
      timeout: 5s
  circuitBreaker:
    maxConnections: 1024
    maxRequests: 1024
```

Traffic management tasks: [Envoy Gateway Traffic Docs](https://gateway.envoyproxy.io/docs/tasks/traffic/)

#### Comparison with Ingress v1

| Concern | Ingress v1 | Gateway API |
|---|---|---|
| Routing (host, path, backend) | Core spec | Core spec (`HTTPRoute`, `TLSRoute`) |
| TLS termination / passthrough | Annotation-driven | Core spec (`Gateway.listeners[].tls.mode`) |
| Timeouts, buffer sizes, header limits | Controller-specific annotations on the Ingress resource | Controller-specific Policy CRDs attached to Gateway/Route via `targetRef` |
| Global controller defaults | Controller-specific ConfigMap | `GatewayClass.parametersRef` pointing to a controller CRD |

### GatewayClass
A `GatewayClass` is a cluster-scoped resource that defines a class of Gateways. It is typically created by the Gateway controller (e.g. Contour creates `contour`, Envoy Gateway creates `eg`). If your controller does not create one automatically, you can create it manually:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller
```

# Envoy
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

### Gateway Resource
Both charts support two modes:

- **Create a new Gateway** -- The chart manages the Gateway resource and auto-generates listeners.
  - Gateway chart: `kubernetesGateway.gateway.create: true`
  - Portal chart: `ingress.gatewayAPI.create: true`
- **Use an existing Gateway** -- Routes attach to the existing Gateway via `parentRefs`.
  - Gateway chart: `kubernetesGateway.gateway.create: false` + `kubernetesGateway.gateway.existingRef`
  - Portal chart: `ingress.gatewayAPI.create: false` + `ingress.gatewayAPI.existingRef`

### Shared Gateway
A shared Gateway allows both the Gateway and Portal charts (and any other services) to route traffic through a single entry point and load balancer IP. Each chart creates its own routes (HTTPRoute/TLSRoute) that attach to the shared Gateway via `parentRefs`.

To use a shared Gateway:

1. Create a Gateway resource independently (e.g. via kubectl or an infrastructure chart):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gateway
  namespace: gateway-system
spec:
  gatewayClassName: contour
  addresses:
    - type: IPAddress
      value: "10.0.0.100"
  listeners:
    - name: tls-passthrough
      protocol: TLS
      port: 443
      hostname: "*.example.com"
      tls:
        mode: Passthrough
      allowedRoutes:
        namespaces:
          from: All
```

**Cross-namespace considerations:**

- `allowedRoutes.namespaces.from: All` permits routes from any namespace to attach. For more granular control, use `from: Selector` with a label selector:

```yaml
allowedRoutes:
  namespaces:
    from: Selector
    selector:
      matchExpressions:
        - key: kubernetes.io/metadata.name
          operator: In
          values: [portal, gateway]
```

- The `kubernetes.io/metadata.name` label is automatically set on every namespace (Kubernetes 1.21+), so you can reference namespaces by name without manually labelling them.


2. Reference it from each chart:

```yaml
# gateway-values.yaml
kubernetesGateway:
  enabled: true
  gateway:
    create: false
    existingRef:
      name: shared-gateway
      namespace: gateway-system
```

```yaml
# portal-values.yaml
ingress:
  type:
    gatewayAPI: true
  gatewayAPI:
    create: false
    existingRef:
      name: shared-gateway
      namespace: gateway-system
```
