# Layer7 API Developer Portal
The Layer7 API Developer Portal (API Portal) is part of the Layer7 API Management solution, which consists of API Portal and API Gateway.

## Introduction
This Chart deploys the Layer7 API Developer Portal on a Kubernetes Cluster using the Helm Package Manager.

## Prerequisites

- Kubernetes 1.17+
- Helm v3.1+
- Persistent Volume Provisioner (if using PVC for RabbitMQ/Analytics)
- ***docker secret.yaml*** from here ==> [CA API Developer Portal
Solutions & Patches](https://techdocs.broadcom.com/us/product-content/recommended-reading/technical-document-index/ca-api-developer-portal-solutions-and-patches.html)

### Production
- A dedicated MySQL 5.6/7 server [TechDocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-developer-portal/5-0/install-configure-and-upgrade/install-portal-on-docker-swarm/configure-an-external-database.html#concept.dita_18bc57ed503d5d7b08bde9b6e90147aef9a864c4_ProvideMySQLSettings)
- An Ingress Controller that supports SSL Passthrough (i.e. Nginx)
- 3 Worker nodes with at least 4vcpu and 32GB ram - High Availability with analytics
- Access to a DNS Server
- Signed SSL Server Certificate

# Install the Chart
When using this Chart in Production, save value-production.yaml as ***<my-values.yaml>*** and use this as your starting point.
Adding ```-f <my-values.yaml>``` to the commands below will apply your configuration to the Chart. For details on what you can change see [configuration](#configuration).

```
 $ helm repo add layer7 https://caapim.github.io/apim-charts/
 $ helm repo update
 $ helm install <release-name> --set-file "portal.registryCredentials=/path/to/docker-secret.yaml" layer7/portal
```

## Upgrade this Chart
To upgrade API Potal deployment
```
 $ helm upgrade <release-name> --set-file "portal.registryCredentials=/path/to/docker-secret.yaml" layer7/portal
```
## Delete this Chart
To delete API Portal installation

```
 $ helm delete <release name>
```

*Additional resources such as PVCs and Secrets will need to be cleaned up manually. This protects your data in the event of an accidental deletion*

## Additional Guides/Info
* [Use/Replace Signed Certificates](#certificates)
* [DNS Configuration](#dns-configuration)
* [SMTP Settings](#smtp-parameters)
* [Migrate from Docker Swarm/Previous Helm Chart](../../utils/portal-migration/README.md)
* [Upgrade this Chart](#upgrade-this-chart)
* [Cloud Deep Storage for Minio](#druid)
* [Troubleshooting](#troubleshooting)

# Configuration
This section describes configurable parameters in **values.yaml**, there is also ***production-values.yaml*** that represents the minimum recommended configuration for deploying the Portal with analytics (if enabled) and core services in an HA, fault tolerant configuration.

### Global Parameters
| Parameter                                 | Description                                                                                                          | Default                                                      |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `global.portalRepository` | Image Repository | `caapim/` |
| `global.pullSecret` | Image Pull Secret name | `broadcom-apim` |
| `global.setupDemoDatabase` | Deploys MySQL as part of this Chart | `false` |
| `global.databaseSecret` | Database secret name | `database-secret` |
| `global.databaseUsername` | Database username | `admin` |
| `global.databasePassword` | Database password | `7layer` |
| `global.databaseHost` | Database Host | `` |
| `global.databasePort` | Database Port | `3306` |
| `global.databaseUseSSL` | Use SSL when communicating with the Database | `true` |
| `global.databaseRequireSSL` | Require Database support of SSL connection if databaseUseSSL=true | `false` |
| `global.legacyHostnames` | Legacy Hostnames | `false` |
| `global.legacyDatabaseNames` | Legacy Database names | `false` |
| `global.subdomainPrefix` | Subdomain Prefix | `dev-portal` |
| `global.storageClass` | Global Storage Class | `_` |
| `global.schedulerName` | Global Scheduler name for Portal + Analytics, this doesn't apply to other subcharts | `not set` |

### Portal Parameters
| Parameter                                 | Description                                                                                                          | Default                                                      |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `portal.domain` | The Portal Domain | `example.com` |
| `portal.enrollNotificationEmail` | Notification email address | `noreply@example.com` |
| `portal.analytics.enabled` | Enable/Disable the Druid Analytics stack | `true` |
| `portal.analytics.aggregation` | Enable/Disable Aggregation, requires a min of 2 analytics.replicaCount | `false` |
| `portal.license.secretName` | License secret name | `portal-license` |
| `portal.license.value` | License value - ***Note: these are not required for Portal 5.x *** | `` |
| `portal.internalSSG.secretName` | APIM/PSSG secret name | `ssg-secret` |
| `portal.internalSSG.username` | APIM/PSSG username - auto-generated | `auto-generated` |
| `portal.internalSSG.password` | APIM/PSSG password - auto-generated | `auto-generated` |
| `portal.papi.secretName` | PAPI secret name | `papi-secret` |
| `portal.papi.password` | PAPI password - auto-generated | `` |
| `portal.otk.port` | OTK Port, update this to 9443 if migrating from Docker Swarm | `443` |
| `portal.ssoDebug` | SSO Debugging | `false` |
| `portal.registryCredentials` | Used to create image pull secret, see prerequisites | `` |
| `portal.hostnameWhiteList` | Hostname whitelist | `` |
| `portal.defaultTenantId` | **Important!** Do not change the default tenant ID unless you have been using a different tenant ID in your previous install/deployment. There is a 15 character limit. See [DNS Configuration](#dns-configuration) for tenant ID character limitations.  | `apim` |

### Certificates
| Parameter                                 | Description                                                                                                          | Default                                                      |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `tls.job.enabled` | Enable or disable the TLS Pre-install/upgrade job - if you've migrated certificates over from a previous installation and wish to keep them then set this to false. | `true` |
| `tls.job.rotate` | One of all, internal, external, none. This rotates the selected set of certificates and upgrades the relevant deployments | `none` |
| `tls.internalSecretName` | Internal Certificate secret name - change this if rotating internal/all certificates | `portal-internal-secret` |
| `tls.externalSecretName` | External Certificate secret name - change this if rotating external/all certificates | `portal-external-secret` |
| `tls.useSignedCertificates` | Use Signed Certificates for Public facing services, requires setting tls.crt,crtChain,key and optionally keyPass | `false` |
| `tls.crt` | Signed Certificate in PEM format | `` |
| `tls.crtChain` | Certificate Chain in PEM format | `` |
| `tls.key` | Private Key in PEM format, if password protected supply .keyPass | `` |
| `tls.keyPass` | Private Key Pass | `` |
| `tls.expiryInDays` | Certificate expiry in days | '1095' |

***To use a signed certificate make sure ```tls.useSignedCertifcates``` is set to true and specify tls.crt (public cert), tls.crtChain (intermediary) and tls.key using --set-file.***

### Ingress Options

| Parameter                                 | Description                                                                                                          | Default                                                      |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `ingress.type.kubernetes` | Create a Kubernetes Ingress Object | `true` |
| `ingress.type.openshift` | Create Openshift Services | `false` |
| `ingress.type.secretName` | Certificate Secret Name to be created | `dispatcher-tls` |
| `ingress.create` | Deploy the Nginx subchart as part of this deployment | `true` |
| `ingress.annotations` | Ingress annotations | `additional annotations that you would like to pass to the Ingress object` |
| `ingress.tenantIds` | A list of tenantIds that you plan to create on the Portal. | `[] - see values.yaml` |
| `ingress.apiVersion` | added for future compatibility, extensions/v1beta1 will soon be deprecated, if you're running 1.18 this will be `networking.k8s.io/v1beta1`  | `extensions/v1beta1` |

### SMTP Parameters
| Parameter                                 | Description                                                                                                          | Default                                                      |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `smtp.host` | SMTP Host | `notinstalled` |
| `smtp.port` | SMTP Port | `notinstalled` |
| `smtp.username` | SMTP Username | `notinstalled` |
| `smtp.password` | SMTP Password | `notinstalled` |
| `smtp.requireSSL` | Require SSL for the SMTP Server | `false` |
| `smtp.cert` | SMTP Server certificate | `notinstalled` |


### Container Deployment Configurations
| Parameter                                 | Description                                                                                                          | Default                                                      |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `analytics.replicaCount` | Number of analytics nodes | `1` |
| `analytics.image.pullPolicy` | Analytics image pull policy | `IfNotPresent` |
| `analytics.strategy` | Update strategy   | `{} evaluated as a template` |
| `analytics.resources` | Resource request/limits   | `{} evaluated as a template` |
| `analytics.nodeSelector` | Node labels for pod assignment | `{} evaluated as a template` |
| `analytics.affinity` | Affinity for pod assignment  | `{} evaluated as a template` |
| `apim.replicaCount` | Number of APIM nodes | `1` |
| `apim.image.pullPolicy` | APIM image pull policy | `IfNotPresent` |
| `apim.strategy` | Update strategy   | `{} evaluated as a template` |
| `apim.resources` | Resource request/limits   | `{} evaluated as a template` |
| `apim.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `apim.affinity` | Affinity for pod assignment  | `{} evaluated as a template` |
| `authenticator.replicaCount` | Number of authenticator nodes | `1` |
| `authenticator.image.pullPolicy` | authenticator image pull policy | `IfNotPresent` |
| `authenticator.strategy` | Update strategy   | `{} evaluated as a template` |
| `authenticator.resources` | Resource request/limits   | `{} evaluated as a template` |
| `authenticator.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `authenticator.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `dispatcher.replicaCount` | Number of dispatcher nodes | `1` |
| `dispatcher.image.pullPolicy` | Dispatcher image pull policy | `IfNotPresent` |
| `dispatcher.strategy` | Update strategy   | `{} evaluated as a template` |
| `dispatcher.resources` | Resource request/limits   | `{} evaluated as a template` |
| `dispatcher.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `dispatcher.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `portalData.replicaCount` | Number of portal data nodes | `1` |
| `portalData.image.pullPolicy` | Portal-data image pull policy | `IfNotPresent` |
| `portalData.strategy` | Update strategy   | `{} evaluated as a template` |
| `portalData.resources` | Resource request/limits   | `{} evaluated as a template` |
| `portalData.nodeSelector` | Node labels for pod assignment | `{} evaluated as a template` |
| `portalData.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `portalEnterprise.replicaCount` | Number of portal-enterprise nodes | `1` |
| `portalEnterprise.image.pullPolicy` | Portal enterprise image pull policy | `IfNotPresent` |
| `portalEnterprise.strategy` | Update strategy   | `{} evaluated as a template` |
| `portalEnterprise.resources` | Resource request/limits   | `{} evaluated as a template` |
| `portalEnterprise.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `portalEnterprise.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `pssg.replicaCount` | Number of PSSG nodes | `1` |
| `pssg.image.pullPolicy` | PSSG image pull policy | `IfNotPresent` |
| `pssg.strategy` | Update strategy   | `{} evaluated as a template` |
| `pssg.resources` | Resource request/limits   | `{} evaluated as a template` |
| `pssg.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `pssg.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `solr.replicaCount` | Number of Solr nodes | `1` |
| `solr.image.pullPolicy` | Solr image pull policy | `IfNotPresent` |
| `solr.strategy` | Update strategy   | `{} evaluated as a template` |
| `solr.resources` | Resource request/limits   | `{} evaluated as a template` |
| `solr.nodeSelector ` | Node labels for pod assignment   | `{} evaluated as a template` |
| `tenantProvisioner.replicaCount` | Number of tenant provisioner nodes | `1` |
| `tenantProvisioner.image.pullPolicy` | Tenant provisioner image pull policy | `IfNotPresent` |
| `tenantProvisioner.strategy` | Update strategy   | `{} evaluated as a template` |
| `tenantProvisioner.resources` | Resource request/limits   | `{} evaluated as a template` |
| `tenantProvisioner.nodeSelector ` | Node labels for pod assignment   | `{} evaluated as a template` |
| `tenantProvisioner.affinity ` | Affinity for pod assignment   | `{} evaluated as a template` |


### RBAC Parameters
| Parameter                                 | Description                                                                                                          | Default                                                      |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `serviceAccount.create` | Enable creation of ServiceAccount for Portal Deployments | `true` |
| `serviceAccount.name` | Name of the created serviceAccount | Generated using the `portal.fullname` template |
| `rbac.create`| Create & use RBAC resources |`true`|
| `druid.serviceAccount.create`| Enable creation of ServiceAccount for Druid |`true`|
| `druid.serviceAccount.name`| Name of the created serviceAccount | Generated using the `portal.fullname` template |
| `rabbitmq.serviceAccount.create`| Enable creation of ServiceAccount for Bitnami RabbitMQ |`true`|
| `rabbitmq.serviceAccount.name`| Name of the created serviceAccount | Generated using the `portal.fullname` template |
| `rabbitmq.rbac.create`| Create & use RBAC resources |`true`|
| `ingress-nginx.podSecurityPolicy.enabled`| Enable Pod Security Policy for Nginx |`true`|
| `ingress-nginx.serviceAccount.create`| Enable creation of ServiceAccount for Nginx |`true`|
| `ingress-nginx.serviceAccount.name`| Name of the created serviceAccount | Generated using the `portal.fullname` template |
| `ingress-nginx.rbac.create`| Create & use RBAC resources |`true`|

### Telemetry Parameters
| Parameter                                 | Description                                                                                                          | Default                                                      |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `telemetry.plaEnabled` | (For PLA customers) Set to **true** to turn on telemetry service as per your agreement, otherwise **false**. **Tip:** For more information on telemetry, see [Licensing and Telemetry](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-developer-portal/5-0/introduction-layer7-api-developer-portal/licensing-and-telemetry.html) ![image](https://img.icons8.com/small/1x/external-link.png) and [Configure Telemetry](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-developer-portal/5-0/install-configure-and-upgrade/install-portal-on-docker-swarm/install-and-configure-api-portal/configure-telemetry.html) ![image](https://img.icons8.com/small/1x/external-link.png)  | `false` |
| `telemetry.usageType` | The telemetry service behavior | `PRODUCTION` |
| `telemetry.domainName` | Domain name of telemetry service. | `` |
| `telemetry.siteId` |  Site ID of the telemetry service | `` |
| `telemetry.chargebackId` | Chargeback ID of the telemetry service | `_` |
| `telemetry.proxy.url` |  Proxy URL, required if you're using a proxy to communicate with the telemetry service. | `_` |
| `telemetry.proxy.username` | Proxy username | `_` |
| `telemetry.proxy.password` | Proxy password | `_` |


### Portal Images
| Parameter                                 | Description                                                                                                          | Default                                                      |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `image.dispatcher` | dispatcher image | `dispatcher:5.0` |
| `image.pssg` | PSSG image | `pssg:5.0` |
| `image.apim` | APIM ingress image | `ingress:5.0` |
| `image.enterprise` | portal-enterprise image | `portal-enterprise:5.0` |
| `image.data` | portal-data image | `portal-data:5.0` |
| `image.tps` | tenant provisioner image | `tenant-provisioning-service:5.0` |
| `image.solr` | Solr image | `solr:5.0` |
| `image.analytics` | Analytics image | `analytics-server:5.0` |
| `image.authenticator` | Authenticator image | `authenticator:5.0` |
| `image.dbUpgrade` | db upgrade image | `db-upgrade-portal:5.0` |
| `image.rbacUpgrade` | Analytics image, per Portal version | `db-upgrade-rbac:5.0` |
| `image.upgradeVerify` | Upgrade verification image | `upgrade-verify:5.0` |
| `image.tlsManager` | TLS manager image | `tls-automator:5.0` |

## Subcharts
For Production, please use an external MySQL Server.

## Druid
The following table lists the configured parameters of the Druid Subchart

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `druid.serviceAccount.create` | Enable creation of ServiceAccount for the Druid Chart   | `true` |
| `druid.serviceAccount.name` |  Name of the created serviceAccount   | Generated using the `druid.fullname` template` |
| `druid.persistence.storage.historical` | Historical PVC Size   | `50Gi` |
| `druid.persistence.storage.minio` | Minio PVC Size   | `40Gi` |
| `druid.persistence.storage.kafka` | Kafka PVC Size   | `10Gi` |
| `druid.persistence.storage.zookeeper` | Zookeeper PVC Size   | `10Gi` |
| `druid.minio.replicaCount` | Number of minio nodes   | `1` |
| `druid.minio.image.pullPolicy`| Minio image pull policy   | `IfNotPresent` |
| `druid.minio.auth.secretName` | The name of the secret that stores Minio Credentials   | `true` |
| `druid.minio.auth.access_key` | Minio access key   | `auto-generated` |
| `druid.minio.auth.secret_key` | Minio secret key   | `auto-generated` |
| `druid.minio.cloudStorage` | Enable Cloud Storage for Minio. GCP, AWS, Azure   | `false` |
| `druid.minio.bucketName` | Minio bucket name - make sure this is updated if using cloud storage. Minio will attempt to the create the bucket if it doesn't exist, it is recommended that you create the bucket in the relevant provider prior to installing this Chart.   | `api-metrics` |
| `druid.minio.s3gateway.enabled` | Use minio as Amazon S3 (Simple Storage Service) gateway - https://docs.minio.io/docs/minio-gateway-for-s3   | `false` |
| `druid.minio.s3gateway.serviceEndpoint` | AWS S3 service endpoint if required   | `nil` |
| `druid.minio.s3gateway.accessKey` | AWS Access Key that has S3 access   | `nil` |
| `druid.minio.s3gateway.secret_key` | AWS Secret Key that has S3 access    | `nil` |
| `druid.minio.gcsgateway.enabled` | Use minio as GCS (Google Cloud Storage) gateway - https://docs.minio.io/docs/minio-gateway-for-gcs   | `false` |
| `druid.minio.gcsgateway.gcsKeyJson` | Google credentials JSON   | `nil` |
| `druid.minio.gcsgateway.projectId` | GCP Project ID   | `nil` |
| `druid.minio.azuregateway.enabled` | Use minio as an azure blob gateway - https://docs.minio.io/docs/minio-gateway-for-azure   | `false` |
| `druid.minio.resources` | Resource request/limits   | `{} evaluated as a template` |
| `druid.minio.nodeSelector`| Node labels for pod assignment   | `{} evaluated as a template` |
| `druid.minio.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `druid.zookeeper.replicaCount` | Number of zookeeper nodes   | `1` |
| `druid.zookeeper.image.pullPolicy` | Zookeeper image pull policy   | `IfNotPresent` |
| `druid.zookeeper.resources` | Resource request/limits   | `{} evaluated as a template` |
| `druid.zookeeper.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `druid.zookeeper.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `druid.coordinator.replicaCount` | Number of coordinator nodes   | `1` |
| `druid.coordinator.image.pullPolicy` | Coordinator image pull policy  | `IfNotPresent` |
| `druid.coordinator.resources` | Resource request/limits   | `{} evaluated as a template` |
| `druid.coordinator.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `druid.coordinator.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `druid.kafka.replicaCount` | Number of kafka nodes   | `1` |
| `druid.kafka.image.pullPolicy` | Kafka image pull policy   | `IfNotPresent` |
| `druid.kafka.resources` | Resource request/limits   | `{} evaluated as a template` |
| `druid.kafka.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `druid.kafka.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `druid.broker.replicaCount` | Number of broker nodes   | `1` |
| `druid.broker.image.pullPolicy` | Broker image pull policy   | `IfNotPresent` |
| `druid.broker.resources` | Resource request/limits   | `{} evaluated as a template` |
| `druid.broker.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `druid.broker.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `druid.historical.replicaCount` | Number of historical nodes   | `1` |
| `druid.historical.image.pullPolicy` | Historical image pull policy   | `IfNotPresent` |
| `druid.historical.resources` | Resource request/limits   | `{} evaluated as a template` |
| `druid.historical.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `druid.historical.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `druid.ingestion.replicaCount` | Number of ingestion nodes   | `1` |
| `druid.ingestion.image.pullPolicy` | Ingestion image pull policy   | `IfNotPresent` |
| `druid.ingestion.resources` | Resource request/limits   | `{} evaluated as a template` |
| `druid.ingestion.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `druid.ingestion.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |
| `druid.middlemanager.replicaCount` | Number of middle manager nodes   | `1` |
| `druid.middlemanager.image.pullPolicy` | Middle manager image pull policy   | `IfNotPresent` |
| `druid.middlemanager.resources` | Resource request/limits   | `{} evaluated as a template` |
| `druid.middlemanager.nodeSelector` | Node labels for pod assignment   | `{} evaluated as a template` |
| `druid.middlemanager.affinity` | Affinity for pod assignment   | `{} evaluated as a template` |

## Druid Images
The following table lists the configured parameters of the Druid Subchart

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `druid.image.zookeeper `                | Zookeeper image   | `zookeeper:5.0` |
| `druid.image.broker`                | Broker image   | `druid:5.0` |
| `druid.image.coordinator`                | Coordinator  | `druid:5.0` |
| `druid.image.middlemanager`                | Middlemanager image   | `druid:5.0` 
| `druid.image.minio`                | Minio image   | `minio:5.0` |
| `druid.image.historical`                | Historical image   | `druid:5.0` |
| `druid.image.kafka`                | Kafka image   | `kafka:5.0` |
| `druid.image.ingestion`                | Ingestion image   | `ingestion-server:5.0` |

## RabbitMQ
The following table lists the configured parameters of the Bitnami RabbitMQ Subchart - https://github.com/bitnami/charts/tree/master/bitnami/rabbitmq

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `rabbitmq.enabled`                | Enable this subchart   | `true` |
| `rabbitmq.host`                |  Host - must match fullnameOverride  | `rabbitmq` |
| `rabbitmq.image.tag`    | RabbitMQ image version | `5.0` |
| `rabbitmq.fullnameOverride`                | Overrides the name of the subchart   | `rabbitmq` |
| `rabbitmq.serviceAccount.create`                | Enable creation of ServiceAccount for RabbitMQ    | `true` |
| `rabbitmq.serviceAccount.name.`                | Name of the created serviceAccount | Generated using the `rabbitmq.fullname` template |
| `rabbitmq.rbac.create`       | Create & use RBAC resources   | `true` |
| `rabbitmq.persistence.enabled`                | Enable persistence for RabbitMQ   | `true` |
| `rabbitmq.persistence.size`                | PVC Size   | `8Gi` |
| `rabbitmq.replicaCount`                | Number of Replicas  | `3` |
| `rabbitmq.affinity`                | RabbitMQ Affinity Settings | `see values.yaml` |
| `rabbitmq.service.port`                | RabbitMQ Port   | `5672` |
| `rabbitmq.service.extraPorts`                | MySQL Configuration equivalent to my.cnf   | `see values.yaml` |
| `rabbitmq.extraContainerPorts`                | MySQL Configuration equivalent to my.cnf   | `see values.yaml` |
| `rabbitmq.auth.username`                | RabbitMQ username   | `see values.yaml` |
| `rabbitmq.auth.secretName`                | RabbitMQ secret name   | `see values.yaml` |
| `rabbitmq.auth.existingPasswordSecret`                | RabbitMQ existing password secret | `see values.yaml` |
| `rabbitmq.auth.existingErlangSecret`                | RabbitMQ existing erlang secret   | `see values.yaml` |
| `rabbitmq.extraPlugins`                | Extra enabled plugins | `see values.yaml` |
| `rabbitmq.loadDefinition.enabled`                | Enable load definitions   | `see values.yaml` |
| `rabbitmq.loadDefinition.existingSecret`                | Existing load definitions secret   | `see values.yaml` |
| `rabbitmq.extraConfiguration`                | Extra configuration   | `see values.yaml` |

## MySQL
The following table lists the configured parameters of the MySQL Subchart - https://github.com/helm/charts/tree/master/stable/mysql

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `mysql.imageTag`                | MySQL Image to use   | `5.7.14` |
| `mysql.serviceAccount.create`                |  Enable creation of ServiceAccount for MySQL  | `true` |
| `mysql.serviceAccount.name`                | Name of the created serviceAccount   | `` |
| `mysql.persistence.enabled`                | Enable persistence   | `true` |
| `mysql.persistence.size`                | PVC size  | `8Gi` |
| `mysql.persistence.storageClass`       | Storage Class   | `` |
| `mysql.existingSecret`                | Secret where credentials are stored, see global.databaseSecret   | `database-secret` |
| `mysql.mysqlUser`                | MySQL Username   | `admin` |
| `mysql.mysqlPassword`                | MySQL User Password - auto-generated  | `7layer` |
| `mysql.initializationFiles`                | SQL Files that are run on start up | `see values.yaml` |
| `mysql.configurationFiles`                | MySQL Configuration equivalent to my.cnf   | `see values.yaml` |


## Nginx-Ingress
The following table lists the configured parameters of the Nginx-Ingress Subchart - https://github.com/helm/charts/tree/master/stable/nginx-ingress

This represents minimal configuration of the Chart, this can be disabled in favor of your own ingress controller in the ingress settings.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `nginx-ingress.podSecurityPolicy.enabled`                | Tell Nginx to read PSP   | `true` |
| `nginx-ingress.rbac.create`                | Create & use RBAC resources   | `true` |
| `nginx-ingress.controller.publishService.enabled`                | Enable Publish Service   | `true` |
| `nginx-ingress.extraArgs.enable-ssl-passthrough`                | Enable SSL Passthrough   | `true` |


## DNS Configuration
To access the API Portal, configure the hostname resolution on your corporate DNS server.
The hostnames must match the values you enter in your **values.yaml**. 

> **IMPORTANT!** If you are migrating from a Docker Swarm deployment, utilize legacy hostnames to ensure continuity of business. For details, see [Migrate from Docker Swarm](../../utils/portal-migration/README.md).

## Resolvable Hostnames

API Portal requires the following hostnames to be resolvable:

| Endpoint | Hostname | Legacy Hostname |
| -------- | -------- | --------------- |
| Default tenant homepage | `apim-<subdomainPrefix>.<domain>` | `apim.<domain>` | 
| Ingress SSG | `<subdomainPrefix>-ssg.<domain>` | `ssg.<domain>` | 
| Message broker | `<subdomainPrefix>-broker.<domain>` | `broker.<domain>` | 
| TSSG enrollment | `<subdomainPrefix>-enroll.<domain>` | `enroll.<domain>` | 
| TSSG sync | `<subdomainPrefix>-sync.<domain>` | `sync.<domain>` | 
| API analytics | `<subdomainPrefix>-analytics.<domain>` | `analytics.<domain>` |

## Hostname Restrictions
```global.subdomainPrefix``` value observes the following restrictions:
* Lowercase characters and numbers are supported
* Hyphens are allowed
* No other special characters are supported

## Example
Based on the following default values:
```
global:
  subdomainPrefix: dev-portal
portal:
  domain: example.com
```

Resulting hostnames:

| Endpoint | Hostname | Legacy Hostname |
| -------- | -------- | --------------- |
| Default tenant homepage | `apim-dev-portal.example.com` | `apim.example.com` | 
| Ingress SSG | `dev-portal-ssg.example.com` | `ssg.example.com` | 
| Message broker | `dev-portal-broker.example.com` | `broker.example.com` | 
| TSSG enrollment | `dev-portal-enroll.example.com` | `enroll.example.com` | 
| TSSG sync | `dev-portal-sync.example.com` | `sync.example.com` | 
| API analytics | `dev-portal-analytics.example.com` | `analytics.example.com` |

## Troubleshooting

### RabbitMQ won't start

#### The Chart was deleted and re-installed
RabbitMQ credentials are auto-generated on install, these are bound to the volume that is created.

1. Remove RabbitMQ Replicas (scale to 0)
```
$ kubectl get statefulset rabbitmq - take note of the total replicas, will likely be 1 or 3

$ kubectl scale statefulset rabbitmq --replicas=0

$ kubectl get pvc | grep rabbitmq
```

2. For each data-rabbitmq-0|1|2 is returned
```
$ kubectl kubectl delete pvc data-rabbitmq-0|1|2
```

3. Add RabbitMQ Replicas (scale to 1|3)
```
$ kubectl scale statefulset rabbitmq --replicas=1|3
```
#### Your Kubernetes nodes failed or RabbitMQ crashed.
If the RabbitMQ nodes are stopped or removed out of order, there is a chance that it won't be restored correctly.

1. Set force boot to true

  - In your <my-values.yaml> file, set ```rabbitmq.clustering.forceBoot:true```

2. Upgrade the Chart
```
$ helm upgrade <release-name> --set-file <values-from-install> --set <values-from-install> -f <my-values.yaml> layer7/portal
```

## License
Copyright (c) 2020 CA, A Broadcom Company. All rights reserved.

This software may be modified and distributed under the terms of the MIT license. See the [LICENSE](https://github.com/CAAPIM/apim-charts/blob/stable/LICENSE) file for details.
