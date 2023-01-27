# OTK Gateway Deployment Examples

## The otk deployment can be fulfilled now
The gateway chart is now includes OTK deployment configuration. The OTK database should be setup independent of the deployment.

## Prerequisite:
1. A Gateway license (`LICENSE.xml`)
2. The database connection details should be provided in the chart

## Examples:
- Sample deployment files for the Edge OTK Gateway in the [Dual Gateway Scenario](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-4/installation-workflow/install-the-oauth-solution-kit/dual-gateway-scenario.html)
- Sample deployment files for the [Single Gateway Scenario](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-4/installation-workflow/install-the-oauth-solution-kit/install-otk-with-api-portal-integration.html)

## Notes
The sample deployment charts utilize the MySQL(for Gateway ssg DB) container without replication for demo purposes. For production deployment, an external MySQL server cluster should be created and managed seperately with replication and content backup.
