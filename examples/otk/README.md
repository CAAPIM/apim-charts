# OTK Gateway Deployment Examples
These examples cover different ways in which OTK can be deployed on Gateway using Gateway Helm Chart.

At a high level the deployment can be categorized based on Gateway type (database backed/Ephemeral) and OTK Type (SINGLE/INTERNAL/DMZ). It determines how the OTK is installed or upgraded on the gateway.

OTK installation involves
1. Installation or upgrade of OTK solution kit.
2. Installation or upgrade of OTK Database.
3. Installation or upgrade of OTK customizations.

| OTK Type | Database backed Gateway <br> (database.enabled=true) | Ephemeral Gateway <br> (database.enabled=false) |
| ------------------------   | ---------------------- | ---------------------  |
| Solution Kit Install/Upgrade | <ul><li>Uses post-install kubernetes Job (Headless installation - Restman)</li><li>Runs after Gateway startup</li></ul> |  <ul><li>Uses kubernetes init-container to bootstrap Gateway with OTK solution kits </li><li> Runs before start of Gateway</li><li> OTK Dual Gateway (DMZ/INTERNAL) configuration is not supported. </li></ul> |
| OTK Database Install/upgrade </br> ***(NA for OTK type DMZ and OTK DB type - Cassandra)*** | <ul><li>Uses pre-install kubernetes Job (Lisqubase scripts)</li><li>Runs before Gateway startup</li></ul> | <ul><li>Uses pre-intall kubernetes Job (Lisqubase scripts)</li><li>Runs before Gateway startup</li></ul> |
| Customizations | <ul><li> Restman bundles applied using restman calls after Gateway startup which can be Kubernetes Config Maps and/or Secrets </li><li>Init containers - Bootstraped on to Gateway</li></ul>  | <ul><li>Restman bundles bootstrapped on to gateway which can be Kubernetes Config Maps and/or Secrets</li><li> Init Containers - Bootstraped on to Gateway</li></ul> |

* [Quick Start](#quick-start)
* [OTK with MySQL/Oracle database](#otk-with-mysql-or-oracle-database)
* [OTK With Cassandra database](#otk-with-cassandra-database)
* [Customizations](#customizations)

### Quick Start

OTK can be installed by okt.enabled=true. This will create OTK database using MySQL subchart and then bootstaps the OTK bundles on to the gateway (type SINGLE). The usage of MySQL subchart for OTK database do not represent production configuration.

Add the layer7 repository:

    helm repo add layer7 https://caapim.github.io/apim-charts/
    helm repo update

Then, you can install OTK by:

    helm install my-ssg layer7/gateway --set-file "license.value=path/to/license.xml"  --set "otk.enabled=true" --set "license.accept=true"

### OTK with MySQL or Oracle database

### OTK With Cassandra database

### Customizations



