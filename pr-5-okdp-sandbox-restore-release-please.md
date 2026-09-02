# PR 5 — `OKDP/okdp-sandbox` — restore release-please

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> **Not a Phase 2 change.** `okdp-sandbox` is one repo shipping one thing, so one
> version for the whole repo is correct — which is what it already had. No
> per-package components, no `1.0.0` baseline, no `x-release-please-version`
> annotations, no tags to pre-create.
> Agreed with `idirze` (1 Sep 2026), who removed it in #58 and confirmed the
> reason no longer applies.

### Why it went, and why it comes back

Not a mistake — a premise that changed.

| when | what |
|---|---|
| 27 May 2026 | `v0.5.0` released. release-please working normally. |
| 5 Jun 2026 | **#58** (`idirze`) strips the repo to **7 files** — "after this cleanup, `okdp-sandbox` becomes a README-focused sandbox entry point". Packages had moved to `platform-packages`, charts to `helm-charts-utilities`. Deleting `release-please.yml` and `release-please-config.json` was **correct**: a README pointing elsewhere has nothing to version. |
| 8 Jul 2026 | `feat: restore the cluster deployment layer under clusters/sandbox` — `clusters/` comes back, plus `deploy-validation.yml`. |
| today | **41 files, 32 under `clusters/`.** The repo is the deployable definition of the sandbox again. The release automation removed under the old premise was never restored. |

One leftover confirms the intent: **`.release-please-manifest.json` survived #58**. The
sweep removed `.github/`, `clusters/` and `packages/`; that file sits at the repo
root and slipped through. It still reads `{".":"0.5.0"}`, with no config and no
workflow to read it.

**Cost so far:** last release `v0.5.0`, 27 May 2026. **58 commits on `main`
since** — 13 `feat`, 19 `fix`, 3 `refactor` (2 breaking), 8 `docs`. Three months
of work with no version, no changelog entry, and no answer to "which OKDP am I
running?" other than a stale `v0.5.0`.

---

## Decide first: `1.0.0` or `0.6.0`?

**This is the only real decision in this pull request, and it must be made before
merging.** Two commits since `v0.5.0` carry a breaking-change marker:

```
e1dd213 refactor(context)!: nest the catalog services under their console section
7a53a48 refactor(contexts)!: merge the context layers into a single platform Context
```

The old config carried `"bump-minor-pre-major": false`. On a `0.x` version that
means a breaking change bumps **major**. Restore the config verbatim and the very
first release pull request proposes **`okdp-sandbox v1.0.0`**.

- **Want `1.0.0`?** Keep `bump-minor-pre-major: false` (as written below). Both
  breaking commits are real: the context layers were merged into a single
  platform Context, and the catalog services were re-nested. Anyone upgrading a
  sandbox across that boundary has to redo their context.
- **Not ready to call it 1.0.0?** Set `"bump-minor-pre-major": true` and the same
  commits produce **`0.6.0`** instead.

Either is defensible. What is not defensible is discovering it from a surprise
release pull request titled `chore(main): release 1.0.0`.

### Title

```
ci: restore release-please for the sandbox
```

### Body

```markdown
## Description

`okdp-sandbox` has not declared a version since `v0.5.0` on 27 May 2026. There
are **58 commits on `main`** since — 13 features, 19 fixes and 2 breaking
refactors — with no release, no tag and no changelog entry.

The automation was removed in #58, correctly: at that point the repository had
just been reduced to a README pointing at `platform-packages` and
`helm-charts-utilities`, and a README has nothing to version.

That is no longer what this repository is. `clusters/sandbox` was restored on
8 July and now holds 32 of the repository's 41 files. This is the deployable
definition of the sandbox again, and it is what a user clones to install OKDP —
so it needs to say which version it is.

`.release-please-manifest.json` was never removed: it still reads
`{".":"0.5.0"}`, with no config and no workflow to read it. The `v0.5.0` tag and
the `CHANGELOG.md` entry are both real, so the anchor is already correct and
nothing needs back-filling.

### What changes

**`release-please-config.json` is restored**, as it was before #58 with two
edits: `extra-files: ["README.md"]` is dropped — the only version-looking string
in the README is a *KuboCD* badge (`v0.3.2`), not this repository's version, and
release-please must not be pointed at it — and `initial-version` is dropped,
which is moot now `0.5.0` has shipped.

**`release-please.yml` is restored, minus its `publish` job.** The old file's
second job ran `gh workflow run publish.yml`; `publish.yml` was legitimately
deleted in #58 along with the packages, so that job would fail. Only the
release-please job comes back.

**The trigger moves to `push: branches: [main]`**, the documented trigger,
matching what `platform-packages` and `sandbox-dependencies` adopt in their own
Phase 2 pull requests. It additionally covers direct pushes.

**Nothing else is touched.** No manifests, no `clusters/`, no tags to
pre-create. This repository is a single release unit and already has a true
anchor at `0.5.0`.

## Related Issue

Refs #57, #58 — the migration this completes.

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [x] Refactor / chore
- [ ] Breaking change

Restoring the workflow is not itself breaking. The **first release it cuts**
will be, if `bump-minor-pre-major` stays `false`: two `refactor!` commits since
`v0.5.0` make the next version `1.0.0`. Agree that number before merging.

## How to Test

1. **Merge, then watch the first run.** release-please reads the existing
   `v0.5.0` tag as its floor and opens one draft pull request,
   `chore(main): release <version>`, covering the 58 commits since 27 May.

2. **Check the proposed version.** `1.0.0` with the config as written, `0.6.0`
   with `bump-minor-pre-major: true`. If it says anything else — `0.5.1`, or a
   changelog reaching back before `v0.5.0` — stop: the manifest or the tag is
   not being read.

3. **Check the changelog window.** It must start after `v0.5.0` and list the 13
   features and 19 fixes, not the whole history of the repository.

4. **Check the README is untouched.** With `extra-files` dropped, the KuboCD
   badge (`v0.3.2`) must not move.

5. **Merge the release pull request.** A `v<version>` tag and a GitHub Release
   appear. Nothing is published to any registry — this repository ships no OCI
   artifacts.

## Checklist

- [x] I have tested my changes
- [ ] Documentation updated if needed
- [x] If breaking change: migration path described above
- [x] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [x] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
```

---

## Making the changes by hand

Two files. Nothing is deleted, nothing is annotated, no tags are created.

### 1. Create `release-please-config.json`

Recovered from `8fe69e6^`, minus `extra-files` and `initial-version`:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "draft-pull-request": true,
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "release-type": "simple",
      "changelog-type": "default",
      "bump-minor-pre-major": false,
      "bump-patch-for-minor-pre-major": false,
      "draft": false,
      "prerelease": false,
      "skip-snapshot": false
    }
  }
}
```

`bump-minor-pre-major: false` gives **`1.0.0`**. Change it to `true` for
**`0.6.0`**. See the decision section above.

`draft-pull-request: true` matches both package repositories, and matches what
this repository used before #58.

### 2. Leave `.release-please-manifest.json` exactly as it is

```json
{".":"0.5.0"}
```

It is already correct. The `v0.5.0` tag exists, the `CHANGELOG.md` entry exists.
**Do not touch it, and do not create any tags** — unlike the package repositories,
there is no baseline to make real here.

### 3. Create `.github/workflows/release-please.yml`

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
    steps:
      - uses: googleapis/release-please-action@v4
        id: release-please
        with:
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
```

No `publish` job: this repository ships no OCI artifacts, and the `publish.yml`
the old workflow dispatched was deleted in #58.

### Check your work

```sh
python3 -c "import json;[json.load(open(f)) for f in ['release-please-config.json','.release-please-manifest.json']];print('json ok')"
python3 -c "import yaml;yaml.safe_load(open('.github/workflows/release-please.yml'));print('yaml ok')"
git tag -l 'v0.5.0'                      # must exist — the anchor
git rev-list v0.5.0..HEAD --count        # the release window, 58 at time of writing
```

## Before merging

Nothing. This is the one document in this series with no pre-merge step: the
`v0.5.0` anchor is already real.

Two settings to confirm on the repository, since the workflow opens a pull
request with `GITHUB_TOKEN` — Settings → Actions → General:

- **Workflow permissions**: Read and write
- **Allow GitHub Actions to create and approve pull requests**: ticked

Both are already true for the package repositories, so they are almost certainly
set org-wide. Worth confirming rather than debugging a bare 403.

## Verified before writing this

Against `OKDP/okdp-sandbox` at `1cf459e`:

- Tags `v0.1.0`…`v0.5.0` exist; `v0.5.0` is dated 27 May 2026 and was cut by
  `github-actions[bot]` (`95de3e6 chore(main): release 0.5.0`).
- `.release-please-manifest.json` reads `{".":"0.5.0"}` and **survived #58**.
- `release-please-config.json` does **not** exist. `.github/workflows/` holds
  only `conventional-commits.yml` and `deploy-validation.yml`.
- `8fe69e6` (#58) deleted `release-please.yml`, `release-please-config.json`,
  `ci.yml`, `publish.yml`, `publish-on-merge.yml`,
  `kubocd-package-template.yml` and the `oci-package-prefix` action, leaving
  **7 files** in the repository.
- `clusters/` was restored on 8 Jul 2026 (`10a3f23`). The repository now holds
  41 files, 32 of them under `clusters/`.
- 58 commits between `v0.5.0` and `HEAD`: 19 `fix`, 13 `feat`, 13 `chore`,
  8 `docs`, 2 `refactor!`, 2 `ci`, 1 `refactor`.
- The README's only version string is the KuboCD badge `v0.3.2` — hence dropping
  `extra-files`.

## Not in this PR

- **Repointing the package pins.** 28 pins across 22 files plus the
  `serviceCatalog` entries still carry `-pNN` tags, 7 of them already behind
  their package repository. That is the Phase 4 work, and it waits on
  `platform-packages` #74 and `sandbox-dependencies` #37 actually releasing.
- **The console's tag ordering.** `okdp-control-plane-server` sorts registry tags
  reverse-lexicographically, which buries new SemVer releases below the legacy
  `-pNN` tags and orders `1.0.9` above `1.0.10`. Independent of this pull
  request, but it must be fixed before the first `1.0.x` package is published.
