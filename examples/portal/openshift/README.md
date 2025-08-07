# Deploy Portal in Openshift
The Portal Chart will not work without the custom SCC in an OSE that is restrictive. 
This folder contains information on how to deploy the portal charts with Openshift.


## Prerequisite:
* Helm 3.x
* Openshift CLI (oc)
* Create a project(aka namespace) in Openshift.

# Example
Throughout the example, layer7portal will be used as project(namespace). Replace this value in production.

The example creates an exception for uid/gid ranges 1001-1010 which means that you can deploy the Portal with minimal changes.

## Installation
1. Creates a SecurityContext for the namespace that was created with uid/gid ranges from 1001-1010.

```$ oc apply -f portal-scc.yaml ```
2. Create a role referrring the above scc.

```$ oc apply -f portal-role.yaml```
3. Create a service account with name 'portal-sa'.

```$ oc apply -f portal-sa.yaml```
4. Create a role-binding that binds the role and service account created in Step 2 and 3.

```$ oc apply -f portal-rolebinding.yaml```
5. Instead of executing the above step by step, go to examples/portal/openshift and execute.

```$ oc apply -f ./scc.yaml```
6. Next is to use the service-account created in the Step 3 to refer in the Portal values.yaml. Sample oc-portal-values.yaml is in place.

```$ helm install  <release-name>  "portal.registryCredentials=/path/to/docker-secret.yaml" layer7/portal -n layer7portal```
7. [Create a new tenant](https://github.com/CAAPIM/apim-charts/tree/stable/utils)

## Note
Openshift works on routes(similar to ingress in k8s). so in the oc-portal-values.yaml, ingress.type.openshift set to true and ingress.type.kubernetes set to false. 


