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
Note: When deployed as a subchart, .Values.portal.* is not available
      Use .Values.intelligence.* or .Values.global.* instead
*/}}
{{- define "kafka-public-host" -}}
    {{- $domain := .Values.intelligence.domain | default .Values.global.domain | default "example.com" -}}
    {{- $defaultTenantId := .Values.intelligence.defaultTenantId | default .Values.global.defaultTenantId | default "apim" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "%s-%s.%s" $defaultTenantId "kafka" $domain -}}
    {{- else }}
        {{- printf "%s-%s-kafka.%s" $defaultTenantId .Values.global.subdomainPrefix $domain -}}
    {{- end }}
{{- end -}}

{{/*
Generate TSSG (Gateway) public hostname for PAPI_PUBLIC_HOST
Uses the same pattern as portal's tssg-public-host helper
Note: When deployed as a subchart, .Values.portal.* is not available
      Use .Values.intelligence.* or .Values.global.* instead
*/}}
{{- define "tssg-public-host-for-intelligence" -}}
    {{- $domain := .Values.intelligence.domain | default .Values.global.domain | default "example.com" -}}
    {{- $defaultTenantId := .Values.intelligence.defaultTenantId | default .Values.global.defaultTenantId | default "apim" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "%s-%s.%s" $defaultTenantId "ssg" $domain -}}
    {{- else if .Values.global.saas }}
         {{- printf "apim-ssg-%s.%s" .Values.global.subdomainPrefix $domain -}}
    {{- else }}
         {{- printf "%s-ssg.%s" .Values.global.subdomainPrefix $domain -}}
    {{- end }}
{{- end -}}

{{/*
Generate TSSG (Gateway) public port for PAPI_PUBLIC_PORT
Defaults to 443 for HTTPS
*/}}
{{- define "tssg-public-port-for-intelligence" -}}
    {{- if .Values.intelligenceServer.papiPublicPort }}
        {{- .Values.intelligenceServer.papiPublicPort -}}
    {{- else }}
        {{- "443" -}}
    {{- end }}
{{- end -}}