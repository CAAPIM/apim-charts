# Grafana Example

## Prerequisite:
1. A Gateway license (`LICENSE.xml`) in this directory
2. Customise Dashboard using JSON file (optional)
```
files:
  enabled: true
  serviceMetricJSONPath: "files/grafana/gateway-service-metrics.json"
```
3. By Default, Grafana Dashboard is named as "grafana-configmap" and Grafana Secret as "grafana-secret" , update the values if needed


## Usage:
`apim-charts/gateway/examples/gateway> helm install  <release_name>  ~/apim-charts/gateway -f ./ssg-grafana-service-metrics.yaml --set-file "license.value=./LICENSE.xml" --set "license.accept=true"`

The `<release_name>` can be any alphanumeric string, for example "ssg-grafana-service-metrics" or "ssg-metrics-01".




# Hazelcast Example

## Connect Gateway to external Hazelcast 3.x Datastore

## Prerequisite:
1. A Gateway license (`LICENSE.xml`) in this directory
2. Enable External Hazelcast Storage for a Container Gateway

### Create the hazelcast-client.xml file in templates/configmap.yaml
```
hazelcast-xml: |+
<hazelcast-client
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.hazelcast.com/schema/client-config
http://www.hazelcast.com/schema/client-config/hazelcast-client-config-3.10.xsd"
xmlns="http://www.hazelcast.com/schema/client-config">
<instance-name>{{ .Release.Name }}-{{ .Release.Namespace }}</instance-name>
<network>
<cluster-members>
{{ if .Values.hazelcast.external }}
<address>{{ required "Please set an external Hazelcast URL in values.yaml" .Values.hazelcast.url }}</address>
{{ else }}
<address>{{ .Release.Name }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.hazelcast.service.port }}</address>
{{ end }}
</cluster-members>
<connection-attempt-limit>10</connection-attempt-limit>
<redo-operation>true</redo-operation>
</network>
<connection-strategy async-start="false" reconnect-mode="ON" />
</hazelcast-client>

```
### Mount the Hazelcast Client Configuration file to the volumes section inside the templates/deployment.yaml file.
```
{{ if or (.Values.hazelcast.enabled) (.Values.hazelcast.external) }}
- name: {{ template "gateway.fullname" . }}-hazelcast-client
mountPath: /opt/SecureSpan/Gateway/node/default/etc/bootstrap/assertions/ExternalHazelcastSharedStateProviderAssertion/hazelcast-client.xml
subPath: hazelcast-client.xml
{{ end }}

```
### Configure the EXTRA_JAVA_ARGS environment variables in templates/configmap.yaml
```
EXTRA_JAVA_ARGS: {{ template "gateway.javaArgs" . }} -Dcom.l7tech.server.extension.sharedCounterProvider=externalhazelcast -Dcom.l7tech.server.extension.sharedKeyValueStoreProvider=externalhazelcast -Dcom.l7tech.server.extension.sharedClusterInfoProvider=externalhazelcast
```


## Usage:
`apim-charts/gateway/examples/gateway> helm install  <release_name>  ~/apim-charts/gateway  -f ./ssg-hazelcast-service-metrics.yaml --set-file "license.value=./LICENSE.xml" --set "license.accept=true"`

The `<release_name>` can be any alphanumeric string, for example "ssg-hazelcast-service-metrics" or "ssg-metrics-01".
