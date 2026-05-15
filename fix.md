# TRUNK-6520: Implement `openmrs-operator` Chart + Makefile

## Context

Rafal suggested in PR #9 review: *"We could have a dedicated helm chart to
install cluster operators named openmrs-operator. We could use it for mariadb,
elasticsearch and possibly others."*

The chart skeleton already exists locally at `helm/openmrs-operator/`.
This document fixes the remaining issues and completes the implementation.

---

## Agent Constraints

- **Read every file before editing** — never assume content
- **Run every command and read its full output** before proceeding
- **Stop and report** if any command exits non-zero
- Do not touch `helm/openmrs-backend/` or `helm/openmrs/` — those are
  already correct and under separate review

---

## Step 0 — Read Current State of All Files

```bash
cat helm/openmrs-operator/Chart.yaml
cat helm/openmrs-operator/values.yaml
cat helm/openmrs-operator/templates/configmap.yaml
ls helm/openmrs-operator/templates/
cat Makefile 2>/dev/null || echo "Makefile not found"
cat helm/openmrs/helm_build.sh
cat helm/kind-openmrs.yaml | head -20
```

Read all output before making any changes.

---

## Step 1 — Fix `Chart.yaml`

Read the file first, then verify indentation is correct.
The YAML must have `version`, `repository`, and `condition` indented
4 spaces under each `-` list item. Correct form:

```yaml
apiVersion: v2
name: openmrs-operator
description: >
  Cluster-scoped operators for OpenMRS (MariaDB, Elasticsearch, etc.).
  Install this chart once per cluster before deploying the OpenMRS app chart.
type: application
version: 1.0.0
appVersion: "1.0.0"

dependencies:
  - name: mariadb-operator-crds
    version: 26.3.0
    repository: https://helm.mariadb.com/mariadb-operator
    condition: mariadb-operator-crds.enabled

  - name: mariadb-operator
    version: 26.3.0
    repository: https://helm.mariadb.com/mariadb-operator
    condition: mariadb-operator.enabled
```

After editing:

```bash
helm lint helm/openmrs-operator
# Must return: 0 chart(s) failed
```

---

## Step 2 — Fix `values.yaml`

The current file has indentation issues. The correct structure is:

```yaml
# MariaDB Operator
# Installs CRDs as a separate chart first (mandatory), then the operator.
# crds.enabled must be false on the operator itself to avoid double-install.
mariadb-operator-crds:
  enabled: true

mariadb-operator:
  enabled: true
  crds:
    enabled: false   # CRDs are installed via mariadb-operator-crds above

# ECK (Elasticsearch) Operator — disabled until TRUNK-6535 migration
# eck-operator:
#   enabled: false
```

Key points:
- `mariadb-operator-crds.enabled: true` and `mariadb-operator.enabled: true`
  are the defaults for this chart — the whole point of installing it is to
  enable the operators
- `mariadb-operator.crds.enabled: false` is mandatory — without this the
  operator tries to install CRDs itself AND via the CRDs chart, causing
  a conflict on re-installs
- ECK section is commented out as a placeholder showing extensibility

---

## Step 3 — Replace `configmap.yaml` with Dynamic Version

The current ConfigMap hardcodes `mariadb-operator` as a static string.
Make it dynamic so it reflects what is actually enabled. This makes the
ConfigMap useful for debugging and future programmatic inspection.

Replace `helm/openmrs-operator/templates/configmap.yaml` with:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-operators
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
data:
  managed-operators: |-
    {{- if index .Values "mariadb-operator" "enabled" | default false }}
    - name: mariadb-operator
      version: "{{ .Chart.Dependencies | default list }}"
      namespace: {{ .Release.Namespace }}
    {{- end }}
    {{- if index .Values "eck-operator" "enabled" | default false }}
    - name: eck-operator
      namespace: elastic-system
    {{- end }}
```

This ConfigMap is queryable after install:

```bash
kubectl -n mariadb-system get configmap openmrs-operators -o yaml
```

---

## Step 4 — Add `NOTES.txt`

Create `helm/openmrs-operator/templates/NOTES.txt`:

```
OpenMRS Operators installed successfully in namespace {{ .Release.Namespace }}.

Enabled operators:
{{- if index .Values "mariadb-operator" "enabled" | default false }}
  mariadb-operator v26.3.0  (namespace: {{ .Release.Namespace }})
{{- end }}
{{- if index .Values "eck-operator" "enabled" | default false }}
  eck-operator  (namespace: elastic-system)
{{- end }}

Next step — deploy the OpenMRS application stack:

  Using Makefile (recommended):
    make deploy-openmrs

  Manually:
    helm dependency update ./helm/openmrs
    helm upgrade --install --create-namespace \
      -n openmrs \
      --values ./helm/kind-openmrs.yaml \
      openmrs ./helm/openmrs

To verify operators are running:
  kubectl -n {{ .Release.Namespace }} get pods
  kubectl get crds | grep mariadb
```

---

## Step 5 — Create or Fix `Makefile`

**Important:** Every command line in a Makefile MUST start with a tab character,
not spaces. If the agent creates this file, it must use literal tab characters.

Create `Makefile` in the repo root:

```makefile
.PHONY: deploy deploy-operator deploy-openmrs deps

## deploy: Install operators then OpenMRS (full stack, use for fresh installs)
deploy: deploy-operator deploy-openmrs

## deploy-operator: Install cluster operators (MariaDB, etc.) into mariadb-system
deploy-operator:
	helm dependency update ./helm/openmrs-operator
	helm upgrade --install openmrs-operator ./helm/openmrs-operator \
	  --namespace mariadb-system \
	  --create-namespace \
	  --wait

## deploy-openmrs: Install OpenMRS app stack (operator must already be running)
deploy-openmrs:
	helm dependency update ./helm/openmrs
	helm upgrade --install openmrs ./helm/openmrs \
	  --namespace openmrs \
	  --create-namespace \
	  --values ./helm/kind-openmrs.yaml \
	  --wait

## deps: Update all subchart dependencies (run after editing any subchart)
deps:
	helm dependency update ./helm/openmrs-backend
	helm dependency update ./helm/openmrs-operator
	helm dependency update ./helm/openmrs
```

After creating, verify tabs are correct:

```bash
cat -A Makefile | grep "helm" | head -5
# Every helm line must start with ^I (tab character)
# If you see spaces instead, the file is wrong
```

If spaces are present, recreate the file with tabs. The agent must use
`\t` or actual tab characters — never spaces — for Makefile command lines.

**Note for Windows users:** `make` requires WSL2 on Windows. Since Kind
(required to run this cluster locally) also requires WSL2, this is not
an additional prerequisite.

---

## Step 6 — Update `helm_build.sh`

Read the current file first:

```bash
cat helm/openmrs/helm_build.sh
```

Add packaging of `openmrs-operator` in the same pattern as the other charts.
Find where `openmrs-backend` is packaged and add the operator chart
in the same location:

```bash
[ "$1" = "update" ] && helm dependency update ../openmrs-operator
helm package ../openmrs-operator -d ../openmrs-operator/
```

The `-d ../openmrs-operator/` puts the packaged chart alongside its source,
consistent with how `openmrs-backend` and `openmrs-frontend` are packaged.

---

## Step 7 — Update `README.md`

Read the current README prerequisites and "How to try it out" section:

```bash
grep -n "Prerequisites\|try it out\|deploy\|make\|operator" README.md | head -30
```

### Add `make` to prerequisites section

Find the existing prerequisites list (Kind, kubectl, helm) and add:

```markdown
- [`make`](https://www.gnu.org/software/make/) (pre-installed on Linux/Mac;
  Windows users: requires WSL2, which is already needed for Kind)
```

### Replace the "How to try it out" section

Replace the existing single-workflow section with three clear workflows:

```markdown
### How to deploy

#### Quick start (cloned repo)

One command installs operators and the full OpenMRS stack:

      make deploy

This runs `helm dependency update` automatically — your local chart changes
are always picked up.

#### After making changes to a subchart

      make deploy

The Makefile always runs `helm dependency update` before installing,
so changes to `openmrs-backend`, `openmrs-operator`, or `openmrs-frontend`
are reflected immediately.

#### From Helm registry (no clone required)

Install the operator chart first, then the application:

      helm repo add openmrs https://openmrs.github.io/openmrs-contrib-cluster
      helm repo update

      # Step 1: Install cluster operators (once per cluster)
      helm install openmrs-operator openmrs/openmrs-operator \
        --namespace mariadb-system --create-namespace

      # Step 2: Install OpenMRS
      helm install openmrs openmrs/openmrs \
        --namespace openmrs --create-namespace
```

---

## Step 8 — Run Full Validation

```bash
# 1. Lint the operator chart
helm lint helm/openmrs-operator
# Required: 0 chart(s) failed

# 2. Lint the full stack with kind values
cd helm
helm lint openmrs --values kind-openmrs.yaml
# Required: 0 chart(s) failed

# 3. Template render — operator chart
helm template openmrs-operator helm/openmrs-operator \
  --namespace mariadb-system
# Required: ConfigMap renders, NOTES.txt content visible at end

# 4. Template render — verify JDBC URL still correct
helm template openmrs openmrs \
  --namespace openmrs \
  --values kind-openmrs.yaml \
  2>&1 | grep "jdbc:mariadb"
# Required: loadbalance://openmrs-mariadb.openmrs.svc.cluster.local

# 5. Verify Makefile uses tabs
cat -A Makefile | grep "helm" | head -3
# Required: lines start with ^I (tab)

# 6. No regressions in openmrs-backend templates
helm template openmrs openmrs \
  --namespace openmrs \
  --values kind-openmrs.yaml \
  2>&1 | grep "OMRS_DB_HOSTNAME"
# Required: single line: openmrs-mariadb
```

All six checks must pass before committing.

---

## Stop Conditions

| Situation | Action |
|---|---|
| `helm lint helm/openmrs-operator` fails | Read the exact error — almost always YAML indentation in Chart.yaml or values.yaml |
| `helm template openmrs-operator` shows no ConfigMap | Check configmap.yaml condition variable names match values.yaml keys exactly |
| `cat -A Makefile` shows spaces not `^I` | File must be recreated with literal tab characters — spaces will silently break make |
| `helm dependency update helm/openmrs-operator` fails | Chart.yaml repository URL or version is wrong — verify against https://helm.mariadb.com/mariadb-operator |
| JDBC URL check returns empty | openmrs-backend values.yaml was accidentally modified — check git diff |

---

*Ticket: TRUNK-6520 | PR: #9 | Contributor: @suubi7*