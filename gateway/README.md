# Layer7 API Gateway

This chart deploys the API Gateway with hazelcast (optional) and mysql (optional).

Currently this only works with Gateway v10.0.00

# Install the Chart

## From this Repository

`$ helm repo add stable https://kubernetes-charts.storage.googleapis.com`
`$ helm repo add hazelcast https://hazelcast-charts.s3.amazonaws.com/`
`$ helm dep build`

If that fails then 

`$ helm dep up`

`$ helm install gateway --set-file "license.value=path/to/license.xml" --set "license.accept=true" .`

## Upgrade this Chart
To upgrade the Gateway deployment

`$ helm upgrade gateway --set-file "license.value=path/to/license.xml" --set "license.accept=true" .`

## Delete this Chart
To delete Gateway installation

`helm delete <release name> -n <release namespace>`

## Custom values
To make sure that your custom values don't get overwritten by a pull, create your own values.yaml (myvalues.yaml..) then specify -f myvalues.yaml when deploying/upgrading

## Configuration
The following table lists the configurable parameters of the Gateway chart and their default values. See values.yaml for additional parameters and info

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `nameOverride`                | Name override   | `""` |
| `fullnameOverride`                      | Full name override                       | `sts-gateway`                                                     |
| `license.value`          | Gateway license file | `nil`  |
| `license.accept`          | Accept Gateway license EULA | `false`  |
| `image.registry`    | List of http external port mappings               | https: 8443 -> 8443, istio: 18888->18888 |
| `image.repository`          | Gateway Cluster Hostname  | `broadcom.localdomain`  |
| `image.tag`          | InfluxDb location | `influxdb`  |
| `image.pullPolicy`          | InfluxDb Tags | `env=sts`  |
| `image.secretName`          | Enable/Disable Policy Manager access | `true`  |
| `image.credentials.username`          | Policy Manager Username | `admin`  |
| `image.credentials.password`          | Policy Manager Password | `7layer`  |
| `replicas`                   | Number of Gateway service replicas        | `1`                                                          |
| `updateStrategy.type`             | Deployment Strategy                       | `RollingUpdate`                                              |
| `updateStrategy.rollingUpdate.maxSurge`             | Rolling Update Max Surge                       | `1`                                              |
| `updateStrategy.rollingUpdate.maxUnavailable`             | Rolling Update Max Unavailable                       | `0`                                              |
| `clusterHostname`          | Gateway Cluster Hostname  | `broadcom.localdomain`  |
| `clusterPassword`          | Cluster Password, used if db backed  | `7layer`  |
| `management.enabled`          | Enable/Disable Policy Manager access | `true`  |
| `management.restman.enabled`          | Enable/Disable the Rest Management API (Restman) | `false`  |
| `management.username`          | Policy Manager Username | `admin`  |
| `management.password`          | Policy Manager Password | `7layer`  |
| `database.enabled`          | Run in DB Backed or Ephemeral Mode | `true`  |
| `database.create`          | Deploy the MySQL stable deployment as part of this release | `true`  |
| `database.username`          | Database Username | `gateway`  |
| `database.password`          | Database Password | `7layer`  |
| `database.name`          | Database name | `ssg`  |
| `serviceMetrics.enabled`          | Enable the background metrics processing task | `false`  |
| `serviceMetrics.influxDbUrl`          | InfluxDB URL | `http://influxdb`  |
| `serviceMetrics.influxDbPort`          | InfluxDB port | `8086`  |
| `serviceMetrics.influxDbDatabase`          | InfluxDB Database Name | `serviceMetricsDb`  |
| `serviceMetrics.tags`          | InfluxDB tags | `env=dev`  |
| `config.heapSize`          | Java Heap Size | `2g`  |
| `config.javaArgs`          | Additional Java Args to pass to the SSG process | `see values.yaml`  |
| `config.log.override`          | Override the standard log configuration | `true`  |
| `config.log.properties`          | Custom logging properties | `see values.yaml`  |
| `tls.customKey.enabled`          | Not currently implemented | `false`  |
| `additionalEnv`          | Additional environment variables you wish to pass to the Gateway Configmap | `see values.yaml`  |
| `additionalSecret`          | Additional secret variables you wish to pass to the Gateway Secret | `see values.yaml`  |
| `bundle.enabled`          | Create and mount an empty configMap that you can use to load policy bundles onto your Gateway | `false`  |
| `service.type`    | Service Type               | `LoadBalancer` |
| `service.loadbal..`    | Additional Loadbalancer Configuration               | `see https://kubernetes.io/docs/tasks/access-application-cluster/configure-cloud-provider-firewall/#restrict-access-for-loadbalancer-service` |
| `service.ports`    | List of http external port mappings               | https: 8443 -> 8443, management: 9443->9443 |
| `service.annotations`    | Additional annotations to add to the service               | {} |
| `ingress.enabled`    | Enable/Disable an ingress record being created               | `false` |
| `ingress.class`    | Ingress Class               | `nginx` |
| `ingress.annotations`    | Additional ingress annotations               | `{}` |
| `ingress.hostname`    | Override clusterHostname               | `nil` |
| `ingress.port`    | The Gateway Port number/name to route to               | `https` |
| `ingress.tls`    | Use TLS on the Ingress resource              | `false` |
| `ingress.secretName`    | The name of an existing Cert secret, setting this does not auto-create the secret               | `nil` |
| `livenessProbe.enabled`    | Enable/Disable               | `true` |
| `livenessProbe.initialDelaySeconds`    | Initial delay               | `60` |
| `livenessProbe.timeoutSeconds`    | Timeout               | `1` |
| `livenessProbe.periodSeconds`    | Frequency               | `10` |
| `livenessProbe.successThreshold`    | Success Threshold               | `1` |
| `livenessProbe.failureThreshold`    | Failure Threshold               | `10` |
| `readinessProbe.enabled`    | Enable/Disable               | `true` |
| `readinessProbe.initialDelaySeconds`    | Initial delay               | `60` |
| `readinessProbe.timeoutSeconds`    | Timeout               | `1` |
| `readinessProbe.periodSeconds`    | Frequency               | `10` |
| `readinessProbe.successThreshold`    | Success Threshold               | `1` |
| `readinessProbe.failureThreshold`    | Failure Threshold               | `10` |
| `resources.limits`    | Resource Limits               | `{}` |
| `resources.requests`    | Resource Requests              | `{}` |

## MySQL
The following table lists the configured parameters of the MySQL Subchart - see the following for more detail https://github.com/helm/charts/tree/master/stable/mysql

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `mysql.imageTag`                | MySQL Image to use   | `8` |
| `mysql.mysqlUser`                | MySQL Username   | `gateway` |
| `mysql.mysqlPassword`                | MySQL User Password   | `7layer` |
| `mysql.mysqlDatabase`                | Database to create   | `ssg` |
| `mysql.mysqlRootPassword`                | MySQL root password, not set by default   | `nil` |
| `mysql.persistence.enabled`                | Enable/Disable Persistence   | `true` |
| `mysql.persistence.size`                | Persistent Volume Size   | `8Gi` |
| `mysql.persistence.storageClass`                | Storage class to use   | `nil` |
| `mysql.configurationFiles`                | Name overrid   | `see values.yaml` |

## Hazelcast
The following table lists the configured parameters of the Hazelcast Subchart - see the following for more detail https://github.com/hazelcast/charts/blob/master/stable/hazelcast/values.yaml

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `hazelcast.enabled`                | Enable/Disable deployment of Hazelcast   | `false` |
| `hazelcast.external`                | Point to an external Hazelcast - set enabled to false and configure the url  | `false` |
| `hazelcast.url`                | External Hazelcast Url  | `hazelcast.example.com:5701` |
| `hazelcast.cluster.memberCount`                | Number of Hazelcast Replicas you wish to deploy   | `see values.yaml` |
| `hazelcast.hazelcast.yaml`                | Hazelcast configuration   | `see the documentation link` |

### Logs & Audit Configuration

The API Gateway containers are configured to output logs and audits as JSON events, and to never write audits to the in-memory Derby database:

- System properties in the default template for the `config.javaArgs` value configure the log and audit behaviour:
  - Auditing to the database is disabled: `-Dcom.l7tech.server.audit.message.saveToInternal=false -Dcom.l7tech.server.audit.admin.saveToInternal=false -Dcom.l7tech.server.audit.system.saveToInternal=false`
  - JSON formatting is enabled: `-Dcom.l7tech.server.audit.log.format=json`
  - Default log output configuration is overridden by specifying an alternative configuration properties file: `-Djava.util.logging.config.file=/opt/SecureSpan/Gateway/node/default/etc/conf/log-override.properties`
- The alternative log configuration properties file `log-override.properties` is mounted on the container, via ConfigMap.
- System property to include well known Certificate Authorities Trust Anchors 
    - API Gateway does not implicitly trust certificates without importing it but If you want to avoid import step then configure Gateway to accept any certificate signed by well known CA's (Certificate Authorities)
      configure following property to true -
      Set '-Dcom.l7tech.server.pkix.useDefaultTrustAnchors=true' for well known Certificate Authorities be included as Trust Anchors (true/false)
- Allow wildcards when verifying hostnames (true/false)
    - Set '-Dcom.l7tech.security.ssl.hostAllowWildcard=true' to allow wildcards when verifying hostnames (true/false)

### Subcharts
*  Hazelcast ==> https://github.com/helm/charts/tree/master/stable/hazelcast
*  MySQL  ==> https://github.com/helm/charts/tree/master/stable/mysql