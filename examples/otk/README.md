# OTK Gateway Deployment Examples
These examples cover different ways in which OTK can be deployed on Gateway using Gateway Helm Chart.

At a high level the deployment can be categorized based on Gateway type (database backed/Ephemeral) and OTK Type (SINGLE/INTERNAL/DMZ). It determines how the OTK is installed or upgraded on the gateway.

OTK installation involves
1. Installation or upgrade of OTK solution kit.
2. Installation or upgrade of OTK Database.
3. Installation or upgrade of OTK customizations.

| OTK Type | Database backed Gateway </br> (database.enabled=true) | Ephemeral Gateway </br> (database.enabled=false) |
| ------------------------   | ---------------------- | ---------------------  |
| Solution Kit Install/Upgrade | <ul><li>Uses post-install kubernetes Job (Headless installation - Restman)</li><li>Runs after Gateway startup</li></ul> |  <ul><li>Uses kubernetes init-container to bootstrap Gateway with OTK solution kits </li><li> Runs before start of Gateway</li><li> OTK Dual Gateway (DMZ/INTERNAL) configuration is not supported. </li></ul> |
| OTK Database Install/upgrade </br> ***(Not applicable for OTK type DMZ and OTK DB type - Cassandra)*** | <ul><li>Uses pre-install kubernetes Job (Liqiubase scripts)</li><li>Runs before Gateway startup</li></ul> | <ul><li>Uses pre-install kubernetes Job (Liqiubase scripts)</li><li>Runs before Gateway startup</li></ul> |
| Customizations | <ul><li> Restman bundles applied using restman calls after Gateway startup which can be Kubernetes Config Maps and/or Secrets </li><li>Init containers - Bootstrapped on to Gateway</li></ul>  | <ul><li>Restman bundles bootstrapped on to gateway which can be Kubernetes Config Maps and/or Secrets</li><li> Init Containers - Bootstrapped on to Gateway</li></ul> |

* [Quick Start](#quick-start)
* [OTK with MySQL/Oracle database](#otk-with-mysql-or-oracle-database)
* [OTK With Cassandra database](#otk-with-cassandra-database)
* [Customizations (optional)](#customizations)
* [Health checks (optional)](#health-checks)
* [Miscellaneous configurations (optional)](#miscellaneous-configurations)

### Quick Start

OTK can be installed by otk.enabled=true. This will create OTK database using MySQL subchart and then bootstraps the OTK bundles on to the gateway (type SINGLE). The usage of MySQL subchart for OTK database do not represent production configuration.

Add the layer7 repository:

    helm repo add layer7 https://caapim.github.io/apim-charts/
    helm repo update

Then, you can install OTK on ephemeral gateway:

    helm install otk layer7/gateway --set-file "license.value=path/license.xml" \
    --set "license.accept=true,database.enabled=false,otk.enabled=true"

Or, install OTK on db backed gateway:

    helm install otk layer7/gateway --set-file "license.value=path/license.xml" \
    --set "license.accept=true,management.restman.enabled=true,otk.enabled=true"

# High Level

![image](https://github.com/APIM-KiranVaddadi/apim-charts/assets/59958248/0ea19c0d-5aee-4083-aacc-7f8c9c537592)

## OTK Solution Kits
The sub solution kits that are used in the installation or upgrade process are determined based on `otk.type` and the `otk.database.type`. This also determines additional configuration needed in case of `DMZ` and `INTERNAL` otk type installation. Optional configurations that also determine the sub solutions that are installed.
- `enablePortalIntegration`
- `skipInternalServerTools` 

| OTK Type </br> `otk.type` | Installed Sub solution Kits  | Additional Configuration Neeed |
| ---------------------- | ---------------------  | ------------------ |
| `SINGLE` | <ul> <li>OTK Assertions</li> <li>OTK Configuration</li> <li>Shared OAuth Resources</li> <li>Internal: OAuth Validation Point</li> <li>Internal: Endpoint to access the client persistence layer</li> <li>Internal: Endpoint to access the session persistence layer</li> <li>Internal: Endpoint to access the token persistence layer</li><li>DMZ: OAuth 2.0 and OpenID Connect endpoints</li> <li>If `otk.skipInternalServerTools` is `false` <ul> <li>Internal: Server Tools</li> </ul> </li> <li>If `otk.database.type` is `mysql` or `oracle` <ul> <li>Persistence Layer: MySQL or Oracle</li> </ul> </li> <li>If `otk.database.type` is `cassandra` <ul> <li>Persistence Layer: Cassandra</li> </ul> </li> <li>if `otk.enablePortalIntegration` is `true` <ul> <li>Shared Portal Resources</li> <li> if `otk.database.type` is `mysql` or `oracle` <ul><li>Portal Persistence Layer: MySQL or Oracle</li></ul> </li> <li> if `otk.database.type` is `cassandra` <ul><li>Portal Persistence Layer: Cassandra</li></ul> </li> </ul> </li> <ul>  | 
| `INTERNAL` </br></br> Does not support <ul><li>Portal integration</li><li>Ephemeral Gateway</li><ul> | <ul> <li>OTK Assertions</li><li>OTK Configuration</li> <li>Shared OAuth Resources</li><li>Internal: OAuth Validation Point</li> <li>Internal: Endpoint to access the client persistence layer</li> <li>Internal: Endpoint to access the session persistence layer</li> <li>Internal: Endpoint to access the token persistence layer</li> <li>If `skipInternalServerTools` is `false` <ul> <li>Internal: Server Tools</li> </ul> </li> <li>If `otk.database.type` is `mysql` or `oracle` <ul> <li>Persistence Layer: MySQL or Oracle</li> </ul> </li> <li>If `otk.database.type` is `cassandra` <ul> <li>Persistence Layer: Cassandra</li> </ul> </li> <ul> | <ul><li>DMZ Gateway details: <ul><li>`otk.dmzGatewayHost`</li><li>`otk.dmzGatewayPort`</li><li>`otk.cert.dmzGatewayCert`</li><li>`otk.cert.dmzGatewayIssuer`</li><li>`otk.cert.dmzGatewaySerial`</li><li>`otk.cert.dmzGatewaySubject`</li></ul></li></ul>
| `DMZ` </br></br> Does not support <ul><li>Portal integration</li><li>Ephemeral Gateway</li><ul> | <ul><li>OTK Assertions</li> <li>OTK Configuration</li> <li>OAuth Resources</li> <li>DMZ: OAuth 2.0 and OpenID Connect endpoints</li><ul>|<ul><li>Internal Gateway details: <ul><li>`otk.internalGatewayHost`</li><li>`otk.internalGatewayPort`</li><li>`otk.cert.internalGatewayCert`</li><li>`otk.cert.internalGatewayIssuer`</li><li>`otk.cert.internalGatewaySerial`</li><li>`otk.cert.internalGatewaySubject`</li></ul></li></ul>

## OTK Database
### MySQL or Oracle database (`otk.database.type:mysql/oracle`) 
OTK MySQL or Oracle can be auto upgraded using the kubernetes job by setting `otk.database.dbUpgrade` to `true`. 
> :information_source: **Important** <br>
> If using existing non liquibase OTK DB, then perform manual OTK DB upgrade and set `otk.database.changeLogSync` to true. </br>This is a onetime activity to initialize liquibase related tables on OTK DB. Set to false for successive helm upgrade.

Properties related to OTK database install/Upgrade.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `otk.database.dbUpgrade`          | Enable/Disable OTK DB Upgrade| `true` |
| `otk.database.waitTimeout`        | OTK database connection wait timeout in seconds  | `60`|
| `otk.database.useDemoDb`          | Enable/Disable OTK Demo DB | `true` |
| `otk.database.sql.createTestClients`   | Enable/Disable creation of test clients | `true` |
| `otk.database.sql.testClientsRedirectUrlPrefix`   | The value of redirect_uri prefix (Example: https://test.com:8443) required for demo test clients  | `true`  |
| `otk.database.changeLogSync`      | If using existing non liquibase OTK DB then perform manual OTK DB upgrade and set 'changeLogSync' to true. <br/> This is a onetime activity to initialize liquibase related tables on OTK DB. Set to false for successive helm upgrade. | `false`|

To configure external mysql/oracle database as OTK db, configure properties in below table.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `otk.database.updateConnection`   | Update database connection properties during helm upgrade | `true`|
| `otk.database.connectionName`     | OTK database connection name | `OAuth`
| `otk.database.existingSecretName` | Point to an existing OTK database Secret |
| `otk.database.username`           | OTK database user name |
| `otk.database.password`           | OTK database password |
| `otk.database.ddlUsername`        | OTK database user name used for OTK DB creation (optional data definition language user) | `otk.database.username`
| `otk.database.ddlPassword`        | OTK database password used for OTK DB creation (optional data definition language password)| `otk.database.password`
| `otk.database.sql.type`           | OTK database type (mysql/oracle/cassandra) | `mysql`
| `otk.database.sql.jdbcURL`        | OTK database sql jdbc URL (oracle/mysql) |
| `otk.database.sql.jdbcDriverClass`| OTK database sql driver class name (oracle/mysql) |
| `otk.database.sql.databaseName`   | OTK database Oracle database name or Demo db name |
| `otk.database.properties`         | OTK database additional properties  | `{}`
| `otk.database.sql.connectionProperties`| OTK database mysql connection properties (oracle/mysql)  | `{}`

Optionally, OTK also supports read only database connection for MySQL and Oracle

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
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

```
otk:
  ....
  ......
  database:
    type: mysql
    connectionName: OAuth
    dbUpgrade: true
    useDemoDb: false
    username: otk_user
    password: mypassword
    properties: {"maximumPoolSize":15, "minimumPoolSize":3}
    sql:
      jdbcURL: jdbc:mysql://mysql-server:3306/otk_db
      jdbcDriverClass: com.mysql.jdbc.Driver
      connectionProperties: {"c3p0.maxPoolSize":15,"c3p0.maxConnectionAge":0,"c3p0.maxIdleTime":0}
....
.....
```
### Cassandra database  (`otk.database.type:mysql/oracle`) 
> :information_source: **Important** <br>
> Install or Upgrade of OTK database on Cassandra is not supported.

Configure cassandra connection properties
| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `otk.database.updateConnection`   | Update database connection properties during helm upgrade | `true`|
| `otk.database.connectionName`     | OTK database connection name | `OAuth`
| `otk.database.existingSecretName` | Point to an existing OTK database Secret |
| `otk.database.username`           | OTK database user name |
| `otk.database.password`           | OTK database password |
| `otk.database.cassandra.connectionPoints`  | OTK database cassandra connection points (comma seperated)  |
| `otk.database.cassandra.port`              | OTK database cassandra connection port  |
| `otk.database.cassandra.keyspace`          | OTK database cassandra keyspace |
| `otk.database.cassandra.driverConfig`      | OTK database cassandra driver config (Gateway 11+) | `{}`
| `otk.healthCheckBundle.enabled`            | Enable/Disable installation of OTK health check service bundle | `true`
| `otk.healthCheckBundle.useExisting`        | Use exising OTK health check service bundle | `false`
| `otk.healthCheckBundle.name`               | OTK health check service bundle name | `otk-health-check-bundle-config`
| `otk.livenessProbe.enabled`                | Enable/Disable. Requires otk.healthCheckBundle.enabled set to true and OTK version >= 4.6.

```
otk:
  ....
  ......
  database:
    type: cassandra
    connectionName: OAuth_Cassandra
    username: cassandra
    password: mypassword
    properties: {"localDataCenterName" : "dc1"}
    cassandra:
      connectionPoints: cassandra-c1,cassandra-c2
      port: 9042
      keyspace: otk_db
....
.....
```

### Customizations

OTK customizations can be configured using Kubernetes config maps or secrets. Existing config maps and secrets can be configured as below.

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `otk.customizations.existingBundle.enabled` | Enable mounting existing configMaps/Secrets that contain OTK Bundles - see values.yaml for more info | `false`  |


> :information_source: **Important** <br>
> In Ephemeral Gateway, the sequence of bundles are determined by alphabetical order of directory names & subsequent bundlefile names within the directories
> By default, OTK skmult & bundle files are hosted in a directory by name '000OTK' so that they are executed first
> Even the bundle names are prefixed appropriately to ensure an alphabetical order
> Any custom bundles related to OTK should be executed after these are executed.
> It is recommended to host custom bundles within folder names prefixed with '1' or '2' so as to maintain the order

### Health checks
> :information_source: **Note** <br>
> In Database backed Gateway, its recomended not to enable health checks of OTK at the time of install.
> Also, OTK version should be >= 4.6.1 and valid only for SINGLE and INTERNAL OTK type installation.

Gateway health checks can be replaced with OTK health checks if needed. If enabled, OTK health check bundle which has the health check service is applied to the gateway. The bundle can be found [here](../../charts/gateway/bundles/otk-healthcheck.bundle) and can be customized. Existing bundle config map can also be provided by setting the `otk.healthCheckBundle.useExisting` to `true` and providing the bundle name at `otk.healthCheckBundle.name`

| Parameter                        | Description                               | Default                                                      |
| -----------------------------    | -----------------------------------       | -----------------------------------------------------------  |
| `otk.healthCheckBundle.enabled`            | Enable/Disable installation of OTK health check service bundle | `true`
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

### Miscellaneous configurations

`otk.forceInstallOrUpgrade` (true/false) - If true uninstalls OTK and installs it. Valid only for DB backed Gateway.
`otk.skipPostInstallationTasks` (true/false) - In case of dual Gateway installation, the post install tasks will update the INTERNAL/DMZ gateways configuration by updating customizations 
- Internal Gateway
  1. #OTK Client Context Variables 
  2. #OTK id_token configuration 
- DMZ Gateway:
  1. #OTK OVP Configuration
  2. #OTK Storage Configuration
 `otk.skipInternalServerTools` (true/false) - Skip installation of the optional sub solution Kit: Internal, Server Tools. The Oauth Manager & Oauth Test Client will not be installed
 `otk.job.scheduledTasks` - List of database maintenance jobs [cron-jobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/). Applicable only in case of ephemeral gateways. Gateway schedule tasks are disabled and crron-job is used to perform database maintenance of OTK MySQL/Oracle db.
