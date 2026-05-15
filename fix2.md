# TRUNK-6520: Fix Two Remaining Issues in openmrs-operator Implementation

## Context

The agent completed the openmrs-operator chart implementation with all 6
validation checks passing. Two issues remain:

1. `README.md` prerequisite for `make` is Mac-only (`brew install make`)
2. `helm/openmrs/helm_build.sh` was not updated — openmrs-operator will
   never be published to the Helm registry without this

---

## Fix 1 — `README.md`: Cross-Platform `make` Prerequisite

### Read first

```bash
grep -n "brew\|make\|prerequisite\|Prerequisites" README.md | head -20
```

### What to find

A line that currently says something like:

```markdown
- [`make`](https://www.gnu.org/software/make/) — `brew install make`
```

or

```markdown
- `brew install make`
```

### Replace with

```markdown
- [`make`](https://www.gnu.org/software/make/) — pre-installed on Linux;
  Mac: `brew install make`; Windows: requires WSL2 (already needed for Kind)
```

### Verify

```bash
grep -n "make" README.md | grep -i "brew\|linux\|windows\|wsl"
# Must show the cross-platform line
```

---

## Fix 2 — `helm_build.sh`: Package `openmrs-operator` for Registry

### Read first

```bash
cat helm/openmrs/helm_build.sh
```

Read the full output. Understand the existing pattern before editing.

### What to look for

The file packages `openmrs-backend` and `openmrs-frontend` in a repeating
pattern like:

```bash
[ "$1" = "update" ] && helm dependency update ../openmrs-backend
helm package ../openmrs-backend -d ../openmrs-backend/

[ "$1" = "update" ] && helm dependency update ../openmrs-frontend
helm package ../openmrs-frontend -d ../openmrs-frontend/
```

### What to add

Add the operator chart in the same pattern, before the final
`helm dependency update` at the bottom:

```bash
[ "$1" = "update" ] && helm dependency update ../openmrs-operator
helm package ../openmrs-operator -d ../openmrs-operator/
```

Keep the same `-d` destination pattern as the other charts.
Do not change anything else in the file.

### Verify

```bash
grep -n "openmrs-operator" helm/openmrs/helm_build.sh
# Must return two lines:
# - the helm dependency update line
# - the helm package line
```

Then do a dry-run to confirm the script runs without errors:

```bash
cd helm/openmrs
bash helm_build.sh
# Must complete without errors
# A file openmrs-operator-1.0.0.tgz must appear in helm/openmrs-operator/
ls ../openmrs-operator/*.tgz
```

---

## Step 3 — Final Validation

After both fixes:

```bash
# Lint still passes
cd helm
helm lint openmrs --values kind-openmrs.yaml
# Required: 0 chart(s) failed

# README has cross-platform make instructions
grep -n "WSL2\|wsl2\|linux\|Linux" README.md | grep -i "make"
# Required: at least one result

# helm_build.sh packages operator
grep "openmrs-operator" helm/openmrs/helm_build.sh
# Required: two lines (dependency update + package)
```

## Stop Conditions

| Situation | Action |
|---|---|
| `grep "openmrs-operator" helm_build.sh` returns empty | File was not edited — re-read and add the two lines |
| `bash helm_build.sh` exits non-zero | Read the error — likely a missing `helm dependency update` for the operator chart |
| No `.tgz` file in `helm/openmrs-operator/` after running helm_build.sh | Package command failed — check Chart.yaml indentation with `helm lint helm/openmrs-operator` |
| `grep "WSL2" README.md` returns empty | README fix was not applied — re-read and replace the brew-only line |

---

*Ticket: TRUNK-6520 | PR: #9 | Contributor: @suubi7*