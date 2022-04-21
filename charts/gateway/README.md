# Layer7 API Gateway

This Chart deploys the API Gateway with the following `optional` subcharts: hazelcast, mysql, influxdb, grafana.

It's targeted at Gateway v10.x onward.

# Java 11
API Gateway is now running with Java 11 with the release of the v10.1.00. The Gateway chart's version has been incremented to 2.0.2.

Things to note and be aware of are the deprecation of TLSv1.0/TLSv1.1 and the JAVA_HOME dir has gone through some changes as well. 

## Changes that will affect you if upgrading from 2.0.1 and below
- MySQL Stable Chart is deprecated - the demo database subChart has been changed to Bitnami MySQL - if your database is NOT externalised you will lose any policy/configuration you have there.
- tls.customKey ==> tls.useSignedCertificates tls.key tls.pass tls.existingSecretName

## 2.0.5 Updates to Gateway Service
- Updated naming conventions to reflect standards. You will need to update your values file to reflect this. If you wish to continue to use the old format specify --version 2.0.4 on install/upgrade

```
v2.0.4
------
ports:
  - name: https
    internal: 8443
    external: 8443
  - name: management
    internal: 9443
    external: 9443

v2.0.5 onwards
------
ports:
  - name: https
    port: 8443
    targetPort: 8443
    protocol: TCP
  - name: management
    port: 9443
    targetPort: 9443
    protocol: TCP
```


- Added name to containerPorts for more consistent service resolution
- Added ingressClassName options for Gateway Ingress

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
### If you are using the demo database in a previous version of this Chart this upgrade will remove it. If you wish to keep your data you will need to perform a backup.
```
$ helm repo update
$ helm show values layer7/gateway > gateway-values.yaml

Inspect and update the new gateway-values.yaml

$ helm upgrade my-ssg --set-file "license.value=path/to/license.xml" --set "license.accept=true" -f ./gateway-values.yaml  layer7/gateway
```

# Install the Chart
```
$ helm repo add layer7 https://caapim.github.io/apim-charts/
$ helm repo update
$ helm install my-ssg --set-file "license.value=path/to/license.xml" --set "license.accept=true" layer7/gateway
```

## Upgrade this Chart
To upgrade the Gateway deployment
```
$ helm upgrade my-ssg --set-file "license.value=path/to/license.xml" --set "license.accept=true" layer7/gateway
```
## Remove this Chart
To delete Gateway installation

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
| `image.registry`    | Image Registry               | `docker.io` |
| `image.repository`          | Image Repository  | `caapim/gateway`  |
| `image.tag`          | Image tag | `10.1.00`  |
| `image.pullPolicy`          | Image Pull Policy | `IfNotPresent`  |
| `imagePullSecret.enabled`          | Configures Gateway Deployment to use imagePullSecret, you can also leave this disabled and associate an image pull secret with the Gateway's Service Account | `false`  |
| `imagePullSecret.existingSecretName`          | Point to an existing Image Pull Secret | `commented out`  |
| `imagePullSecret.username`          | Registry Username | `nil`  |
| `imagePullSecret.password`          | Registry Password | `nil`  |
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
| `serviceMetrics.enabled`          | Enable the background metrics processing task | `false`  |
| `serviceMetrics.external`          | Point to an external influx database. Set influxDbUrl if true | `false`  |
| `serviceMetrics.influxDbUrl`          | InfluxDB URL | `http://influxdb`  |
| `serviceMetrics.influxDbPort`          | InfluxDB port | `8086`  |
| `serviceMetrics.influxDbDatabase`          | InfluxDB Database Name | `serviceMetricsDb`  |
| `serviceMetrics.tags`          | InfluxDB tags | `env=dev`  |
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
| `service.loadbal..`    | Additional Loadbalancer Configuration               | `see https://kubernetes.io/docs/tasks/access-application-cluster/configure-cloud-provider-firewall/#restrict-access-for-loadbalancer-service` |
| `service.ports`    | List of http external port mappings               | https: 8443 -> 8443, management: 9443->9443 |
| `service.annotations`    | Additional annotations to add to the service               | {} |
| `ingress.enabled`    | Enable/Disable an ingress record being created               | `false` |
| `ingress.class.enabled`    | Use spec.IngressClassName vs. old annotation kubernetes.io/ingress.class               | `false` |
| `ingress.class.name`    | Specify Ingress Class Name               | `nginx` |
| `ingress.annotations`    | Additional ingress annotations               | `{}` |
| `ingress.hostname`    | Sets Ingress Hostname  | `nil` |
| `ingress.port`    | The Gateway Port number/name to route to  | `8443` |
| `ingress.tlsHostnames`    | Register additional Hostnames for the TLS Certificate  | `[]` |
| `ingress.secretName`    | The name of an existing Cert secret, setting this does not auto-create the secret               | `tls-secret` |
| `ingress.additionalHostnamesAndPorts`    | key/value pairs of hostname:port that will be added to the ingress object  | `{}` |
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

### Exposing Additional Ports
Add an entry under the ports section of the service section of the values.yaml file.

Sample entry that exposes ports 8443, 9443, and 8080:
```
ports:
  - name: https
    internal: 8443
    external: 8443
  - name: management
    internal: 9443
    external: 9443
  - name: http
    internal: 8080
    external: 8080
```
### Ingress - Adding Routes
To prepare an Ingress controller for the purpose of deploying API Gateway on Kubernetes. Skip this step if you already have your Ingress controller set up from an existing or previous deployment.

Use Nginx controller

Deploy an Nginx controller with SSL passthrough enabled:

`$ helm install nginx-ingress stable/nginx-ingress --set rbac.create=true --set controller.publishService.enabled=true --set controller.extraArgs.enable-ssl-passthrough=true `

Override ingress values in values.yaml file using ingress-values.yaml

- New install

`$ helm install -f ingress-values.yaml --set-file "license.value=LICENSE.xml" --set "license.accept=true" . `

- Upgrade

`$ helm upgrade --install -f ingress-values.yaml --set-file "license.value=LICENSE.xml" --set "license.accept=true"  <release-name> . `

### Using External Database
You can configure the deployment to use an external database. In the values.yaml file, set the create field in the database section to false, and set jdbcURL to use your own database server:
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

## Subcharts - these do not represent production configurations
For Production implementations, please see the Chart links for recommended settings. The best approach would be deploying each independently
MySQL doesn't have a tried and tested K8's production deployment so it's best to use an external service. You could also try Vitess (https://vitess.io/)
reference implementation coming soon...

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
| `hazelcast.image.tag`                | The Gateway currently supports Hazelcast 3.x servers.  | `3.12.8` |
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
*  Hazelcast (default: disabled) ==> https://github.com/helm/charts/tree/master/stable/hazelcast
*  MySQL (default: enabled)  ==> https://github.com/bitnami/charts/tree/master/bitnami/mysql
*  InfluxDb (default: disabled) ==> https://github.com/influxdata/helm-charts/tree/master/charts/influxdb
*  Grafana (default: disabled) ==> https://github.com/bitnami/charts/tree/master/bitnami/grafana
