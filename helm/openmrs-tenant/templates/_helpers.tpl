{{- /*
Standard labels for every K8s resource the tenant chart renders.
Use in metadata.labels via: {{ include "openmrs-tenant.labels" . | nindent N }}
*/}}
{{- define "openmrs-tenant.labels" -}}
app.kubernetes.io/name: openmrs-tenant
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/tenant: {{ .Values.global.tenant.name | quote }}
{{- end }}

{{- /*
Default database name: openmrs_<tenant>. Hyphens become underscores so the name
stays consistent with the openmrs_<tenant> JDBC URL convention.
*/}}
{{- define "openmrs-tenant.dbName" -}}
{{- .Values.dbBootstrap.database | default (printf "openmrs_%s" (.Values.global.tenant.name | toString | replace "-" "_")) -}}
{{- end }}
