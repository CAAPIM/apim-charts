# OTK Gateway Deployment Examples

## Prerequisite:
1. A Gateway license (`LICENSE.xml`)
2. OTK solution kit and Liquibase files to create OTK database schema must exist on Gateway container image under /tmp (e.g. /tmp/OAuthSolutionKit-4.4.1-4425.sskar and /tmp/otk-db-liquibase/)
3. Download the dependent Charts by navigating to the location of the `gateway-1.0.2-modified` chart and run this command.
`$ helm dep up ../gateway-1.0.2-modified`. You should see a commandline output similar to this,

>Saving 4 charts<br/>
>Downloading hazelcast from repo https://hazelcast-charts.s3.amazonaws.com/<br/>
>Downloading influxdb from repo https://helm.influxdata.com/<br/>
>Downloading grafana from repo https://charts.bitnami.com/bitnami<br/>
>Downloading mysql from repo https://kubernetes-charts.storage.googleapis.com<br/>

## Edge-Gateway Folder
Examples:
- Sample deployment files for the Edge OTK Gateway in the [Dual Gateway Scenario](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-4/installation-workflow/install-the-oauth-solution-kit/dual-gateway-scenario.html)
- Sample deployment files for the [Single Gateway Scenario](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-4/installation-workflow/install-the-oauth-solution-kit/install-otk-with-api-portal-integration.html)

## Sts-Gateway folder
Examples:
- Sample deployment files for the STS OTK Gateway in the [Dual Gateway Scenario](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-4/installation-workflow/install-the-oauth-solution-kit/dual-gateway-scenario.html)

## Notes

The sample deployment charts utilize the MySQL container without replication for demo purposes. For production deployment, an external MySQL server cluster should be created and managed seperately with replication and content backup.
