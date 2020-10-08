# Edge Gateway

## Prerequisite:
1. A Gateway license (`LICENSE.xml`) in this directory
2. OTK solution kit and Liquibase files to create OTK database schema must exist on Gateway container image under /tmp (e.g. /tmp/OAuthSolutionKit-4.4.1-4425.sskar and /tmp/otk-db-liquibase/)
3. Download the dependent Charts.

## Usage:
`apim-charts/examples/gateway/edge-gateway> ./ssg-edge-deploy.sh`

## Options:
To change release name. Edit `ssg-edge-deploy.sh`:
 - `STS_RELEASE_NAME="ssg-sts"`
 - `EDGE_RELEASE_NAME="ssg-edge"` (e.g. `EDGE_RELEASE_NAME="username-ssg-edge-v4"` for a shared environment to identify pod owner and version)

## Deployment Modes:
There is currently only 1 mode available for the Edge Gateway, which is MySQL db-backed.

## Trying It Out With Docker for Desktop
Replace the following in the ssg-edge-values-env-01.yaml file,
```
    annotations:
      cloud.google.com/load-balancer-type: "Internal"
```
with,
```
    annotations: {}
```

## Health Check:
The sample is using an OTK specific readiness check which targets the 200 OK response code
from an endpoint that the OTK solution provides. This provides a more accurate measure of 
"ready" for the Edge Gateway.

## Potential Environment Issue:
The ssg-edge-deploy.sh uses --wrap=0 in the following two commands
```
STS_KEY=$(base64 ./ssg-sts.p12 --wrap=0)
EDGE_KEY=$(base64 ./ssg-edge.p12 --wrap=0)
```
We have seen in our test enviroment that depending on the OS, the --wrap=0 is not required. 
And when specified in incompatible environment, you may get errors like 
```
Error: unable to build kubernetes objects from release manifest: error validating "": error validating data: unknown object type "nil" in Secret.data.SSG_SSL_KEY"
```