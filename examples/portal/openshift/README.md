# Deploy Portal in Openshift

The Portal Chart will not work without the custom SCC in an OSE that is restrictive.
This folder contains information on how to deploy the portal charts with Openshift.

## Prerequisite:

- Helm 3.x
- Openshift CLI (oc)
- Create a project(aka namespace) in Openshift.

# Example

Throughout the example, it assumes the project/namespace that the portal will be installed is set as default.

The example creates an exception for uid/gid ranges 1001-1010 which means that you can deploy the Portal with minimal changes.

## Installation

1. Creates a SecurityContext for the namespace that was created with uid/gid ranges from 1001-1010.

```
$ oc apply -f portal-scc.yaml
```

2. Create a role referrring the above scc.

```
$ oc apply -f portal-role.yaml
```

3. Create a service account with name 'portal-sa'.

```
$ oc apply -f portal-sa.yaml
```

4. Create a role-binding that binds the role and service account created in Step 2 and 3.

```
$ oc apply -f portal-rolebinding.yaml
```

5. Instead of executing the above step by step, go to examples/portal/openshift and execute.

```
$ oc apply -f ./scc
```

6. Next is to use the service-account created in the Step 3 to refer in the Portal values.yaml. Refer sample [oc-portal-values.yaml](oc-portal-values.yaml).

```
$ helm install  <release-name>   --set-file "portal.registryCredentials=/path/to/docker-secret.yaml" layer7/portal -f oc-portal-values.yaml

```

7. [Create a new tenant](https://github.com/CAAPIM/apim-charts/tree/stable/utils)

8. Add new tenant route in Openshift. This step is required only if tenant is created by not specifying in values.ingress.tenantIds.

```
$ oc process -f new-tenant-route-template.yaml -p TENANT_NAME=<YOUR-TENANT-NAME> -p PORTAL_DOMAIN=<PORTAL-DOMAIN> | oc apply -f -
```

## Note

Openshift works on routes(similar to ingress in k8s). so in the oc-portal-values.yaml, ingress.type.openshift set to true and ingress.type.kubernetes set to false.
