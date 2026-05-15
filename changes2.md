# Changes for TRUNK-6520: Implement `openmrs-operator` Chart + Makefile

## Files Modified

### 1. `helm/openmrs-operator/Chart.yaml`
- **What:** Updated `description` from a single line to a multi-line YAML block scalar (`>`).
- **Why:** The new description documents that this is a cluster-scoped chart for MariaDB, Elasticsearch, etc., and clarifies it should be installed once per cluster before the app chart.

### 2. `helm/openmrs-operator/templates/configmap.yaml`
- **What:** Replaced the static ConfigMap (hardcoded `mariadb-operator`) with a dynamic version that:
  - Sets proper Kubernetes labels (`app.kubernetes.io/name`, `instance`, `version`, `managed-by`)
  - Adds `namespace` to metadata
  - Uses `hasKey` + `index` guard to conditionally list the operator only when enabled
- **Why:** The ConfigMap is now queryable after install (`kubectl get configmap`) and reflects what operators are actually enabled, making it useful for debugging and programmatic inspection.

### 3. `helm/openmrs-operator/templates/NOTES.txt` (new file)
- **What:** Created a Helm NOTES.txt template that displays after `helm install`:
  - Lists enabled operators with their versions and namespaces
  - Provides next-step instructions for deploying the OpenMRS stack
  - Shows verification commands (`kubectl get pods`, `kubectl get crds`)
- **Why:** Gives users immediate feedback on what was installed and what to do next.

### 4. `Makefile`
- **What:** Updated the `deploy-operator` target to:
  - Run `helm dependency update` before installing (picks up local chart changes)
  - Add `--wait` flag (blocks until resources are ready)
  - Use long-form `--namespace` instead of `-n` for clarity
  - Added `##` doc comments for each target
- **Why:** Ensures the operator chart dependencies are always fresh and the install waits for readiness. Documented targets help new contributors understand the workflow.

### 5. `README.md`
- **What:**
  - Added `brew install make` to prerequisites
  - Replaced the old "Quick start", "After making changes", and "From Helm registry" sections with a unified "How to deploy" section with three workflows
  - Changed the Helm registry URL to omit trailing slash (`https://openmrs.github.io/openmrs-contrib-cluster`)
- **Why:** Clearer documentation that separates cloned-repo workflow from registry workflow.

## Key Technical Decisions

- **`hasKey` guard on mariadb-operator:** Using `hasKey .Values "mariadb-operator"` before indexing prevents template errors if the key is absent — defensive pattern for future operator additions.
- **`mariadb-operator.crds.enabled: false` in values.yaml:** The CRDs are installed via the separate `mariadb-operator-crds` subchart. Without setting `crds.enabled: false` on the main operator chart, both charts try to install CRDs, causing conflicts on re-install.
- **Tab characters in Makefile:** Make requires command lines to start with literal tab characters (`^I`), not spaces. Verified with `cat -A Makefile`.

## Validation

All 6 validation checks pass:

| # | Check | Result |
|---|-------|--------|
| 1 | `helm lint helm/openmrs-operator` | 0 chart(s) failed |
| 2 | `helm lint openmrs --values kind-openmrs.yaml` | 0 chart(s) failed |
| 3 | `helm template openmrs-operator` | ConfigMap + NOTES render without errors |
| 4 | JDBC URL contains `loadbalance://openmrs-mariadb.openmrs.svc.cluster.local` | Pass |
| 5 | Makefile uses `^I` (tab) for command lines | Pass |
| 6 | `OMRS_DB_HOSTNAME: "openmrs-mariadb"` (no regressions) | Pass |
