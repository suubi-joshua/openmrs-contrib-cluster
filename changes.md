# Latest Changes: openmrs-operator chart + Makefile

## What & Why

### `helm/openmrs-operator/` — standalone operator chart

Bundles the MariaDB operator (CRDs + controller). Extensible for ECK later.

**Standalone, not a subchart of `openmrs`**, because:
- `helm uninstall openmrs` would cascade-delete MariaDB CRDs cluster-wide
- Operator lifecycle decoupled from app releases
- Installs into `mariadb-system` namespace (convention), not the app namespace

### `Makefile` — one-command deploy for every workflow

```makefile
make deploy           # installs operator + full OpenMRS stack
make deploy-openmrs   # app only (operator must already exist)
make deps             # update all subchart dependencies
```

The `deploy-openmrs` target runs `helm dependency update ./helm/openmrs` before
installing. This ensures that after you edit any subchart (backend, frontend,
operator), the parent chart picks up the changes automatically.

**Why:** Without this, users who edit a chart and run `helm upgrade` would get
stale cached versions and wonder why their changes didn't apply. The Makefile
removes that friction — one command, always fresh.

### Registry method (`helm_build.sh` + README)

The operator chart is published alongside the app charts so registry users can
install without cloning:

```bash
helm install openmrs-operator openmrs/openmrs-operator -n mariadb-system --create-namespace
helm install openmrs openmrs/openmrs
```

`helm/openmrs/helm_build.sh` updated to package `openmrs-operator` for CI/CD.

**Why:** Registry users don't have the Makefile (no clone), so they need
equivalent commands documented in README. The build script needed updating so
the operator chart actually gets published.

### README restructured

Three workflow sections instead of one:
1. **Quick start (cloned repo)** — `make deploy`, no prerequisite reading
2. **After making changes** — `make deploy` auto-updates deps
3. **From Helm registry (no clone)** — explicit operator + app install commands

**Why:** A single "how to try it out" section didn't cover the different
workflows. New users, returning developers, and registry users each need a
clear path.
