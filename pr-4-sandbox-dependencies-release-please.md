# PR 4 — `OKDP/sandbox-dependencies` — Phase 2, release-please

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> Sibling of `pr-3-release-please.md`. **PR 2 is merged** (#32, 28 Aug), so apply
> this onto a fresh branch off `main` (`12bb63a` at the time of writing).
> Checked against the real repository, not assumed from `platform-packages`.

### Three differences from PR 3, before you start

1. **Fourteen packages**, not thirteen, and one of them is a trap:
   `packages/system/kubocd-webhooks` holds `webhooks.yaml`, **not**
   `kubocd-webhooks.yaml`. Its `extra-files.path` must be `webhooks.yaml`.
2. **There is no `charts/` directory** and no package references a chart by
   relative path. The shared-chart guard from PR 3 is **not needed here**. This
   is six edits, not seven.
3. **The README carries a version table** that PR 3's repo does not — a fourth
   hand-maintained copy of every version, and it is already wrong (see step 6).

### Title

```
chore(ci): let release-please own the package versions
```

Deliberately `chore:`, not `feat:`. If this is squash-merged the title becomes
the subject of one commit touching all fourteen package directories, and
release-please assigns commits by directory. A `feat:` title would open every
one of the fourteen new changelogs with a spurious "Features: let release-please
own the package versions" entry and force a minor bump on all of them. `chore`
is not in `changelog-sections`, so it contributes nothing.

### Body

```markdown
## Description

The published version of a package is a literal typed into its manifest, and
`kubocd package` has no tag override, so whatever sits in that field is what
reaches the registry. #23 stopped the overwriting. This removes the cause.

**`-pNN` is not a usable version.** Under SemVer a hyphen introduces a
pre-release, so `1.17.1-p08` ranks *below* plain `1.17.1`. Three of the fourteen
tags do not even parse as SemVer: `cnpg-postgresql` is `18.3-p03` (two
segments), `kubocd-webhooks` is `v0.3.2-p01` (leading `v`), and `kubauth` is
`0.3.0-snapshot-p03`.

**There is no release.** Zero git tags, zero GitHub Releases,
`.release-please-manifest.json` is `{}`. release-please has been installed the
whole time but configured for the wrong repo shape — a single root package with
`release-type: simple`, minting one repo-wide `v0.3.0` unrelated to the fourteen
per-package tags that actually ship. Its release PR #2 has been open since
24 July because that number means nothing to anyone.

**The version is written down in three places and already disagrees with
itself.** Each manifest's `tag:`, the README's package table, and the consuming
pins in `OKDP/okdp-sandbox`. Five of the fourteen README rows are stale today:
`external-secrets` (`p02` vs `p03`), `keycloak` (`p14` vs `p16`), `kubauth`
(`p01` vs `p03`), `seaweedfs` (`p07` vs `p08`) and `vault` (`p01` vs `p03`).

### What changes

**One release-please component per package**, following the pattern already used
in `OKDP/helm-charts-utilities`. Tags become `keycloak/v1.0.0`, each package gets
its own `CHANGELOG.md`, and `separate-pull-requests: false` groups them into a
single release pull request.

**release-please writes the OCI tag.** The `generic` updater replaces the version
on any line carrying an `x-release-please-version` annotation. It is a line-level
text substitution, so the rest of each manifest — module charts, image tags,
schema — is untouched.

**Every package restarts at `1.0.0`.** The existing `-pNN` tags stay on the
registry; nothing is deleted.

**Publishing is triggered by a release, for the released packages only.**
`release-please.yml` passes `paths_released` to the package template, which
resolves each released directory to its manifest. `on_existing_tag: fail` is set
on this path: release-please has just minted versions that never existed, so a
tag already being present means something is genuinely wrong.

`release-please.yml` also moves from `pull_request: types: [closed]` to
`push: branches: [main]`, the documented trigger, which additionally covers
direct pushes.

**The interim tag guard is removed.** `tag-must-move` — the `ci.yml` job and
`.github/scripts/tag-must-move.sh` — fails a pull request that edits a package
without bumping its `tag:`. From here on that is what *every* package change
looks like: the developer must not touch `tag:`, release-please writes it at
release time. Left in place the guard would block all package work. It was
labelled interim in both the job comment and the script header; this is the
handover it was waiting for. The `[no-publish]` escape hatch goes with it.

**The README stops restating the versions.** The version column is dropped from
the package table and the example tag is corrected. The manifests are the source
of truth, and from here on release-please owns them.

## Related Issue

Fixes #<number of the release-please issue — file it first; this repo has no open issues>

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [x] Refactor / chore
- [x] Breaking change

Every published tag changes shape: `keycloak:24.4.11-p16` becomes
`keycloak:1.0.0`. Existing tags are not deleted, so nothing breaks immediately,
but consumers stop receiving updates until they are repointed.
`OKDP/okdp-sandbox` must be updated in two places per package — the `tag:` on
each Release, and the `versions:` / `default:` entries in
`spec.context.serviceCatalog`. This needs an announcement, not just a pull
request.

## How to Test

1. **The updater touches one line.** After applying, `git diff` on any manifest
   shows only the `tag:` line. Every manifest has exactly one line starting
   `tag:` at column zero; nested `tag:` keys are indented and must not move.

2. **The awkward versions.** `cnpg-postgresql` (`18.3-p03`), `kubocd-webhooks`
   (`v0.3.2-p01`) and `kubauth` (`0.3.0-snapshot-p03`) are the ones a naive
   version regex would mangle. All three are normalised to `1.0.0` by this
   change, so the updater only ever sees `X.Y.Z` afterwards.

3. **The release pull request.** On merge, release-please opens
   `chore: release main` bumping every package with pending commits, each with a
   `CHANGELOG.md` and a `tag:` rewrite. Nothing is published yet.

4. **Publishing follows the release.** Merge that pull request; release-please
   creates the tags — `keycloak/v1.0.1` for a `fix:`, `keycloak/v1.1.0` for a
   `feat:`, counting up from the `1.0.0` baseline — then publishes **only** the
   released packages. The job log line `Processing: ...` names them.

5. **The old guard is gone.** Open a pull request editing `keycloak.yaml`
   without touching `tag:`. Before this change `tag-must-move` fails it; after,
   CI is green and the `fix:` or `feat:` title is what decides the version.

6. **`kubocd-webhooks` in particular.** Its manifest is `webhooks.yaml`, so a
   copy-paste of the `platform-packages` config would silently never update it.
   Confirm its `tag:` moves in the release pull request along with the others.

## Checklist

- [x] I have tested my changes
- [x] Documentation updated if needed
- [x] If breaking change: migration path described above
- [x] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [x] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
```

---

## Making the changes by hand

Six edits, plus one action **before** merging and one after.

### 1. Replace `release-please-config.json`

One block per package. Strict JSON — **no comments**. Note
`packages/system/kubocd-webhooks` uses `webhooks.yaml`.

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "separate-pull-requests": false,
  "include-v-in-tag": true,
  "draft-pull-request": true,
  "packages": {
    "packages/services/seaweedfs": {
      "component": "seaweedfs",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "seaweedfs.yaml"
        }
      ]
    },
    "packages/system/cert-manager": {
      "component": "cert-manager",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "cert-manager.yaml"
        }
      ]
    },
    "packages/system/cloudnative-pg": {
      "component": "cloudnative-pg",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "cloudnative-pg.yaml"
        }
      ]
    },
    "packages/system/cnpg-postgresql": {
      "component": "cnpg-postgresql",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "cnpg-postgresql.yaml"
        }
      ]
    },
    "packages/system/coredns-patch": {
      "component": "coredns-patch",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "coredns-patch.yaml"
        }
      ]
    },
    "packages/system/dns-server": {
      "component": "dns-server",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "dns-server.yaml"
        }
      ]
    },
    "packages/system/external-secrets": {
      "component": "external-secrets",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "external-secrets.yaml"
        }
      ]
    },
    "packages/system/ingress-nginx": {
      "component": "ingress-nginx",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "ingress-nginx.yaml"
        }
      ]
    },
    "packages/system/keycloak": {
      "component": "keycloak",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "keycloak.yaml"
        }
      ]
    },
    "packages/system/kubauth": {
      "component": "kubauth",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "kubauth.yaml"
        }
      ]
    },
    "packages/system/kubocd-webhooks": {
      "component": "kubocd-webhooks",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "webhooks.yaml"
        }
      ]
    },
    "packages/system/local-secrets-provider": {
      "component": "local-secrets-provider",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "local-secrets-provider.yaml"
        }
      ]
    },
    "packages/system/tools": {
      "component": "tools",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "tools.yaml"
        }
      ]
    },
    "packages/system/vault": {
      "component": "vault",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        {
          "type": "generic",
          "path": "vault.yaml"
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
  "packages/services/seaweedfs": "1.0.0",
  "packages/system/cert-manager": "1.0.0",
  "packages/system/cloudnative-pg": "1.0.0",
  "packages/system/cnpg-postgresql": "1.0.0",
  "packages/system/coredns-patch": "1.0.0",
  "packages/system/dns-server": "1.0.0",
  "packages/system/external-secrets": "1.0.0",
  "packages/system/ingress-nginx": "1.0.0",
  "packages/system/keycloak": "1.0.0",
  "packages/system/kubauth": "1.0.0",
  "packages/system/kubocd-webhooks": "1.0.0",
  "packages/system/local-secrets-provider": "1.0.0",
  "packages/system/tools": "1.0.0",
  "packages/system/vault": "1.0.0"
}
```

This asserts that every package *has already been released* at `1.0.0`, so the
first release-please run counts up from there — `1.0.1` or `1.1.0`, never
`1.0.0` itself. Make the assertion true **before** this merges: see
**Before merging** below.

### 3. Annotate the fourteen manifests

In **each** package manifest, replace the `tag:` line:

```yaml
- tag: 24.4.11-p16
+ tag: 1.0.0 # x-release-please-version
```

Set the value *and* add the comment in the same edit. The updater replaces the
first `X.Y.Z`-looking string on an annotated line, and three current tags don't
match that shape (`18.3-p03`, `v0.3.2-p01`, `0.3.0-snapshot-p03`). Normalising
to `1.0.0` avoids it.

The whole set at once. Every manifest has exactly **one** line starting `tag:`
at column zero — nested `tag:` keys are indented — so a plain substitution is
safe and needs no line-range address:

```sh
for f in packages/*/*/*.yaml; do
  grep -q '^modules:' "$f" || continue
  sed -i '' 's/^tag: .*/tag: 1.0.0 # x-release-please-version/' "$f"   # drop the '' on Linux
done
git diff --stat        # expect 14 files, one line each
```

> Do **not** use the `0,/^tag: /s//.../` form given in `pr-3-release-please.md`.
> `0,/re/` is a GNU extension; BSD/macOS `sed` accepts it, exits 0, and changes
> nothing. Verified on this repo — the command ran clean and produced an empty
> `git diff`.

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

The step being replaced is byte-identical to `platform-packages`', but it sits
at a **different position** in this file: here `Install yq 🛠️` and
`Install oras 🛠️` come *after* it, where in `platform-packages` they come
before. Anchor on the step name, not on a line number. `PACKAGE_PATHS` is passed
through `env:` rather than interpolated into the script, so the JSON's quotes
cannot break the shell.

Because this manifest resolution is a `find` over the released directory rather
than a name guess, `kubocd-webhooks/webhooks.yaml` needs no special case here.

### 5. Replace `release-please.yml`

Identical to `platform-packages` except `values_path`. The current file is
byte-identical between the two repos, so this replaces it wholesale.

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
          values_path: sandbox-dependencies-values.yaml

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

Note `values_path: sandbox-dependencies-values.yaml` — the one line that differs
from PR 3. `packageRepository` there is `quay.io/okdp/sandbox-dependencies`, so
the OCI prefix resolves to `sandbox-dependencies`.

### 6. Remove the interim tag guard, and stop restating versions in the README

**`.github/workflows/ci.yml` — keep the file, delete the first job.** Lines
60–77 as `main` stands today (the same line range as `platform-packages`): the
three comment lines under `jobs:` through the
`bash .github/scripts/tag-must-move.sh ...` line. `get-package-oci-prefix:`
becomes the first job, and `kubocd-packages-ci` is untouched.

Unlike PR 3, nothing takes the vacated slot — this repo has no `charts/`, so
there is no shared-chart guard to add. `ci.yml` ends with two jobs.

**`.github/scripts/tag-must-move.sh` — delete the whole file.**

```sh
git rm .github/scripts/tag-must-move.sh
grep -rn tag-must-move .github/ || echo "guard removed"
```

The `[no-publish]` escape hatch in the pull-request body disappears with it.
Worth a line in the announcement, since reviewers have been told to use it.

**`README.md` — three corrections.** All three are made wrong by this change,
and fixing them is what lets the "Documentation updated if needed" box be ticked.

- **Drop the version column** from both package tables (system and services).
  It is a hand-maintained copy that already disagrees with the manifests in five
  of fourteen rows, and once release-please owns the versions it would drift on
  every release. The manifests are the source of truth.
- **Fix the example** at the "Example:" line —
  `quay.io/okdp/sandbox-dependencies/seaweedfs:4.17.0-p07` is both stale and in
  the format this pull request abolishes. Make it `seaweedfs:1.0.0`.
- **Fix the Release Publishing paragraph.** It still references
  `publish-on-merge.yml`, which #32 deleted, and says release-please *triggers*
  `publish.yml`. Neither is true after this change. Suggested replacement:

  > [`publish.yml`](./.github/workflows/publish.yml) can be dispatched manually
  > and publishes every package to Quay using `REGISTRY_USERNAME` and
  > `REGISTRY_ROBOT_TOKEN`. [`release-please.yml`](./.github/workflows/release-please.yml)
  > runs on every push to `main`; when merging its release pull request creates
  > releases, it publishes **only the released packages**.

Also drop `"extra-files": ["README.md"]` — it is gone already, since step 1
replaces the whole config, but it is worth knowing that the old config was
pointing release-please at the README.

### Check your work

```sh
python3 -c "import json;[json.load(open(f)) for f in ['release-please-config.json','.release-please-manifest.json']];print('json ok')"
for f in .github/workflows/*.yml; do python3 -c "import yaml;yaml.safe_load(open('$f'))" || echo "BAD $f"; done
grep -rn tag-must-move .github/ || echo "guard removed"
git diff --stat        # expect 20 files, incl. the deleted tag-must-move.sh
# the trap: kubocd-webhooks must be wired to webhooks.yaml
python3 -c "import json;print(json.load(open('release-please-config.json'))['packages']['packages/system/kubocd-webhooks']['extra-files'])"
```

---

## Before merging: create the fourteen baseline tags

**This must happen before the merge, not after.** `release-please.yml` fires on
push to `main`, so the first run starts the instant this merges — it completed in
about 15 seconds in a fork dry-run. With no tags present, release-please has no
scan floor: it reads every commit in each package's history and opens a release
pull request whose changelogs cover the entire repository. Tagging afterwards is
too late; the bogus release pull request already exists.

Git tags are independent of this pull request, so create them on `main` as it
stands today:

```sh
git fetch origin
for c in seaweedfs cert-manager cloudnative-pg cnpg-postgresql coredns-patch \
         dns-server external-secrets ingress-nginx keycloak kubauth \
         kubocd-webhooks local-secrets-provider tools vault
do
  git tag "${c}/v1.0.0" origin/main
  git push origin "refs/tags/${c}/v1.0.0"
done
git ls-remote --tags origin | wc -l        # expect 14
```

This creates lightweight git tags and nothing else: no GitHub Releases, no
workflow runs (`release-please.yml` and `ci.yml` both trigger on branches, not
tags), no publishes. Reversible with `git push origin :refs/tags/<name>`.

Verified in a `platform-packages` fork: with the tags in place the first
release-please run after the merge logged `No user facing commits found since
<sha>` once per component and opened no release pull request. Without them it
would have opened one covering all of history.

Any `fix:`/`feat:` that lands on `main` between tagging and merging will
legitimately appear in the first release pull request. That is correct
behaviour, just something to expect.

## After merging: publish the baseline once

The manifest and the git tags now agree, but the registry still has no `1.0.0`
for any package, so `main` declares a `tag:` the registry does not have.

Actions → **publish** → Run workflow. It calls the template without
`on_existing_tag`, which defaults to `skip` — right for this run, since none of
the fourteen `1.0.0` tags exist yet. Expect fourteen `build and push` and no
skips.

The manifest, the git tags, the registry and the `tag:` lines then all agree.

---

## Verified before writing this

Against `OKDP/sandbox-dependencies` at `12bb63a`, not inferred from PR 3:

- **Fourteen** package manifests, at the paths in step 1. Zero git tags.
  `.release-please-manifest.json` is `{}`; `release-please-config.json` is the
  root-package `initial-version: 0.3.0` shape. Release PR **#2** open since
  24 July. The repo has **no open issues**, so the `Fixes #` number must be
  filed first.
- **No `charts/` directory**, and `grep -rn "path: \.\./" packages/` returns
  nothing — no package embeds a local chart by relative path. PR 3's step 7 is
  correctly omitted.
- `kubocd-webhooks` is the only package whose manifest filename differs from its
  directory name (`webhooks.yaml`). Every manifest's `name:` matches its
  directory, so components are the directory names.
- Workflows compared file by file against `platform-packages@main`:
  `release-please.yml` and `tag-must-move.sh` are **byte-identical**; `ci.yml`
  and `publish.yml` differ only in `values_path`;
  `kubocd-package-template.yml` differs only in the `oci_package_prefix`
  description, one comma/semicolon, and the **position** of the `Install yq` and
  `Install oras` steps. `on_existing_tag` and the `rc=0; out=$(...)` fix are
  both present. `ci.yml`'s `tag-must-move` job is at lines 60–77, the same range
  as in `platform-packages`.
- The README table was diffed against the manifests: five of fourteen rows are
  stale (`external-secrets`, `keycloak`, `kubauth`, `seaweedfs`, `vault`).
- Every manifest has exactly one `^tag:` line at column zero, so the plain
  substitution in step 3 is safe. The `0,/re/` form from PR 3 was run against
  this repo and changed nothing.
- Both generated JSON files parse.

## Not in this PR

- Repointing `OKDP/okdp-sandbox`. Separate, and it needs the announcement.
- The automated bump PR into `okdp-sandbox` — needs a machine account, since
  `GITHUB_TOKEN` cannot write to another repository.
- Closing release PR **#2**. Do it before this merges; it means nothing under
  the new scheme.
