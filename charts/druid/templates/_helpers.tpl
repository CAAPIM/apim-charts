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

{{- define "s3.url" -}}
    {{- if eq .Values.global.analytics.deepStorage "seaweedfs" -}}
    {{- printf "http://%s-filer:%s" .Values.global.analytics.deepStorage | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
    {- printf "http://%s:%s" .Values.global.analytics.deepStorage .Values.minio.port | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
{{- end -}}

{{/*
Inject extra environment vars in the format key:value, if populated
*/}}
{{- define "seaweedfs.extraEnvironmentVars" -}}
{{- if .extraEnvironmentVars -}}
{{- range $key, $value := .extraEnvironmentVars }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Return the proper filer image */}}
{{- define "filer.image" -}}
{{- if .Values.filer.imageOverride -}}
{{- $imageOverride := .Values.filer.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.image.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $name := .Values.global.image.seaweedfs| toString -}}
{{- $tag := .Chart.AppVersion | toString -}}
{{- printf "%s%s%s:%s" $registryName $repositoryName $name $tag -}}
{{- end -}}
{{- end -}}

{{/* Return the proper master image */}}
{{- define "master.image" -}}
{{- if .Values.master.imageOverride -}}
{{- $imageOverride := .Values.master.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.image.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $name := .Values.global.image.seaweedfs | toString -}}
{{- printf "%s%s%s" $registryName $repositoryName $name -}}
{{- end -}}
{{- end -}}

{{/* Return the proper s3 image */}}
{{- define "s3.image" -}}
{{- if .Values.s3.imageOverride -}}
{{- $imageOverride := .Values.s3.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.image.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $name := .Values.global.image.seaweedfs | toString -}}
{{- $tag := .Chart.AppVersion | toString -}}
{{- printf "%s%s%s" $registryName $repositoryName $name -}}
{{- end -}}
{{- end -}}

{{/* Return the proper volume image */}}
{{- define "volume.image" -}}
{{- if .Values.volume.imageOverride -}}
{{- $imageOverride := .Values.volume.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.image.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $name := .Values.global.image.seaweedfs | toString -}}
{{- printf "%s%s%s" $registryName $repositoryName $name -}}
{{- end -}}
{{- end -}}

{{/* Return the proper cronjob image */}}
{{- define "cronjob.image" -}}
{{- if .Values.cronjob.imageOverride -}}
{{- $imageOverride := .Values.cronjob.imageOverride -}}
{{- printf "%s" $imageOverride -}}
{{- else -}}
{{- $registryName := default .Values.image.registry .Values.global.localRegistry | toString -}}
{{- $repositoryName := .Values.image.repository | toString -}}
{{- $name := .Values.global.image.seaweedfs | toString -}}
{{- printf "%s%s%s" $registryName $repositoryName $name -}}
{{- end -}}
{{- end -}}


{{/* check if any PVC exists */}}
{{- define "volume.pvc_exists" -}}
{{- if or (or (eq .Values.volume.data.type "persistentVolumeClaim") (and (eq .Values.volume.idx.type "persistentVolumeClaim") .Values.volume.dir_idx )) (eq .Values.volume.logs.type "persistentVolumeClaim") -}}
{{- printf "true" -}}
{{- else -}}
{{- printf "false" -}}
{{- end -}}
{{- end -}}

{{/* check if any HostPath exists */}}
{{- define "volume.hostpath_exists" -}}
{{- if or (or (eq .Values.volume.data.type "hostPath") (and (eq .Values.volume.idx.type "hostPath") .Values.volume.dir_idx )) (eq .Values.volume.logs.type "hostPath") -}}
{{- printf "true" -}}
{{- else -}}
{{- if .Values.volume.extraVolumes -}}
{{- printf "true" -}}
{{- else -}}
{{- printf "false" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get "filer db name" database name
*/}}
{{- define "filer-db-name" -}}
    {{ if .Values.global.legacyDatabaseNames }}
        {{- print "analytics" }}
    {{- else }}
        {{- $f:= .Values.global.subdomainPrefix -}}
        {{ if empty $f }}
            {{- fail "Please define subdomainPrefix in values.yaml" }}
        {{- else }}
            {{- printf "%s_%s" $f "analytics" | replace "-" "_" -}}
        {{- end }}
    {{- end }}
{{- end -}}
