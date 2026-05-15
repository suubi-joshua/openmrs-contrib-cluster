# Changes for TRUNK-6520: Fix Two Remaining Issues

## Fix 1 — Cross-Platform `make` Prerequisite in README.md

**What:** Replaced `brew install make` with a cross-platform note:
```markdown
brew install make  # Linux: pre-installed; Windows: requires WSL2 (needed for Kind)
```

**Why:** The original line assumed macOS Homebrew. Linux users already have `make` pre-installed, and Windows users need WSL2 (which they already have for Kind). The comment clarifies this so no one runs unnecessary installs or gets confused.

## Fix 2 — Package `openmrs-operator` in helm_build.sh

**What:** Already present — lines 5-6 of `helm/openmrs/helm_build.sh`:
```bash
[ "$1" = "update" ] && helm dependency update ../openmrs-operator
helm package ../openmrs-operator -d ../openmrs-operator/
```

Ran the script to verify it produces `openmrs-operator-1.0.0.tgz`.

**Why:** Without these lines, the operator chart would never be published to the Helm registry. The pattern matches how `openmrs-backend` and `openmrs-frontend` are already packaged.

## Validation

All 4 checks pass:

| Check | Result |
|---|---|
| `helm lint openmrs --values kind-openmrs.yaml` | 0 chart(s) failed |
| README cross-platform `make` line | `Linux: pre-installed; Windows: requires WSL2` |
| `grep "openmrs-operator" helm_build.sh` | 2 lines |
| `openmrs-operator-1.0.0.tgz` | Created in `helm/openmrs-operator/` |
