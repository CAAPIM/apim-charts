# Layer7 API Gateway
This Chart deploys the API Gateway v10.x onward with the following `optional` subcharts: hazelcast, mysql, influxdb, grafana.

### Important Note
The included MySQL subChart is enabled by default to make trying this chart out easier. ***It is not supported or recommended for production.*** Layer7 assumes that you are deploying a Gateway solution to a Kubernetes environment with an external MySQL database.

## Prerequisites
- Kubernetes 1.24.x
  - [Refer to techdocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw-10-1/release-notes_cgw/container-gateway-platform-support.html#concept.dita_3277fc35fde9c5232f0d64d7a360181d5d18fd6c) for the latest version support
- Helm v3.7.x
- Gateway v10.x License

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

# Java 11
The Layer7 API Gateway is now running with Java 11 with the release of the v10.1.00. The Gateway chart's version has been incremented to 2.0.2.

Things to note and be aware of are the deprecation of TLSv1.0/TLSv1.1 and the JAVA_HOME dir has gone through some changes as well.

## 3.0.2 General Updates
***The default image tag in values.yaml and production-values.yaml now points at specific CR versions of the API Gateway. The appVersion in Chart.yaml has also be updated to reflect that. As of this release that is 10.1.00_CR2***

To reduce reliance on requiring a custom/derived gateway image for custom and modular assertions, scripts and restman bundles a bootstrap script has been introduced. The script works with the /opt/docker/custom folder.

The best way to populate this folder is with an initContainer where files can be copied directly across or dynamically loaded from an external source.
- [InitContainer Examples](https://github.com/Layer7-Community/Utilities/tree/main/gateway-init-container-examples) - this repository also contains examples for custom health checks and configuration files.

The following configuration options have been added
- [Custom Health Checks](#custom-health-checks)
- [Custom Configuration Files](#custom-configuration-files)
- [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#spread-constraints-for-pods)
- [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
- [Pod Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)
- [Container Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)
- Http headers can also now be added to the liveness and readiness probes
- Ingress and HPA API Version validation has been updated to check for available APIs vs. KubeVersion
- SubCharts now show image repository and tags

### Upgrading to Chart v3.0.0
Please see the 3.0.0 updates, this release brings significant updates and ***breaking changes*** if you are using an external Hazelcast 3.x server. Services and Ingress configuration have also changed. Read the 3.0.0 Updates below and check out the [additional guides](#additional-guides) for more info. 

## 3.0.0 Updates to Hazelcast
***Hazelcast 4.x/5.x servers are now supported*** this represents a breaking change if you have configured an external Hazelcast 3.x server.
- If you are using Gateway v10.1 and below you will either need to set *hazelcast.legacy.enabled=true* and use the following gateway image *docker.io/caapim/gateway:10.1.00_20220802* or update your external Hazelcast server.
- The included Hazelcast subChart has been updated to reflect this change

### 3.0.0 Updates to Ingress Configuration
Ingress configuration has been updated to include multiple hosts, please see [Ingress Configuration](#ingress-configuration) for more detail. You will need to update your values.yaml to reflect the changes.

## 3.0.0 General Updates
- You can now configure [Gateway Ports.](#port-configuration)
  This does not cover Kubernetes Service level configuration which will ***need to be updated*** to reflect your changes.

- New Management Service
  - Provides separation of concerns for external/management traffic. This was previously a manual step.
- [Autoscaling](#autoscaling)
- [Ingress Configuration](#ingress-configuration)
- [PM Tagger](#pm-tagger-configuration)
  - PM (Policy Manager) tagger is a lightweight go application that works with the new management service.
  - RBAC Role Required if using PM Tagger.
- Default values.yaml restructure
  - configuration items more closely aligned
- Added production-values.yaml
  - Includes a baseline for production configuration
  - Resources are set to minimum recommended values
  - Application ports are hardened
   - 8080 (disabled)
   - 8443 (management features disabled - service is ClusterIP)
   - 9443 (configured with management service)
  - Autoscaling is enabled
  - Ingress is enabled
   - Rules are configured for 8443
  - Database is not created - you will need to supply a JDBC Url

## Changes that will affect you if upgrading from 2.0.1 and below
- MySQL Stable Chart is deprecated - the demo database subChart has been changed to Bitnami MySQL - if your database is NOT externalised you will lose any policy/configuration you have there.
- tls.customKey ==> tls.useSignedCertificates tls.key tls.pass tls.existingSecretName

## 2.0.6 General Updates
- Fixing bitnami repository dependency issue.

## 2.0.5 General Updates
- Internal only.

## 2.0.4 Updates to Secret Management
- Added support for the Kubernetes CSI Driver for gateway bundles. This does not currently extend to environment variables or the Gateway license.
- The CSI functionality is optional

## 2.0.4 General Updates
- Added support for sidecars and initContainers
  - volumeMounts are automatically configured with emptyDir 
- Updated default values update to reflect empty objects/arrays for optional fields.
- Load the Gateway Deployment's ServiceAccountToken as a stored password for querying the Kubernetes API.
  - management.kubernetes.loadServiceAccountToken

## 2.0.2 Updates to Secret Management
- You can now specify existing secrets for Gateway Configuration, DefaultSSLKey (tls) and bundles

## 2.0.2 General Updates
- Ingress Definition updated to reflect the new API Version, additional configuration added.
- HostAliases applies to /etc/hosts for dns names that aren't available on a dns server.
- System.properties is now mounted to the Gateway Container, default values have been applied.
- You can now reference existing bundles stored in configMaps/Secrets
- NodeSelector and Affinity settings for the Gateway Deployment
- Resources values updated to reflect minimum recommended configuration

## Upgrading to 2.0.2
***If you are using the demo database in a previous version of this Chart this upgrade will remove it. If you wish to keep your data you will need to perform a backup.***
```
$ helm repo update
$ helm show values layer7/gateway > gateway-values.yaml

Inspect and update the new gateway-values.yaml

$ helm upgrade my-ssg --set-file "license.value=path/to/license.xml" --set "license.accept=true" -f ./gateway-values.yaml  layer7/gateway
```

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

## Additional Guides
* [Service Configuration](#port-configuration)
* [Gateway Application Ports](#gateway-application-ports)
* [Ingress Configuration](#ingress-configuration)
* [PM Tagger Configuration](#pm-tagger-configuration)
* [OTK Install or Upgrage](#otk-install-or-upgrage)
* [Database Configuration](#database-configuration)
* [Cluster-Wide Properties](#cluster-wide-properties)
* [Java Args](#java-args)
* [System Properties](#system-properties)
* [Gateway Bundles](#bundle-configuration)
* [Bootstrap Script](#bootstrap-script)
* [Custom Health Checks](#custom-health-checks)
* [Custom Configuration Files](#custom-configuration-files)
* [Logs & Audit Configuration](#logs--audit-configuration)
* [Autoscaling](#autoscaling)
* [RBAC Parameters](#rbac-parameters)
* [Service Metrics Demo](#service-metrics-demo)
* [SubChart Configuration](#subchart-configuration)

## Configuration
The following table lists the configurable parameters of the Gateway chart and their default values. See values.yaml for additional parameters and info

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `nameOverride`                | Name override   | `nil` |
| `fullnameOverride`                      | Full name override                       | `nil`                                                     |
| `global.schedulerName`                      | Override the default scheduler | `nil` |
| `license.value`          | Gateway license file | `nil`  |
| `license.accept`          | Accept Gateway license EULA | `false`  |
| `image.registry`    | Image Registry               | `docker.io` |
| `image.repository`          | Image Repository  | `caapim/gateway`  |
| `image.tag`          | Image tag | `10.1.00_CR2`  |
| `image.pullPolicy`          | Image Pull Policy | `IfNotPresent`  |
| `imagePullSecret.enabled`          | Configures Gateway Deployment to use imagePullSecret, you can also leave this disabled and associate an image pull secret with the Gateway's Service Account | `false`  |
| `imagePullSecret.existingSecretName`          | Point to an existing Image Pull Secret | `commented out`  |
| `imagePullSecret.username`          | Registry Username | `nil`  |
| `imagePullSecret.password`          | Registry Password | `nil`  |
| `pdb.create`          | Create a PodDisruptionBudget (PDB) object | `false` |
| `pdb.maxUnavailable`         | PodDisruptionBudget maximum unavailable pod count         | `nil` |
| `pdb.minAvailable`         | PodDisruptionBudget minimum available pod count          | `nil` |
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
| `database.name`          | Database name | `ssg`  |
| `tls.useSignedCertificates`          | Enable/Disable use of your own TLS Certificate, this ovverides the Gateway's defaultSSLKey | `false`  |
| `tls.existingSecretName`          | Existing Secret that contains TLS p12 container and pass, see values.yaml for what must be included | `commented out`  |
| `tls.key`          | p12 container - this can be set with --set-file tls.key=/path/to/tls.p12 | `nil`  |
| `tls.pass`          | p12 container password - this cannot be empty | `nil`  |
| `config.heapSize`          | Java Heap Size | `2g`  |
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
| `ingress.enabled`    | Enable/Disable an ingress record being created               | `false` |
| `ingress.annotations`    | Additional ingress annotations               | `{}` |
| `ingress.hostname`    | Sets Ingress Hostname  | `nil` |
| `ingress.port`    | The Gateway Port number/name to route to  | `8443` |
| `ingress.tlsHostnames`    | Register additional Hostnames for the TLS Certificate  | `see values.yaml` |
| `ingress.secretName`    | The name of an existing Cert secret, setting this does not auto-create the secret               | `tls-secret` |
| `ingress.additionalHostnamesAndPorts`    | key/value pairs of hostname:port that will be added to the ingress object  | `see values.yaml` |
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
| `bootstrap.script.cleanup`    | Cleanup the /opt/docker/custom folder              | `false` |


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
### OTK install or upgrage
OTK job is used to install or upgrade otk on gateway. It supports single, internal and external type of OTK installations.

Prerequisites:
* Create or upgrade the OTK Database https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-6/installation-workflow/create-or-upgrade-the-otk-database.html
* Configure cluster wide property for otk.port pointing to gateway ingress port.
```
config:
  cwp:
    enabled: true
    properties:
      - name: otk.port
        value: 443
```
* Restman is enabled. Can be disabled once the install/upgrage is complete.
```
management:
  restman:
    enabled: true
```
* Management is enabled with restman (management.enabled: true, management.restman.enabled: true)

Limitations:
* OTK Instance modifiers are not supported.
* OTK not supported on ephemeral gateway.
```
database:
  # DB Backed or ephemeral
  enabled: true
```

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `otk.enabled`                     | Enable/Disable OTK installation or upgrade | `false`  |
| `otk.type`                        | OTK installation type - SINGLE, DMZ or INTERNAL | `SINGLE`
| `otk.forceInstallOrUpgrade`       | Force install or upgrade by uninstalling existing otk soluction kit and install. | false
| `otk.enablePortalIngeration`      | Not applicable for DMZ and INTERNAL OTK types | `false`
| `otk.skipPostInstallationTasks`   | Skip post installation tasks for OTK type INTERNAL and DMZ <br/>Intrenal Gateway: <br/> - #OTK Client Context Variables <br/> - #OTK id_token configuration <br/> - Import SSL Certificate of DMZ gateway <br/>DMZ Gareway: <br/> - #OTK OVP Configuration<br/> - #OTK Storage Configuration<br/> - Import SSL Certificate of Internal gateway   | `false`
| `otk.internalGatewayHost`         | Internal gateway host for OTK type DMZ| 
| `otk.internalGatewayPort`         | Internal gateway post for OTK type DMZ|
| `otk.dmzGatewayHost`              | DMZ gateway host for OTK type INTERNAL|
| `otk.dmzGatewayPort`              | DMZ gateway port for OTK type INTERNAL|
| `otk.subSolutionKitNames`         | List of comma seperated sub soluction Kits to install or upgrade. |
| `otk.job.image.repository`        | Image Repositor | `caapim/otk-install`
| `otk.job.image.tag`               | Image Tag. (OTK version) | `4.6`
| `otk.job.image.pullPolicy`        | Image Pull Policy | `IfNotPresent`
| `otk.job.image.labels`            | Job lables | {}
| `otk.job.image.nodeSelector`      | Job Node selector | {}
| `otk.job.image.tolerations`       | Job tolerations | []
| `otk.database.type`               | OTK database type - mysql/oracle/cassandra | `mysql`
| `otk.database.connectionName`     | OTK database connection name | `OAuth`
| `otk.database.existingSecretName` | Point to an existing OTK database Secret |
| `otk.database.username`           | OTK database user name | 
| `otk.database.password`           | OTK database password |
| `otk.database.properties`         | OTK database additional properties  | `{}`
| `otk.database.sql.type`           | OTK database type (mysql/oracle/cassandra) | `mysql`
| `otk.database.sql.jdbcURL`        | OTK database sql jdbc URL (oracle/mysql) | 
| `otk.database.sql.jdbcDriverClass`| OTK database sql driver class name (oracle/mysql) | 
| `otk.database.sql.databaseName`   | OTK database Oracle database name | 
| `otk.database.cassandra.connectionPoints`  | OTK database cassandra connection points (comma seperated)  | 
| `otk.database.cassandra.port`              | OTK database cassandra connection port  |
| `otk.database.cassandra.keyspace`          | OTK database cassandra keyspace |
| `otk.database.cassandra.driverConfig`      | OTK database cassandra driver config (Gateway 11+) | `{}`
| `otk.livenessProbe.enabled`                |  Enable/Disable Have a higher initialDelaySeconds for livenessProbe when OTK is included to allow OTK installation job to complete | `false`
| `otk.livenessProbe.type`                   |  | `httpGet`
| `otk.livenessProbe.httpGet.path`           |  | `/auth/oauth/health`
| `otk.livenessProbe.httpGet.port`           |  | `8443`
| `otk.readinessProbe.enabled`               | Enable/Disable Have a higher initialDelaySeconds for readinessProbe when OTK is included to allow OTK installation job to complete  | `false`
| `otk.readinessProbe.type`                  |  | `httpGet`
| `otk.readinessProbe.httpGet.path`          |  | `/auth/oauth/health`
| `otk.readinessProbe.httpGet.port`          |  | `8443`

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
          - TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
          - TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
          - TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
          - TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
          - TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
          - TLS_DHE_RSA_WITH_AES_256_CBC_SHA256
          - TLS_DHE_RSA_WITH_AES_256_CBC_SHA
          - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
          - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
          - TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
          - TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
          - TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
          - TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
          - TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
          - TLS_DHE_RSA_WITH_AES_128_CBC_SHA256
          - TLS_DHE_RSA_WITH_AES_128_CBC_SHA
          - TLS_AES_256_GCM_SHA384
          - TLS_AES_128_GCM_SHA256
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

### PM Tagger Configuration
[PM (Policy Manager) Tagger](https://github.com/gvermeulen7205/pm-tagger) is a lightweight go application that works in conjunction with the management service to provide a stable connection to your container gateway via Policy Manager.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `pmtagger.enabled`          | Enable pm-tagger | `false`  |
| `pmtagger.replicas`          | Replicas (you should never need more than one | `1`  |
| `pmtagger.image.registry`          | Image Registry | `docker.io`  |
| `pmtagger.image.repository`          | Image Repository | `layer7api/pm-tagger`  |
| `pmtagger.image.tag`          | Image Tag | `1.0.0`  |
| `pmtagger.image.pullPolicy`          | Image Pull Policy | `IfNotPresent`  |
| `pmtagger.image.imagePullSecret.enabled`                | Use Image Pull secret - this uses the image pull secret configured for the API Gateway   | `false` |
| `pmtagger.pdb.create`                | Create a PodDisruptionBudget object | `false` |
| `pmtagger.pdb.maxUnavailable`                | PodDisruptionBudget maximum unavailable pod count         | `nil` |
| `pmtagger.pdb.minAvailable`                | PodDisruptionBudget minimum available pod count          | `nil` |
| `pmtagger.resources`                | Resources   | `see values.yaml` |

### Database Configuration
You can configure the deployment to use an external database (this is the recommended approach - the included MySQL SubChart is not supported). In the values.yaml file, set the create field in the database section to false, and set jdbcURL to use your own database server:
```
database:
  enabled: true
  create: false
  jdbcURL: jdbc:mysql://myprimaryserver:3306,mysecondaryserver:3306/ssg?failOverReadOnly=false
  username: myuser
  password: mypassword
  name: ssg
```
In the above example, two MySQL database servers are specified with myprimaryserver acting as the primary server and mysecondaryserver acting as the secondary server. The failOverReadOnly property is also set to false meaning that the secondary server db is also writable.

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


### Java Args
Additional Java Arguments as may be recommended by support can be configured in values.yaml

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `config.heapSize`          | Java Heap Size - this should be a percentage of the memory configured in resources.limits and should be updated together. The default assumes 50%, going above 75% is not recommended | `2G`  |
| `config.javaArgs`          | Additional Java Args to pass to the SSG process | `see values.yaml`  |

The default Java Args are as follows
```
config:
  heapSize: "2g"
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
| `hazelcast.image.tag`                | The Gateway currently supports Hazelcast 4.x/5.x servers.  | `5.1.1` |
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
*  Hazelcast (default: disabled) ==> https://github.com/helm/charts/tree/master/stable/hazelcast
*  MySQL (default: enabled)  ==> https://github.com/bitnami/charts/tree/master/bitnami/mysql
*  InfluxDb (default: disabled) ==> https://github.com/influxdata/helm-charts/tree/master/charts/influxdb
*  Grafana (default: disabled) ==> https://github.com/bitnami/charts/tree/master/bitnami/grafana
