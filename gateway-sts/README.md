# Layer7 API Gateway - OAUTH TOOLKIT

This Chart deploys the API Gateway - OAUTH TOOLKIT with the following `optional` subcharts: hazelcast, mysql, influxdb, grafana.

It's targeted at Gateway v10.x onward.

# Install the Chart
First we need to download the dependent charts.

`$ helm dep up ./charts/gateway-1.0.2-modified`

You should see a commandline output similar to this,

>Saving 4 charts<br/>
>Downloading hazelcast from repo https://hazelcast-charts.s3.amazonaws.com/<br/>
>Downloading influxdb from repo https://helm.influxdata.com/<br/>
>Downloading grafana from repo https://charts.bitnami.com/bitnami<br/>
>Downloading mysql from repo https://kubernetes-charts.storage.googleapis.com<br/>
>

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

## OTK Deployment Examples:
- refer to the apim-charts/examples for more details

### Subcharts
*  Gateway (default: enabled) ==> TBD
*  Hazelcast (default: disabled) ==> https://github.com/helm/charts/tree/master/stable/hazelcast
*  MySQL (default: enabled)  ==> https://github.com/helm/charts/tree/master/stable/mysql
*  InfluxDb (default: disabled) ==> https://github.com/influxdata/helm-charts/tree/master/charts/influxdb
*  Grafana (default: disabled) ==> https://github.com/bitnami/charts/tree/master/bitnami/grafana
