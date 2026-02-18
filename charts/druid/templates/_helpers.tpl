{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "druid.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "druid.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "druid.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
 Set the service account name for the Portal Stack
 */}}
{{- define "druid.serviceAccountName" -}}
{{- if .Values.global.serviceAccountName }}
   {{ default "default" .Values.global.serviceAccountName }}
{{- else }}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "druid.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
{{- end -}}



{{/*
Get "druid" database name
*/}}
{{- define "druid-db-name" -}}
    {{ if .Values.global.legacyDatabaseNames }}
        {{- print "druid" }}
    {{- else }}
        {{- $f:= .Values.global.subdomainPrefix -}}
        {{ if empty $f }}
            {{- fail "Please define subdomainPrefix in values.yaml" }}
        {{- else }}
            {{- printf "%s_%s" $f "druid" | replace "-" "_" -}}
        {{- end }}
    {{- end }}
{{- end -}}


{{/*
Get "portal" database name
*/}}
{{- define "portal-db-name" -}}
    {{ if .Values.global.legacyDatabaseNames }}
        {{- print "portal" }}
    {{- else }}
        {{- $f:= .Values.global.subdomainPrefix -}}
        {{ if empty $f }}
            {{- fail "Please define subdomainPrefix in values.yaml" }}
        {{- else }}
            {{- printf "%s_%s" $f "portal" | replace "-" "_" -}}
        {{- end }}
    {{- end }}
{{- end -}}


{{/*
Get "database-port" based on databaseType value
*/}}

{{- define "database-port" -}}
        {{- print .Values.global.databasePort -}}
{{- end -}}

{{/*
Portal Docops page
*/}}
{{- define "portal.help.page" -}}
{{- printf "%s" "https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-developer-portal/5-0.html" -}}
{{- end -}}

{{- define "minio.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Return the Master Server peers
*/}}
{{- define "seaweedfs.master.servers" -}}
{{- $peers := list -}}
{{- $masterFullname := "seaweedfs-s3"  -}}
{{- $masterHeadlessSvcName := printf "seaweedfs-s3"  -}}
{{- $clusterDomain := .Values.seaweedfs.clusterDomain -}}
{{- $masterPort := int .Values.seaweedfs.master.port -}}
{{- $namespace := .Release.Namespace -}}
{{- range $i := until (int .Values.seaweedfs.replicaCount) }}
    {{- $peers = append $peers (printf "%s-%d.%s.%s.svc.%s:%d" $masterFullname $i $masterHeadlessSvcName $namespace $clusterDomain $masterPort) -}}
{{- end -}}
{{- print (join "," $peers) -}}
{{- end -}}

{{/*
Construct the Kafka broker service name for internal connections
*/}}
{{- define "druid.kafka-brokers" -}}
    {{- $kafkaName := "" -}}
    {{- if .Values.kafka.brokerService -}}
        {{- if ne .Values.kafka.brokerService "kafka" -}}
            {{- $kafkaName = .Values.kafka.brokerService -}}
        {{- else -}}
            {{- $kafkaName = printf "%s-kafka" .Release.Name -}}
        {{- end -}}
    {{- else -}}
        {{- $kafkaName = printf "%s-kafka" .Release.Name -}}
    {{- end -}}
    {{- printf "%s:%s" $kafkaName (.Values.kafka.brokerPort | toString) -}}
{{- end -}}