# Portal Utility Scripts

### Create a new tenant on your API Developer Portal
* [Create a New Tenant ](#create-a-new-tenant)
* [Migrate from Docker Swarm or Helm 2 Chart (v4.4 and above)](portal-migration/README.md)

## Create a New Tenant
### create-tenant.sh
Follow these steps:
* [Prepare JSON Payload](#prepare-json-payload)
* [Create New Tenant](#create-tenant)
* [Troubleshooting](#troubleshooting)

## Prepare JSON Payload
Create and generate JSON payload for the Tenant Creation API call using the tenant parameters defined next. 

|Tenant Parameters|Standard|Notes|
|---|---|---|		
|adminEmail|*|The Admin email of the tenant|
|noReplyEmail|*|The tenant no-reply-email|
|portalName|*|Name of the portal. Lowercase letters (a-z) and numbers (0-9) only. 255 characters maximum.|
|subdomain| |The portal subdomain|
|tenantId|*|The Tenant ID you create. Lowercase letters (a-z) and numbers (0-9) only. 255 characters maximum.|
|auditLogLevel||One of the following values: TRACE, DEBUG, INFO, WARN, ERROR|
|multiclusterEnabled||Either true or false. Set to true for a tenant with an API Portal integrated with on-premise API proxy clusters. Set to false for a SaaS Portal.|
|performanceLogLevel||One of the following values: TRACE, DEBUG, INFO, WARN, ERROR|
|portalLogLevel||One of the following values: TRACE, DEBUG, INFO, WARN, ERROR|
|tenantType||One of the following values: SAAS, ON-PREM|
|termOfUse|*|Your tenant term of use. One of the following values: a string such as "EULA", or "null"| 

Save the file as **payload.json**. A sample payload is shown next:
```
{
   "adminEmail": "YOUR-ADMIN-EMAIL",
   "auditLogLevel": "TRACE",
   "multiclusterEnabled": true,
   "noReplyEmail":"noreply@YOUR-MAIL_DOMAIN",
   "performanceLogLevel": "ERROR",
   "portalLogLevel": "ERROR",
   "portalName": "YOUR-PORTAL-NAME",
   "subdomain": "YOUR-DOMAIN",
   "tenantId": "YOUR-TENANT-NAME",
   "tenantType": "ON-PREM",
   "termOfUse": "eula"
}
```

*Note: The tenant creation endpoint uses Mutual SSL/TLS, your Ingress Controller must support SSL/TLS Passthrough*

## Create Tenant
This script takes in the following parameters

```
-d /path/to/payload.json

-n <namespace> | default: default

-k <keyname> | default: portal-internal-secret

Example usage
$ ./create-tenant.sh -d ./payload.json -n myportalnamespace

The tenant has been added to the database. The tenant info can be found in the tenant_info.json file in the current directory.
Please follow the rest of the instructions at TechDocs to enroll your gateway with the portal.
(https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-developer-portal/5-0/install-configure-and-upgrade/post-installation-tasks/enroll-a-layer7-api-gateway.html)
1. You will need to navigate to the portal at <tenantUrl> and create a new API PROXY. 
2. Copy the enrollment URL
3. Open your tenant gateway and enroll this gateway with the portal using the URL from step 2.

```
## Troubleshooting

**Please check you've set the correct namespace and have the Chart installed.**
```
* Make sure the correct namespace is set -n <namespace>
* Verify the Chart is installed
$ helm list -n <namespace>
```
 **'portalHost' is not resolvable. Please make sure this points to your portal IP address.**
```
* Verify that you have added the Portal endpoints to DNS or your hosts file and are able to resolve them
```
 **Please check you've set the correct key name, it should be portal-internal-secret, check tls.internalSecretName in your values file.**
 ```
* Check tls.internalSecret name in your values.yaml file, if it doesn't match 'portal-internal-secret' then add -k <your-value>
```
***401/403 Authentication Error***
```
* Ensure that your Ingress Controller supports SSL/TLS Passthrough.
```
