{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "intelligence.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "intelligence.fullname" -}}
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
{{- define "intelligence.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
 Set the service account name for the Portal Stack
 */}}
{{- define "intelligence.serviceAccountName" -}}
{{- if .Values.global.serviceAccountName }}
   {{ default "default" .Values.global.serviceAccountName }}
{{- else }}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "intelligence.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Get "intelligence" database name
*/}}
{{- define "intelligence-db-name" -}}
    {{ if .Values.global.legacyDatabaseNames }}
        {{- print "intelligence" }}
    {{- else }}
        {{- $f:= .Values.global.subdomainPrefix -}}
        {{ if empty $f }}
            {{- fail "Please define subdomainPrefix in values.yaml" }}
        {{- else }}
            {{- printf "%s_%s" $f "intelligence" | replace "-" "_" -}}
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
Get "kafka" brokers
*/}}
{{- define "kafka-brokers" -}}
    {{- $kafkaName := "kafka" -}}
    {{- if .Values.kafka.fullnameOverride -}}
        {{- $kafkaName = .Values.kafka.fullnameOverride -}}
    {{- else -}}
        {{- $kafkaName = printf "%s-kafka" .Release.Name -}}
    {{- end -}}
    {{- if and .Values.kafka.kafka .Values.kafka.kafka.listeners }}
        {{- /* Custom Kafka subchart */ -}}
        {{- printf "%s:%g" $kafkaName .Values.kafka.kafka.listeners.internal.port -}}
    {{- else if and .Values.kafka.listeners .Values.kafka.listeners.client }}
        {{- /* Bitnami Kafka chart */ -}}
        {{- printf "%s:%g" $kafkaName .Values.kafka.listeners.client.containerPort -}}
    {{- else }}
        {{- /* Default fallback */ -}}
        {{- printf "%s:9092" $kafkaName -}}
    {{- end }}
{{- end -}}

{{/*
Create Image Pull Secret
*/}}
{{- define "intelligence-imagePullSecret" }}
{{- if and (not .Values.intelligence.useExistingPullSecret) (.Values.intelligence.imagePullSecret.enabled) }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" .Values.global.portalRepository .Values.intelligence.imagePullSecret.username .Values.intelligence.imagePullSecret.password (printf "%s:%s" .Values.intelligence.imagePullSecret.username .Values.intelligence.imagePullSecret.password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{- define "intelligence.validate" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "intelligence.validateValues.autoDiscoveryRBAC" .) -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate values of intelligence - RBAC should be enabled when autoDiscovery is enabled */}}
{{- define "intelligence.validateValues.autoDiscoveryRBAC" -}}
{{- if and .Values.intelligence.kafka.autoDiscovery.enabled (not .Values.intelligence.rbac.create ) }}
intelligence: rbac-create
    By specifying ".Values.intelligence.kafka.autoDiscovery.enabled=true"
    an initContainer will be used to auto-detect the external IPs/ports by querying the
    K8s API. Please note this initContainer requires specific RBAC resources.
{{- end -}}
{{- if and .Values.intelligence.kafka.autoDiscovery.enabled (not .Values.serviceAccount.automountServiceAccountToken) }}
intelligence: serviceAccount-automountServiceAccountToken
    By specifying ".Values.intelligence.kafka.autoDiscovery.enabled=true"
    an initContainer will be used to auto-detect the external IPs/ports by querying the
    K8s API. Please note this initContainer requires the service account token. Please set serviceAccount.automountServiceAccountToken=true
{{- end -}}
{{- end -}}
