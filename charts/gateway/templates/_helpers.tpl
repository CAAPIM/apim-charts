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
{{- if .Values.image.secretName}}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .Values.image.registry .Values.image.credentials.username .Values.image.credentials.password .Values.image.credentials.email (printf "%s:%s" .Values.image.credentials.username .Values.image.credentials.password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
 Define OS Env Secret Name
 */}}
{{- define "gateway.envSecretName" -}}
{{- if .Values.env.existingSecretName -}}
    {{ .Values.env.existingSecretName }}
{{- else -}}
{{- printf "%s-%s" (include "gateway.fullname" .) "env-secret" -}}
{{- end -}}
{{- end -}}
