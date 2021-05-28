{{/*
Expand the name of the chart.
*/}}
{{- define "portal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "portal.fullname" -}}
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
{{- define "portal.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
 Set the service account name for the Portal Stack
 */}}
{{- define "portal.serviceAccountName" -}}
{{- if .Values.global.serviceAccountName }}
   {{ default "default" .Values.global.serviceAccountName }}
{{- else }}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "portal.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Get the license file required by the portal
*/}}
{{- define "portal.license" -}}
{{- if contains "4.5" .Chart.AppVersion }}
{{- $f:= .Values.portal.license.value  }}
{{- if empty $f }}
{{- fail "Please set portal.license.value via set file" }}
{{- else }}
{{- print $f | b64enc | quote }}
{{- end }}
{{- end }}
{{- end -}}


### If something hasn't been defined for this certificate then create a key/cert and pass it to the pre-install job
### so that they are both the same...
{{/*
Get the dispatcher container SSL certificate and private key bundle
*/}}
{{- define "dispatcher-self-signed" -}}
{{- $cert := genSelfSignedCert (printf "%s%s" "*." .Values.portal.domain) nil nil 365 -}}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
{{- end -}}

{{/*
Get the dispatcher container SSL certificate and private key bundle
*/}}
{{- define "dispatcher-ssl-crt" -}}
{{- if .Values.tls.useSignedCertificates}}
    {{- $f:= printf "%s%s" .Values.tls.crt .Values.tls.crtChain  }}
    {{- if empty $f }}
        {{- fail "Please set tls.crt and tls.crtChain" }}
    {{- else }}
        {{- print $f }}
    {{- end }}
{{- end }}
{{- end -}}

{{/*
Get the dispatcher container SSL certificate and private key bundle
*/}}
{{- define "dispatcher-ssl-key" -}}
{{- if .Values.tls.useSignedCertificates}}
    {{- $f:= .Values.tls.key  }}
    {{- if empty $f }}
        {{- fail "Please set tls.key" }}
    {{- else }}
        {{- print $f }}
    {{- end }}
{{- end }}
{{- end -}}



{{/*
Get a user provided SMTP certificate
*/}}
{{- define "smtp-external-crt" -}}
    {{- if and (eq .Values.smtp.cert "notinstalled") .Values.smtp.requireSSL }}
        {{- fail "Please set smtp.cert via set file or disable smtp.requireSSL" }}
    {{- else }}
        {{- print .Values.smtp.cert | b64enc | quote }}
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
Get "otk" database name
*/}}
{{- define "otk-db-name" -}}
    {{ if .Values.global.legacyDatabaseNames }}
        {{- print "apim_otk_db" }}
    {{- else }}
        {{- $f:= .Values.global.subdomainPrefix -}}
        {{ if empty $f }}
            {{- fail "Please define subdomainPrefix in values.yaml" }}
        {{- else }}
            {{- printf "%s_%s" $f .Values.apim.otkDb.name | replace "-" "_" -}}
        {{- end }}
    {{- end }}
{{- end -}}

{{/*
Get "rbac" database name
*/}}
{{- define "rbac-db-name" -}}
    {{ if .Values.global.legacyDatabaseNames }}
        {{- print "rbac" }}
    {{- else }}
        {{- $f:= .Values.global.subdomainPrefix -}}
        {{ if empty $f }}
            {{- fail "Please define subdomainPrefix in values.yaml" }}
        {{- else }}
            {{- printf "%s_%s" $f "rbac" | replace "-" "_" -}}
        {{- end }}
    {{- end }}
{{- end -}}

{{/*
Get "tenant provisioning" database name
*/}}
{{- define "tps-db-name" -}}
    {{ if  .Values.global.legacyDatabaseNames }}
        {{- print "tenant_provisioning" }}
    {{- else }}
        {{- $f:= .Values.global.subdomainPrefix -}}
        {{ if empty $f }}
            {{- fail "Please define subdomainPrefix in values.yaml" }}
        {{- else }}
            {{- printf "%s_%s" $f "tenant_provisioning" | replace "-" "_" -}}
        {{- end }}
    {{- end }}
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
Get "analytics" database name
*/}}
{{- define "analytics-db-name" -}}
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

{{/*
Portal Docops page
*/}}
{{- define "portal.help.page" -}}
{{- printf "%s" "https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-developer-portal/5-0-2/" -}}
{{- end -}}

{{/*
Generate a unique "default-tenant-id" appended with the subdomainPrefix to enable multiple deployments on
one k8s cluster
*/}}
{{- define "default-tenant-id" -}}
    {{- $f:= .Values.portal.defaultTenantId -}}
        {{ if empty $f }}
            {{- fail "Please define defaultTenantId in values.yaml" }}
    {{- else }}
        {{- if .Values.global.legacyHostnames }}
            {{- printf .Values.portal.defaultTenantId | replace "_" "-" -}}
        {{- else }}
            {{- printf "%s-%s" .Values.portal.defaultTenantId .Values.global.subdomainPrefix | replace "_" "-" -}}
        {{- end }}
    {{- end }}
{{- end -}}

{{/*
Generate Ingress SSG endpoint based on configurations
*/}}
{{- define "tssg-public-host" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "%s-%s.%s" .Values.portal.defaultTenantId "ssg" .Values.portal.domain -}}
    {{- else if .Values.global.saas }}
         {{- printf "apim-ssg-%s.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- else }}
         {{- printf "%s-ssg.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- end }}
{{- end -}}

{{/*
Generate Rabbit MQ endpoint based on configurations
*/}}
{{- define "broker-host" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "broker.%s" .Values.portal.domain -}}
    {{- else if .Values.global.saas }}
         {{- printf "broker-apim-ssg-%s.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- else }}
         {{- printf "%s-broker.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- end }}
{{- end -}}

{{/*
Generate PSSG enrolment endpoint based on configurations
*/}}
{{- define "pssg-enroll-host" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "enroll.%s" .Values.portal.domain -}}
    {{- else }}
    {{- if .Values.global.saas }}
      {{- printf "enroll-%s.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- else }}
      {{- printf "%s-enroll.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}        
    {{- end }}
    {{- end }}
{{- end -}}

{{/*
Generate PSSG sync endpoint based on configurations
*/}}
{{- define "pssg-sync-host" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "sync.%s" .Values.portal.domain -}}
    {{- else }}
    {{- if .Values.global.saas }}
         {{- printf "sync-%s.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- else }}
         {{- printf "%s-sync.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- end }}
    {{- end }}
{{- end -}}

{{/*
Generate PSSG SSO endpoint based on configurations
*/}}
{{- define "pssg-sso-host" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "sso.%s" .Values.portal.domain -}}
    {{- else }}
    {{- if .Values.global.saas }}
         {{- printf "sso-%s.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- else }}
         {{- printf "%s-sso.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- end }}
    {{- end }}
{{- end -}}

{{/*
Generate analytics endpoint based on configurations
*/}}
{{- define "analytics-host" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "analytics.%s" .Values.portal.domain -}}
    {{- else }}
    {{- if .Values.global.saas }}
         {{- printf "analytics-%s.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- else }}
         {{- printf "%s-analytics.%s" .Values.global.subdomainPrefix  .Values.portal.domain -}}
    {{- end }}
    {{- end }}
{{- end -}}

{{/*
Generate default tenant endpoint based on configurations
*/}}
{{- define "default-tenant-host" -}}
    {{- if .Values.global.legacyHostnames }}
        {{- printf "%s.%s" .Values.portal.defaultTenantId .Values.portal.domain -}}
    {{- else }}
        {{- printf "%s-%s.%s" .Values.portal.defaultTenantId .Values.global.subdomainPrefix .Values.portal.domain -}}
    {{- end }}
{{- end -}}

{{/*
Get "database-port" based on databaseType value
*/}}

{{- define "database-port" -}}
        {{- print .Values.global.databasePort -}}
{{- end -}}

{{/*
 Ingress domain hosts
*/}}
{{- define "get-ingress-hosts" -}}
    {{- $f:= .Values.portal.domain -}}
    {{ if empty $f }}
        {{- fail "Please define domain in values.yaml" }}
    {{- else }}
        {{- printf "*.%s" .Values.portal.domain }}
    {{- end }}
{{- end -}}
