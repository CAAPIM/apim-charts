# Portal Chart - Contour Example

Deploys Contour with the Portal and routes with Gateway API `TLSRoute` (TLS passthrough). The Portal chart itself stays controller-agnostic; Contour is an optional, reference-only subchart (`ingress.createContour`, default `false`).

> Contour does not support `TLSRoute` at `v1` yet, so `tlsRouteApiVersion` is `v1alpha2`.

## Steps

0. If installing from a git clone, run `helm dependency build charts/portal` first. Not needed when installing from the Helm repo or a released chart package.

1. Install the CRDs once per cluster, either by setting `contour.gatewayAPI.manageCRDs=true` and `contour.contour.manageCRDs=true` on the first install, or by applying them separately. Uninstalling a release that owns the CRDs removes them for the whole cluster.
2. Apply the GatewayClass (namespace in `controllerName` must be the release namespace):
   ```
   kubectl apply -f gatewayclass.yaml
   ```
3. Install the Portal with [values.yaml](./values.yaml):
   ```
   helm install portal layer7/portal -n portal --create-namespace \
     --set-file "portal.registryCredentials=/path/to/docker-secret.yaml" \
     -f values.yaml
   ```
4. Get the external address: `kubectl get svc -n portal | grep envoy`

## Using an existing Contour

Set `ingress.createContour=false`, and either keep `gatewayAPI.create=true` with the `gatewayClassName` of your existing GatewayClass, or set `gatewayAPI.create=false` and `gatewayAPI.existingRef.name` to your Gateway.

See also [Gateway API examples](../gateway/).
