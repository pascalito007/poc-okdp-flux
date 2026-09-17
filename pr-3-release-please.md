# PR 3: `OKDP/platform-packages`, Phase 2, release-please

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> **PR 1 is merged** (#67, 28 Aug). Apply this onto a fresh branch off `main`.
> This is the branch PR **#74** uses, which is still a draft.

> **Rewritten 17 Sep 2026.** The previous version of this document had
> release-please own the whole version, with every package restarting at
> `1.0.0` and the upstream version dropped from the tag. The team sent that
> back: keep the upstream version, automate only what comes after the dash.
> The superseded document is in `rejected-design-2026-09-17/`.

## The scheme

```
tag: 24.4.11-1.0.0
     ^^^^^^^ ^^^^^
     upstream  OKDP
```

| | owner | changes when |
|---|---|---|
| left of the dash | a human, in a normal PR | upstream Keycloak / Trino / Airflow moves |
| right of the dash | release-please, from the commit types | every release |
| the `tag:` line itself | a step in `release-please.yml` | it only joins the two |

`24.4.11-p07` becomes `24.4.11-1.0.0`. The `p` goes away because the suffix now
carries its own patch position, so keeping `p` would mean two conflicting patch
markers in one string.

An upstream bump is committed as `feat!:`, so the OKDP half takes the major and
the tag reads `25.0.0-2.0.0`. The OKDP half is never reset to `1.0.0`, because
the git tag `keycloak/v1.0.0` already exists and release-please would collide
with it. Letting the upstream bump be the major is also honest: a new upstream
is a breaking change for consumers.

### Why release-please cannot do this by itself

This is the part reviewers will ask about, and it is why the composition sits in
the workflow rather than in `release-please-config.json`. Both candidate
configurations were run against release-please **17.11.2**, the version behind
`googleapis/release-please-action@v4`.

**The `generic` updater cannot preserve the prefix.** Its version regex is
`(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(-(?<preRelease>[\w.]+))?` and it
applies it with a plain `line.replace`. The optional prerelease group swallows
the OKDP half, so the match covers the entire composite and the entire composite
is replaced:

```
tag: 24.4.11-1.0.0 # x-release-please-version    ->   tag: 1.0.1
tag: v0.3.2-1.0.0 # x-release-please-version     ->   tag: v1.0.1
tag: 1.3.0-incubating-1.0.0 # x-release-please…  ->   tag: 1.1.0-1.0.0
```

**`versioning: "prerelease"` destroys the upstream half on anything but a fix.**
`PrereleaseMinorVersionUpdate` only touches the prerelease when the outer patch
is `0`, and `PrereleaseMajorVersionUpdate` only when outer minor and patch are
both `0`. Keycloak is `24.4.11`, so:

```
current 24.4.11-1.0.0
  fix:   -> 24.4.11-1.0.1     correct
  feat:  -> 24.5.0-1.0.0      invents an upstream Keycloak 24.5.0
  feat!: -> 25.0.0-1.0.0      invents an upstream Keycloak 25.0.0
```

And in the one shape where it does keep the prefix (`1.0.0-1.0.0`), `feat:` and
`feat!:` both collapse to a patch bump, so `-1.1.0` and `-2.0.0` are
unreachable.

So there is no configuration of release-please that emits
`<upstream>-<X.Y.Z>`. The composition is four lines of shell in the workflow,
and release-please keeps everything else: the version arithmetic, the
changelogs, the git tags, the Releases, and `paths_released`.

---

### Branch

```
chore/release-please
```

Off `main`.

### Title

```
chore(ci): let release-please own the package versions
```

Still accurate: release-please owns the versions. What changed is that it no
longer *writes* them into the yaml.

Deliberately `chore:`, not `feat:`. On a squash merge the title becomes the
subject of one commit touching all thirteen package directories, and
release-please assigns commits by directory. A `feat:` title would open all
thirteen new changelogs with a spurious "Features: let release-please own the
package versions" and force a minor bump on every one of them. `chore` is not in
`changelog-sections`, so it contributes nothing.

**Commits.** `conventional-commits.yml` validates every commit in the pull
request, not the title, so each commit must be conventional on its own. Keep
them `chore:` for the same reason.

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

**The counter gets forgotten.** 24 of 71 package edits shipped with no bump at
all. Before #67 that silently overwrote a published tag; after #67 it fails CI,
which is better but still manual.

**`-pNN` is not a version anyone can order.** `airflow` has shipped both
`3.2.1-p2` and `3.2.1-p03`: two different registry tags that sort against each
other wrongly. `trino.yaml` already carries a comment about the version being
inflated from `480` to `480.0.0` because the UI requires SemVer.

**There is no release.** Zero git tags, zero GitHub Releases,
`.release-please-manifest.json` is empty. release-please has been installed the
whole time but configured for the wrong repo shape: a single root package with
`release-type: simple`, minting one repo-wide `v0.3.0` unrelated to the thirteen
per-package tags that actually ship. Its release PR #18 has been open since
26 June because that number means nothing to anyone.

### What changes

**The tag keeps its upstream half and gains an automated one.**

    tag: 480.0.0-p21   ->   tag: 480.0.0-1.0.0

Left of the dash stays a human decision made in an ordinary reviewable PR, as
today. Right of the dash is a plain `X.Y.Z` that release-please computes from
the commit types. Only the old `-pNN` counter stops being hand-typed.

**One release-please component per package**, following the pattern already used
in `OKDP/helm-charts-utilities`. Git tags become `trino/v1.0.0`, each package
gets its own `CHANGELOG.md`, and `separate-pull-requests: false` groups them
into a single release pull request. Cross-cutting commits are normal here
(`9f28ef6` touched eight packages), so that is one review instead of eight.

**The OCI tag is composed, not overwritten.** release-please cannot produce a
`<upstream>-<X.Y.Z>` string: its `generic` updater's regex swallows the whole
composite, and `versioning: "prerelease"` rewrites the upstream half on any
`feat:`. Both were run against release-please 17.11.2 to confirm. So this PR
removes `extra-files` from the config and adds one step to `release-please.yml`
that joins the prefix already in the file with the version release-please just
computed. The step invents nothing.

**An upstream bump is a `feat!:`.** When upstream Keycloak moves to 25.0.0 the
developer edits the upstream half by hand and marks the commit `feat!:`.
release-please takes the major, and the tag becomes `25.0.0-2.0.0`. The OKDP
half does not reset, because `keycloak/v1.0.0` is already a git tag.

**Publishing is triggered by a release, for the released packages only.**
`release-please.yml` passes `paths_released` to the package template, which
resolves each released directory to its manifest. `on_existing_tag: fail` is set
on this path: release-please has just minted versions that never existed, so a
tag already being present means something is genuinely wrong.

`release-please.yml` also moves from `pull_request: types: [closed]` to
`push: branches: [main]`, the documented trigger, which additionally covers
direct pushes.

**The interim tag guard is removed.** `tag-must-move` (the `ci.yml` job and
`.github/scripts/tag-must-move.sh`) fails a pull request that edits a package
without bumping its `tag:`. From here on that is what every package change looks
like: the developer must not touch `tag:`, the release workflow writes it.
Left in place the guard would block all package work. It was labelled interim in
both the job comment and the script header; this is the handover it was waiting
for. The `[no-publish]` escape hatch goes with it.

**Shared charts are guarded.** `airflow`, `superset` and `trino` embed
`charts/internal-secrets` by relative path, and `jupyterhub` embeds
`charts/oidc-client`. release-please assigns commits to packages by directory,
and `charts/` sits outside every package, so a charts-only change would release
nothing and never reach the registry.

This is not hypothetical: all three commits that have ever touched `charts/`
touched no package manifest, including `fix(oidc-client): generate a 32-byte
key, hex encoded`. Today that reaches users only because publish-on-merge
rebuilds everything, which is the behaviour #56 removed.

A new CI job fails the pull request when a shared chart moves without its
consumers, naming them.

## Related Issue

Fixes #68

## Type of Change

- [ ] Bug fix
- [x] New feature
- [ ] Documentation update
- [x] Refactor / chore
- [x] Breaking change

**Migration path.** Every published tag changes shape:
`trino:480.0.0-p21` becomes `trino:480.0.0-1.0.0`. The upstream half is
unchanged, so a human reading the tag still sees which Trino it is. Existing
tags are not deleted and nothing breaks immediately, but consumers stop
receiving updates until they are repointed. `OKDP/okdp-sandbox` must be updated
in two places per package: the `tag:` on each Release, and the `versions:` /
`default:` entries in `spec.context.serviceCatalog`. That is tracked separately
in `issue-okdp-sandbox-repoint-packages.md` and needs an announcement, not just
a pull request.

**One known regression, fixed separately.** In a correct SemVer ordering the
legacy `-pNN` tags outrank every new tag for the same upstream version, because
SemVer 2.0.0 rule 11.4.3 ranks numeric prerelease identifiers below alphanumeric
ones. `24.4.11-p16` therefore stays at the top of the console dropdown until
upstream moves off `24.4.11`. `OKDP/okdp-control-plane-server` needs the
three-band sort from PR 7 **before** the first release cut here.

## How to Test

1. **The migration touches one line per manifest.** After applying,
   `git diff` on any manifest shows only the `tag:` line, with the upstream half
   intact. `jupyterhub.yaml` is the sharp case: it holds fourteen other
   version-looking lines (`version: 4.3.3`, `tag: "4.3.3"`, the notebook image
   tags) and none may change.

2. **The awkward upstream version survives.** `polaris` is
   `1.3.0-incubating`, an upstream version that already carries a dash. After
   migration it must read `1.3.0-incubating-1.0.0`, not `1.3.0-1.0.0`. It is the
   only one of this repo's thirteen with that shape.

3. **The release pull request.** On merge, release-please opens
   `chore: release main` bumping every package with pending commits, each with a
   `CHANGELOG.md`. The compose step then rewrites each `tag:` line on the same
   branch, so what a reviewer sees is
   `- tag: 480.0.0-1.0.0` / `+ tag: 480.0.0-1.0.1`. Nothing is published yet.

4. **Publishing follows the release.** Merge that pull request; release-please
   creates the git tags (`trino/v1.0.1` for a `fix:`, `trino/v1.1.0` for a
   `feat:`, counting up from the `1.0.0` baseline) then publishes only the
   released packages. The job log line `Processing: ...` names them.

5. **An upstream bump.** Open a pull request that edits `trino.yaml`'s upstream
   half to a new Trino and titles the commit `feat!:`. The release pull request
   should show `- tag: 480.0.0-1.0.1` / `+ tag: 481.0.0-2.0.0`.

6. **A malformed tag fails loudly.** Set one manifest's `tag:` back to
   `480.0.0-p21` and push. The compose step must fail the workflow with
   `tag '480.0.0-p21' has no -X.Y.Z suffix`, not publish something malformed.

7. **The old guard is gone.** Open a pull request editing `trino.yaml` without
   touching `tag:`. Before this change `tag-must-move` fails it; after, CI is
   green and the `fix:` or `feat:` title is what decides the version.

8. **The shared-chart guard.** Open a pull request changing only
   `charts/oidc-client/templates/client.yaml`. The `shared-charts` job fails with
   "charts/oidc-client is embedded by packages/services/jupyterhub, but nothing
   under packages/services/jupyterhub changed". Touch `jupyterhub.yaml` as well
   and it passes.

9. **Dry-run on a fork first.** Every failure mode in this mechanism is silent
   except the one in step 6.

## Checklist

- [x] I have tested my changes
- [x] Documentation updated if needed
- [x] If breaking change: migration path described above
- [x] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [x] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
```

---

## Making the changes by hand

Eight edits. Steps 1, 2, 5, 7 and 8 are unchanged from the superseded document.
Steps 3, 4 and 6 are where the new scheme lives.

### 1. Replace `release-please-config.json`

Drop-in file: `generated-release-please-config.json` in this directory,
**already updated** to the new scheme.

Thirteen components, one per package directory. Each entry is now:

```json
    "packages/system/okdp-control-plane-server": {
      "component": "okdp-control-plane-server",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md"
    },
```

**The `extra-files` block is gone from all thirteen entries.** That is the one
difference from the superseded config, and it is the whole reason the upstream
half survives. With no `extra-files`, release-please never opens the package
manifests: on its release branch it writes only `.release-please-manifest.json`
and the changelogs, leaving every `tag:` line untouched for step 4 to compose.

Consequence worth noting in review: the `# x-release-please-version` markers are
**not** added to the manifests. That annotation is read only by the `generic`
updater, which no longer runs on these files, so it would be a comment claiming
release-please owns a line it never touches.

### 2. Replace `.release-please-manifest.json`

Currently `{}`. This is the scoreboard release-please keeps from here on, and it
holds only the OKDP half.

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

This asserts that every package has already been released at OKDP `1.0.0`, so
the first release-please run counts up from there: `1.0.1` or `1.1.0`, never
`1.0.0` itself. Make the assertion true once this is merged: see **After
merging**.

### 3. Migrate the thirteen `tag:` lines

In each package manifest, swap the `-pNN` counter for `-1.0.0` and leave the
upstream half exactly as it is:

```yaml
- tag: 480.0.0-p21
+ tag: 480.0.0-1.0.0
```

No annotation comment. The whole set at once (macOS `sed`; drop the `''` on
Linux):

```sh
for f in packages/*/*/*.yaml; do
  grep -q '^modules:' "$f" || continue
  sed -i '' -E 's/^(tag: .*)-p[0-9]+$/\1-1.0.0/' "$f"
done
git diff --stat        # expect 13 files, one line each
grep -rn '^tag:' packages/ | grep -v -- '-1\.0\.0$' || echo "all thirteen migrated"
```

The `-E` regex is anchored on `-p<digits>` at end of line, so it cannot touch an
upstream version that happens to contain `p`. The second `grep` is the check
that matters: anything it prints is a manifest the migration missed, and step 4
would fail the workflow on it later.

Expected result, all thirteen:

Read off `origin/main` on 17 Sep 2026:

| package | before | after |
|---|---|---|
| airflow | `3.2.1-p09` | `3.2.1-1.0.0` |
| hive-metastore | `4.0.1-p02` | `4.0.1-1.0.0` |
| jupyterhub | `4.3.3-p07` | `4.3.3-1.0.0` |
| okdp-examples | `1.3.0-p08` | `1.3.0-1.0.0` |
| polaris | `1.3.0-incubating-p09` | `1.3.0-incubating-1.0.0` |
| spark-defaults | `1.0.0-p01` | `1.0.0-1.0.0` |
| spark-history-server | `3.5.1-p08` | `3.5.1-1.0.0` |
| spark-operator | `2.4.0-p04` | `2.4.0-1.0.0` |
| spark-rbac | `1.0.1-p02` | `1.0.1-1.0.0` |
| superset | `6.0.0-p05` | `6.0.0-1.0.0` |
| trino | `480.0.0-p21` | `480.0.0-1.0.0` |
| okdp-control-plane-server | `0.8.0-p01` | `0.8.0-1.0.0` |
| okdp-control-plane-ui | `0.8.0-p01` | `0.8.0-1.0.0` |

`polaris` is the one to eyeball: `1.3.0-incubating` must survive intact. It is
the only awkward upstream shape in this repo; `sandbox-dependencies` has three.

**Re-read these before applying.** The counters move constantly, and a stale
local checkout will give the wrong `before` column. The `after` column does not
depend on the counter, so only the left side rots.

Every manifest has exactly one line starting `tag:` at column zero; nested
`tag:` keys are indented. Checked against `jupyterhub.yaml`, which has three of
them: one line changes.

### 4. Add `.github/scripts/compose-oci-tag.sh`

New file. This is the entire mechanism.

```bash
#!/usr/bin/env bash
#
# Copyright 2026 The OKDP Authors.
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
# Compose each package's OCI tag from its two halves.
#
# A published tag is <upstream version>-<OKDP version>, e.g. 24.4.11-1.0.0.
# The upstream half is maintained by hand and is already in the manifest. The
# OKDP half is owned by release-please, which has just written it into
# .release-please-manifest.json on its release branch.
#
# release-please cannot write the composite itself: its `generic` updater's
# version regex swallows the prerelease, so annotating the line would replace
# the whole tag with a bare X.Y.Z. Hence this step, and hence no `extra-files`
# in release-please-config.json.
#
# Runs on the release-please branch, after release-please-action.
set -euo pipefail

rc=0

while read -r path version; do
  # The kubocd manifest in this package. kubocd-webhooks/ holds webhooks.yaml,
  # so match on content rather than on the directory name.
  # `|| true` matters: with `set -o pipefail` a grep that matches nothing
  # would abort the script before the check below can report it.
  file=$(grep -l '^modules:' "${path}"/*.yaml 2>/dev/null | head -1 || true)
  if [[ -z "${file}" ]]; then
    echo "::error title=No package manifest::${path} is in the manifest but holds no file with 'modules:'"
    rc=1
    continue
  fi

  old=$(sed -n 's/^tag: *//p' "${file}" | head -1 | sed 's/ *#.*//')

  # Strip exactly one trailing -X.Y.Z, anchored at end of string. Anything to
  # the left is the upstream half, however many dashes it contains:
  #   24.4.11-1.0.0          -> 24.4.11
  #   1.3.0-incubating-1.0.0 -> 1.3.0-incubating
  #   v0.2.1-1.0.0           -> v0.2.1
  if [[ ! "${old}" =~ ^(.+)-([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    echo "::error file=${file}::tag '${old}' has no -X.Y.Z suffix, so the upstream half cannot be identified"
    rc=1
    continue
  fi

  new="${BASH_REMATCH[1]}-${version}"
  if [[ "${new}" != "${old}" ]]; then
    # Not `sed -i`: the BSD/macOS form needs an argument, so this stays
    # runnable on a maintainer's laptop as well as on the runner.
    tmp=$(mktemp)
    sed "s|^tag: .*|tag: ${new}|" "${file}" > "${tmp}" && mv "${tmp}" "${file}"
    echo "  ${file}: ${old} -> ${new}"
  fi
done < <(jq -r 'to_entries[] | "\(.key) \(.value)"' .release-please-manifest.json)

exit "${rc}"
```

Three properties worth stating in review:

- **It invents nothing.** The prefix comes from the file, the version comes from
  release-please. If release-please bumped nothing, `new` equals `old` and no
  file changes.
- **It fails rather than guesses.** A bash glob suffix strip (`${old%-*.*.*}`)
  would silently hand back `24.4.11-p07` unchanged and publish
  `24.4.11-p07-1.0.1`. The anchored regex refuses, which is what catches a
  manifest missed by step 3.
- **It is idempotent.** release-please force-pushes its release branch from
  scratch on every run, so this recomputes each time and never accumulates.
  Run twice, the second run prints nothing and changes nothing.

Exercised locally against four packages at once: two valid (including
`1.3.0-incubating-1.0.0`, which must keep its own dash), one still on `-p07`,
and one directory holding no manifest. It rewrote the two, reported both
failures as GitHub annotations, exited 1, and was silent and clean on a rerun.

Mark it executable: `chmod +x .github/scripts/compose-oci-tag.sh`.

### 5. Teach the package template to publish a subset

Unchanged from the superseded document. In
`.github/workflows/kubocd-package-template.yml`, add an input directly after
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

### 6. Replace `release-please.yml`

One job gains a second step. Everything else is as in the superseded document.

```yaml
#
# Copyright 2026 The OKDP Authors.
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

      # release-please owns only the OKDP half of the tag and writes it to
      # .release-please-manifest.json on its own branch. Join it with the
      # upstream half already in each manifest, on that same branch, before
      # anyone reviews the release pull request.
      - name: Compose the OCI tags
        if: steps.release-please.outputs.prs_created == 'true'
        env:
          BRANCH: release-please--branches--${{ github.ref_name }}
        run: |
          git fetch origin "${BRANCH}"
          git checkout "${BRANCH}"
          .github/scripts/compose-oci-tag.sh
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git commit -am "chore: compose the upstream version into the OCI tags" || exit 0
          git push origin "${BRANCH}"

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

Notes for review:

- `contents: write` is already on this job for release-please's own commits, so
  the push needs no new permission.
- `|| exit 0` on the commit: when release-please only refreshes a changelog and
  no `tag:` moves, there is nothing to commit and the step should succeed.
- The step runs when a release **pull request** is created or updated
  (`prs_created`), not when a release is cut. By the time `paths_released` is
  set, the composed tags are already on `main` because that PR was merged.

### 7. Remove the interim tag guard

`tag-must-move` fails a pull request that edits a package without bumping its
`tag:`. From here on the developer must not bump it, so the guard would fail
every package pull request. Both pieces say so themselves in their headers.

**`.github/workflows/ci.yml`:** delete the first job (the three comment lines
under `jobs:` through the `bash .github/scripts/tag-must-move.sh ...` line).
Step 8's `shared-charts` job takes the vacated slot.

**`.github/scripts/tag-must-move.sh`:** delete the whole file.

```sh
git rm .github/scripts/tag-must-move.sh
grep -rn tag-must-move .github/ || echo "guard removed"
```

The `[no-publish]` escape hatch in the pull-request body disappears with it.
Worth a line in the announcement, since reviewers have been told to use it.

**README.** It still says release-please *triggers* `publish.yml` and shows a
`-pNN` example tag. Correct the example to `trino:480.0.0-1.0.0` and the
paragraph to match step 6.

### 8. Guard the shared charts

Unchanged from the superseded document: add `.github/scripts/shared-chart-consumers.sh`
and the `shared-charts` job in `ci.yml`. See `rejected-design-2026-09-17/pr-3-release-please.md`
step 7 for the script, which this change does not affect.

### Check your work

```sh
python3 -c "import json;[json.load(open(f)) for f in ['release-please-config.json','.release-please-manifest.json']];print('json ok')"
for f in .github/workflows/*.yml; do python3 -c "import yaml;yaml.safe_load(open('$f'))" || echo "BAD $f"; done
bash -n .github/scripts/compose-oci-tag.sh
bash -n .github/scripts/shared-chart-consumers.sh
grep -rn tag-must-move .github/ || echo "guard removed"
grep -rn 'x-release-please-version' . || echo "no stale annotations"
grep -rn extra-files release-please-config.json || echo "no extra-files"
grep -rn '^tag:' packages/ | grep -vE -- '-[0-9]+\.[0-9]+\.[0-9]+$' || echo "all tags composite"
git diff --stat        # expect 21 files, incl. the deleted tag-must-move.sh
```

The last two greps are the ones that catch the mistakes specific to this design:
a leftover annotation, and a manifest step 3 missed.

---

## Before merging: create the thirteen baseline tags

**Already done on `OKDP/platform-packages` on 1 Sep 2026:** all thirteen tags
exist on `dee31fd`. Nothing to do unless `main` has moved in a way that matters.
Kept here because the reasoning still governs.

`release-please.yml` fires on push to `main`, so the first run starts the
instant this merges; in a fork dry-run it completed in about 15 seconds. With no
tags present release-please has no scan floor: it reads every commit in each
package's history and opens a release pull request whose changelogs cover the
entire repository. Tagging afterwards is too late.

```sh
git fetch origin
for c in airflow hive-metastore jupyterhub okdp-examples polaris \
         spark-defaults spark-history-server spark-operator spark-rbac \
         superset trino okdp-control-plane-server okdp-control-plane-ui
do
  git tag "${c}/v1.0.0" origin/main
  git push origin "refs/tags/${c}/v1.0.0"
done
git ls-remote --tags origin | wc -l        # expect 13
```

Lightweight git tags and nothing else: no GitHub Releases, no workflow runs
(`release-please.yml` and `ci.yml` both trigger on branches, not tags), no
publishes. Reversible with `git push origin :refs/tags/<name>`.

Verified in a fork: with the tags in place, the first release-please run after
the merge logged `No user facing commits found since <sha>` once per component,
thirteen times, and opened no release pull request.

Note the git tag is `trino/v1.0.0`, the OKDP half only. The OCI tag is
`480.0.0-1.0.0`. Two different strings for the same release, which is expected:
the git tag identifies the OKDP release, the OCI tag identifies the artifact.

## After merging: publish the baseline once

The manifest and the git tags now agree, but the registry has no
`480.0.0-1.0.0` for any package, so `main` declares a `tag:` the registry does
not have.

Actions → **publish** → Run workflow. It calls the template without
`on_existing_tag`, which defaults to `skip`. None of the thirteen composite tags
exist yet, so expect thirteen `build and push` and no skips.

The manifest, the git tags, the registry and the `tag:` lines then all agree.

---

## Evidence

### Against release-please 17.11.2, 17 Sep 2026

Installed locally and driven through its own classes, not simulated:

- `Generic.updateContent` on `tag: 24.4.11-1.0.0 # x-release-please-version`
  with next version `1.0.1` returns `tag: 1.0.1`. On
  `tag: 1.3.0-incubating-1.0.0` with `1.1.0` it returns `tag: 1.1.0-1.0.0`.
  This is why `extra-files` is removed.
- `PrereleaseVersioningStrategy({prerelease: true}).bump(Version.parse('24.4.11-1.0.0'), …)`
  returns `24.4.11-1.0.1` for a `fix`, `24.5.0-1.0.0` for a `feat`, and
  `25.0.0-1.0.0` for a breaking change. From `1.0.0-1.0.0` all three return
  `1.0.0-1.0.1`. This is why `versioning: "prerelease"` is not used.
- End-to-end in a throwaway git repo, three cycles with the real updater
  generating the release branch: `24.4.11-1.0.0` → `fix:` → `24.4.11-1.0.1` →
  `feat:` → `24.4.11-1.1.0` → `feat!:` with a hand-edited prefix →
  `25.0.0-2.0.0`, git tag `keycloak/v2.0.0`.

### The split rule, against every real tag

All 24 distinct tags across both package repos split correctly under
`^(.+)-([0-9]+\.[0-9]+\.[0-9]+)$`, including `1.3.0-incubating-1.0.0` →
`1.3.0-incubating`, `0.3.0-snapshot-1.0.0` → `0.3.0-snapshot`, `v0.3.2-1.0.0` →
`v0.3.2` and `480.0.0-10.20.30` → `480.0.0`. The three inputs it refuses are
exactly the ones it should: `24.4.11-p07`, `1.0.0` and `1.0.0-rc.1`.

The one shape it cannot resolve is an upstream version that itself ends in
`-N.N.N`, where the last one always wins (`a-1.0.0-b-2.0.0` → prefix
`a-1.0.0-b`). No real tag looks like that and upstream projects do not version
that way.

### Ordering, against the `semver` library

`24.4.11-1.0.0 < 24.4.11-1.0.1 < 24.4.11-1.1.0 < 24.4.11-2.0.0`, correct. But
`24.4.11-p16` is greater than all of them, per SemVer 2.0.0 rule 11.4.3. See
PR 7.

`18.3-1.0.0` is **not valid SemVer** (`cnpg-postgresql`, two-segment upstream).
That package is in `sandbox-dependencies`, not here, so it is PR 4's problem,
but the same is true of any future two-segment upstream in this repo.

### Carried over from the 1 Sep fork dry-run

Still valid, because none of it depends on how the `tag:` line is written:

- Baseline tags anchor release-please: `No user facing commits found since
  dee31fd`, thirteen times, no release PR.
- `paths_released: []` skips `get-package-oci-prefix` and `publish`.
- `chore:` commits cut no release.
- One `fix(trino):` produced one draft release PR bumping only trino, with a
  `CHANGELOG.md` and the compare link `trino/v1.0.0...trino/v1.0.1`.
- Merging it minted `trino/v1.0.1`, then `PACKAGE_PATHS: ["packages/services/trino"]`
  → one `kubocd package` call → one push.

**Still untested:** `on_existing_tag: "fail"` (needs real quay credentials), and
the compose step on a real runner. The compose step has only been proven
locally, against the real library, in a throwaway repo.

## Not in this PR

- **A guard on the upstream half.** The natural successor to `tag-must-move`:
  fail a pull request that edits the upstream half of a `tag:` without a
  `feat!:` commit. Worth doing, but this PR is already Breaking and was already
  sent back once. Its own issue.
- Repointing `OKDP/okdp-sandbox`. Separate, and it needs the announcement.
  See `pr-6-okdp-sandbox-repoint-packages.md`.
- The automated bump PR into `okdp-sandbox`, which needs a machine account:
  `GITHUB_TOKEN` cannot write to another repository.
- Publishing `charts/internal-secrets` and `charts/oidc-client` to the registry
  like the other module charts, so packages reference them by version instead of
  by relative path. That would remove the need for step 8 entirely.
