{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "seaweedfs.fullname" -}}
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
 Set the service account name for the Portal Stack
 */}}
{{- define "seaweedfs.serviceAccountName" -}}
{{- if .Values.global.serviceAccountName }}
   {{ default "default" .Values.global.serviceAccountName }}
{{- else }}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "seaweedfs.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "seaweedfs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "seaweedfs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Get database port from global values (used when chart is subchart of portal).
*/}}
{{- define "database-port" -}}
{{- print .Values.global.databasePort -}}
{{- end -}}

{{/*
Get portal database name from global values (used when chart is subchart of portal).
*/}}
{{- define "portal-db-name" -}}
{{- if .Values.global.legacyDatabaseNames -}}
{{- print "portal" -}}
{{- else -}}
{{- $f := .Values.global.subdomainPrefix -}}
{{- if empty $f -}}
{{- fail "Please define global.subdomainPrefix in values.yaml" -}}
{{- else -}}
{{- printf "%s_%s" $f "portal" | replace "-" "_" -}}
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
{{- $clusterDomain := .Values.clusterDomain -}}
{{- $masterPort := int .Values.master.port -}}
{{- $namespace := .Release.Namespace -}}
{{- range $i := until (int .Values.replicaCount) }}
    {{- $peers = append $peers (printf "%s-%d.%s.%s.svc.%s:%d" $masterFullname $i $masterHeadlessSvcName $namespace $clusterDomain $masterPort) -}}
{{- end -}}
{{- print (join "," $peers) -}}
{{- end -}}