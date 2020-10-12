# Layer7 API Gateway

This Chart deploys the API Gateway with the following `optional` subcharts: hazelcast, mysql, influxdb, grafana.

It's targeted at Gateway v10.x onward.

# Install the Chart

## From this Repository
Install from this repository assuming you've downloaded/forked the Git Repo

`$ helm install ssg --set-file "license.value=path/to/license.xml" --set "license.accept=true" .`

## From the Layer7 Repository (Please read!)
Install from the charts.brcmlabs.com Helm Repository, the ssg chart will require authentication until is made GA. Customers that have been invited to try the Chart out will receive credentials in a separate email. Please reach out to gary.vermeulen@broadcom.com if you haven't received these.

`$ helm repo add layer7 https://charts.brcmlabs.com --username <username> --password <password>`

`$ helm install ssg --set-file "license.value=path/to/license.xml" --set "license.accept=true" layer7/ssg`

## Upgrade this Chart
To upgrade the Gateway deployment

`$ helm upgrade ssg --set-file "license.value=path/to/license.xml" --set "license.accept=true" .`

## Delete this Chart
To delete Gateway installation

`$ helm delete <release name> -n <release namespace>`

## Rebuild Chart Dependencies
To update the Charts dependencies

`$ helm dep up`

## Custom values
To make sure that your custom values don't get overwritten by a pull, create your own values.yaml (myvalues.yaml..) then specify -f myvalues.yaml when deploying/upgrading

## Configuration
The following table lists the configurable parameters of the Gateway chart and their default values. See values.yaml for additional parameters and info

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `nameOverride`                | Name override   | `nil` |
| `fullnameOverride`                      | Full name override                       | `nil`                                                     |
| `license.value`          | Gateway license file | `nil`  |
| `license.accept`          | Accept Gateway license EULA | `false`  |
| `image.registry`    | Image Registry               | `docker.io` |
| `image.repository`          | Image Repository  | `caapim/gateway`  |
| `image.tag`          | Image tag | `10.0.00`  |
| `image.pullPolicy`          | Image Pull Policy | `Always`  |
| `image.secretName`          | Creates an imagePullSecrets | `nil`  |
| `image.credentials.username`          | Registry Username | `nil`  |
| `image.credentials.password`          | Registry Password | `nil`  |
| `replicas`                   | Number of Gateway replicas        | `1`                                                          |
| `updateStrategy.type`             | Deployment Strategy                       | `RollingUpdate`                                              |
| `updateStrategy.rollingUpdate.maxSurge`             | Rolling Update Max Surge                       | `1`                                              |
| `updateStrategy.rollingUpdate.maxUnavailable`             | Rolling Update Max Unavailable                       | `0`                                              |
| `clusterHostname`          | Gateway Cluster Hostname  | `my.localdomain`  |
| `clusterPassword`          | Cluster Password, used if db backed  | `mypassword`  |
| `management.enabled`          | Enable/Disable Policy Manager access | `true`  |
| `management.restman.enabled`          | Enable/Disable the Rest Management API (Restman) | `false`  |
| `management.username`          | Policy Manager Username | `admin`  |
| `management.password`          | Policy Manager Password | `mypassword`  |
| `database.enabled`          | Run in DB Backed or Ephemeral Mode | `true`  |
| `database.create`          | Deploy the MySQL stable deployment as part of this release | `true`  |
| `database.username`          | Database Username | `gateway`  |
| `database.password`          | Database Password | `mypassword`  |
| `database.name`          | Database name | `ssg`  |
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
| `tls.customKey.enabled`          | Not currently implemented | `false`  |
| `additionalEnv`          | Additional environment variables you wish to pass to the Gateway Configmap | `see values.yaml`  |
| `additionalSecret`          | Additional secret variables you wish to pass to the Gateway Secret | `see values.yaml`  |
| `bundle.enabled`          | Create and mount an empty configMap that you can use to load policy bundles onto your Gateway | `false`  |
| `bundle.path`          | Specify the path to the bundle files. The bundles folder in this repo has some example bundle files | `"bundles/*.bundle"`  |
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

In order the create the database on the remote server, the provided user in the username field must have write privilege on the database. See GRANT statement usage: https://dev.mysql.com/doc/refman/8.0/en/grant.html#grant-database-privileges

## Subcharts - these do not represent production configurations
For Production implementations, please see the Chart links for recommended settings. The best approach would be deploying each independently
MySQL doesn't have a tried and tested K8's production deployment so it's best to use an external service. You could also try Vitess (https://vitess.io/)
reference implementation coming soon...

## MySQL
The following table lists the configured parameters of the MySQL Subchart - see the following for more detail https://github.com/helm/charts/tree/master/stable/mysql

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `mysql.imageTag`                | MySQL Image to use   | `8` |
| `mysql.mysqlUser`                | MySQL Username   | `gateway` |
| `mysql.mysqlPassword`                | MySQL User Password   | `mypassword` |
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
*  MySQL (default: enabled)  ==> https://github.com/helm/charts/tree/master/stable/mysql
*  InfluxDb (default: disabled) ==> https://github.com/influxdata/helm-charts/tree/master/charts/influxdb
*  Grafana (default: disabled) ==> https://github.com/bitnami/charts/tree/master/bitnami/grafana
