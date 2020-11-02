# OTK Gateway Deployment Examples

## This Chart is currently in an alpha state
Requires a custom Gateway image, more details to follow in the coming weeks.

## Prerequisite:
1. A Gateway license (`LICENSE.xml`)
2. OTK solution kit and Liquibase files to create OTK database schema must exist on Gateway container image under /tmp (e.g. /tmp/OAuthSolutionKit-4.4.1-4425.sskar and /tmp/otk-db-liquibase/)

## Edge Gateway Folder
Examples:
- Sample deployment files for the Edge OTK Gateway in the [Dual Gateway Scenario](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-4/installation-workflow/install-the-oauth-solution-kit/dual-gateway-scenario.html)
- Sample deployment files for the [Single Gateway Scenario](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-4/installation-workflow/install-the-oauth-solution-kit/install-otk-with-api-portal-integration.html)

## Sts Gateway folder
Examples:
- Sample deployment files for the STS OTK Gateway in the [Dual Gateway Scenario](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-management-oauth-toolkit/4-4/installation-workflow/install-the-oauth-solution-kit/dual-gateway-scenario.html)

## Notes

The sample deployment charts utilize the MySQL container without replication for demo purposes. For production deployment, an external MySQL server cluster should be created and managed seperately with replication and content backup.
