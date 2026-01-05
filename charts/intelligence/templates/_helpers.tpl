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
{{- if .Values.intelligenceServer.serviceAccount.create -}}
    {{ default (include "intelligence.fullname" .) .Values.intelligenceServer.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.intelligenceServer.serviceAccount.name }}
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
{{- if and (not .Values.intelligenceServer.useExistingPullSecret) (.Values.intelligenceServer.imagePullSecret.enabled) }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" .Values.global.portalRepository .Values.intelligenceServer.imagePullSecret.username .Values.intelligenceServer.imagePullSecret.password (printf "%s:%s" .Values.intelligenceServer.imagePullSecret.username .Values.intelligenceServer.imagePullSecret.password | b64enc) | b64enc }}
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
{{- if and .Values.intelligenceServer.kafka.autoDiscovery.enabled (not .Values.intelligenceServer.rbac.create ) }}
intelligence: rbac-create
    By specifying ".Values.intelligenceServer.kafka.autoDiscovery.enabled=true"
    an initContainer will be used to auto-detect the external IPs/ports by querying the
    K8s API. Please note this initContainer requires specific RBAC resources.
{{- end -}}
{{- if and .Values.intelligenceServer.kafka.autoDiscovery.enabled (not .Values.intelligenceServer.serviceAccount.automountServiceAccountToken) }}
intelligence: serviceAccount-automountServiceAccountToken
    By specifying ".Values.intelligenceServer.kafka.autoDiscovery.enabled=true"
    an initContainer will be used to auto-detect the external IPs/ports by querying the
    K8s API. Please note this initContainer requires the service account token. Please set serviceAccount.automountServiceAccountToken=true
{{- end -}}
{{- end -}}

{{/*
Generate Intelligence public host based on global configurations
*/}}
{{- define "intelligence.publicHost" -}}
    {{- $domain := default "example.com" .Values.global.domain -}}
    {{- $subdomainPrefix := default "dev-portal" .Values.global.subdomainPrefix -}}
    {{- $defaultTenantId := default "apim" .Values.global.defaultTenantId -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "%s-%s.%s" $defaultTenantId "ssg" $domain -}}
    {{- else if .Values.global.saas }}
         {{- printf "apim-ssg-%s.%s" $subdomainPrefix $domain -}}
    {{- else }}
         {{- printf "%s-ssg.%s" $subdomainPrefix $domain -}}
    {{- end }}
{{- end -}}

{{/*
Generate Intelligence public port
Defaults to 443 for HTTPS, or from global.papiPublicPort if set
*/}}
{{- define "intelligence.publicPort" -}}
    {{- if .Values.global.papiPublicPort }}
        {{- .Values.global.papiPublicPort -}}
    {{- else }}
        {{- "443" -}}
    {{- end }}
{{- end -}}