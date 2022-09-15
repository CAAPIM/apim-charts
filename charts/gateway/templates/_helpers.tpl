{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gateway.fullname" -}}
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
{{- define "gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
 Set the service account name for the Gateway
 */}}
{{- define "gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "gateway.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
 Generate []16bit HEX
 This creates Gateway ids for bundles  
 */}}
 {{- define "gateway.listenPort.hex" -}}
 {{ $hexArr := "" }}
 {{- range .Values.config.listenPorts.ports }}
 {{- $hex := randAlphaNum 16 }}
 {{- join $hex (printf " %x" $hex) }}
 {{- end -}}
 {{- end -}}


 {{/*
 Generate []16bit HEX
 This creates Gateway ids for bundles  
 */}}
 {{- define "gateway.cwp.hex" -}}
 {{ $hexArr := "" }}
 {{- range .Values.config.cwp.properties }}
 {{- $hex := randAlphaNum 16 }}
 {{- join $hex (printf " %x" $hex) }}
 {{- end -}}
 {{- end -}}

{{/*
 Generate 16bit HEX 
 #  {{ split " " $hexArr }}
 #  {{ $hexArr = append $hexArr (printf "%x" $hex) }}
 */}}
 
{{/*
Create java args to apply.
*/}}
{{- define "gateway.javaArgs" -}}
{{- if .Values.management.enabled -}}
  {{- join " " .Values.config.javaArgs }}
{{- else -}}
  {{- join " " .Values.config.javaArgs }} -Dcom.l7tech.server.config.mode=RUNTIME
{{- end  -}}
{{- end -}}

{{/*
Create Image Pull Secret
*/}}
{{- define "imagePullSecret" }}
{{- if not .Values.imagePullSecret.existingSecretName }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" .Values.image.registry .Values.imagePullSecret.username .Values.imagePullSecret.password (printf "%s:%s" .Values.imagePullSecret.username .Values.imagePullSecret.password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
Define Image Pull Secret Name
*/}}
{{- define "gateway.imagePullSecret" -}}
{{- if .Values.imagePullSecret.existingSecretName -}}
    {{ .Values.imagePullSecret.existingSecretName }}
{{- else -}}
    {{- printf "%s-%s" (include "gateway.fullname" .) "image-pull-secret" -}}
{{- end -}}
{{- end -}}

{{/*
 Define Gateway TLS Secret Name
 */}}
{{- define "gateway.tlsSecretName" -}}
{{- if .Values.tls.existingSecretName -}}
    {{ .Values.tls.existingSecretName }}
{{- else -}}
{{- printf "%s-%s" (include "gateway.fullname" .) "tls-secret" -}}
{{- end -}}
{{- end -}}

{{/*
 Define Gateway Management Secret Name
 */}}
{{- define "gateway.secretName" -}}
{{- if .Values.existingGatewaySecretName -}}
    {{ .Values.existingGatewaySecretName }}
{{- else -}}
    {{- printf "%s-%s" (include "gateway.fullname" .) "secret" -}}
{{- end -}}
{{- end -}}

{{/*
 Define Gateway License Secret Name
 */}}
{{- define "gateway.license" -}}
{{- if .Values.license.existingSecretName -}}
    {{ .Values.license.existingSecretName }}
{{- else -}}
    {{- printf "%s-%s" (include "gateway.fullname" .) "license" -}}
{{- end -}}
{{- end -}}
