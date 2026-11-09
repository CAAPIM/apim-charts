# Portal Chart - Contour Example

Deploys Contour with the Portal (the chart creates the GatewayClass and Gateway) and routes with Gateway API `TLSRoute` (TLS passthrough). The Portal chart itself stays controller-agnostic; Contour is an optional, reference-only subchart (`ingress.createContour`, default `false`).

> Contour does not support `TLSRoute` at `v1` yet, so `tlsRouteApiVersion` is `v1alpha2`.

> The examples use the release name `my-portal` and the namespace `portal`. Change them to match your own.

## Steps

1. Install the CRDs once per cluster, either by setting `contour.gatewayAPI.manageCRDs=true` and `contour.contour.manageCRDs=true` on the first install, or by applying them separately. Uninstalling a release that owns the CRDs removes them for the whole cluster.
2. Install the Portal with [values.yaml](./values.yaml):
   ```
   helm install my-portal layer7/portal -n portal --create-namespace \
     --set-file "portal.registryCredentials=/path/to/docker-secret.yaml" \
     -f values.yaml
   ```
3. Get the external address (the Envoy `LoadBalancer` IP, shown under `EXTERNAL-IP`): `kubectl get svc -n portal | grep envoy`
4. Create DNS records for the Portal hostnames (the hosts in `portal.domain`, for example the tenant, `*-ssg`, `enroll-*` and `analytics-*` hosts) pointing to that address, or use a wildcard record for your domain. Use `contour.envoy.service.loadBalancerIP` to request a fixed IP so the DNS records stay valid. Then open the Portal at `https://<tenant>-<subdomainPrefix>.<portal.domain>`.

### Install with `--set` flags instead of values.yaml

The chart creates the GatewayClass and the Gateway reference itself, so no `kubectl apply` or `gatewayRef` settings are needed. Use a unique `gatewayClassName` per release on a shared cluster (a GatewayClass is cluster-wide).

```
helm install my-portal layer7/portal -n portal --create-namespace \
  --set global.subdomainPrefix=my-portal \
  --set portal.domain=example.com \
  --set-file "portal.registryCredentials=/path/to/docker-secret.yaml" \
  --set ingress.create=false \
  --set ingress.type.kubernetes=false \
  --set contour.contour.ingressClass.create=false \
  --set contour.contour.ingressClass.default=false \
  --set ingress.createContour=true \
  --set ingress.type.gatewayAPI=true \
  --set ingress.gatewayAPI.create=true \
  --set ingress.gatewayAPI.gatewayClassName=contour-my-portal \
  --set contour.contour.manageCRDs=false \
  --set contour.envoy.service.loadBalancerIP=<static-ip>
```

Add `--dry-run=server --debug` to check the rendered resources first. `ingress.create=false` is needed because the bundled Nginx subchart is on by default (and deprecated).

## Upgrading an existing release (for example from the bundled Nginx)

Use the same settings with `helm upgrade`. Keep `ingress.create=false`, which removes the bundled Nginx from the release.

```
helm upgrade my-portal layer7/portal -n portal --reset-then-reuse-values \
  --set ingress.create=false \
  --set ingress.type.kubernetes=false \
  --set contour.contour.ingressClass.create=false \
  --set contour.contour.ingressClass.default=false \
  --set ingress.createContour=true \
  --set ingress.type.gatewayAPI=true \
  --set ingress.gatewayAPI.create=true \
  --set ingress.gatewayAPI.gatewayClassName=contour-my-portal \
  --set contour.contour.manageCRDs=false \
  --set contour.envoy.service.loadBalancerIP=<static-ip>
```

If you created the GatewayClass manually in an earlier install, the upgrade fails because it already exists. Delete it first (`kubectl delete gatewayclass contour-my-portal`), or let Helm adopt it by adding the label `app.kubernetes.io/managed-by=Helm` and the annotations `meta.helm.sh/release-name` and `meta.helm.sh/release-namespace`.

## Using an existing Contour

Set `ingress.createContour=false`, and either keep `gatewayAPI.create=true` with the `gatewayClassName` of your existing GatewayClass, or set `gatewayAPI.create=false` and `gatewayAPI.existingRef.name` to your Gateway.

See also [Gateway API examples](../gateway/).
