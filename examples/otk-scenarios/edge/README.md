# Single Gateway OTK with base selections

## Prerequisite:
1. A Gateway license (`LICENSE.xml`) in this directory
2. OTK solution kit and Liquibase files to create OTK database schema must exist on Gateway container image under /tmp (e.g. /tmp/OAuthSolutionKit-4.4.1-4425.sskar and /tmp/otk-db-liquibase/)

## Usage:
`apim-charts/examples/otk-scenarios> helm install -f ./ssg-single-otk-base-selection-values.yaml <release_name> ../../gateway-sts --set-file "ssg.license.value=./LICENSE.xml" --set "ssg.license.accept=true"`

The `<release_name>` can be any alphanumeric string, for example "ssg-base-select-otk" or "ssg-dev01". This `release_name` value will also need to be added to the following 2 lines inside the ssg-single-otk-base-selection-values.yaml file.

- otkJdbcUrl: jdbc:mysql://`<release_name>`-mysql:3306/otk_db

- --url="jdbc:mysql://`<release_name>`-mysql:3306/otk_db?createDatabaseIfNotExist=true&useSSL=false"

## Trying It Out With Docker for Desktop
Replace the following in the ssg-single-otk-base-selection-values.yaml file,
```
    annotations:
      cloud.google.com/load-balancer-type: "Internal"
```
with,
```
    annotations: {}
```

## Edge Gateway Deployment
Head to the `gateway` folder