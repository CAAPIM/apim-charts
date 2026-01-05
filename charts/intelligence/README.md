# API Management Intelligence Chart

This chart deploys the API Management Intelligence. APIM Intelligence is responsible for processing and aggregating policy code from the API Gateway and making it available to the Portal.

## Parameters

### Global parameters

These values are typically provided by a parent chart.

| Parameter | Description | Default |
| --- | --- | --- |
| `global.portalRepository` | The repository for the portal images. | `caapim/` |
| `global.pullSecret` | The name of an existing image pull secret. | `""` |
| `global.databaseType` | The type of database to use. | `mysql` |
| `global.databaseSecret` | The name of the secret containing the database password. | `intelligence-db-secret` |
| `global.databaseUsername` | The username for the database. | `intelligence_user` |
| `global.databaseHost` | The hostname of the database. | `mysql` |
| `global.databasePort` | The port of the database. | `3306` |
| `global.databaseUseSSL` | Whether to use SSL for the database connection. | `true` |
| `global.databaseRequireSSL` | Whether to require SSL for the database connection. | `false` |
| `global.legacyDatabaseNames` | Whether to use legacy database names. | `false` |
| `global.subdomainPrefix` | The prefix for the subdomain. | `dev-portal` |
| `global.podSecurityContext` | The security context for the pod. | `{}` |
| `global.containerSecurityContext` | The security context for the container. | `{}` |
| `global.schedulerName` | The name of the scheduler to use for the pods. | `""` |
| `global.additionalLabels` | Additional labels to be applied to all resources. | `{}` |

### General parameters

| Parameter | Description | Default |
| --- | --- | --- |
| `nameOverride` | A string to override the name of the chart. | `""` |
| `fullnameOverride` | A string to override the full name of the chart. | `""` |
| `forceRedeploy` | Whether to force redeployment of statefulsets and deployments on upgrade. | `false` |

### Intelligence Server settings

| Parameter | Description | Default |
| --- | --- | --- |

| `intelligenceServer.image.intelligenceServer` | The image for the intelligence-server. | `intelligence-server:mr_bitnami_kafka` |
| `intelligenceServer.image.pullPolicy` | The pull policy for the intelligence-server image. | `IfNotPresent` |
| `intelligenceServer.serviceAccount.create` | Whether to create a service account. | `true` |
| `intelligenceServer.serviceAccount.name` | The name of the service account to use. | `""` |
| `intelligenceServer.serviceAccount.automountServiceAccountToken` | Whether to automount the service account token. | `true` |
| `intelligenceServer.rbac.create` | Whether to create RBAC resources. | `true` |
| `intelligenceServer.replicaCount` | The number of replicas for the intelligence-server. | `1` |
| `intelligenceServer.image.pullPolicy` | The pull policy for the intelligence-server image. | `IfNotPresent` |
| `intelligenceServer.additionalLabels` | Additional labels for the intelligence-server deployment. | `{}` |
| `intelligenceServer.affinity` | The affinity for the intelligence-server pods. | `{}` |
| `intelligenceServer.nodeSelector` | The node selector for the intelligence-server pods. | `{}` |
| `intelligenceServer.tolerations` | The tolerations for the intelligence-server pods. | `[]` |
| `intelligenceServer.podSecurityContext` | The security context for the intelligence-server pod. | `{}` |
| `intelligenceServer.containerSecurityContext` | The security context for the intelligence-server container. | `{}` |
| `intelligenceServer.resources` | The resource requests and limits for the intelligence-server pods. | `{}` |
| `intelligenceServer.service.type` | The type of service for the intelligence-server. | `ClusterIP` |
| `intelligenceServer.service.port` | The port for the intelligence-server service. | `8282` |
| `intelligenceServer.service.sessionAffinity` | The session affinity for the intelligence-server service. | `None` |
| `intelligenceServer.service.externalTrafficPolicy` | The external traffic policy for the intelligence-server service. | `""` |
| `intelligenceServer.service.internalTrafficPolicy` | The internal traffic policy for the intelligence-server service. | `""` |
| `intelligenceServer.portalDataHost` | The host and port for the portal data service. | `"portal-data:8080"` |

### Kafka settings

The Intelligence Server requires a connection to a Kafka cluster. The following settings are used to configure the connection.

| Parameter | Description | Default |
| --- | --- | --- |
| `intelligenceServer.kafka.autoDiscovery.enabled` | When enabled, an initContainer is used to discover Kafka broker external addresses. | `true` |
| `intelligenceServer.kafka.autoDiscovery.image.repository` | The repository for the auto-discovery initContainer image. | `docker.io/bitnami/kubectl` |
| `intelligenceServer.kafka.autoDiscovery.image.tag` | The tag for the auto-discovery initContainer image. | `1.33.3-debian-12-r0` |
| `intelligenceServer.kafka.autoDiscovery.image.pullPolicy` | The pull policy for the auto-discovery initContainer image. | `IfNotPresent` |
| `intelligenceServer.kafka.autoDiscovery.resources` | The resource requests and limits for the auto-discovery initContainer. | `{}` |
| `intelligenceServer.kafka.externalAdvertisedBrokers` | A comma-separated list of external advertised Kafka brokers. | `""` |
| `intelligenceServer.kafka.kafkaCa.caSecretName` | The name of the secret containing the Kafka CA certificate. | `""` |
| `intelligenceServer.kafka.kafkaCa.passwordSecretName` | The name of the secret containing the password for the Kafka CA certificate. | `""` |
| `intelligenceServer.kafka.kafkaCa.passwordSecretKey` | The key in the password secret that contains the password. | `keypass.txt` |

**NOTE:** When this chart is used as a subchart, it requires Kafka configuration for its initContainer to discover brokers. The parent chart must provide these values under the `apim-intelligence.kafka` key.

To avoid duplication, the parent chart's `values.yaml` can use a YAML alias:

```yaml
kafka: &kafka_config
  #... kafka subchart values

apim-intelligence:
  kafka: *kafka_config
```