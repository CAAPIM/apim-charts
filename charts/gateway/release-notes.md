# Layer7 Gateway Chart Release Notes

Back to [Readme](./README.md#release-notes)

# Java 17
The Layer7 API Gateway is now running with Java 17 with the release of v11.1.00.

If you use Policy Manager, you will need to update to v11.1.00.

## 3.0.30 General Updates
Release notes will also be moved to a new file before merge...
**Note** Gateway restart required if using preview Redis features.
- Support added for running the Gateway without [Diskless Config](./README.md#diskless-configuration)
  - Uses node.properties which can be mounted via [Secret or Secret Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
  - Must be conciously enabled (limited to Gateway v11.1.1)
- Redis configuration update
  - Additional system properties for the key/value store assertion added (commented by default)
    - please refer to [Techdocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw11-1/policy-assertions/assertion-palette/service-availability-assertions/key-value-storage-assertions.html#_c8b71b7b-dd84-4ee6-9771-d0bc262c36e9_sys_prop_configs) for more details
  - Using new shared state provider config **(limited to Redis and Gateway v11.1.1)**
    - this new configuration is **not backwards or forwards compatible**
      - Please view [redis configuration](./README.md#redis-configuration) for more details on how to configure your values file.
    - config.redis is used to configure this
    - additional redis providers can be set directly in your values file via sharedStateProviders.additionalProviders
      - if using an existing secret that contains multiple providers with TLS, please use [Custom Config](./README.md#custom-configuration-files) to load the additional certs.
 - Configurable Java Min/Max Heap size
   - Java Min and Max Heap Size is now [configurable](./README.md#java-args)
 - Liquibase Log Level is now settable via database.liquibaseLogLevel.
   - default "off"
     - possible values
       - severe
       - warning
       - info
       - fine(debug)
       - off

## 3.0.29 OTK 4.6.3 Released
- The default image tag in values.yaml and production-values.yaml for OTK updated to **4.6.3**.
    - otk.job.image.tag: 4.6.3
- Liquibase version has been upgraded to 4.12.0 to enable offline Liquibase schema support for OTK Helm charts.
- UTFMB4 Character Set Support for MySQL.
- Fixed backward compatibility issue related to bootstrap director location for pre 4.6.2 OTK versions
  - For versions older than OTK 4.6.2, in values.yaml manually add a new parameter otk.bootstrapDir with value "." indicating current directory

## 3.0.28 General Updates
- Added a [Startup probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) for the Gateway Container.
  - Disabled by default

## 3.0.27 General Updates
- Default image updated to v11.1.00
  - Due to conflicting embedded Hazelcast versions between Gateway 10.x and 11.1, and between 11.0 and 11.1, a rolling update cannot be performed when upgrading to version 11.1 GA. Instead, follow the alternative steps:
    - Scale down your containers to zero.
      - Update the image tag to the target version (e.g., 11.1.00)
    - Scale up your containers back to their original state.
  - Hazelcast versions have not changed between 11.0 CR1/CR2 and 11.1 GA, rolling updates are supported between these Gateway versions.
- Added preview support for [OpenTelemetry](https://opentelemetry.io/)
  - Please see [Techdocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/11-1/install-configure-upgrade/configuring-opentelemetry-for-the-gateway.html) for more details about this integration
  - Preview feature (only available on Gateway v11.1.00)
  - An integration example is available [here](https://github.com/Layer7-Community/Integrations/tree/main/grafana-stack-prometheus-otel) that details how to deploy and configure an observability backend to use with the Gateway
    - OpenTelemetry is supported by [numerous vendors](https://opentelemetry.io/ecosystem/vendors/)
      - You are ***not required*** to use the observability stack that we provide as an example.
      - The observability stack that we provide ***is not*** production ready and should be used solely as an example or reference point.
  - [OpenTelemetry Configuration](./README.md#opentelemetry-configuration)
- Redis standalone now supports TLS and Password auth (only available on Gateway v11.1.00)
  - see [Redis configuration](./README.md#redis-configuration)
- Cipher Suites in [Gateway Application Ports](./README.md#gateway-application-ports) have been updated to reflect updates in Gateway v11.1.00. Please refer to [Techdocs](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/11-1/release-notes.html#concept.dita_ea0082004fb8c78a1723b9377f592085674b7ef7_jdk17) for more details. This configuration is ***disabled by default.***

## 3.0.26 General Updates
- Commented out Nginx specific annotations in the ingress configuration
  - If you are using an Nginx ingress controller you will need to add or uncomment the following annotation manually
    - nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    - [production-values.yaml](https://github.com/CAAPIM/apim-charts/blob/stable/charts/gateway/production-values.yaml#L792) sets this if you would like to use that as a starting point.
- Upgraded Hazelcast SubChart and set default image to latest versions.
- Added Gateway [Pod Disruption Budget](./README.md#pod-disruption-budgets)

## 3.0.25 OTK Schedule job success and failure limts
- Added configurable success and failure job history limit for OTK database maintenance schedule jobs.

## 3.0.24 General Updates
- Custom Volumes for initContainers and Sidecars
  - This allows configmaps/secrets to be mounted to initContainers and sideCars
    - customSideCarVolumes
    - customInitVolumes

## 3.0.23 OTK 4.6.2_202402 Released 
- Updated OTK image version value

## 3.0.22 General Updates
- Updated Chart ci values
  - no impact

## 3.0.21 General Updates
- Updated [Redis Configuration](./README.md#redis-configuration)
  - More context added for creating your own redis properties file
  - More context added for Redis auth
    - note: the Gateway only supports Redis master auth
  - Removed comments from values.yaml
- Added Graphman Bundle support to the bootstrap script
  - files that end in .json will be copied into the bootstrap folder


## 3.0.20 General Updates
- Updated image
  - Updated to Gateway 11.0.00_CR2
    - this will cause a restart if you are not overriding the default image

## 3.0.19 General Updates
- Updated image
  - Updated to Gateway 11.0.00_CR1
    - this will cause a restart if you are not overriding the default image
- Redis Integration
  - [Redis Configuration](./README.md#redis-configuration) options for the Gateway (future use)
  - Added Redis SubChart
- Ingress
  - Backend service is now more configurable allowing the management service to be exposed via ingress controller
    - ***this should only be done in environments where the ingress controller does not have a Public Address***
    - ingress.rules[n]backend can be set to "management"
- Restart on config change
  - A new flag has been added to facilitate auto redeploy of Gateways when there is a config change
  - Applies to the default config map only
    - does not include config.cwp, config.listenPorts or the Gateway Secret
- MySQL subChart updated
- Grafana subChart updated


## 3.0.18 General Updates
- OTK documentation updates.

## 3.0.17 OTK 4.6.2 Released
  - The default image tag in values.yaml and production-values.yaml for OTK updated to **4.6.2**.
    - otk.job.image.tag: 4.6.2
  - OTK DB install/upgrade using Liquibase scripts for MySql and Oracle.
    - otk.database.dbupgrade
  - OTK DB install/upgrade on the gateways MySQL container (MySQL subchart) - ***This is not supported or recommended for production use.***
    - otk.database.useDemodb
  - Install/upgrade OTK of type SINGLE on Ephemeral gateways using initContainer is now supported.
    - database.enabled: false
    - otk.type: SINGLE
  - Added OTK Connection properties to support c3p0 settings.
    - otk.database.connectionProperties
  - Added support OTK read-only connections for MySQL and Oracle.
    - otk.database.readOnlyConnection.*
  - Added support for OTK policies customization through config maps and secrets.
    - otk.customizations.existingBundle.enabled
  - OTK DMZ/Internal gateway certs can now be configured using values file.
    - otk.cert
> [!Important]  
> - To upgrade OTK to 4.6.2 installed over gateway with demo db as database, update helm repo, perform helm delete and install.
> - When upgrading OTK 4.6.2 on a db backed gateway, the gateway will restart as there is a change related to OTK health check bundle in gateway deployment. This can lead to failure of OTK upgrade. To circumvent this, please perform a helm upgrade `otk.healthCheckBundle.enabled` set to `false` and then upgrade to the 3.0.17.
> ```
> helm upgrade my-ssg --set-file "license.value=license.value=path/to/license.xml" --set "license.accept=true,otk.healthCheckBundle.enabled=false" layer7/gateway --version 3.0.16 -f ./values-production.yaml
> helm upgrade my-ssg --set-file "license.value=license.value=path/to/license.xml" --set "license.accept=true" layer7/gateway --version 3.0.17 -f ./values-production.yaml
> ```


## 3.0.16 General Updates
- Added resources to otk install job
  - otk.job.resources

## 3.0.15 General Updates
- Updated [bootstrap script](./README.md#bootstrap-script)
  - 'find' replaced with 'du'

## 3.0.14 General Updates
- Added pod labels and annotations to the otk-install job.
  - otk.job.podLabels
  - otk.job.podAnnotations

## 3.0.13 General Updates
- The OTK Install job now uses podSecurity and containerSecurity contexts if set.
- Updated how pod labels and annotations are templated in deployment.yaml

## 3.0.12 General Updates
Traffic Policies for Gateway Services are now configurable. The Kubernetes default for these options is `Cluster` if left unset.
- [Internal Traffic Policy](https://kubernetes.io/docs/concepts/services-networking/service-traffic-policy/#using-service-internal-traffic-policy)
- [External Traffic Policy](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip)


## 3.0.11 General Updates
Updates to Gateway Container Lifecycle.
- [A new preStop script has been added for graceful termination](./README.md#graceful-termination)
  - terminationGracePeriodSeconds must be greater than preStopScript.timeoutSeconds
- Container Lifecycle can be overridden for custom exec/http calls

## 3.0.10 General Updates
Custom labels and annotations have been extended to all objects the Gateway Chart deploys. Pod Labels and annotations have been added to the Gateway and PM-Tagger deployments.

- Additional Labels/Annotations apply to everything in this Chart's templates
```
# Additional Annotations apply to all deployed objects
additionalAnnotations: {}

# Additional Labels apply to all deployed objects
additionalLabels: {}
```

- Pod Labels/Annotations at the base level apply to the Gateway Pod
```
## Pod Labels for the Gateway Pod
## ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
podLabels: {}

# Pod Annotations apply to the Gateway Pod
## ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/
podAnnotations: {}
```

- PM-Tagger pod labels/annotations are separate
```
pmtagger:
  ...
  ## Pod Labels for the PM Tagger Pod
  ## ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
  podLabels: {}

  # Pod Annotations apply to the PM Tagger Pod
  ## ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/
  podAnnotations: {}
```

## 3.0.9 Updates to PM-Tagger
PM tagger has following additional configuration options
- [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#spread-constraints-for-pods)
- [Pod Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)
- [Container Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)
- [All PM-Tagger Configuration](./README.md#pm-tagger-configuration)

## 3.0.8 Updates to Hazelcast
The default image tag in values.yaml is updated to **5.2.1** and xsd version in configmap.yaml to **5.2**. The updates are due to vulnerability from CVE-2022-36437.
The updates are applied to both the gateway and gateway-otk chart.

## 3.0.7 General Updates
The bootstrap script has been updated to reflect changes to the Container Gateway's filesystem. The updates are currently limited to 10.1.00_CR3. Please see the [InitContainer Examples](https://github.com/Layer7-Community/Utilities/tree/main/gateway-init-container-examples) for more info .

The PM Tagger image default version tag been updated to 1.0.1.

## 3.0.6 General Updates
The default image tag in values.yaml and production-values.yaml for OTK updated to **4.6.1**. Support for liveness and readiness probes using OTK health check service.

## 3.0.5 General Updates
The default image tag in values.yaml and production-values.yaml, and the appVersion in Chart.yaml have been updated to **11.0.00**.

Before upgrading existing deployments, please see the [Container Gateway 11.0 Release Notes](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw-11-0/release-notes_cgw.html) for important information regarding the procedure.

## 3.0.4 General Updates
OTK installation and upgrade is now supported as part of Gateway charts.  Please refer to [OTK Install or Upgrade](./README.md#otk-install-or-upgrade) for more details.
[Gateway-OTK](../gateway-otk) is now deprecated.

## 3.0.2 General Updates
***The default image tag in values.yaml and production-values.yaml now points at specific GA or CR versions of the API Gateway. The appVersion in Chart.yaml has also been updated to reflect that. As of this release, that is 10.1.00_CR2***

To reduce reliance on requiring a custom/derived gateway image for custom and modular assertions, scripts and restman bundles a bootstrap script has been introduced. The script works with the /opt/docker/custom folder.

The best way to populate this folder is with an initContainer where files can be copied directly across or dynamically loaded from an external source.
- [InitContainer Examples](https://github.com/Layer7-Community/Utilities/tree/main/gateway-init-container-examples) - this repository also contains examples for custom health checks and configuration files.

The following configuration options have been added
- [Custom Health Checks](./README.md#custom-health-checks)
- [Custom Configuration Files](./README.md#custom-configuration-files)
- [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#spread-constraints-for-pods)
- [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
- [Pod Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)
- [Container Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)
- Http headers can also now be added to the liveness and readiness probes
- Ingress and HPA API Version validation has been updated to check for available APIs vs. KubeVersion
- SubCharts now show image repository and tags

### Upgrading to Chart v3.0.0
Please see the 3.0.0 updates, this release brings significant updates and ***breaking changes*** if you are using an external Hazelcast 3.x server. Services and Ingress configuration have also changed. Read the 3.0.0 Updates below and check out the [additional guides](./README.md#additional-guides) for more info.

## 3.0.0 Updates to Hazelcast
***Hazelcast 4.x/5.x servers are now supported*** this represents a breaking change if you have configured an external Hazelcast 3.x server.
- If you are using Gateway v10.1 and below you will either need to set *hazelcast.legacy.enabled=true* and use the following gateway image *docker.io/caapim/gateway:10.1.00_20220802* or update your external Hazelcast server.
- The included Hazelcast subChart has been updated to reflect this change

### 3.0.0 Updates to Ingress Configuration
Ingress configuration has been updated to include multiple hosts, please see [Ingress Configuration](./README.md#ingress-configuration) for more detail. You will need to update your values.yaml to reflect the changes.

## 3.0.0 General Updates
- You can now configure [Gateway Ports.](./README.md#port-configuration)
  This does not cover Kubernetes Service level configuration which will ***need to be updated*** to reflect your changes.

- New Management Service
  - Provides separation of concerns for external/management traffic. This was previously a manual step.
- [Autoscaling](./README.md#autoscaling)
- [Ingress Configuration](./README.md#ingress-configuration)
- [PM Tagger](./README.md#pm-tagger-configuration)
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

# Java 11
The Layer7 API Gateway is now running with Java 11 with the release of the v10.1.00. The Gateway chart's version has been incremented to 2.0.2.

Things to note and be aware of are the deprecation of TLSv1.0/TLSv1.1 and the JAVA_HOME dir has gone through some changes as well.

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