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
For StatefulSet with headless service, use pod hostname format
*/}}
{{- define "kafka-brokers" -}}
    {{- if and .Values.kafka.kafka .Values.kafka.kafka.listeners }}
        {{- /* Custom Kafka subchart - use StatefulSet pod hostname */ -}}
        {{- printf "%s-portal-kafka-0.%s-portal-kafka:%g" .Release.Name .Release.Name .Values.kafka.kafka.listeners.internal.port -}}
    {{- else if and .Values.kafka.listeners .Values.kafka.listeners.client }}
        {{- /* Bitnami Kafka chart */ -}}
        {{- printf "%s-kafka:%g" .Release.Name .Values.kafka.listeners.client.containerPort -}}
    {{- else }}
        {{- /* Default fallback - use StatefulSet pod hostname */ -}}
        {{- printf "%s-portal-kafka-0.%s-portal-kafka:9092" .Release.Name .Release.Name -}}
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
{{- $messages := append $messages (include "intelligenceServer.validateValues.autoDiscoveryRBAC" .) -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate values of intelligenceServer - RBAC should be enabled when autoDiscovery is enabled */}}
{{- define "intelligenceServer.validateValues.autoDiscoveryRBAC" -}}
{{- if and .Values.intelligenceServer.kafka.autoDiscovery.enabled (not .Values.rbac.create ) }}
intelligenceServer: rbac-create
    By specifying ".Values.intelligenceServer.kafka.autoDiscovery.enabled=true"
    an initContainer will be used to auto-detect the external IPs/ports by querying the
    K8s API. Please note this initContainer requires specific RBAC resources.
{{- end -}}
{{- if and .Values.intelligenceServer.kafka.autoDiscovery.enabled (not .Values.serviceAccount.automountServiceAccountToken) }}
intelligenceServer: serviceAccount-automountServiceAccountToken
    By specifying ".Values.intelligenceServer.kafka.autoDiscovery.enabled=true"
    an initContainer will be used to auto-detect the external IPs/ports by querying the
    K8s API. Please note this initContainer requires the service account token. Please set serviceAccount.automountServiceAccountToken=true
{{- end -}}
{{- end -}}

{{/*
Generate Kafka hostname for APIM_SSG_HOSTNAME
Uses the full hostname pattern with -kafka suffix
*/}}
{{- define "kafka-public-host" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "%s-%s.%s" .Values.portal.defaultTenantId "kafka" .Values.portal.domain -}}
    {{- else }}
        {{- printf "%s-%s-kafka.%s" .Values.portal.defaultTenantId .Values.global.subdomainPrefix .Values.portal.domain -}}
    {{- end }}
{{- end -}}