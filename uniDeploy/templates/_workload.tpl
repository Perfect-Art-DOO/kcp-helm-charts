{{/*
Shared renderers for the root workload and optional component workloads.
*/}}

{{- define "app.workloadName" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- if .component -}}
{{- $defaultName := .defaultName | default .component -}}
{{- default $defaultName (coalesce $values.nameOverride $values.appName) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "app.name" $root -}}
{{- end -}}
{{- end }}

{{- define "app.workloadFullname" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- if .component -}}
{{- if $values.fullnameOverride -}}
{{- $values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $root.Release.Name (include "app.workloadName" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- include "app.fullname" $root -}}
{{- end -}}
{{- end }}

{{- define "app.selectorLabelsFor" -}}
{{- if .component -}}
app.kubernetes.io/name: {{ include "app.workloadName" . }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component | quote }}
{{- else -}}
{{- include "app.selectorLabels" .root -}}
{{- end -}}
{{- end }}

{{- define "app.labelsFor" -}}
helm.sh/chart: {{ include "app.chart" .root }}
{{ include "app.selectorLabelsFor" . }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- range $key, $val := .root.Values.labels }}
{{ $key }}: {{ $val }}
{{- end }}
{{- if .component }}
{{- range $key, $val := (.values.labels | default dict) }}
{{ $key }}: {{ $val }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.serviceAccountNameFor" -}}
{{- $values := .values | default dict -}}
{{- $serviceAccount := $values.serviceAccount | default dict -}}
{{- if $serviceAccount.create -}}
{{- default (include "app.workloadFullname" .) $serviceAccount.name -}}
{{- else -}}
{{- default "default" $serviceAccount.name -}}
{{- end -}}
{{- end }}

{{- define "app.renderDeployment" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- if $values.containers -}}
{{- $appName := include "app.workloadFullname" . -}}
{{- $checkConnectionBeforeStart := $values.checkConnectionBeforeStart -}}
{{- $appVersion := $root.Chart.AppVersion -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $appName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" . | nindent 4 }}
spec:
  {{- if not $values.autoscaling.enabled }}
  replicas: {{ default 1 $values.replicaCount }}
  {{- end }}
  {{- with $values.deploymentStrategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "app.selectorLabelsFor" . | nindent 6 }}
  template:
    metadata:
      {{- if or $values.configmap.create $values.podAnnotations }}
      annotations:
      {{- with $values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- end }}
      labels:
        {{- include "app.labelsFor" . | nindent 8 }}
    spec:
      {{- if or $values.imagePullSecrets $values.imagePullSealedSecrets }}
      imagePullSecrets:
      {{- range $values.imagePullSecrets }}
        - name: {{ .name }}
      {{- end }}
      {{- range $values.imagePullSealedSecrets }}
      {{- if .fullName }}
        - name: "{{ .fullName }}"
      {{- else }}
        - name: "{{ $appName }}-{{ .name }}"
      {{- end }}
      {{- end }}
      {{- end }}
      serviceAccountName: {{ include "app.serviceAccountNameFor" . }}
      {{- if eq $values.automountServiceAccountToken false }}
      automountServiceAccountToken: false
      {{- end }}
      restartPolicy: Always
      securityContext:
        {{- toYaml ($values.securityContext | default dict) | nindent 8 }}
      {{- if or $checkConnectionBeforeStart $values.extraInitContainers }}
      initContainers:
        {{- range $checkConnectionBeforeStart }}
        - name: check-{{ .host | replace "." "-" | trunc 51 }}-{{ .port }}
          image: {{ $values.initContainers.image }}
          command: ['sh', '-c', 'for i in $(seq 1 12); do echo "$i/12: Checking connection to {{ .host }}:{{ .port }}..."; nc -z -w 2 {{ .host }} {{ .port }} && exit 0; sleep 8; done; exit 1']
          securityContext:
          {{- if $values.initContainers.securityContext }}
            {{- toYaml $values.initContainers.securityContext | nindent 12 }}
          {{- else }}
            {}
          {{- end }}
          resources:
          {{- if $values.initContainers.resources }}
            {{- toYaml $values.initContainers.resources | nindent 12 }}
          {{- else }}
            {}
          {{- end }}
        {{- end }}
        {{- with $values.extraInitContainers }}
          {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- end }}
      {{- if $values.hostAliases }}
      hostAliases:
        {{- toYaml $values.hostAliases | nindent 8 }}
      {{- end }}
      containers:
      {{- range $values.containers }}
        - name: {{ .name }}
          {{- if .command }}
          command: {{ toYaml .command | nindent 12 }}
          {{- end }}
          {{- if .args }}
          args: {{ toYaml .args | nindent 12 }}
          {{- end }}
          {{- if or .env .envFromSecrets .envFromFields }}
          env:
          {{- range .env }}
          {{- range $name, $value := . }}
            - name: {{ $name | quote }}
              value: {{ $value | quote }}
          {{- end }}
          {{- end }}
          {{- range .envFromSecrets }}
            - name: {{ .variable | quote }}
              valueFrom:
                secretKeyRef:
                  {{- if .fullSecretName }}
                  name: "{{ .fullSecretName }}"
                  {{- else }}
                  name: "{{ $appName }}-{{ .secretName }}"
                  {{- end }}
                  key: {{ .variable | quote }}
          {{- end }}
          {{- range .envFromFields }}
            - name: {{ .name | quote }}
              valueFrom:
                fieldRef:
                  fieldPath: {{ .field }}
          {{- end }}
          {{- end }}
          {{- if .secretFrom }}
          envFrom:
            {{- range .secretFrom }}
            - secretRef:
                name: {{ .name | quote }}
            {{- end }}
          {{- end }}
          securityContext:
          {{- if .securityContext }}
            {{- toYaml .securityContext | nindent 12 }}
          {{- else }}
            {}
          {{- end }}
          image: "{{ .image.repository }}:{{ .image.tag | default $appVersion }}"
          imagePullPolicy: {{ .image.pullPolicy | default "IfNotPresent" }}
          {{- if .ports }}
          ports:
            {{- range .ports }}
            - name: {{ .name | quote }}
              containerPort: {{ .containerPort }}
              {{- if .protocol }}
              protocol: {{ .protocol }}
              {{- else }}
              protocol: TCP
              {{- end }}
            {{- end }}
          {{- end }}
          {{- with .livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .startupProbe }}
          startupProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          resources:
          {{- if .resources }}
            {{- toYaml .resources | nindent 12 }}
          {{- else }}
            {}
          {{- end }}
          {{- if or .configmap .secrets .volumes .persistentVolumeClaims .emptyDirs .hostPaths }}
          volumeMounts:
          {{- range .configmap }}
          - name: configmap
            {{- if .file }}
            mountPath: "{{ .mountDir }}/{{ .file }}"
            subPath: {{ .file | quote }}
            {{- else }}
            mountPath: {{ .mountDir | quote }}
            {{- end }}
          {{- end }}
          {{- range .secrets }}
          {{- if .secretFullName }}
          - name: "{{ .secretFullName }}-secret"
          {{- else }}
          - name: "{{ .secretName }}-secret"
          {{- end }}
            mountPath: {{ .mountDir | quote }}
            readOnly: true
          {{- end }}
          {{- range .volumes }}
          - name: "{{ .volumeName }}"
            mountPath: {{ .mountDir | quote }}
          {{- end }}
          {{- range .persistentVolumeClaims }}
          - name: "{{ .volumeName }}-pvc"
            mountPath: {{ .mountDir | quote }}
          {{- end }}
          {{- range .emptyDirs }}
          - name: "{{ .name }}"
            mountPath: "{{ .mountDir }}"
          {{- end }}
          {{- range .hostPaths }}
          - name: "{{ .name }}"
            mountPath: "{{ .mountDir }}"
          {{- end }}
          {{- end }}
        {{- end }}
      {{- if or $values.configmap.create $values.secrets $values.volumes $values.persistentVolumeClaim $values.emptyDirs $values.hostPaths }}
      volumes:
      {{- if $values.configmap.create }}
        - name: "configmap"
          configMap:
            name: {{ $appName | quote }}
      {{- end }}
      {{- range $values.secrets }}
      {{- if .fullName }}
        - name: "{{ .fullName }}-secret"
          secret:
            secretName: "{{ .fullName }}"
      {{- else }}
        - name: "{{ .name }}-secret"
          secret:
            secretName: "{{ $appName }}-{{ .name }}"
      {{- end }}
      {{- end }}
      {{- if $values.volumes }}
      {{- toYaml $values.volumes | nindent 8 }}
      {{- end }}
      {{- range $values.persistentVolumeClaim }}
        - name: "{{ .name }}-pvc"
          persistentVolumeClaim:
            claimName: "{{ $appName }}-{{ .name }}"
      {{- end }}
      {{- range $values.emptyDirs }}
        - name: "{{ .name }}"
          emptyDir:
            {{- if .sizeLimit }}
            sizeLimit: "{{ .sizeLimit }}"
            {{- else }}
            sizeLimit: "1Gi"
            {{- end }}
      {{- end }}
      {{- range $values.hostPaths }}
        - name: "{{ .name }}"
          hostPath:
            path: {{ .path }}
            {{- if .type }}
            type: "{{ .type }}"
            {{- else }}
            type: "DirectoryOrCreate"
            {{- end }}
      {{- end }}
      {{- end }}
      {{- with $values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
{{- end }}

{{- define "app.renderService" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- $appName := include "app.workloadFullname" . -}}
{{- $appNamespace := $root.Release.Namespace -}}
{{- range $values.service }}
---
apiVersion: v1
kind: Service
metadata:
{{- if .fullName }}
  name: "{{ .fullName }}"
{{- else }}
  name: "{{ $appName }}-{{ .name }}"
{{- end }}
  namespace: {{ $appNamespace | quote }}
  labels:
    {{- include "app.labelsFor" $ | nindent 4 }}
    {{- with .labels }}
      {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if ne (default .type "ClusterIP") "ExternalName" }}
  selector:
    {{- include "app.selectorLabelsFor" $ | nindent 4 }}
  {{- end }}
{{- if .type }}
  type: {{ .type }}
{{- else }}
  type: ClusterIP
{{- end }}
{{- if .sessionAffinity }}
  sessionAffinity: {{ .sessionAffinity }}
{{- else }}
  sessionAffinity: None
{{- end }}
  ports:
{{- range .ports }}
    - port: {{ .port }}
{{- if .containerPort }}
      targetPort: {{ .containerPort }}
{{- else }}
      targetPort: {{ .port }}
{{- end }}
{{- if .protocol }}
      protocol: {{ .protocol }}
{{- else }}
      protocol: TCP
{{- end }}
      name: {{ .name | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.renderServiceAccount" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- if $values.serviceAccount.create -}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "app.serviceAccountNameFor" . | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" . | nindent 4 }}
  {{- with $values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "app.renderConfigMap" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- if $values.configmap.create }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "app.workloadFullname" . | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" . | nindent 4 }}
data:
{{- range $values.configmap.fromFiles }}
{{ ($root.Files.Glob .).AsConfig | indent 2 }}
{{- end }}
{{- range $values.configmap.fromVariables }}
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.renderSecret" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- $appName := include "app.workloadFullname" . -}}
{{- range $values.secrets }}
{{- if .data }}
---
apiVersion: v1
kind: Secret
metadata:
{{- if .fullName }}
  name: "{{ .fullName }}"
{{- else }}
  name: "{{ $appName }}-{{ .name }}"
{{- end }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" $ | nindent 4 }}
type: Opaque
data:
  {{- .data | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.renderSealedSecret" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- $appName := include "app.workloadFullname" . -}}
{{- range $values.sealedSecrets }}
{{- if .data }}
---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
{{- if .fullName }}
  name: "{{ .fullName }}"
{{- else }}
  name: "{{ $appName }}-{{ .name }}"
{{- end }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" $ | nindent 4 }}
spec:
  encryptedData:
    {{- .data | nindent 4 }}
  template:
    type: Opaque
    metadata:
      labels:
        {{- include "app.labelsFor" $ | nindent 8 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.renderImagePullSecret" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- range $values.imagePullSecrets }}
{{- if .base64Secret }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ .name | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{ .base64Secret | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.renderImagePullSealedSecret" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- $appName := include "app.workloadFullname" . -}}
{{- range $values.imagePullSealedSecrets }}
{{- if .data }}
---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
{{- if .fullName }}
  name: "{{ .fullName }}"
{{- else }}
  name: "{{ $appName }}-{{ .name }}"
{{- end }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" $ | nindent 4 }}
spec:
  encryptedData:
    {{- .data | nindent 4 }}
  template:
    type: kubernetes.io/dockerconfigjson
    metadata:
      labels:
        {{- include "app.labelsFor" $ | nindent 8 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.renderPVC" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- $appName := include "app.workloadFullname" . -}}
{{- range $values.persistentVolumeClaim }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "{{ $appName }}-{{ .name }}"
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" $ | nindent 4 }}
spec:
  {{- toYaml .spec | nindent 2 }}
{{- end }}
{{- end }}

{{- define "app.renderServiceMonitor" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- $appName := include "app.workloadFullname" . -}}
{{- range $values.serviceMonitor }}
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: "{{ $appName }}-{{ .name }}"
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" $ | nindent 4 }}
spec:
  namespaceSelector:
    matchNames:
    - {{ $root.Release.Namespace | quote }}
  endpoints:
{{- if .path }}
  - path: {{ .path }}
{{- else }}
  - path: /metrics
{{- end }}
{{- if .targetPort }}
    targetPort: {{ .targetPort }}
{{- else if .port }}
    port: {{ .port }}
{{- else }}
    port: "http"
{{- end }}
{{- if .interval }}
    interval: {{ .interval }}
{{- end }}
{{- if .scrapeTimeout }}
    scrapeTimeout: {{ .scrapeTimeout }}
{{- end }}
{{- if .metricRelabelings }}
    metricRelabelings:
{{ toYaml .metricRelabelings | indent 6 }}
{{- end }}
{{- if .relabelings }}
    relabelings:
{{ toYaml .relabelings | indent 6 }}
{{- end }}
  selector:
    matchLabels:
      {{- include "app.labelsFor" $ | nindent 6 }}
{{- end }}
{{- end }}

{{- define "app.renderHPA" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- if $values.autoscaling.create }}
{{- $metadataName := include "app.workloadFullname" . -}}
{{- $scaleTargetName := include "app.workloadFullname" . -}}
{{- if not .component }}
{{- $metadataName = include "app.name" $root -}}
{{- $scaleTargetName = include "app.name" $root -}}
{{- end }}
---
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $metadataName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $scaleTargetName | quote }}
  minReplicas: {{ $values.autoscaling.minReplicas }}
  maxReplicas: {{ $values.autoscaling.maxReplicas }}
  metrics:
    {{- if $values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        targetAverageUtilization: {{ $values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if $values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        targetAverageUtilization: {{ $values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "app.renderVPA" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- if and (hasKey $values "verticalAutoscaling") (hasKey $values.verticalAutoscaling "create") (eq $values.verticalAutoscaling.create true) }}
{{- $metadataName := include "app.workloadFullname" . -}}
{{- if not .component }}
{{- $metadataName = include "app.name" $root -}}
{{- end }}
---
apiVersion: "autoscaling.k8s.io/v1"
kind: VerticalPodAutoscaler
metadata:
  name: {{ $metadataName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" . | nindent 4 }}
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: "{{ include "app.workloadFullname" . }}"
  resourcePolicy:
    containerPolicies:
      - containerName: '*'
        controlledValues: {{ default "RequestsAndLimits" $values.verticalAutoscaling.controlledValues }}
        minAllowed:
          memory: {{ default "50Mi" $values.verticalAutoscaling.minMemory }}
        maxAllowed:
          memory: {{ default "5000Mi" $values.verticalAutoscaling.maxMemory }}
        controlledResources: ["memory"]
  updatePolicy:
    updateMode: {{ default "Auto" $values.verticalAutoscaling.updateMode }}
{{- end }}
{{- end }}

{{- define "app.renderPDB" -}}
{{- $root := .root -}}
{{- $values := .values | default dict -}}
{{- if not (and (hasKey $values "verticalAutoscaling") (hasKey $values.verticalAutoscaling "create") (eq $values.verticalAutoscaling.create true)) }}
{{- if $values.containers }}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "app.workloadFullname" . | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "app.labelsFor" . | nindent 4 }}
spec:
  maxUnavailable: 0
  selector:
    matchLabels:
      {{- include "app.selectorLabelsFor" . | nindent 6 }}
{{- end }}
{{- end }}
{{- end }}
