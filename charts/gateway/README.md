# Layer7 API Gateway
This Chart deploys the API Gateway v10.x onward with the following `optional` subcharts: hazelcast, mysql, influxdb, grafana, redis.

### Important Note
The included MySQL subChart is enabled by default to make trying this chart out easier. ***It is not supported or recommended for production.*** Layer7 assumes that you are deploying a Gateway solution to a Kubernetes environment with an external MySQL database.

## Release notes
- Current Chart Version 3.0.30
  - Please review release notes [here](./release-notes.md)

## Prerequisites
- Kubernetes
  - [Refer to techdocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw-11-0/release-notes_cgw/requirements-and-compatibility.html#concept.dita_req_comp_refresh_gw10cr2_platforms) for the latest version support
- Helm v3.x
  - Refer to the [Helm Documentation](https://helm.sh/docs/topics/version_skew/#supported-version-skew) for their compatibility matrix
- Gateway v10.x or v11.x License

#### Note
It's important that your Kubernetes Client and Server versions are compatible.

You can verify this by running the following
```
kubectl version
```
output
```
Client Version: v1.29.1
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.27.6+b49f9d1
WARNING: version difference between client (1.29) and server (1.27) exceeds the supported minor version skew of +/-1
```
The above message indicates that the client version (kubectl) is greater than the server version by more than 1 minor version. This may cause unforseen errors when using Kubectl or Helm.

Please also check your Helm version against [this](https://helm.sh/docs/topics/version_skew/#supported-version-skew) compatibility matrix
```
helm version
```
output
```
version.BuildInfo{Version:"v3.13.3", GitCommit:"c8b948945e52abba22ff885446a1486cb5fd3474", GitTreeState:"clean", GoVersion:"go1.21.5"}

Helm Version    Supported Kubernetes Versions
3.13.x         	1.28.x - 1.25.x
```

## Optional
- Persistent Volume Provisioner (if using PVC for the Demo MySQL Database or Service Metrics example with Grafana or InfluxDb)

## Recommended
- [An Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

### Production
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server) if you would like to enable autoscaling.

#### MySQL/Database Backed Gateways
- [A dedicated external MySQL 8.0.22/8.0.26 server](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw-10-1/install-configure-upgrade/using-mysql-8-0-with-gateway-10.html)

### Advanced Configuration
* [Additional Guides](#additional-guides)
* [Thinking in Kubernetes](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw-10-1/learning-center/thinking-in-kubernetes.html)

#### Getting Started
***If you are using a previous version of this Chart please read the updates section before you upgrade.***
* [Install the Chart](#installing-the-chart)
* [Upgrade the Chart](#upgrading-the-chart)
* [Uninstall the Chart](#uninstalling-the-chart)

## Additional Guides
* [Configuration](#configuration)
* [Service Configuration](#port-configuration)
* [Gateway Application Ports](#gateway-application-ports)
* [OTK Install or Upgrade](#otk-install-or-upgrade)
* [Ingress Configuration](#ingress-configuration)
* [PM Tagger Configuration](#pm-tagger-configuration)
* [Redis Configuration](#redis-configuration)
* [Shared State Provider Configuration](#shared-state-provider-config)
* [OpenTelemetry Configuration](#opentelemetry-configuration)
* [Database Configuration](#database-configuration)
* [Cluster-Wide Properties](#cluster-wide-properties)
* [Java Args](#java-args)
* [System Properties](#system-properties)
* [Diskless Configuration](#diskless-configuration)
* [Gateway Bundles](#bundle-configuration)
* [Bootstrap Script](#bootstrap-script)
* [Custom Health Checks](#custom-health-checks)
* [Custom Configuration Files](#custom-configuration-files)
* [Logs & Audit Configuration](#logs--audit-configuration)
* [Graceful Termination](#graceful-termination)
* [Autoscaling](#autoscaling)
* [Pod Disruption Budgets](#pod-disruption-budgets)
* [RBAC Parameters](#rbac-parameters)
* [Service Metrics Demo](#service-metrics-demo)
* [SubChart Configuration](#subchart-configuration)



## Installing the Chart
Check out [this guide](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw-10-1/learning-center/thinking-in-kubernetes/hands-on-gateway-deployment-in-kubernetes.html) for more in-depth instruction
```
$ helm repo add layer7 https://caapim.github.io/apim-charts/
$ helm repo update
$ helm install my-ssg --set-file "license.value=path/to/license.xml" --set "license.accept=true" layer7/gateway
```
## Upgrading the Chart
To upgrade your Gateway Release
```
$ helm upgrade my-ssg --set-file "license.value=path/to/license.xml" --set "license.accept=true" layer7/gateway
```
## Uninstalling the Chart
To uninstall the Gateway Chart

```
$ helm uninstall <release name> -n <release namespace>
```

## Custom values
To make sure that your custom values don't get overwritten by a pull, create your own values.yaml (myvalues.yaml..) then specify -f myvalues.yaml when deploying/upgrading

## Note on custom values
You only need to include the values you wish to change in your myvalues.yaml

For example, you wish to deploy the Gateway Chart as is without a database. Your myvalues.yaml would then contain the following
```
database:
  enabled: false
  create: false
```

## Configuration
The following table lists the configurable parameters of the Gateway chart and their default values. See values.yaml for additional parameters and info

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `nameOverride`                | Name override   | `nil` |
| `fullnameOverride`                      | Full name override                       | `nil`                                                     |
| `global.schedulerName`                      | Override the default scheduler | `nil` |
| `license.value`          | Gateway license file | `nil`  |
| `license.accept`          | Accept Gateway license EULA | `false`  |
| `disklessConfig.enabled` | Enable diskless configuration | `true` |
| `disklessConfig.existingSecret` | existing node.properties secret mount configuration | `{}` |
| `disklessConfig.existingSecret.name` | existing secret containing node.properties | `gateway-secret` |
| `disklessConfig.existingSecret.csi` | csi configuration for the [secret store csi driver](https://secrets-store-csi-driver.sigs.k8s.io/) | `commented out` |
| `image.registry`    | Image Registry               | `docker.io` |
| `image.repository`          | Image Repository  | `caapim/gateway`  |
| `image.tag`          | Image tag | `11.0.00`  |
| `image.pullPolicy`          | Image Pull Policy | `IfNotPresent`  |
| `imagePullSecret.enabled`          | Configures Gateway Deployment to use imagePullSecret, you can also leave this disabled and associate an image pull secret with the Gateway's Service Account | `false`  |
| `imagePullSecret.existingSecretName`          | Point to an existing Image Pull Secret | `commented out`  |
| `imagePullSecret.username`          | Registry Username | `nil`  |
| `imagePullSecret.password`          | Registry Password | `nil`  |
| `additionalAnnotations`          | Additional Annotations apply to all deployed objects | `{}`  |
| `additionalLabels`          | Additional Labels apply to all deployed objects | `{}`  |
| `podLabels`          | Pod Labels for the Gateway Pod | `{}`  |
| `podAnnotations`          | Pod Annotations apply to the Gateway Pod | `{}`  |
| `replicas`                   | Number of Gateway replicas        | `1`                                                          |
| `updateStrategy.type`             | Deployment Strategy                       | `RollingUpdate`                                              |
| `updateStrategy.rollingUpdate.maxSurge`             | Rolling Update Max Surge                       | `1`                                              |
| `updateStrategy.rollingUpdate.maxUnavailable`             | Rolling Update Max Unavailable                       | `0`                                              |
| `clusterHostname`          | Gateway Cluster Hostname  | `my.localdomain`  |
| `existingGatewaySecretName`          | Existing Secret that contains management credentials, see values.yaml for what must be included  | `commented out`  |
| `clusterPassword`          | Cluster Password, used if db backed  | `mypassword`  |
| `management.enabled`          | Enable/Disable Policy Manager access | `true`  |
| `management.restman.enabled`          | Enable/Disable the Rest Management API (Restman) | `false`  |
| `management.username`          | Policy Manager Username | `admin`  |
| `management.password`          | Policy Manager Password | `mypassword`  |
| `management.kubernetes.loadServiceAccountToken`    | Automatically load the Gateway Deployment's ServiceAccount Token for querying the Kubernetes API | `false`  |
| `database.enabled`          | Run in DB Backed or Ephemeral Mode | `true`  |
| `database.create`          | Deploy the MySQL stable deployment as part of this release | `true`  |
| `database.username`          | Database Username | `gateway`  |
| `database.password`          | Database Password | `mypassword`  |
| `database.liquibaseLogLevel`          | Liquibase log level | `off`  |
| `database.name`          | Database name | `ssg`  |
| `tls.useSignedCertificates`          | Enable/Disable use of your own TLS Certificate, this ovverides the Gateway's defaultSSLKey | `false`  |
| `tls.existingSecretName`          | Existing Secret that contains TLS p12 container and pass, see values.yaml for what must be included | `commented out`  |
| `tls.key`          | p12 container - this can be set with --set-file tls.key=/path/to/tls.p12 | `nil`  |
| `tls.pass`          | p12 container password - this cannot be empty | `nil`  |
| `config.heapSize`          | Java Heap Size | `2g`  |
| `config.minHeapSize`          | Java Min Heap Size | `1g`  |
| `config.maxHeapSize`          | Java Max Heap Size | `3g`  |
| `config.javaArgs`          | Additional Java Args to pass to the SSG process | `see values.yaml`  |
| `config.log.override`          | Override the standard log configuration | `true`  |
| `config.log.properties`          | Custom logging properties | `see values.yaml`  |
| `config.cwp.enabled`          | Enable/Disable settable cluster-wide properties | `false`  |
| `config.cwp.properties`          | Set name/value pairs of cluster-wide properties | `see values.yaml`  |
| `config.sytemProperties`          | Configure the Gateway's system.properties file | `see values.yaml`  |
| `additionalEnv`          | Additional environment variables you wish to pass to the Gateway Configmap | `see values.yaml`  |
| `additionalSecret`          | Additional secret variables you wish to pass to the Gateway Secret | `see values.yaml`  |
| `bundle.enabled`          | Creates a configmap with bundles from the ./bundles folder | `false`  |
| `bundle.path`          | Specify the path to the bundle files. The bundles folder in this repo has some example bundle files | `"bundles/*.bundle"`  |
| `existingBundle.enabled`          | Enable mounting existing configMaps/Secrets that contain Layer7 Gateway Bundles - see values.yaml for more info | `false`  |
| `existingBundle.configMaps`          | Array of configMaps that will be mounted to the Gateway's bootstrap folder | `see values.yaml`  |
| `existingBundle.secrets`          | Array of Secrets that will be mounted to the Gateway's bootstrap folder  | `see values.yaml`  |
| `customHosts.enabled`          | Enable customHosts on the Gateway, this overrides /etc/hosts.  | `see values.yaml`  |
| `customHosts.hostAliases`          | Array of hostAliases to add to the Container Gateway  | `see values.yaml`  |
| `service.type`    | Service Type               | `LoadBalancer` |
| `service.loadbalancer`    | Additional Loadbalancer Configuration               | `see https://kubernetes.io/docs/tasks/access-application-cluster/configure-cloud-provider-firewall/#restrict-access-for-loadbalancer-service` |
| `service.ports`    | List of http external port mappings               | https: 8443 -> 8443, management: 9443->9443 |
| `service.annotations`    | Additional annotations to add to the service               | {} |
| `service.internalTrafficPolicy`    | [Internal Traffic Policy](https://kubernetes.io/docs/concepts/services-networking/service-traffic-policy/#using-service-internal-traffic-policy)               | `Cluster` |
| `service.externalTrafficPolicy`    | [External Traffic Policy](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip)               | `Cluster` |
| `ingress.enabled`    | Enable/Disable an ingress record being created               | `false` |
| `ingress.annotations`    | Additional ingress annotations               | `{}` |
| `ingress.hostname`    | Sets Ingress Hostname  | `nil` |
| `ingress.port`    | The Gateway Port number/name to route to  | `8443` |
| `ingress.tlsHostnames`    | Register additional Hostnames for the TLS Certificate  | `see values.yaml` |
| `ingress.secretName`    | The name of an existing Cert secret, setting this does not auto-create the secret               | `tls-secret` |
| `ingress.additionalHostnamesAndPorts`    | key/value pairs of hostname:port that will be added to the ingress object  | `see values.yaml` |
| `startupProbe.enabled`    | Enable/Disable               | `false` |
| `startupProbe.initialDelaySeconds`    | Initial delay               | `60` |
| `startupProbe.timeoutSeconds`    | Timeout               | `1` |
| `startupProbe.periodSeconds`    | Frequency               | `10` |
| `startupProbe.successThreshold`    | Success Threshold               | `1` |
| `startupProbe.failureThreshold`    | Failure Threshold               | `10` |
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
| `nodeSelector`    | [Node Selector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)              | `{}` |
| `affinity`    | [Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)             | `{}` |
| `topologySpreadConstraints`    | [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#spread-constraints-for-pods)             | `[]` |
| `tolerations`    | [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)              | `[]` |
| `podSecurityContext`    | [Pod Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)              | `[]` |
| `containerSecurityContext`    | [Container Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)          | `{}` |
| `bootstrap.script.enabled`    | Enable the bootstrap script              | `false` |


[Back to Additional Guides](#additional-guides)

## Port Configuration
There are two types of port configuration available in the Gateway Helm Chart that are configured in the following ways

### Container/Service Level Ports

### Default Gateway Service
Sample entry that exposes 8443 which is one of the default TLS port on the API Gateway using service type LoadBalancer.
```
service:
  type: LoadBalancer
  annotations: {}
  ports:
    - name: https
      internal: 8443
      external: 8443
      protocol: TCP
```

### Production Values Default
Sample entry that exposes 8443 which is one of the default TLS ports on the API Gateway
Note that the service type is ClusterIP which does not receive an external IP address. We can make this service accessible by configuring an [ingress resource](#ingress-configuration).

```
service:
  type: ClusterIP
  annotations: {}
  ports:
    - name: https
      internal: 8443
      external: 8443
      protocol: TCP
```
### Gateway Management Service
The Gateway Management Service is primarily used to expose Gateway Ports that you wish to use for Internal Management Access for tools like Policy Manager. This Service requires the [PM Tagger](#pm-tagger) to function correctly.

```
management:
...
  service:
    enabled: true
    type: LoadBalancer
    annotations: {}
      # cloud.google.com/load-balancer-type: "Internal"
      # service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    ports:
      - name: management
        internal: 9443
        external: 9443
        protocol: TCP
```

[Back to Additional Guides](#additional-guides)

### OTK install or upgrade
OTK can be install or upgrade gateway.  Supports SINGLE, INTERNAL and DMZ types of OTK installations on db backed gateway. On ephermal gateway only SINGLE mode is supported.

- On a database backed gateway, once gateway is healthy, k8s kind/job is used to install OTK using Restman ([OTK Headless installation](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-6/installation-workflow/install-the-oauth-solution-kit/headless-installation-of-otk-solution-kit.html))
- On a Ephemeral gateway, before the start of gateway, initContainer is used to bootstrap gateway with OTK sub-solution kits.
- On a Ephemeral or database backed gateway, before the start of gateway, k8s job to used to install/update the OTK database (Cassandra database is not supported and should be upgraded [manually](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-6/installation-workflow/create-or-upgrade-the-otk-database.html))

***NOTE: In dual gateway installation, restart the pods after OTK install or upgrade is required.***

Prerequisites:
* Configure cluster wide property for otk.port pointing to gateway ingress port and OTK database type.
```
config:
  cwp:
    enabled: true
    properties:
      - name: otk.port
        value: 443
      - name: otk.dbsystem
        value: mysql
```
* Restman is enabled. Can be disabled once the install/upgrage is complete.
  * This is not applicable for ephemeral GW
```
management:
  restman:
    enabled: true
```

Limitations:
* OTK Instance modifiers are not supported.
* Install/Upgrade of OTK schema on cassandra database using kubernetes job is not supported.
* Dual gateway OTK set-up (otk.type: DMZ or INTERNAL) is not supported with ephemeral gateway.
* OTK upgrade to 4.6.3 will not upgrade the DB with utf8mb4 character set. This has to be done seperately following the steps provided in upgrade section in [Techdocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-6/installation-workflow/create-or-upgrade-the-otk-database/mysql-database.html)

OTK Deployment examples can be found [here](/examples/otk)


| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `otk.enabled`                     | Enable/Disable OTK installation or upgrade | `false`  |
| `otk.type`                        | OTK installation type - SINGLE, DMZ or INTERNAL | `SINGLE`
| `otk.forceInstallOrUpgrade`       | Force install or upgrade by uninstalling existing otk soluction kit and install. | false
| `otk.enablePortalIntegration`      | Not applicable for DMZ and INTERNAL OTK types | `false`
| `otk.skipPostInstallationTasks`   | Skip post installation tasks for OTK type INTERNAL and DMZ <br/>Internal Gateway: <br/> - #OTK Client Context Variables <br/> - #OTK id_token configuration <br/>DMZ Gateway: <br/> - #OTK OVP Configuration<br/> - #OTK Storage Configuration | `false`
| `otk.skipInternalServerTools`     | Skip installation of the optional sub soluction Kit: Internal, Server Tools.<br/> The Oauth Manager & Oauth Test Client will not be installed  | `false`
| `otk.internalGatewayHost`         | Internal gateway host for OTK type DMZ|
| `otk.internalGatewayPort`         | Internal gateway post for OTK type DMZ|
| `otk.dmzGatewayHost`              | DMZ gateway host for OTK type INTERNAL|
| `otk.networkMask`                 | Network mask used in the 'Restrict Access to IP Address Range Assertion' to protect the schedule jobs and health checks.| `16` |
| `otk.startIP`                 | Start IP used in the 'Restrict Access to IP Address Range Assertion' to protect the schedule jobs and health checks.| `240.224.2.1` |
| `otk.cert.dmzGatewayCert`         | DMZ gateway certificate (encoded) for OTK type DMZ            |
| `otk.cert.internalGatewayIssuer`  | DMZ gateway certificate issuer for OTK type DMZ               |
| `otk.cert.dmzGatewaySerial`       | DMZ gateway certificate serial for OTK type DMZ               |
| `otk.cert.dmzGatewaySubject`      | DMZ gateway certificate subject for OTK type DMZ              |
| `otk.cert.internalGatewayCert`    | INTERNAL gateway certificate (encoded) for OTK type INTERNAL  |
| `otk.cert.internalGatewayIssuer`  | INTERNAL gateway certificate issuer for OTK type INTERNAL     |
| `otk.cert.internalGatewaySerial`  | INTERNAL gateway certificate serial for OTK type INTERNAL     |
| `otk.cert.internalGatewaySubject` | INTERNAL gateway certificate subject for OTK type INTERNAL    |
| `otk.customizations.existingBundle.enabled` | Enable mounting existing configMaps/Secrets that contain OTK Bundles - see values.yaml for more info | `false`  |
| `otk.dmzGatewayPort`              | DMZ gateway port for OTK type INTERNAL|
| `otk.subSolutionKitNames`         | List of comma seperated sub soluction Kits to install or upgrade. |
| `otk.job.image.repository`        | Image Repositor | `caapim/otk-install`
| `otk.job.image.tag`               | Image Tag. (OTK version) | `4.6`
| `otk.job.image.pullPolicy`        | Image Pull Policy | `IfNotPresent`
| `otk.job.image.labels`            | Job lables | {}
| `otk.job.image.nodeSelector`      | Job Node selector | {}
| `otk.job.image.tolerations`       | Job tolerations | []
| `otk.job.podLabels`               | OTK Job podLabels | {}
| `otk.job.podAnnotations`          | OTK Job podAnnotations | {}
| `otk.job.resources`               | OTK Job resources | {}
| `otk.job.scheduledTasksSuccessfulJobsHistoryLimit`| OTK db maintenance scheduled job success history limit | `1` |
| `otk.job.scheduledTasksFailedJobsHistoryLimit`| OTK db maintenance scheduled job failed history limit | `1` |
| `otk.bootstrapDir`| The location of OTK artifacts in the image | `/opt/SecureSpan/Gateway/node/default/etc/bootstrap/bundle/000OTK` |
| `otk.database.type`               | OTK database type - mysql/oracle/cassandra | `mysql`
| `otk.database.waitTimeout`        | OTK database connection wait timeout in seconds  | `60`|
| `otk.database.dbUpgrade`          | Enable/Disable OTK DB Upgrade| `true` |
| `otk.database.useDemoDb`          | Enable/Disable OTK Demo DB | `true` |
| `otk.database.sql.createTestClients`   | Enable/Disable creation of demo test clients | `false` |
| `otk.database.sql.testClientsRedirectUrlPrefix`   | The value of redirect_uri prefix (Example: https://test.com:8443) Required if createTestClients is `true`  | |
| `otk.database.changeLogSync`      | If using existing non liquibase OTK DB then perform manual OTK DB upgrade and set 'changeLogSync' to true. <br/> This is a onetime activity to initialize liquibase related tables on OTK DB. Set to false for successive helm upgrade. | `false`|
| `otk.database.updateConnection`   | Update database connection properties during helm upgrade | `true`|
| `otk.database.connectionName`     | OTK database connection name | `OAuth`
| `otk.database.existingSecretName` | Point to an existing OTK database Secret |
| `otk.database.username`           | OTK database user name |
| `otk.database.password`           | OTK database password |
| `otk.database.properties`         | OTK database additional properties  | `{}`
| `otk.database.sql.ddlUsername`        | OTK database user name used for OTK DB creation |
| `otk.database.sql.ddlPassword`        | OTK database password used for OTK DB creation |
| `otk.database.sql.type`           | OTK database type (mysql/oracle/cassandra) | `mysql`
| `otk.database.sql.jdbcURL`        | OTK database sql jdbc URL (oracle/mysql) |
| `otk.database.sql.jdbcDriverClass`| OTK database sql driver class name (oracle/mysql) |
| `otk.database.sql.databaseName`   | OTK database Oracle database name or Demo db name |
| `otk.database.sql.connectionProperties`| OTK database mysql connection properties (oracle/mysql)  | `{}`
| `otk.database.readOnlyConnection.enabled`   | Enable/Disable OTK read only database connection   | `false` |
| `otk.database.readOnlyConnection.connectionName` | OTK read only database connection name  | `OAuth_ReadOnly` |
| `otk.database.readOnlyConnection.existingSecretName` | Point to an existing OTK read only database Secret |
| `otk.database.readOnlyConnection.username`  | OTK read only database user name|
| `otk.database.readOnlyConnection.password`  | OTK read only database password |
| `otk.database.readOnlyConnection.properties` | OTK read only database additional properties  | `{}` |
| `otk.database.readOnlyConnection.jdbcURL`   | OTK read only database sql jdbc URL (oracle/mysql) |
| `otk.database.readOnlyConnection.jdbcDriverClass` | OTK read only database sql driver class name (oracle/mysql)  |
| `otk.database.readOnlyConnection.connectionProperties`| OTK read only database mysql connection properties (oracle/mysql)  | `{}`
| `otk.database.readOnlyConnection.databaseName` | OTK read only Oracle database name |
| `otk.database.cassandra.connectionPoints`  | OTK database cassandra connection points (comma seperated)  |
| `otk.database.cassandra.port`              | OTK database cassandra connection port  |
| `otk.database.cassandra.keyspace`          | OTK database cassandra keyspace |
| `otk.database.cassandra.driverConfig`      | OTK database cassandra driver config (Gateway 11+) | `{}`
| `otk.healthCheckBundle.enabled`            | Enable/Disable installation of OTK health check service bundle | `false`
| `otk.healthCheckBundle.useExisting`        | Use exising OTK health check service bundle | `false`
| `otk.healthCheckBundle.name`               | OTK health check service bundle name | `otk-health-check-bundle-config`
| `otk.livenessProbe.enabled`                | Enable/Disable. Requires otk.healthCheckBundle.enabled set to true and OTK version >= 4.6.1. Valid only for SINGLE and INTERNAL OTK type installation. | `true`
| `otk.livenessProbe.type`                   |  | `httpGet`
| `otk.livenessProbe.httpGet.path`           |  | `/auth/oauth/health`
| `otk.livenessProbe.httpGet.port`           |  | `8443`
| `otk.readinessProbe.enabled`               | Enable/Disable. Requires otk.healthCheckBundle.enabled set to true and OTK version >= 4.6.1. Valid only for SINGLE and INTERNAL OTK type installation.  | `true`
| `otk.readinessProbe.type`                  |  | `httpGet`
| `otk.readinessProbe.httpGet.path`          |  | `/auth/oauth/health`
| `otk.readinessProbe.httpGet.port`          |  | `8443`

#### Note:
* In case of ephemeral GW instances where there only updates to OTK, it should be done using Helm --force option

[Back to Additional Guides](#additional-guides)

### Gateway Application Ports
Once you have decided on which container ports you would like to expose, you need to create the corresponding ports on the API Gateway. *These will need match the corresponding service and management service ports above.*

This configuration creates and mounts a gateway bundle,
if you wish to maintain Gateway ports outside of the Gateway Chart you can either use Policy Manager or create and mount your own bundle in the existingBundle section.

By default the following ports are created
- 8080 (HTTP - disabled)
- 8443 (HTTPS - Published service message input only)
- 9443 (HTTPS - Published service message input only, Administrative access, Browser-based administration, Built-in services)

Things to note before you get started:
- If you are deploying the Gateway with a fresh MySQL database
  - This port configuration will replace the defaults.
- If you are using an existing database
  - Named ports will be updated. Ports not configured in this list (like 2124 - internode communication) will remain.

```
config:
...
  listenPorts:
    custom:
      enabled: true
    ports:
      - name: Default HTTPS (8443)
        port: 8443

        enabled: true
        protocol: HTTPS
        managementFeatures:
        - Published service message input
        # - Administrative access
        # - Browser-based administration
        # - Built-in services
        properties:
        - name: server
          value: A
        tls:
          enabled: true
        # privateKey: 00000000000000000000000000000002:ssl
          clientAuthentication: Optional
          versions:
          #- TLSv1.0
          #- TLSv1.1
          - TLSv1.2
          - TLSv1.3
          useCipherSuitesOrder: true
          cipherSuites:
          - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
          - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          - TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
          - TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
          - TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
          - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
          - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
          - TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
          - TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
          - TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
          - TLS_AES_256_GCM_SHA384
          - TLS_AES_128_GCM_SHA256
        # - TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
        # - TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
        # - TLS_DHE_RSA_WITH_AES_256_CBC_SHA256
        # - TLS_DHE_RSA_WITH_AES_256_CBC_SHA
        # - TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
        # - TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384
        # - TLS_DHE_RSA_WITH_AES_128_CBC_SHA256
        # - TLS_DHE_RSA_WITH_AES_128_CBC_SHA
        # - TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384
        # - TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384
        # - TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384
        # - TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384
        # - TLS_ECDH_RSA_WITH_AES_256_CBC_SHA
        # - TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA
        # - TLS_RSA_WITH_AES_256_GCM_SHA384
        # - TLS_RSA_WITH_AES_256_CBC_SHA256
        # - TLS_RSA_WITH_AES_256_CBC_SHA
        # - TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256
        # - TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256
        # - TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256
        # - TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256
        # - TLS_ECDH_RSA_WITH_AES_128_CBC_SHA
        # - TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA
        # - TLS_RSA_WITH_AES_128_GCM_SHA256
        # - TLS_RSA_WITH_AES_128_CBC_SHA256
        # - TLS_RSA_WITH_AES_128_CBC_SHA
```

[Back to Additional Guides](#additional-guides)

### Ingress Configuration
The Gateway Helm Chart allows you to configure an Ingress Resource that your central Ingress Controller can manage. You can find more information on [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) here.

This represents the ingress configuration for Gateway Chart < 3.0.0 you need to configure an Ingress Resource for the API Gateway

```
ingress:
  enabled: true
  annotations:
  # Ingress class
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  # nginx.ingress.kubernetes.io/ssl-passthrough: "true"
  secretName: tls-secret
  hostname: dev.ca.com
  tlsHostnames: []
  # - dev.ca.com
  # - dev1.ca.com
  ## The port that you want to route to via ingress. This needs to be available via service.ports.
  port: 8443
  ## Define additional hostnames and ports as key-value pairs.
  additionalHostnamesAndPorts: {}
```

New Ingress Configuration Gateway Chart >= 3.0.0
```
ingress:
  enabled: true
  # Ingress Class Name
  ingressClassName: nginx
  # Ingress annotations
  annotations:
  # Ingress class
   # kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  # nginx.ingress.kubernetes.io/ssl-passthrough: "true"
  # When the ingress is enabled, a host pointing to this will be created
  # By default clusterHostname is used, only set this if you want to use a different host
   ## Enable TLS configuration for the hostname defined at ingress.hostname/clusterHostname parameter
  tls:
  - hosts:
    - dev.ca.com
    secretName: tls-secret-1
#  - hosts:
#    - dev1.ca.com
#    secretName: tls-secret-2

  rules:
   - host: dev.ca.com
     path: "/"
     service:
       port:
         name: https
         #number:
#   - host: dev1.ca.com
#     path: "/"
#     service:
#       port:
#         name: anotherport
#        #number:
```

[Back to Additional Guides](#additional-guides)

### PM Tagger Configuration
[PM (Policy Manager) Tagger](https://github.com/gvermeulen7205/pm-tagger) is a lightweight go application that works in conjunction with the management service to provide a stable connection to your container gateway via Policy Manager.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `pmtagger.enabled`          | Enable pm-tagger | `false`  |
| `pmtagger.replicas`          | Replicas (you should never need more than one | `1`  |
| `pmtagger.image.registry`          | Image Registry | `docker.io`  |
| `pmtagger.image.repository`          | Image Repository | `layer7api/pm-tagger`  |
| `pmtagger.image.tag`          | Image Tag | `1.0.1`  |
| `pmtagger.image.pullPolicy`          | Image Pull Policy | `IfNotPresent`  |
| `pmtagger.image.imagePullSecret.enabled`                | Use Image Pull secret - this uses the image pull secret configured for the API Gateway   | `false` |
| `pmtagger.resources`                | Resources   | `see values.yaml` |
| `pmtagger.podLabels`          | Pod Labels for the Gateway Pod | `{}`  |
| `pmtagger.podAnnotations`          | Pod Annotations apply to the Gateway Pod | `{}`  |
| `pmtagger.nodeSelector`    | [Node Selector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)              | `{}` |
| `pmtagger.affinity`    | [Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)             | `{}` |
| `pmtagger.topologySpreadConstraints`    | [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#spread-constraints-for-pods)             | `[]` |
| `pmtagger.tolerations`    | [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)              | `[]` |
| `pmtagger.podSecurityContext`    | [Pod Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)              | `[]` |
| `pmtagger.containerSecurityContext`    | [Container Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)          | `{}` |

[Back to Additional Guides](#additional-guides)

### OpenTelemetry Configuration
The Gateway from v11.1.00 can be configured to send telemetry to Observability backends [that support OpenTelemetry](https://opentelemetry.io/ecosystem/vendors/). Please see [Techdocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/11-1/install-configure-upgrade/configuring-opentelemetry-for-the-gateway.html) for more details about this integration.

This feature is a ***preview feature*** for v11.1.00 and is ***intentionally disabled*** by default. As with any integration that generates telemetry, there is a performance drop when turning on the OpenTelemetry integration with all of the features enabled.

There is an integration example available [here](https://github.com/Layer7-Community/Integrations/tree/main/grafana-stack-prometheus-otel) that details how to deploy and configure an observability backend to use with the Gateway.
- You are ***not required*** to use the observability stack that we provide as an example.
- The observability stack that we provide ***is not*** production ready and should be used solely as an example or reference point.
- OpenTelemetry is supported by [numerous vendors](https://opentelemetry.io/ecosystem/vendors/)

***NOTE: *** In our example we inject the OpenTelemetry Java Agent to the Container Gateway, this emits additional telemetry like JVM metrics. The Gateway has the OpenTelemetry SDK built-in making the OpenTelemetry Java Agent Optional, the key difference between the built-in SDK and the OTel Agent is that the SDK only captures Gateway application level traces and metrics, things like JVM metrics will not be captured in this mode.

#### Gateway OTel Configuration
OpenTelemetry is configured on the Gateway in two places, system properties and cluster-wide Properties. The configuration below represents the minimal settings required to enable the built-in SDK and configure the Gateway to send telemetry to an OpenTelemetry Collector.

These can be configured in values.yaml. See the section below to view examples of how and where to configure this.

- system.properties
```
otel.sdk.disabled=false
otel.java.global-autoconfigure.enabled=true
otel.service.name=ssg-gateway
otel.exporter.otlp.endpoint=http://localhost:4318/
otel.exporter.otlp.protocol=http/protobuf
otel.traces.exporter=otlp
otel.metrics.exporter=otlp
otel.logs.exporter=none
```
- cluster-wide properties
```
otel.enabled=true
otel.serviceMetricEnabled=true
otel.traceEnabled=true (if tracing is required)
otel.traceConfig=(default {})
```
example otel.traceConfig
```
{
  "services": [
    {
      "resolutionPath": ".*test_otel_service.*"
    }
  ],
  "assertions": {
    "exclude": [
      "Decode MTOM Message"
    ]
  },
  "contextVariables": {
    "exclude": [
      ".*mypassword.*"
    ]
  }
}
```

[Back to Additional Guides](#additional-guides)

##### Gateway OTel Examples (with or without the Optional Agent)
The integration example [here](https://github.com/Layer7-Community/Integrations/tree/main/grafana-stack-prometheus-otel) contains two Gateway examples (values.yaml overrides) that are configured to use the SDK only approach ***or*** include the Optional OTel Java Agent. There are two Grafana Dashboards included that show the differences in the telemetry that emitted from the Gateway.
- [SDK only, no agent](https://github.com/Layer7-Community/Integrations/tree/main/grafana-stack-prometheus-otel/gateway-example/gateway-sdk-only-values.yaml)
- [Agent](https://github.com/Layer7-Community/Integrations/tree/main/grafana-stack-prometheus-otel/gateway-example/gateway-otel-java-agent-values.yaml)

[Back to Additional Guides](#additional-guides)

### Redis Configuration
This enables integration with [Redis](https://redis.io/). The following sections configure a redis configuration file on the Gateway. The following properties in config.systemProperties will need to be updated.

**Important Note** The latest version of this chart uses a new format for Redis configuration that will simplify configuring additional shared state providers in the future. Please view [shared state provider config](#shared-state-provider-config) for more details. This is only compatible with Gateway v11.1.1.

Comment out the following
```
# com.l7tech.server.extension.sharedKeyValueStoreProvider=embeddedhazelcast
# com.l7tech.server.extension.sharedCounterProvider=ssgdb
```
Uncomment the following
```
# com.l7tech.server.extension.sharedKeyValueStoreProvider=redis
# com.l7tech.server.extension.sharedCounterProvider=redis
# com.l7tech.server.extension.sharedRateLimiterProvider=redis
# com.l7tech.external.assertions.keyvaluestore.sharedKeyValueStoreProvider=redis
# com.l7tech.external.assertions.keyvaluestore.storeIdList=GW_STORE_ID
```

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `config.redis.enabled`          | Enable redis configuration | `false`  |
| `config.redis.subChart.enabled`          | Deploy the redis subChart | `true`  |
| `config.redis.additionalProviders`          | Configure additional Redis connections | `[]`  |
| `config.redis.groupName`          | Redis Group name | `l7GW`  |
| `config.redis.commandTimeout`          | Redis Command Timeout | `5000`  |
| `config.redis.connectTimeout`          | Redis Connect Timeout | `10000`  |
| `config.redis.testOnStart`          | Test the connection to Redis during Gateway start. If the conection fails and this is true, the Gateway will not start | `false`  |
| `config.redis.auth.enabled`          | Use auth for Redis | `false`  |
| `config.redis.auth.username`          | Redis username | ``  |
| `config.redis.auth.password.encoded`          | Password is encoded | `false`  |
| `config.redis.auth.password.value`          | Redis password | `mypassword`  |
| `config.redis.sentinel.enabled`                | Enable sentinel configuration   | `true` |
| `config.redis.sentinel.masterSet`          | Redis Master set | `mymaster`  |
| `config.redis.sentinel.nodes`          | Array of sentinel nodes host and port | `[]`  |
| `config.redis.standalone.host`                | Redis host if sentinel is not enabled   | `redis-standalone` |
| `config.redis.standalone.port`                | Redis port if sentinel is not enabled   | `6379` |
| `config.redis.tls.enabled`    | Enable SSL/TLS              | `false` |
| `config.redis.tls.existingSecret`    | Use an existing secret - must contain a key called tls.crt        | `` |
| `config.redis.tls.verifyPeer`    | Verify Peer             | `true` |
| `config.redis.tls.redisCrt`    | Redis Public Cert            | `` |


#### Creating your own Redis Configuration
Please refer to [Techdocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw-11-0/install-configure-upgrade/connect-to-an-external-redis-datastore.html) for more context on the available configuration options

#### Note
The Gateway supports Redis master auth only. The Gateway will not be able to connect to Redis if your Sentinel nodes have passwords. Please refer to the notes in values.yaml for details on config.redis.auth and redis.auth (subChart)

##### Redis Sentinel (11.1.1)
sharedstate_client.yaml
```
redis:
  default:
    type: sentinel
    keyPrefixGroupName: test
    username: redisuser
    #password: "redispassword"
    encodedPassword: "redisencodedpassword"
    commandTimeout: 5000
    connectTimeout: 10000
    testOnStart: false
    sentinel:
      master: mymaster
      nodes:
      - host: node1
        port: 26379
      - host: node2
        port: 26379
      - host: node3
        port: 26379
```

##### Redis Standalone (11.1.1)
sharedstate_client.yaml
```
redis:
  default:
    type: standalone
    keyPrefixGroupName: test
    username: redisuser
    #password: "redispassword"
    encodedPassword: "redisencodedpassword"
    commandTimeout: 5000
    connectTimeout: 10000
    testOnStart: false
    standalone:
      host: redis-standalone
      port: 6379
    ssl:
      enabled: true
      cert: host.cert
      verifyPeer: false
```

##### Redis Sentinel (11.0.00_CR2 and 11.1.00)
redis.properties
```
# Redis type can be sentinel or standalone
 redis.type=sentinel
 redis.sentinel.nodes=node1:26379,node2:26379,node3:26379
## Credentials are optional
 redis.sentinel.username=redisuser
# Password can be plaintext or encoded
 redis.sentinel.password=redispassword
 redis.sentinel.encodedPassword=redisencodedpassword
# SSL is optional
 redis.ssl=true
 redis.ssl.cert=redis.crt
 redis.ssl.verifypeer=true
# Additional Config
 redis.key.prefix.grpname=l7GW
 redis.commandTimeout=5000
 ```

##### Redis Standalone (11.1.00)
**Gateway Chart v3.0.30 onwards only supports Gateway 11.1.1 and later for Redis** if you are not upgrading to Gateway v11.1.1 please specify the --version flag when installing or upgrading your release.
The Gateway supports SSL/TLS and Authentication when connecting to a standalone Redis instance. This configuration should only be used for development purposes

redis.properties
```
# Redis type can be sentinel or standalone
 redis.type=standalone
 redis.hostname=redis-standalone
## Credentials are optional
 redis.standalone.username=redisuser
 redis.standalone.password=redispassword
 redis.standalone.encodedPassword=redisencodedpassword
 redis.port=6379
# SSL is optional
 redis.ssl=true
 redis.ssl.cert=redis.crt
 redis.ssl.verifypeer=true
# Additional Config
 redis.key.prefix.grpname=l7GW
 redis.commandTimeout=5000
 ```

##### Redis Standalone (11.0.00_CR2)
**Gateway Chart v3.0.30 onwards only supports Gateway 11.1.1 and later for Redis** if you are not upgrading to Gateway v11.1.1 please specify the --version flag when installing or upgrading your release.
The Gateway does not support SSL/TLS or Authentication when connecting to a standalone Redis instance. This configuration should only be used for development purposes

redis.properties
```
# Redis type can be sentinel or standalone
# standalone does not support SSL or Auth
 redis.type=standalone
 redis.hostname=redis-standalone
 redis.port=6379
 redis.key.prefix.grpname=l7GW
 redis.commandTimeout=5000
 ```

##### Create a secret from this configuration (11.1.1)
```
kubectl create secret generic shared-state-provider-secret --from-file=sharedstate_client.yaml=/path/to/sharedstate_client.yaml
```
my-values.yaml
```
config:
  sharedStateClient:
    enabled: true
    existingConfigSecret: shared-state-provider-secret
```

##### Create a secret from this configuration (11.0.00_CR2 and 11.1.00)
**Gateway Chart v3.0.30 onwards only supports Gateway 11.1.1 and later for Redis** if you are not upgrading to Gateway v11.1.1 please specify the --version flag when installing or upgrading your release.
```
kubectl create secret generic redis-config-secret --from-file=redis.properties=/path/to/redis.properties
```
my-values.yaml
```
redis:
    enabled: true
    existingConfigSecret: redis-config-secret
```

[Back to Additional Guides](#additional-guides)

### Shared State Provider Config
Shared State Providers from Gateway v11.1.1 onwards simplifies the configuration required to connect to providers like Redis. This is currently limited to Redis.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `config.sharedStateProvider.enabled`          | Enable redis configuration | `false`  |
| `config.sharedStateProvider.existingConfigSecret`          | Use an existing config secret - must contain a key called sharedstate_client.yaml | `sharedstate-client-secret`  |
| `config.sharedStateProvider.additionalProviders`          | Configure additional shared state providers - example in values.yaml | `[]`  |

### Database Configuration
You can configure the deployment to use an external database (this is the recommended approach - the included MySQL SubChart is not supported). In the values.yaml file, set the create field in the database section to false, and set jdbcURL to use your own database server:
```
database:
  enabled: true
  create: false
  jdbcURL: jdbc:mysql://myprimaryserver:3306,mysecondaryserver:3306/ssg?failOverReadOnly=false
  username: myuser
  password: mypassword
  liquibaseLogLevel: "off"
  name: ssg
```
In the above example, two MySQL database servers are specified with myprimaryserver acting as the primary server and mysecondaryserver acting as the secondary server. The failOverReadOnly property is also set to false meaning that the secondary server db is also writable.

When disklessConfig.enabled is false (see [Diskless Configuration](#diskless-configuration)), the following database fields will be ignored:
- jdbcURL
- username
- password

The values will come from node.properties instead. See [External MySQL](#external-mysql) section.

More info on the JDBC URL:
- Connection URL syntax: https://dev.mysql.com/doc/connector-j/5.1/en/connector-j-reference-url-format.html
- Failover config: https://dev.mysql.com/doc/connector-j/5.1/en/connector-j-config-failover.html
- Configuration properties: https://dev.mysql.com/doc/connector-j/5.1/en/connector-j-reference-configuration-properties.html

Configuring SSL/TLS: the following parameters can be added to enable secure communication between the Gateway and an external MySQL Database
- useSSL=true
- requireSSL=true
- verifyServerCertificate=false

```
jdbcURL: jdbc:mysql://myprimaryserver:3306,mysecondaryserver:3306/ssg?useSSL=true&requireSSL=true&verifyServerCertificate=false
```

In order the create the database on the remote server, the provided user in the username field must have write privilege on the database. See GRANT statement usage: https://dev.mysql.com/doc/refman/8.0/en/grant.html#grant-database-privileges

[Back to Additional Guides](#additional-guides)

### Cluster Wide Properties
You can specify cluster-wide properties in values.yaml, you can also use the [bundle](#bundle-configuration) to load your own Gateway Bundles.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `config.cwp.enabled`          | Enable the CWP functionality (mounts a volume) | `false`  |
| `config.cwp.properties`          | Array of Key/Value pairs of cluster-wide properties | `see values.yaml`  |

The default cluster-wide properties are as follows
```
config:
...
  cwp:
    enabled: true
    properties:
      - name: io.httpsHostAllowWildcard
        value: true
      - name: log.levels
        value: |
          com.l7tech.level = CONFIG
          com.l7tech.server.policy.variable.ServerVariables.level = SEVERE
          com.l7tech.external.assertions.odata.server.producer.jdbc.GenerateSqlQuery.level = SEVERE
          com.l7tech.server.policy.assertion.ServerSetVariableAssertion.level = SEVERE
          com.l7tech.external.assertions.comparison.server.ServerComparisonAssertion = SEVERE
      - name: audit.setDetailLevel.FINE
        value: 152 7101 7103 9648 9645 7026 7027 4155 150 4716 4114 6306 4100 9655 150 151 11000 4104
```

[Back to Additional Guides](#additional-guides)

### Java Args
Additional Java Arguments as may be recommended by support can be configured in values.yaml. Gateway v11.1.1 supports two new fields that allows a min and max heap size to be set. If these are not set config.heapSize will take precedence.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `config.heapSize`          | Java Heap Size - this should be a percentage of the memory configured in resources.limits and should be updated together. The default assumes 50%, going above 75% is not recommended | `2G`  |
| `config.minHeapSize`          | Java Min Heap Size - this should be a percentage of the memory configured in resources.limits and should be updated together. The default assumes 25% | `1G`  |
| `config.maxHeapSize`          | Java Max Heap Size - this should be a percentage of the memory configured in resources.limits and should be updated together. The default assumes 75%, going above this is not recommended | `3G`  |
| `config.javaArgs`          | Additional Java Args to pass to the SSG process | `see values.yaml`  |

The default Java Args are as follows
```
config:
  heapSize: "2g"
  minHeapSize: "1g"
  maxHeapSize: "3g"
  javaArgs:
    - -Dcom.l7tech.bootstrap.autoTrustSslKey=trustAnchor,TrustedFor.SSL,TrustedFor.SAML_ISSUER
    - -Dcom.l7tech.server.audit.message.saveToInternal=false
    - -Dcom.l7tech.server.audit.admin.saveToInternal=false
    - -Dcom.l7tech.server.audit.system.saveToInternal=false
    - -Dcom.l7tech.server.audit.log.format=json
    - -Djava.util.logging.config.file=/opt/SecureSpan/Gateway/node/default/etc/conf/log-override.properties
    - -Dcom.l7tech.server.pkix.useDefaultTrustAnchors=true
    - -Dcom.l7tech.security.ssl.hostAllowWildcard=true
```

[Back to Additional Guides](#additional-guides)

### System Properties
Additional System Properties as may be recommended by support can be configured in values.yaml

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `config.systemProperties`          | Gateway System Properties | `see values.yaml`  |

The default systemProperties represent what is currently in the base Gateway image with one added flag

```
Period of time before the Gateway removes inactive nodes.
com.l7tech.server.clusterStaleNodeCleanupTimeoutSeconds=86400
```

The full default is this
```
  systemProperties: |-
    # Default Gateway system properties
    # Configuration properties for shared state extensions.
    com.l7tech.server.extension.sharedKeyValueStoreProvider=embeddedhazelcast
    com.l7tech.server.extension.sharedCounterProvider=ssgdb
    com.l7tech.server.extension.sharedClusterInfoProvider=ssgdb
    # By default, FIPS module will block an RSA modulus from being used for encryption if it has been used for
    # signing, or visa-versa. Set true to disable this default behaviour and remain backwards compatible.
    com.safelogic.cryptocomply.rsa.allow_multi_use=true
    # Specifies the type of Trust Store (JKS/PKCS12) provided by AdoptOpenJDK that is used by Gateway.
    # Must be set correctly when Gateway is running in FIPS mode. If not specified it will default to PKCS12.
    javax.net.ssl.trustStoreType=jks
    # Period of time before the Gateway removes inactive nodes.
    com.l7tech.server.clusterStaleNodeCleanupTimeoutSeconds=86400
    # Additional properties go here
```

[Back to Additional Guides](#additional-guides)

### Diskless Configuration
Refer to [TechDocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw11-1/install-configure-upgrade/configuring-the-container-gateway/environment-variables-for-the-container-gateway.html) for more info. Running without Diskless config is supported from Gateway v11.1.1 onwards. Please make sure disklessConfig.enabled is true (default) if you are using a previous version of the Container Gateway.

**DISKLESS_CONFIG** is a new environment variable that was introduced in Gateway v11.1.1, that allows switching between configuration sources.

This is exposed in the Gateway Helm Chart via the disklessConfig configuration in values.yaml.
- **disklessConfig.enabled: true**
  - Default, No changes.
```
disklessConfig:
  enabled: true
  # existingSecret:
  #   name: gateway-secret
  #   csi: {}
```
- **disklessConfig.enabled: false**
  - The Gateway will be read its configuration from node.properties which is mounted to the container gateway.
    - This facilitates the use of the [secret store csi driver](https://secrets-store-csi-driver.sigs.k8s.io/) to mount configuration.
    - Creates a secret with node.properties by default
      - We **strongly recommend** you create your own node.properties file and make use of disklessConfig.existingSecret configuration.
```
disklessConfig:
  enabled: false
  # existingSecret:
  #   name: gateway-secret
  #   csi: {}
```

#### Creating a node.properties file

##### External MySQL
- Make sure the database configuration matches what is in node.properties

Example: node.properties with MySQL database configuration
```
node.cluster.pass=mypassword
admin.user=admin
admin.pass=mypassword
node.db.config.main.user=gateway
node.db.config.main.pass=mypassword
l7.mysql.connection.url=jdbc:mysql://myprimaryserver:3306,mysecondaryserver:3306/ssg?failOverReadOnly=false&useSSL=true&requireSSL=true 
```

See [Techdocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw11-1/install-configure-upgrade/enable-ssl-connections-for-mysql.html) for more info on setting l7.mysql.connection.url. JDBC URLs like the value provided in database.jdbcUrl can be used as the value of l7.mysql.connection.url in node.properties. 

##### Gateway running in Ephemeral Mode (no external MySQL)
- To run the Gateway in Ephemeral mode, ***node.db.type=derby*** needs to be added to node.properties

Example: node.properties with Derby configuration
```
node.cluster.pass=mypassword
admin.user=admin
admin.pass=mypassword
node.db.type=derby
node.db.config.main.user=gateway
```

##### Update values.yaml
Update your values file to use the new node.properties file.

This command is the simplest way to create a secret with node.properties. Note that this can also be created with tools like [kustomize](https://kustomize.io/) which will be better for CI/CD pipelines. You can also take advantage of the secret [secret store csi driver](https://secrets-store-csi-driver.sigs.k8s.io/) to mount this secret from an external KMS provider.

Note that the key name is node.properties. This is required.
```
kubectl create secret generic gateway-secret --from-file=node.properties=path/to/node.properties
```
values.yaml
```
disklessConfig:
  enabled: false
  existingSecret:
    name: gateway-secret
  # csi:
  #   driver: secrets-store.csi.k8s.io
  #   readOnly: true
  #   volumeAttributes:
  #     secretProviderClass: "secret-provider-class-name"
```

[Back to Additional Guides](#additional-guides)

### Bundle Configuration
There are a variety of ways to mount Gateway (Restman format) Bundles to the Gateway Container. The best option is making use of existingBundles where the bundle has been created ahead of deployment as a configMap or secret.
This allows for purpose built Gateways with a guaranteed set of configuration, apis/services.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `existingBundle.enabled`          | Enable bundle mounts | `false`  |
| `existingBundle.configMaps`          | Array of configmap configurations | `see values.yaml`  |
| `existingBundle.secrets`          | Array of secret configurations | `see values.yaml`  |

This example shows 1 secret and 1 configmap configured - you can also use the secrets-store.csi.k8s.io driver for bundles that contain sensitive information.
```
# Bundles that contain sensitive information can be mounted using the Kubernetes CSI Driver
existingBundle:
  enabled: true
  configMaps:
  - name: mybundle1
    configMap:
      defaultMode: 420
      optional: false
      name: mybundle1
  secrets:
  - name: mysecretbundle1
  #   csi:
  #     driver: secrets-store.csi.k8s.io
  #     readOnly: true
  #     volumeAttributes:
  #       secretProviderClass: "secret-provider-class-name"
```

[Back to Additional Guides](#additional-guides)

### Bootstrap Script
To reduce reliance on requiring a custom gateway image for custom and modular assertions, scripts and restman bundles a bootstrap script has been introduced. The script works with the /opt/docker/custom folder. The best way to populate this folder is with an initContainer where files can be copied directly across or dynamically loaded from an external source.

The following configuration enables the script
```
bootstrap:
  script:
    enabled: true
  cleanup: false <== set this to true if you'd like to clear the /opt/docker/custom folder after it has run.
```

The bootstrap script scans files in ```/opt/docker/custom```. This folder is populated by an initContainer.

The following folder stucture must be maintained

- Restman Bundles (.bundle)
  - Source ```/opt/docker/custom/bundles```
  - Target ```/opt/SecureSpan/Gateway/node/default/etc/bootstrap/bundle```
- Custom Assertions (.jar)
  - Source ```/opt/docker/custom/custom-assertions```
  - Target ```/opt/SecureSpan/Gateway/runtime/modules/lib/```
- Modular Assertions (.aar)
  - Source ```/opt/docker/custom/modular-assertions```
  - Target ```/opt/SecureSpan/Gateway/runtime/modules/assertions```
- Properties (.properties)
  - Source ```/opt/docker/custom/properties```
  - Target ```/opt/SecureSpan/Gateway/node/default/etc/conf/```


More information on how to use initContainers with examples can be found on the [Layer7 Community Github Utilities Repository](https://github.com/Layer7-Community/Utilities/tree/main/gateway-init-container-examples).

[Back to Additional Guides](#additional-guides)

### Custom Health Checks
You can now specify a configMap or Secret that contains healthcheck scripts. These are mounted to ```/opt/docker/rc.d/diagnostic/health_check``` where they are run by ```/opt/docker/rc.d/diagnostic/health_check.sh```.

- Limited to a single configmap or secret.
  - ConfigMaps and Secrets can hold multiple scripts.
  - [See this example](https://github.com/Layer7-Community/Utilities/tree/main/gateway-init-container-examples)

***NOTE: if you set a configMap and a Secret only one of them will be applied to your API Gateway.***
```
existingHealthCheck:
  enabled: false
  configMap: {}
    # name: healthcheck-scripts-configmap
    # defaultMode: 292
    # optional: false
  secret: {}
    # name: healthcheck-scripts-secret
    # csi:
    #   driver: secrets-store.csi.k8s.io
    #   readOnly: true
    #   volumeAttributes:
    #     secretProviderClass: "vault-database"
```

[Back to Additional Guides](#additional-guides)

### Custom Configuration Files
Certain folders on the Container Gateway are not writeable by design. This configuration allows you to mount existing configMap/Secret keys to specific paths on the Gateway without the need for a root user or a custom/derived image.

- [See this example](https://github.com/Layer7-Community/Utilities/tree/main/gateway-init-container-examples)
```
customConfig:
  enabled: false
  # mounts:
  # - name: sampletrafficloggerca-override
  #   mountPath: /opt/SecureSpan/Gateway/node/default/etc/conf/sampletrafficloggerca.properties
  #   subPath: sampletrafficloggerca.properties
  #   secret:
  #     name: config-override-secret
  #     item:
  #       key: sampletrafficloggerca.properties
  #       path: sampletrafficloggerca.properties
```

[Back to Additional Guides](#additional-guides)

### Graceful Termination
During upgrades and other events where Gateway pods are replaced you may have APIs/Services that have long running connections open.

This functionality delays Kubernetes sending a SIGTERM to the container gateway while connections remain open. This works in conjunction with terminationGracePeriodSeconds which should always be higher than preStopScript.timeoutSeconds. If preStopScript.timeoutSeconds is exceeded, the script will exit 0 and normal pod termination will resume.

The preStop script will monitor connections to <b>inbound (not outbound)</b> Gateway Application TCP ports (i.e. inbound listener ports opened by the Gateway Application and not some other process) except those that are explicitly excluded.

The following ports are excluded from monitoring by default.
- 8777 (Hazelcast) - Embedded Hazelcast.
- 2124 (Internode-Communication) - not utilised by the Container Gateway.

If there are no open connections, the preStop script will exit immediately ignoring preStopScript.timeoutSeconds to avoid unnecessary resource utilisation (pod stuck in terminating state) during upgrades.

While there aren't any explicit limits on preStopScript.timeoutSeconds and terminationGracePeriodSeconds running these for extended periods of time (i.e. more than 5 minutes) may be less reliable where other Kubernetes processes may remove the pod before terminationGracePeriodSeconds is reached. If you do run services like this we recommend testing before any real life implementation or better, creating a dedicated workload without autoscaling enabled (HPA) where you have more control over when/how pods are replaced.

The graceful termination (preStop script) is disabled by default.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `lifecycleHooks`          | Custom lifecycle hooks, takes precedence over the preStopScript | `{}`  |
| `preStopScript.enabled`          | Enable the preStop script | `false`  |
| `preStopScript.periodSeconds`          | The time in seconds between checks | `3`  |
| `preStopScript.timeoutSeconds`          | Timeout - must be lower than terminationGracePeriodSeconds  | `60`  |
| `preStopScript.excludedPorts`          | Array of ports that should be excluded from the preStop script check | `[8777, 2124]`  |
| `terminationGracePeriodSeconds`          | Default duration in seconds kubernetes waits for container to exit before sending kill signal. | `see values.yaml`  |

[Back to Additional Guides](#additional-guides)

### Autoscaling
Autoscaling is disabled by default, you will need [metrics server](https://github.com/kubernetes-sigs/metrics-server) in conjunction with the configuration below.
In order for Kubernetes to determine when to scale, you will also need to configure resources

We do not recommend setting MaxReplicas for a MySQL backed API Gateway above 8.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `autoscaling.enabled`          | Enable autoscaling | `false`  |
| `autoscaling.hpa.minReplicas`          | Minimum replicas that should be available | `1`  |
| `autoscaling.hpa.maxReplicas`          | Maximum replicas that should be available | `3`  |
| `autoscaling.hpa.metrics`          | Metrics to scale on | `see values.yaml`  |
| `autoscaling.hpa.behaviour`          | Scale up/down behaviour | `see values.yaml`  |

Here is an example of a configured autoscaling section.
```
autoscaling:
  enabled: true
  hpa:
    minReplicas: 1
    maxReplicas: 3
    metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
    behavior:
      scaleDown:
        stabilizationWindowSeconds: 300
        policies:
        - type: Pods
          value: 1
          periodSeconds: 60
      scaleUp:
        stabilizationWindowSeconds: 0
        policies:
        - type: Percent
          value: 100
          periodSeconds: 15
```

[Back to Additional Guides](#additional-guides)

### Pod Disruption Budgets
[Pod Disruption Budgets](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) allow you to limit the number of concurrent disruptions that your application experiences, allowing for higher availability while permitting the cluster administrator to manage the clusters nodes.
| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `pdb.create`    | Create a PodDisruptionBudget for your Gateway Release            | `false` |
| `pdb.maxUnavailable`    |   number of pods from that set that can be unavailable after the eviction. It can be either an absolute number or a percentage. | `""` |
| `pdb.minAvailable`    |  number of pods from that set that must still be available after the eviction, even in the absence of the evicted pod. minAvailable can be either an absolute number or a percentage. | `""` |

Example - note that only ***maxUnavailable*** or ***minAvailable*** can be set - both values ***cannot*** be set at the same time.
```
pdb:
  create: true
  maxUnavailable: 1
  minAvailable: ""
```

[Back to Additional Guides](#additional-guides)

### RBAC Parameters
PM Tagger requires access to pods in the current namespace, it uses the Gateway Configured service account.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `serviceAccount.create`          | Create a service account for the Gateway | `true`  |
| `serviceAccount.name`          | Use an existing service account or specify the name of the service account that you would like to be created | `nil`  |
| `rbac.create`          | Create Role and Rolebinding for Gateway Service Account | `true` |

If you would like to create and use your own service account the Gateway with PM Tagger will require the following role to function correctly.
***This should NOT be a cluster role***
```
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list", "patch"]
```

[Back to Additional Guides](#additional-guides)

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

[Back to Additional Guides](#additional-guides)

### Service Metrics Demo
To deploy the service metrics example you will need to enable serviceMetrics, influxdb and grafana.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `serviceMetrics.enabled`          | Enable the background metrics processing task | `false`  |
| `serviceMetrics.external`          | Point to an external influx database. Set influxDbUrl if true | `false`  |
| `serviceMetrics.influxDbUrl`          | InfluxDB URL | `http://influxdb`  |
| `serviceMetrics.influxDbPort`          | InfluxDB port | `8086`  |
| `serviceMetrics.influxDbDatabase`          | InfluxDB Database Name | `serviceMetricsDb`  |
| `serviceMetrics.tags`          | InfluxDB tags | `env=dev`  |
| `influxdb.enabled`                | Enable/Disable deployment of InfluxDb   | `false` |
| `grafana.enabled`                | Enable/Disable deployment of Grafana   | `false` |

[Back to Additional Guides](#additional-guides)

## Subchart Configuration
***these do not represent production configurations***

For Production implementations, please see the Chart links for recommended settings. The best approach would be deploying each independently
MySQL doesn't have a tried and tested K8's production deployment so it's best to use an external service.

## MySQL
The following table lists the configured parameters of the MySQL Bitnami chart - https://github.com/bitnami/charts/tree/master/bitnami/mysql (DO NOT USE IN PRODUCTION!!)

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `mysql.image.tag`                | MySQL Image to use   | `8` |
| `mysql.auth.username`                | MySQL Username   | `gateway` |
| `mysql.auth.password`                | MySQL User Password   | `mypassword` |
| `mysql.auth.database`                | Database to create   | `ssg` |
| `mysql.auth.rootPassword`                | MySQL root password, not set by default   | `mypassword` |
| `mysql.primary.persistence.enabled`                | Enable/Disable Persistence   | `true` |
| `mysql.primary.persistence.size`                | Persistent Volume Size   | `8Gi` |
| `mysql.primary.persistence.storageClass`                | Storage class to use   | `nil` |
| `mysql.primary.configuration`                | MySQL Configuration   | `see values.yaml` |

## Hazelcast
The following table lists the configured parameters of the Hazelcast Subchart - see the following for more detail https://github.com/hazelcast/charts/blob/master/stable/hazelcast/values.yaml

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `hazelcast.enabled`                | Enable/Disable deployment of Hazelcast   | `false` |
| `hazelcast.external`                | Point to an external Hazelcast - set enabled to false and configure the url  | `false` |
| `hazelcast.image.tag`                | The Gateway currently supports Hazelcast 4.x/5.x servers.  | `5.2.1` |
| `hazelcast.url`                | External Hazelcast Url  | `hazelcast.example.com:5701` |
| `hazelcast.cluster.memberCount`                | Number of Hazelcast Replicas you wish to deploy   | `see values.yaml` |
| `hazelcast.hazelcast.yaml`                | Hazelcast configuration   | `see the documentation link` |

## InfluxDb
The following table lists the configured parameters of the InfluxDb Subchart - see the following for more detail https://github.com/influxdata/helm-charts/tree/master/charts/influxdb

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `influxdb.enabled`                | Enable/Disable deployment of InfluxDb   | `false` |
| `influxdb.service.port`                | Service Port  | `8086` |
| `influxdb.persistence.enabled`                | Enable Persistence for InfluxDb   | `true` |
| `influxdb.persistence.storageClass`                | Persistence Storage Class   | `nil` |
| `influxdb.persistence.size`                | Persistent Volume Claim Size   | `8Gi` |
| `influxdb.env`                | Array of additional environment variables   | `see values.yaml` |

## Grafana
The following table lists the configured parameters of the Grafana Subchart - see the following for more detail https://github.com/bitnami/charts/tree/master/bitnami/grafana

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `grafana.enabled`                | Enable/Disable deployment of Grafana   | `false` |
| `grafana.admin.user`                | admin username  | `admin` |
| `grafana.admin.password`                | admin password, leave blank to auto-generate  | `password` |
| `grafana.dashboardsProvider.enabled`                | Allows dashboards to be preloaded   | `true` |
| `grafana.dashboardsConfigMaps`                | Configmaps that contain grafana dashboards. You can create your own and set here.   | `see values.yaml` |
| `grafana.datasources.secretName`                | Configures an InfluxDb Datasource.   | `see values.yaml` |

### Subcharts
*  Hazelcast  (default: disabled) ==> https://github.com/helm/charts/tree/master/stable/hazelcast
*  MySQL      (default: enabled)  ==> https://github.com/bitnami/charts/tree/master/bitnami/mysql
*  InfluxDb   (default: disabled) ==> https://github.com/influxdata/helm-charts/tree/master/charts/influxdb
*  Grafana    (default: disabled) ==> https://github.com/bitnami/charts/tree/master/bitnami/grafana
*  Redis      (default: disabled) ==>https://github.com/bitnami/charts/tree/master/bitnami/redis

[Back to Additional Guides](#additional-guides)
