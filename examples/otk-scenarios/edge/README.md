# Single Gateway OTK with base selections

## Prerequisite:
1. A Gateway license (`LICENSE.xml`) in this directory
2. The OTK database should be setup independent of the deployment. The database connection details should be provided in the chart

## Usage:
`apim-charts/examples/otk-scenarios/edge> helm install -f ./ssg-single-otk-base-selection-values.yaml <release_name> ../../../charts/gateway-otk --set-file "ssg.license.value=./LICENSE.xml" --set "ssg.license.accept=true"`

The `<release_name>` can be any alphanumeric string, for example "ssg-base-select-otk" or "ssg-dev01". 

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