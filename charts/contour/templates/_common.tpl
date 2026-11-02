{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* This contains all the helper functions from bitnami/common */}}

{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.names.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $releaseName := regexReplaceAll "(-?[^a-z\\d\\-])+-?" (lower .Release.Name) "-" -}}
{{- if contains $name $releaseName -}}
{{- $releaseName | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $releaseName $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts.
*/}}
{{- define "common.names.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper image version (ingores image revision/prerelease info & fallbacks to chart appVersion)
{{ include "common.images.version" ( dict "imageRoot" .Values.path.to.the.image "chart" .Chart ) }}
*/}}
{{- define "common.images.version" -}}
{{- $imageTag := .imageRoot.tag | toString -}}
{{/* regexp from https://github.com/Masterminds/semver/blob/23f51de38a0866c5ef0bfc42b3f735c73107b700/version.go#L41-L44 */}}
{{- if regexMatch `^([0-9]+)(\.[0-9]+)?(\.[0-9]+)?(-([0-9A-Za-z\-]+(\.[0-9A-Za-z\-]+)*))?(\+([0-9A-Za-z\-]+(\.[0-9A-Za-z\-]+)*))?$` $imageTag -}}
    {{- $version := semver $imageTag -}}
    {{- printf "%d.%d.%d" $version.Major $version.Minor $version.Patch -}}
{{- else -}}
    {{- print .chart.AppVersion -}}
{{- end -}}
{{- end -}}

{{/*
Merge a list of values that contains template after rendering them.
Merge precedence is consistent with http://masterminds.github.io/sprig/dicts.html#merge-mustmerge
Usage:
{{ include "common.tplvalues.merge" ( dict "values" (list .Values.path.to.the.Value1 .Values.path.to.the.Value2) "context" $ ) }}
*/}}
{{- define "common.tplvalues.merge" -}}
{{- $dst := dict -}}
{{- range .values -}}
{{- $dst = include "common.tplvalues.render" (dict "value" . "context" $.context "scope" $.scope) | fromYaml | merge $dst -}}
{{- end -}}
{{ $dst | toYaml }}
{{- end -}}

{{/*
Renders a value that contains template perhaps with scope if the scope is present.
Usage:
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $ ) }}
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $ "scope" $app ) }}
*/}}
{{- define "common.tplvalues.render" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
{{- if contains "{{" (toJson .value) }}
  {{- if .scope }}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $value "{{- end }}") (merge (dict "RelativeScope" .scope) .context) }}
  {{- else }}
    {{- tpl $value .context }}
  {{- end }}
{{- else }}
    {{- $value }}
{{- end }}
{{- end -}}

{{/*
Kubernetes standard labels
{{ include "common.labels.standard" (dict "customLabels" .Values.commonLabels "context" $) -}}
*/}}
{{- define "common.labels.standard" -}}
{{- if and (hasKey . "customLabels") (hasKey . "context") -}}
{{- $default := dict "app.kubernetes.io/name" (include "common.names.name" .context) "helm.sh/chart" (include "common.names.chart" .context) "app.kubernetes.io/instance" .context.Release.Name "app.kubernetes.io/managed-by" .context.Release.Service -}}
{{- with .context.Chart.AppVersion -}}
{{- $_ := set $default "app.kubernetes.io/version" . -}}
{{- end -}}
{{ template "common.tplvalues.merge" (dict "values" (list .customLabels $default) "context" .context) }}
{{- else -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
helm.sh/chart: {{ include "common.names.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "common.names.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.names.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels used on immutable fields such as deploy.spec.selector.matchLabels or svc.spec.selector
{{ include "common.labels.matchLabels" (dict "customLabels" .Values.podLabels "context" $) -}}

We don't want to loop over custom labels appending them to the selector
since it's very likely that it will break deployments, services, etc.
However, it's important to overwrite the standard labels if the user
overwrote them on metadata.labels fields.
*/}}
{{- define "common.labels.matchLabels" -}}
{{- if and (hasKey . "customLabels") (hasKey . "context") -}}
{{ merge (pick (include "common.tplvalues.render" (dict "value" .customLabels "context" .context) | fromYaml) "app.kubernetes.io/name" "app.kubernetes.io/instance") (dict "app.kubernetes.io/name" (include "common.names.name" .context) "app.kubernetes.io/instance" .context.Release.Name ) | toYaml }}
{{- else -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "common.capabilities.networkPolicy.apiVersion" -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names (deprecated: use common.images.renderPullSecrets instead)
{{ include "common.images.pullSecrets" ( dict "images" (list .Values.path.to.the.image1, .Values.path.to.the.image2) "global" .Values.global) }}
*/}}
{{- define "common.images.pullSecrets" -}}
  {{- $pullSecrets := list }}

  {{- range ((.global).imagePullSecrets) -}}
    {{- if kindIs "map" . -}}
      {{- $pullSecrets = append $pullSecrets .name -}}
    {{- else -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end }}
  {{- end -}}

  {{- range .images -}}
    {{- range .pullSecrets -}}
      {{- if kindIs "map" . -}}
        {{- $pullSecrets = append $pullSecrets .name -}}
      {{- else -}}
        {{- $pullSecrets = append $pullSecrets . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if (not (empty $pullSecrets)) -}}
imagePullSecrets:
    {{- range $pullSecrets | uniq }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Return a podAffinity/podAntiAffinity definition
{{ include "common.affinities.pods" (dict "type" "soft" "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}
{{- define "common.affinities.pods" -}}
  {{- if eq .type "soft" }}
    {{- include "common.affinities.pods.soft" . -}}
  {{- else if eq .type "hard" }}
    {{- include "common.affinities.pods.hard" . -}}
  {{- end -}}
{{- end -}}

{{/*
Return a soft nodeAffinity definition
{{ include "common.affinities.nodes.soft" (dict "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}
{{- define "common.affinities.nodes.soft" -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - preference:
      matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
    weight: 1
{{- end -}}

{{/*
Return a hard nodeAffinity definition
{{ include "common.affinities.nodes.hard" (dict "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}
{{- define "common.affinities.nodes.hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
{{- end -}}

{{/*
Return a nodeAffinity definition
{{ include "common.affinities.nodes" (dict "type" "soft" "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}
{{- define "common.affinities.nodes" -}}
  {{- if eq .type "soft" }}
    {{- include "common.affinities.nodes.soft" . -}}
  {{- else if eq .type "hard" }}
    {{- include "common.affinities.nodes.hard" . -}}
  {{- end -}}
{{- end -}}

{{/*
Render a compatible securityContext depending on the platform. By default it is maintained as it is. In other platforms like Openshift we remove default user/group values that do not work out of the box with the restricted-v1 SCC
Usage:
{{- include "common.compatibility.renderSecurityContext" (dict "secContext" .Values.containerSecurityContext "context" $) -}}
*/}}
{{- define "common.compatibility.renderSecurityContext" -}}
{{- $adaptedContext := .secContext -}}

{{- if (((.context.Values.global).compatibility).openshift) -}}
  {{- if or (eq .context.Values.global.compatibility.openshift.adaptSecurityContext "force") (and (eq .context.Values.global.compatibility.openshift.adaptSecurityContext "auto") (include "common.compatibility.isOpenshift" .context)) -}}
    {{/* Remove incompatible user/group values that do not work in Openshift out of the box */}}
    {{- $adaptedContext = omit $adaptedContext "fsGroup" "runAsUser" "runAsGroup" -}}
    {{- if not .secContext.seLinuxOptions -}}
    {{/* If it is an empty object, we remove it from the resulting context because it causes validation issues */}}
    {{- $adaptedContext = omit $adaptedContext "seLinuxOptions" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{/* Remove empty seLinuxOptions object if global.compatibility.omitEmptySeLinuxOptions is set to true */}}
{{- if and (((.context.Values.global).compatibility).omitEmptySeLinuxOptions) (not .secContext.seLinuxOptions) -}}
  {{- $adaptedContext = omit $adaptedContext "seLinuxOptions" -}}
{{- end -}}
{{/* Remove fields that are disregarded when running the container in privileged mode */}}
{{- if $adaptedContext.privileged -}}
  {{- $adaptedContext = omit $adaptedContext "capabilities" -}}
{{- end -}}
{{- omit $adaptedContext "enabled" | toYaml -}}
{{- end -}}

{{/* 
Return true if the detected platform is Openshift
Usage:
{{- include "common.compatibility.isOpenshift" . -}}
*/}}
{{- define "common.compatibility.isOpenshift" -}}
{{- if .Capabilities.APIVersions.Has "security.openshift.io/v1" -}}
{{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper image name.
If image tag and digest are not defined, termination fallbacks to chart appVersion.
{{ include "common.images.image" ( dict "imageRoot" .Values.path.to.the.image "global" .Values.global "chart" .Chart ) }}
*/}}
{{- define "common.images.image" -}}
{{- $registryName := default .imageRoot.registry ((.global).imageRegistry) -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | toString -}}

{{- if not .imageRoot.tag }}
  {{- if .chart }}
    {{- $termination = .chart.AppVersion | toString -}}
  {{- end -}}
{{- end -}}
{{- if .imageRoot.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .imageRoot.digest | toString -}}
{{- end -}}
{{- if $registryName }}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s"  $repositoryName $separator $termination -}}
{{- end -}}
{{- end -}}


{{/*
Return a resource request/limit object based on a given preset.
These presets are for basic testing and not meant to be used in production
{{ include "common.resources.preset" (dict "type" "nano") -}}
*/}}
{{- define "common.resources.preset" -}}
{{/* The limits are the requests increased by 50% (except ephemeral-storage and xlarge/2xlarge sizes)*/}}
{{- $presets := dict 
  "nano" (dict 
      "requests" (dict "cpu" "100m" "memory" "128Mi" "ephemeral-storage" "50Mi")
      "limits" (dict "cpu" "150m" "memory" "192Mi" "ephemeral-storage" "2Gi")
   )
  "micro" (dict 
      "requests" (dict "cpu" "250m" "memory" "256Mi" "ephemeral-storage" "50Mi")
      "limits" (dict "cpu" "375m" "memory" "384Mi" "ephemeral-storage" "2Gi")
   )
  "small" (dict 
      "requests" (dict "cpu" "500m" "memory" "512Mi" "ephemeral-storage" "50Mi")
      "limits" (dict "cpu" "750m" "memory" "768Mi" "ephemeral-storage" "2Gi")
   )
  "medium" (dict 
      "requests" (dict "cpu" "500m" "memory" "1024Mi" "ephemeral-storage" "50Mi")
      "limits" (dict "cpu" "750m" "memory" "1536Mi" "ephemeral-storage" "2Gi")
   )
  "large" (dict 
      "requests" (dict "cpu" "1.0" "memory" "2048Mi" "ephemeral-storage" "50Mi")
      "limits" (dict "cpu" "1.5" "memory" "3072Mi" "ephemeral-storage" "2Gi")
   )
  "xlarge" (dict 
      "requests" (dict "cpu" "1.0" "memory" "3072Mi" "ephemeral-storage" "50Mi")
      "limits" (dict "cpu" "3.0" "memory" "6144Mi" "ephemeral-storage" "2Gi")
   )
  "2xlarge" (dict 
      "requests" (dict "cpu" "1.0" "memory" "3072Mi" "ephemeral-storage" "50Mi")
      "limits" (dict "cpu" "6.0" "memory" "12288Mi" "ephemeral-storage" "2Gi")
   )
 }}
{{- if hasKey $presets .type -}}
{{- index $presets .type | toYaml -}}
{{- else -}}
{{- printf "ERROR: Preset key '%s' invalid. Allowed values are %s" .type (join "," (keys $presets)) | fail -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for RBAC resources.
*/}}
{{- define "common.capabilities.rbac.apiVersion" -}}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "common.capabilities.deployment.apiVersion" -}}
{{- print "apps/v1" -}}
{{- end -}}


{{/*
Return a soft podAffinity/podAntiAffinity definition
{{ include "common.affinities.pods.soft" (dict "component" "FOO" "customLabels" .Values.podLabels "extraMatchLabels" .Values.extraMatchLabels "topologyKey" "BAR" "extraPodAffinityTerms" .Values.extraPodAffinityTerms "extraNamespaces" (list "namespace1" "namespace2") "context" $) -}}
*/}}
{{- define "common.affinities.pods.soft" -}}
{{- $component := default "" .component -}}
{{- $customLabels := default (dict) .customLabels -}}
{{- $extraMatchLabels := default (dict) .extraMatchLabels -}}
{{- $extraPodAffinityTerms := default (list) .extraPodAffinityTerms -}}
{{- $extraNamespaces := default (list) .extraNamespaces -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - podAffinityTerm:
      labelSelector:
        matchLabels: {{- (include "common.labels.matchLabels" ( dict "customLabels" $customLabels "context" .context )) | nindent 10 }}
          {{- if not (empty $component) }}
          {{ printf "app.kubernetes.io/component: %s" $component }}
          {{- end }}
          {{- range $key, $value := $extraMatchLabels }}
          {{ $key }}: {{ $value | quote }}
          {{- end }}
      {{- if $extraNamespaces }}
      namespaces:
        - {{ .context.Release.Namespace }}
        {{- with $extraNamespaces }}
        {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
        {{- end }}
      {{- end }}
      topologyKey: {{ include "common.affinities.topologyKey" (dict "topologyKey" .topologyKey) }}
    weight: 1
  {{- range $extraPodAffinityTerms }}
  - podAffinityTerm:
      labelSelector:
        matchLabels: {{- (include "common.labels.matchLabels" ( dict "customLabels" $customLabels "context" $.context )) | nindent 10 }}
          {{- if not (empty $component) }}
          {{ printf "app.kubernetes.io/component: %s" $component }}
          {{- end }}
          {{- range $key, $value := .extraMatchLabels }}
          {{ $key }}: {{ $value | quote }}
          {{- end }}
      {{- if .namespaces }}
      namespaces:
        - {{ $.context.Release.Namespace }}
        {{- with .namespaces }}
        {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
        {{- end }}
      {{- end }}
      topologyKey: {{ include "common.affinities.topologyKey" (dict "topologyKey" .topologyKey) }}
    weight: {{ .weight | default 1 -}}
  {{- end -}}
{{- end -}}

{{/*
Return a hard podAffinity/podAntiAffinity definition
{{ include "common.affinities.pods.hard" (dict "component" "FOO" "customLabels" .Values.podLabels "extraMatchLabels" .Values.extraMatchLabels "topologyKey" "BAR" "extraPodAffinityTerms" .Values.extraPodAffinityTerms "extraNamespaces" (list "namespace1" "namespace2") "context" $) -}}
*/}}
{{- define "common.affinities.pods.hard" -}}
{{- $component := default "" .component -}}
{{- $customLabels := default (dict) .customLabels -}}
{{- $extraMatchLabels := default (dict) .extraMatchLabels -}}
{{- $extraPodAffinityTerms := default (list) .extraPodAffinityTerms -}}
{{- $extraNamespaces := default (list) .extraNamespaces -}}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels: {{- (include "common.labels.matchLabels" ( dict "customLabels" $customLabels "context" .context )) | nindent 8 }}
        {{- if not (empty $component) }}
        {{ printf "app.kubernetes.io/component: %s" $component }}
        {{- end }}
        {{- range $key, $value := $extraMatchLabels }}
        {{ $key }}: {{ $value | quote }}
        {{- end }}
    {{- if $extraNamespaces }}
    namespaces:
      - {{ .context.Release.Namespace }}
      {{- with $extraNamespaces }}
      {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 6 }}
      {{- end }}
    {{- end }}
    topologyKey: {{ include "common.affinities.topologyKey" (dict "topologyKey" .topologyKey) }}
  {{- range $extraPodAffinityTerms }}
  - labelSelector:
      matchLabels: {{- (include "common.labels.matchLabels" ( dict "customLabels" $customLabels "context" $.context )) | nindent 8 }}
        {{- if not (empty $component) }}
        {{ printf "app.kubernetes.io/component: %s" $component }}
        {{- end }}
        {{- range $key, $value := .extraMatchLabels }}
        {{ $key }}: {{ $value | quote }}
        {{- end }}
    {{- if .namespaces }}
    namespaces:
      - {{ $.context.Release.Namespace }}
      {{- with .namespaces }}
      {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 6 }}
      {{- end }}
    {{- end }}
    topologyKey: {{ include "common.affinities.topologyKey" (dict "topologyKey" .topologyKey) }}
  {{- end -}}
{{- end -}}

{{/*
Return a topologyKey definition
{{ include "common.affinities.topologyKey" (dict "topologyKey" "BAR") -}}
*/}}
{{- define "common.affinities.topologyKey" -}}
{{ .topologyKey | default "kubernetes.io/hostname" -}}
{{- end -}}
{{/*
Warning about using rolling tag.
Usage:
{{ include "common.warnings.rollingTag" .Values.path.to.the.imageRoot }}
*/}}
{{- define "common.warnings.rollingTag" -}}

{{- if and (contains "bitnami/" .repository) (not (.tag | toString | regexFind "-r\\d+$|sha256:")) }}
WARNING: Rolling tag detected ({{ .repository }}:{{ .tag }}), please note that it is strongly recommended to avoid using rolling tags in a production environment.
+info https://techdocs.broadcom.com/us/en/vmware-tanzu/application-catalog/tanzu-application-catalog/services/tac-doc/apps-tutorials-understand-rolling-tags-containers-index.html
{{- end }}
{{- end -}}


{{/*
Warning about not setting the resource object in all deployments.
Usage:
{{ include "common.warnings.resources" (dict "sections" (list "path1" "path2") context $) }}
Example:
{{- include "common.warnings.resources" (dict "sections" (list "csiProvider.provider" "server" "volumePermissions" "") "context" $) }}
The list in the example assumes that the following values exist:
  - csiProvider.provider.resources
  - server.resources
  - volumePermissions.resources
  - resources
*/}}
{{- define "common.warnings.resources" -}}
{{- $values := .context.Values -}}
{{- $printMessage := false -}}
{{ $affectedSections := list -}}
{{- range .sections -}}
  {{- if eq . "" -}}
    {{/* Case where the resources section is at the root (one main deployment in the chart) */}}
    {{- if not (index $values "resources") -}}
    {{- $affectedSections = append $affectedSections "resources" -}}
    {{- $printMessage = true -}}
    {{- end -}}
  {{- else -}}
    {{/* Case where the are multiple resources sections (more than one main deployment in the chart) */}}
    {{- $keys := split "." . -}}
    {{/* We iterate through the different levels until arriving to the resource section. Example: a.b.c.resources */}}
    {{- $section := $values -}}
    {{- range $keys -}}
      {{- $section = index $section . -}}
    {{- end -}}
    {{- if not (index $section "resources") -}}
      {{/* If the section has enabled=false or replicaCount=0, do not include it */}}
      {{- if and (hasKey $section "enabled") -}}
        {{- if index $section "enabled" -}}
          {{/* enabled=true */}}
          {{- $affectedSections = append $affectedSections (printf "%s.resources" .) -}}
          {{- $printMessage = true -}}
        {{- end -}}
      {{- else if and (hasKey $section "replicaCount")  -}}
        {{/* We need a casting to int because number 0 is not treated as an int by default */}}
        {{- if (gt (index $section "replicaCount" | int) 0) -}}
          {{/* replicaCount > 0 */}}
          {{- $affectedSections = append $affectedSections (printf "%s.resources" .) -}}
          {{- $printMessage = true -}}
        {{- end -}}
      {{- else -}}
        {{/* Default case, add it to the affected sections */}}
        {{- $affectedSections = append $affectedSections (printf "%s.resources" .) -}}
        {{- $printMessage = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if $printMessage }}

WARNING: There are "resources" sections in the chart not set. Using "resourcesPreset" is not recommended for production. For production installations, please set the following values according to your workload needs:
{{- range $affectedSections }}
  - {{ . }}
{{- end }}
+info https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for Horizontal Pod Autoscaler.
*/}}
{{- define "common.capabilities.hpa.apiVersion" -}}
{{- $kubeVersion := include "common.capabilities.kubeVersion" .context -}}
{{- print "autoscaling/v2" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for poddisruptionbudget.
*/}}
{{- define "common.capabilities.policy.apiVersion" -}}
{{- print "policy/v1" -}}
{{- end -}}
{{/*
Generate backend entry that is compatible with all Kubernetes API versions.

Usage:
{{ include "common.ingress.backend" (dict "serviceName" "backendName" "servicePort" "backendPort" "context" $) }}

Params:
  - serviceName - String. Name of an existing service backend
  - servicePort - String/Int. Port name (or number) of the service. It will be translated to different yaml depending if it is a string or an integer.
  - context - Dict - Required. The context for the template evaluation.
*/}}
{{- define "common.ingress.backend" -}}
service:
  name: {{ .serviceName }}
  port:
    {{- if typeIs "string" .servicePort }}
    name: {{ .servicePort }}
    {{- else if or (typeIs "int" .servicePort) (typeIs "float64" .servicePort) }}
    number: {{ .servicePort | int }}
    {{- end }}
{{- end -}}

{{/*
Reuses the value from an existing secret, otherwise sets its value to a default value.

Usage:
{{ include "common.secrets.lookup" (dict "secret" "secret-name" "key" "keyName" "defaultValue" .Values.myValue "context" $) }}

Params:
  - secret - String - Required - Name of the 'Secret' resource where the password is stored.
  - key - String - Required - Name of the key in the secret.
  - defaultValue - String - Required - The path to the validating value in the values.yaml, e.g: "mysql.password". Will pick first parameter with a defined value.
  - context - Context - Required - Parent context.

*/}}
{{- define "common.secrets.lookup" -}}
{{- $value := "" -}}
{{- $secretData := (lookup "v1" "Secret" (include "common.names.namespace" .context) .secret).data -}}
{{- if and $secretData (hasKey $secretData .key) -}}
  {{- $value = index $secretData .key -}}
{{- else if .defaultValue -}}
  {{- $value = .defaultValue | toString | b64enc -}}
{{- end -}}
{{- if $value -}}
{{- printf "%s" $value -}}
{{- end -}}
{{- end -}}

{{/*
Return the target Kubernetes version
*/}}
{{- define "common.capabilities.kubeVersion" -}}
{{- default (default .Capabilities.KubeVersion.Version .Values.kubeVersion) ((.Values.global).kubeVersion) -}}
{{- end -}}