# Gateway Chart - Ingress v1 Examples

These examples demonstrate how to configure the Layer7 API Gateway Helm Chart using standard Kubernetes [Ingress v1](https://kubernetes.io/docs/concepts/services-networking/ingress/) resources.

For full parameter reference, see the [Ingress Configuration](../../../../charts/gateway/README.md#ingress-configuration) section in the Gateway chart README.

## Overview

```
 Client                  Ingress Controller          L7 Gateway Pod
 ──────                  ──────────────────          ──────────────
   │       TLS               │       TLS                 │
   ├────────────────────────►├──────────────────────────►│
   │                         │                           │
   │  e.g. nginx,            │  Backend speaks HTTPS     │
   │  Contour                │  on 8443/9443             │
```

The Ingress v1 approach uses a Kubernetes Ingress resource that is managed by an Ingress controller. The chart supports any Ingress controller that implements the `networking.k8s.io/v1` API.

---

> **Ingress NGINX Deprecation Notice**
>
> The Kubernetes project has announced the [retirement of Ingress NGINX](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/). Best-effort maintenance will continue until **March 2026**, after which there will be no further releases, bug fixes, or security patches. Existing deployments will continue to function and installation artifacts will remain available, but no new security vulnerabilities will be addressed.
>
> **Recommendation:** If you are currently using Ingress NGINX (`ingressClassName: nginx`), consider migrating to the [Kubernetes Gateway API](../gateway/) or an alternative Ingress controller such as [Contour](https://projectcontour.io/).
>
> The existing Ingress v1 configuration in this chart will continue to work unchanged. No action is required immediately, but planning a migration is strongly advised.

---

## Example 1: Default Configuration

The chart ships with a default Ingress v1 configuration that works with most Ingress controllers. No changes are required for existing deployments.

```yaml
ingress:
  enabled: true
  ingressClassName: nginx
  tls:
    - hosts:
        - dev.ca.com
      secretName: gateway-tls
  rules:
    - host: dev.ca.com
      path: "/"
      service:
        port:
          name: https
```

This creates a standard Ingress resource. TLS termination behavior depends on your Ingress controller's configuration and annotations.

---

## Example 2: Contour as an Ingress Controller

[Contour](https://projectcontour.io/) can operate as a standard Ingress controller. When using Contour, the `projectcontour.io/upstream-protocol.tls` annotation tells Contour to use TLS when connecting to the backend.

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
  enabled: true
  ingressClassName: contour
  tls:
    - hosts:
        - dev.ca.com
        - dev-pm.ca.com
      secretName: gateway-tls
  rules:
    - host: dev.ca.com
      path: "/"
      service:
        port:
          name: https
    - host: dev-pm.ca.com
      path: "/"
      backend: management
      service:
        port:
          name: management
```

**Key points:**
- The `projectcontour.io/upstream-protocol.tls` annotation on the Service (not the Ingress) tells Contour the backend speaks TLS
- The annotation value should match the port number (e.g. `"8443"`)
- Apply the annotation to both the default service and the management service if management routing is needed

**Limitations with Contour in Ingress mode:**
- TLS passthrough is not supported via standard Ingress annotations with Contour
- If you need TLS passthrough (SNI routing), use the [Gateway API with TLSRoute](../gateway/) instead

---

## Example 3: Management Service Routing

To route management traffic (e.g. Policy Manager) to the management service, add a rule with `backend: management`:

```yaml
ingress:
  enabled: true
  ingressClassName: contour
  tls:
    - hosts:
        - dev.ca.com
        - dev-pm.ca.com
      secretName: gateway-tls
  rules:
    - host: dev.ca.com
      path: "/"
      service:
        port:
          name: https
    - host: dev-pm.ca.com
      path: "/"
      backend: management
      service:
        port:
          name: management
```

The `backend: management` field tells the chart to target the management service (`<release>-<chart>-management`) instead of the default service.

---

## Example 4: OpenShift Routes

For OpenShift environments, Routes can be used instead of Ingress:

```yaml
ingress:
  enabled: true
  openshift:
    route:
      enabled: true
      wildcardPolicy: None
    # weight: 100
  tls:
    - hosts:
        - dev.ca.com
      secretName: gateway-tls
  rules:
    - host: dev.ca.com
      path: "/"
      service:
        port:
          name: https
```

---

## Migrating to Gateway API

If you are planning to migrate from Ingress v1 to the Kubernetes Gateway API, see the [Gateway API examples](../gateway/) for equivalent configurations. The key differences are:

| Feature | Ingress v1 | Gateway API |
|---|---|---|
| TLS termination | Via annotations (controller-specific) | Native `HTTPRoute` + `BackendTLSPolicy` |
| TLS passthrough | Limited (controller-specific) | Native `TLSRoute` with SNI routing |
| Path-based routing | Supported | Supported (HTTPRoute mode) |
| Header manipulation | Via annotations (controller-specific) | Native HTTPRoute filters |
| Certificate management | Manual (external secrets) | Auto-generated or manual |
| Backend TLS validation | Not standardized | `BackendTLSPolicy` with CA validation |
