# PR 3 — `OKDP/platform-packages` — Phase 2, release-please

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> **Stacks on PR 1** (`chore/publish-guardrails`). Don't open it until that is merged.
> A prepared branch exists as `chore/release-please` on top of PR 1's head.

### Title

```
feat(ci): let release-please own the package versions
```

### Body

```markdown
## Description

The published version of a package is a literal typed into its manifest, and
`kubocd package` has no tag override, so whatever sits in that field is what
reaches the registry. #56 stopped the overwriting. This removes the cause.

Three consequences of a hand-typed version, all visible in this repo's history:

**Versions go backwards.** Reading `trino`'s `tag:` forward through git:
`p06 → p07 ×5 → p17 → p18 ×3 → p19 ×3 → p20 → p07 → p08 → p21`. After `p20`
shipped, the manifest was set back to `p07`. `okdp-control-plane-server` went
`0.8.0-p01 → 0.7.0-p01 → 0.7.1-p01`.

**`-pNN` is not a usable version.** Under SemVer a hyphen introduces a
pre-release, so `3.2.1-p04` ranks *below* plain `3.2.1`. `trino.yaml` already
carries a comment about this — the version was inflated from `480` to `480.0.0`
because "the UI requires the version to conform to SemVer". And `airflow` has
shipped both `3.2.1-p2` and `3.2.1-p03`: different tags in the registry, sorting
against each other wrongly.

**There is no release.** Zero git tags, zero GitHub Releases,
`.release-please-manifest.json` is empty. release-please has been installed the
whole time but configured for the wrong repo shape — a single root package with
`release-type: simple`, minting one repo-wide `v0.3.0` unrelated to the thirteen
per-package tags that actually ship. Its release PR #18 has been open since
26 June because that number means nothing to anyone.

### What changes

**One release-please component per package**, following the pattern already used
in `OKDP/helm-charts-utilities`. Tags become `trino/v1.0.0`, each package gets
its own `CHANGELOG.md`, and `separate-pull-requests: false` groups them into a
single release pull request — cross-cutting commits are normal here (`9f28ef6`
touched eight packages), so that is one review instead of eight.

**release-please writes the OCI tag.** The `generic` updater replaces the version
on any line carrying an `x-release-please-version` annotation. It is a line-level
text substitution, so the rest of each manifest — module charts, image tags,
schema — is untouched.

**Every package restarts at `1.0.0`.** The existing `-pNN` tags stay on the
registry; nothing is deleted. Verified safe: there is no semver library in
`okdp-control-plane-server`'s `go.mod` nor in `okdp-control-plane-ui`, and the
console's version picker (`versionOptionsFor`) renders the list in the order the
server supplies. Nothing computes "latest", so the numbers can restart.

**Publishing is triggered by a release, for the released packages only.**
`release-please.yml` passes `paths_released` to the package template, which
resolves each released directory to its manifest. `on_existing_tag: fail` is set
on this path: release-please has just minted versions that never existed, so a
tag already being present means something is genuinely wrong.

`release-please.yml` also moves from `pull_request: types: [closed]` to
`push: branches: [main]`, the documented trigger, which additionally covers
direct pushes.

**Shared charts are guarded.** `airflow`, `superset` and `trino` embed
`charts/internal-secrets` by relative path, and `jupyterhub` embeds
`charts/oidc-client`. release-please assigns commits to packages *by directory*,
and `charts/` sits outside every package — so a charts-only change would release
nothing and never reach the registry.

This is not hypothetical: **all three commits that have ever touched `charts/`
touched no package manifest**, including `fix(oidc-client): generate a 32-byte
key, hex encoded`. Today that reaches users only because publish-on-merge
rebuilds everything, which is the behaviour #56 removed.

A new CI job fails the pull request when a shared chart moves without its
consumers, naming them.

## Related Issue

Fixes #<number of the release-please issue>

## Type of Change

- [ ] Bug fix
- [x] New feature
- [ ] Documentation update
- [x] Refactor / chore
- [x] Breaking change

Every published tag changes shape: `trino:480.0.0-p21` becomes `trino:1.0.0`.
Existing tags are not deleted, so nothing breaks immediately, but consumers stop
receiving updates until they are repointed. `OKDP/okdp-sandbox` must be updated
in two places per package — the `tag:` on each Release, and the `versions:` /
`default:` entries in `spec.context.serviceCatalog`. This needs an announcement,
not just a pull request.

## How to Test

1. **The updater touches one line.** After applying, `git diff` on any manifest
   shows only the `tag:` line. `jupyterhub.yaml` is the sharp case: it holds
   fourteen other version-looking lines (`version: 4.3.3`, `tag: "4.3.3"`, the
   notebook image tags) and none may change.

2. **The release pull request.** On merge, release-please opens
   `chore: release main` bumping every package with pending commits, each with a
   `CHANGELOG.md` and a `tag:` rewrite. Nothing is published yet.

3. **Publishing follows the release.** Merge that pull request; release-please
   creates `trino/v1.0.0` and friends, then publishes **only** the released
   packages. The job log line `Processing: ...` names them.

4. **The shared-chart guard.** Open a pull request changing only
   `charts/oidc-client/templates/client.yaml`. The `shared-charts` job fails with
   "charts/oidc-client is embedded by packages/services/jupyterhub, but nothing
   under packages/services/jupyterhub changed". Touch `jupyterhub.yaml` as well
   and it passes.

5. **Dry-run on a fork first.** Every failure mode in this mechanism is silent —
   a wrong `extra-files` form, a missing annotation, or a version that does not
   match `X.Y.Z` all produce a perfect-looking release PR whose published tag
   never moves.

## Checklist

- [x] I have tested my changes
- [ ] Documentation updated if needed
- [x] If breaking change: migration path described above
- [x] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [x] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
```

---

## Making the changes by hand

Six edits. The first three are mechanical, the last three are workflow wiring.

### 1. Replace `release-please-config.json`

One block per package. Strict JSON — **no comments**. Three details that are easy
to get wrong and that fail silently:

- `separate-pull-requests: false` groups pending packages into one release PR.
- `extra-files` must use the **object** form with `"type": "generic"`. The bare
  string `["trino.yaml"]` selects the default YAML updater, which looks for a
  `version:` key; these manifests have `tag:`, so it would change nothing and the
  published tag would never move.
- `path` inside `extra-files` resolves relative to the package path above, so it
  is just the filename.

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "separate-pull-requests": false,
  "include-v-in-tag": true,
  "draft-pull-request": true,
  "packages": {
    "packages/services/airflow": {
      "component": "airflow",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "airflow.yaml"
        }
      ]
    },
    "packages/services/hive-metastore": {
      "component": "hive-metastore",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "hive-metastore.yaml"
        }
      ]
    },
    "packages/services/jupyterhub": {
      "component": "jupyterhub",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "jupyterhub.yaml"
        }
      ]
    },
    "packages/services/okdp-examples": {
      "component": "okdp-examples",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "okdp-examples.yaml"
        }
      ]
    },
    "packages/services/polaris": {
      "component": "polaris",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "polaris.yaml"
        }
      ]
    },
    "packages/services/spark-defaults": {
      "component": "spark-defaults",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "spark-defaults.yaml"
        }
      ]
    },
    "packages/services/spark-history-server": {
      "component": "spark-history-server",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "spark-history-server.yaml"
        }
      ]
    },
    "packages/services/spark-operator": {
      "component": "spark-operator",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "spark-operator.yaml"
        }
      ]
    },
    "packages/services/spark-rbac": {
      "component": "spark-rbac",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "spark-rbac.yaml"
        }
      ]
    },
    "packages/services/superset": {
      "component": "superset",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "superset.yaml"
        }
      ]
    },
    "packages/services/trino": {
      "component": "trino",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "trino.yaml"
        }
      ]
    },
    "packages/system/okdp-control-plane-server": {
      "component": "okdp-control-plane-server",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "okdp-control-plane-server.yaml"
        }
      ]
    },
    "packages/system/okdp-control-plane-ui": {
      "component": "okdp-control-plane-ui",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "okdp-control-plane-ui.yaml"
        }
      ]
    }
  },
  "changelog-sections": [
    {
      "type": "feat",
      "section": "Features"
    },
    {
      "type": "fix",
      "section": "Bug Fixes"
    },
    {
      "type": "docs",
      "section": "Documentation",
      "hidden": false
    },
    {
      "type": "refactor",
      "section": "Refactoring",
      "hidden": false
    },
    {
      "type": "test",
      "section": "Tests",
      "hidden": true
    },
    {
      "type": "ci",
      "section": "Continuous Integration",
      "hidden": true
    }
  ]
}
```

### 2. Replace `.release-please-manifest.json`

Currently `{}`. This is the scoreboard release-please keeps from here on.

```json
{
  "packages/services/airflow": "1.0.0",
  "packages/services/hive-metastore": "1.0.0",
  "packages/services/jupyterhub": "1.0.0",
  "packages/services/okdp-examples": "1.0.0",
  "packages/services/polaris": "1.0.0",
  "packages/services/spark-defaults": "1.0.0",
  "packages/services/spark-history-server": "1.0.0",
  "packages/services/spark-operator": "1.0.0",
  "packages/services/spark-rbac": "1.0.0",
  "packages/services/superset": "1.0.0",
  "packages/services/trino": "1.0.0",
  "packages/system/okdp-control-plane-server": "1.0.0",
  "packages/system/okdp-control-plane-ui": "1.0.0"
}
```

### 3. Annotate the thirteen manifests

In **each** package manifest, replace the `tag:` line:

```yaml
- tag: 480.0.0-p21
+ tag: 1.0.0 # x-release-please-version
```

Set the value *and* add the comment in the same edit. The updater replaces the
first `X.Y.Z`-looking string on an annotated line, and some current tags don't
match that shape — `sandbox-dependencies` has `18.3-p03`, only two segments,
which would be left untouched silently. Normalising to `1.0.0` avoids it.

The whole set at once (macOS `sed`; drop the `''` on Linux):

```sh
for f in packages/*/*/*.yaml; do
  grep -q '^modules:' "$f" || continue
  sed -i '' '0,/^tag: /s//tag: 1.0.0 # x-release-please-version/' "$f"
done
git diff --stat        # expect 13 files, one line each
```

### 4. Teach the package template to publish a subset

In `.github/workflows/kubocd-package-template.yml`, add an input directly after
`on_existing_tag`:

```yaml
      package_paths:
        description: >-
          JSON array of package directories to process, as emitted by
          release-please's paths_released output. Empty or "[]" means every
          package under packages/.
        required: false
        type: string
        default: ""
```

then replace the whole **Find KuboCD packages** step with:

```yaml
      - name: Find KuboCD packages 🔎
        env:
          PACKAGE_PATHS: ${{ inputs.package_paths }}
        run: |
          set -uo pipefail

          if [[ -n "${PACKAGE_PATHS}" && "${PACKAGE_PATHS}" != "[]" ]]; then
            # A release published only some packages: resolve each released
            # directory to the manifest it contains.
            KUBOCD_PACKAGES=""
            for dir in $(jq -r '.[]' <<<"${PACKAGE_PATHS}")
            do
              manifest=$(find "${dir}" -maxdepth 1 -type f \( -name "*.yaml" -o -name "*.yml" \) -exec grep -l '^modules:' {} \;)
              if [[ -z "${manifest}" ]]; then
                echo "::error title=No package manifest::${dir} was released but holds no manifest with 'modules:'"
                exit 1
              fi
              KUBOCD_PACKAGES="${KUBOCD_PACKAGES} ${manifest}"
            done
            KUBOCD_PACKAGES="${KUBOCD_PACKAGES# }"
          else
            KUBOCD_PACKAGES=$(find packages -type f \( -name "*.yaml" -o -name "*.yml" \) -exec grep -l '^modules:' {} \; | tr '\n' ' ')
          fi

          echo "Processing: ${KUBOCD_PACKAGES}"
          echo "KUBOCD_PACKAGES=${KUBOCD_PACKAGES}" >> $GITHUB_ENV
```

`PACKAGE_PATHS` is passed through `env:` rather than interpolated into the
script, so the JSON's quotes cannot break the shell.

### 5. Replace `release-please.yml`

```yaml
#
# Copyright 2025 The OKDP Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name: release-please

# Every push to main is a candidate: release-please keeps one release pull
# request up to date, and cutting the release is merging that pull request.
on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false

jobs:

  release-please:
    runs-on: ubuntu-latest
    if: github.repository_owner == 'OKDP'
    outputs:
      # JSON array of the package directories released by this run, "[]" when
      # this push only updated the release pull request.
      paths_released: ${{ steps.release-please.outputs.paths_released }}
    steps:
      - uses: googleapis/release-please-action@v4
        id: release-please
        with:
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json

  get-package-oci-prefix:
    needs: [release-please]
    if: needs.release-please.outputs.paths_released != '[]'
    runs-on: ubuntu-latest
    outputs:
      oci_package_prefix: ${{ steps.prefix.outputs.oci_package_prefix }}
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Get OCI package prefix
        id: prefix
        uses: ./.github/actions/oci-package-prefix
        with:
          values_path: platform-packages-values.yaml

  publish:
    needs: [release-please, get-package-oci-prefix]
    if: needs.release-please.outputs.paths_released != '[]'
    permissions:
      contents: read
      packages: write
    uses: ./.github/workflows/kubocd-package-template.yml
    with:
      ci_registry: "ghcr.io"
      registry: "quay.io"
      publish_to_registry: "true"
      # release-please has just minted versions that have never existed, so a
      # tag already being on the registry means something is genuinely wrong.
      on_existing_tag: "fail"
      package_paths: ${{ needs.release-please.outputs.paths_released }}
      oci_package_prefix: "${{ needs.get-package-oci-prefix.outputs.oci_package_prefix }}"
      runs-on: "ubuntu-latest"
    secrets: inherit
```

### 6. Guard the shared charts

New file `.github/scripts/shared-chart-consumers.sh`:

```bash
#!/usr/bin/env bash
#
# A package embeds a local chart by relative path (`path: ../../../charts/x`),
# so changing that chart changes the package's artifact. release-please assigns
# commits to packages by directory, and charts/ is outside every package, so a
# charts-only change would release nothing and never reach the registry.
#
# This fails the build when a shared chart moves without its consumers.
#
# Usage: shared-chart-consumers.sh <changed-file>...
set -uo pipefail

changed=("$@")
status=0

# Nothing to inspect (empty diff): succeed rather than trip `set -u`.
[[ ${#changed[@]} -eq 0 ]] && exit 0

changed_under() {           # changed_under <dir>
  local dir="$1" f
  for f in "${changed[@]}"; do
    [[ "$f" == "$dir/"* ]] && return 0
  done
  return 1
}

# Which shared charts were touched?
charts=$(printf '%s\n' "${changed[@]}" | grep -oE '^charts/[^/]+' | sort -u)

for chart in ${charts}
do
  name="${chart#charts/}"
  # Packages embedding this chart by relative path
  consumers=$(grep -rl "path: .*charts/${name}\$" packages/ 2>/dev/null | xargs -r -n1 dirname | sort -u)

  [[ -z "${consumers}" ]] && continue

  for pkg in ${consumers}
  do
    if changed_under "${pkg}"; then
      echo "ok   ${chart} changed, and so did ${pkg}"
    else
      echo "::error title=Shared chart changed without its consumer::${chart} is embedded by ${pkg}, but nothing under ${pkg} changed. release-please assigns commits by directory, so ${pkg} would not be released and the change would never be published. Bump or touch ${pkg} in this pull request."
      status=1
    fi
  done
done

exit ${status}
```

```sh
chmod +x .github/scripts/shared-chart-consumers.sh
```

and a new job at the top of `jobs:` in `.github/workflows/ci.yml`:

```yaml
  shared-charts:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: A shared chart must move with its consumers
        run: |
          set -uo pipefail
          git fetch -q --depth=1 origin "${{ github.base_ref }}"
          mapfile -t CHANGED < <(git diff --name-only FETCH_HEAD...HEAD)
          printf 'changed: %s\n' "${CHANGED[@]:-<none>}"
          bash .github/scripts/shared-chart-consumers.sh "${CHANGED[@]:-}"
```

### Check your work

```sh
python3 -c "import json;[json.load(open(f)) for f in ['release-please-config.json','.release-please-manifest.json']];print('json ok')"
for f in .github/workflows/*.yml; do python3 -c "import yaml;yaml.safe_load(open('$f'))" || echo "BAD $f"; done
bash -n .github/scripts/shared-chart-consumers.sh
git diff --stat        # expect 19 files
```

---

## Verified before writing this

- All five workflows parse; every `run:` step passes `bash -n`.
- Both JSON files parse.
- The new **Find** step was exercised in four modes: a released subset resolves
  to the right manifests; empty and `"[]"` both fall back to all thirteen; a
  released directory holding no manifest fails with a clear error.
- The generic updater was simulated against `jupyterhub.yaml` — exactly one line
  changed, and the fourteen other version-looking lines, including a different
  `tag: 1.0.1`, were untouched.
- The shared-chart guard was run against the **real** `charts/oidc-client` commit
  from 21 Aug and correctly failed, naming `packages/services/jupyterhub`. It
  passes once jupyterhub is touched, names all three consumers for
  `internal-secrets`, and stays silent for ordinary package-only changes.
- `kubocd` v0.3.2 was run locally: `tag: 1.0.0 # x-release-please-version` parses
  and produces tag `1.0.0`. An `appVersion:` key is **rejected** —
  `json: unknown field "appVersion"` — which is why the upstream version belongs
  in `description:` rather than a new field.

## Not in this PR

- Repointing `OKDP/okdp-sandbox`. Separate, and it needs the announcement.
- The automated bump PR into `okdp-sandbox` — needs a machine account, since
  `GITHUB_TOKEN` cannot write to another repository.
- Publishing `charts/internal-secrets` and `charts/oidc-client` to the registry
  like the other module charts, so packages reference them by version instead of
  by relative path. That would remove the need for the guard in step 6 entirely,
  and it matches what the other charts already do. Worth its own issue.
