# PR 4: `OKDP/sandbox-dependencies`, Phase 2, release-please

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> This is the branch PR **#37** uses, which is still a draft.
> Read `pr-3-release-please.md` first: it carries the reasoning, the evidence
> against release-please 17.11.2, and the compose script. This document is the
> delta.

> **Rewritten 17 Sep 2026.** The previous version had release-please own the
> whole version, with every package restarting at `1.0.0` and the upstream
> version dropped from the tag. The team sent that back. The superseded
> document is in `rejected-design-2026-09-17/`.

## The scheme

Identical to PR 3: `tag: <upstream>-<OKDP X.Y.Z>`, so `24.4.11-p16` becomes
`24.4.11-1.0.0`. The upstream half stays a human decision in a normal PR, the
OKDP half is release-please's, and a step in `release-please.yml` joins them
because release-please cannot emit a composite string. `pr-3-release-please.md`
has the two failing candidate configurations and the runs that prove it.

## Five differences from PR 3, before you start

1. **Fourteen packages**, not thirteen, and one is a trap:
   `packages/system/kubocd-webhooks` holds `webhooks.yaml`, not
   `kubocd-webhooks.yaml`. Under the old design this mattered because
   `extra-files.path` had to name the file. Under the new design `extra-files`
   is gone, and `compose-oci-tag.sh` finds the manifest by grepping for
   `^modules:` rather than by filename, so **the trap is defused**. Confirm it
   anyway in review: this is the package most likely to be silently skipped.
2. **There is no `charts/` directory** and no package embeds a chart by relative
   path. PR 3's shared-chart guard is not needed here. Six edits, not eight.
3. **The README carries a version table** that PR 3's repo does not: a fourth
   hand-maintained copy of every version, already wrong in five of fourteen
   rows.
4. **`cnpg-postgresql`'s upstream version is `18.3`**, two segments, so
   `18.3-1.0.0` is not valid SemVer. See **The `18.3` decision** below. This is
   the one thing in either repo that the new scheme does not cleanly absorb.
5. **Two upstream versions carry their own dash:** `kubauth` is
   `0.3.0-snapshot-p03` and `kubocd-webhooks` is `v0.3.2-p01`. Both are handled,
   because the split is anchored at the end of the string, but both belong in
   the "How to Test" list.

### Branch

```
chore/release-workflow
```

Off `main`.

### Title

```
chore(ci): let release-please own the package versions
```

Deliberately `chore:`, not `feat:`. On a squash merge the title becomes the
subject of one commit touching all fourteen package directories, and
release-please assigns commits by directory. A `feat:` title would open all
fourteen new changelogs with a spurious "Features: let release-please own the
package versions" and force a minor bump on every one. `chore` is not in
`changelog-sections`, so it contributes nothing.

**Commits.** `conventional-commits.yml` validates every commit in the pull
request, not the title, so each commit must be conventional on its own.

### Body

```markdown
## Description

The published version of a package is a literal typed into its manifest, and
`kubocd package` has no tag override, so whatever sits in that field is what
reaches the registry. #32 stopped the overwriting. This removes the cause.

**The counter gets forgotten.** Across both package repos, 24 of 71 package
edits shipped with no bump at all. Before the guard rails that silently
overwrote a published tag; after them it fails CI, which is better but still a
manual step on every single package change.

**`-pNN` is not a version anyone can order.** It is a SemVer pre-release, so
`24.4.11-p16` ranks below plain `24.4.11`, and the ordering only works today
because the counter happens to be zero-padded.

**There is no release.** Zero git tags, zero GitHub Releases,
`.release-please-manifest.json` is empty. release-please has been installed the
whole time but configured for the wrong repo shape: a single root package with
`release-type: simple` and `initial-version: 0.3.0`, unrelated to the fourteen
per-package tags that actually ship. Release PR #2 has been open since 24 July
because that number means nothing to anyone.

### What changes

**The tag keeps its upstream half and gains an automated one.**

    tag: 24.4.11-p16   ->   tag: 24.4.11-1.0.0

Left of the dash stays a human decision made in an ordinary reviewable PR, as
today. Right of the dash is a plain `X.Y.Z` that release-please computes from
the commit types. Only the old `-pNN` counter stops being hand-typed. The `p`
goes because the suffix now has its own patch position.

**One release-please component per package**, following the pattern already used
in `OKDP/helm-charts-utilities`. Git tags become `keycloak/v1.0.0`, each package
gets its own `CHANGELOG.md`, and `separate-pull-requests: false` groups them
into a single release pull request.

**The OCI tag is composed, not overwritten.** release-please cannot produce a
`<upstream>-<X.Y.Z>` string: its `generic` updater's regex swallows the whole
composite, and `versioning: "prerelease"` rewrites the upstream half on any
`feat:`. Both were run against release-please 17.11.2 to confirm. So this PR
removes `extra-files` from the config and adds one step to `release-please.yml`
that joins the prefix already in the file with the version release-please just
computed.

**An upstream bump is a `feat!:`.** When upstream Keycloak moves to 25.0.0 the
developer edits the upstream half by hand and marks the commit `feat!:`.
release-please takes the major and the tag becomes `25.0.0-2.0.0`. The OKDP half
does not reset, because `keycloak/v1.0.0` is already a git tag.

**Publishing is triggered by a release, for the released packages only.**
`release-please.yml` passes `paths_released` to the package template, which
resolves each released directory to its manifest. `on_existing_tag: fail` is set
on this path.

`release-please.yml` also moves from `pull_request: types: [closed]` to
`push: branches: [main]`, the documented trigger, which additionally covers
direct pushes.

**The interim tag guard is removed.** `tag-must-move` (the `ci.yml` job and
`.github/scripts/tag-must-move.sh`) fails a pull request that edits a package
without bumping its `tag:`. From here on that is what every package change looks
like: the developer must not touch `tag:`, the release workflow writes it. Left
in place the guard would block all package work. It was labelled interim in both
the job comment and the script header. The `[no-publish]` escape hatch goes with
it.

**The README stops restating the versions.** The version column is dropped from
both package tables and the example tag is corrected. The manifests are the
source of truth. The column is already wrong in five of fourteen rows
(`external-secrets`, `keycloak`, `kubauth`, `seaweedfs`, `vault`).

**`cnpg-postgresql` is pinned to `18.3.0`.** Its upstream version is `18.3`, two
segments, which is not valid SemVer in any form and is rejected outright by a
strict parser. It has been quietly outside the versioning scheme all along.

## Related Issue

Fixes #<number of the release-please issue: file it first, this repo has no open issues>

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [x] Documentation update
- [x] Refactor / chore
- [x] Breaking change

**Migration path.** Every published tag changes shape:
`keycloak:24.4.11-p16` becomes `keycloak:24.4.11-1.0.0`. The upstream half is
unchanged, so a human reading the tag still sees which Keycloak it is. Existing
tags are not deleted and nothing breaks immediately, but consumers stop
receiving updates until they are repointed. `OKDP/okdp-sandbox` must be updated
in two places per package: the `tag:` on each Release, and the `versions:` /
`default:` entries in `spec.context.serviceCatalog`. That is tracked in
`issue-okdp-sandbox-repoint-packages.md` and needs an announcement.

`cnpg-postgresql` additionally changes its upstream half from `18.3` to
`18.3.0`. The chart is the same; only the string changes.

**One known regression, fixed separately.** In a correct SemVer ordering the
legacy `-pNN` tags outrank every new tag for the same upstream version, because
SemVer 2.0.0 rule 11.4.3 ranks numeric prerelease identifiers below alphanumeric
ones. `24.4.11-p16` therefore stays at the top of the console dropdown until
upstream moves off `24.4.11`. `OKDP/okdp-control-plane-server` needs the
three-band sort from PR 7 before the first release cut here.

## How to Test

1. **The migration touches one line per manifest.** After applying, `git diff`
   on any manifest shows only the `tag:` line, with the upstream half intact.
   Every manifest has exactly one line starting `tag:` at column zero; nested
   `tag:` keys are indented and must not move.

2. **The four awkward upstream versions.** These are the shapes a naive split
   would mangle:

   | package | before | after |
   |---|---|---|
   | `kubauth` | `0.3.0-snapshot-p03` | `0.3.0-snapshot-1.0.0` |
   | `kubocd-webhooks` | `v0.3.2-p01` | `v0.3.2-1.0.0` |
   | `cnpg-postgresql` | `18.3-p03` | `18.3.0-1.0.0` |
   | `seaweedfs` | `4.17.0-p08` | `4.17.0-1.0.0` |

3. **`kubocd-webhooks` in particular.** Its manifest is `webhooks.yaml`, not
   `kubocd-webhooks.yaml`. Confirm its `tag:` moves in the release pull request
   along with the other thirteen. `compose-oci-tag.sh` locates it by grepping
   for `^modules:`, so the filename should not matter, but this is the package
   worth checking by eye.

4. **The release pull request.** On merge, release-please opens
   `chore: release main` bumping every package with pending commits, each with a
   `CHANGELOG.md`. The compose step then rewrites each `tag:` line on the same
   branch, so a reviewer sees `- tag: 24.4.11-1.0.0` / `+ tag: 24.4.11-1.0.1`.
   Nothing is published yet.

5. **Publishing follows the release.** Merge that pull request; release-please
   creates the git tags (`keycloak/v1.0.1` for a `fix:`, `keycloak/v1.1.0` for a
   `feat:`, counting up from the `1.0.0` baseline) then publishes only the
   released packages. The job log line `Processing: ...` names them.

6. **An upstream bump.** Open a pull request that edits `keycloak.yaml`'s
   upstream half to a new Keycloak and titles the commit `feat!:`. The release
   pull request should show `- tag: 24.4.11-1.0.1` / `+ tag: 25.0.0-2.0.0`.

7. **A malformed tag fails loudly.** Set one manifest's `tag:` back to
   `24.4.11-p16` and push. The compose step must fail the workflow with
   `tag '24.4.11-p16' has no -X.Y.Z suffix`, not publish something malformed.

8. **The old guard is gone.** Open a pull request editing `keycloak.yaml`
   without touching `tag:`. Before this change `tag-must-move` fails it; after,
   CI is green and the `fix:` or `feat:` title is what decides the version.

## Checklist

- [x] I have tested my changes
- [x] Documentation updated if needed
- [x] If breaking change: migration path described above
- [x] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [x] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
```

---

## The `18.3` decision

`cnpg-postgresql` is the only package in either repo whose upstream version is
not three segments. Verified with the `semver` library: `semver.valid('18.3-p01')`
returns `null`, and so does `semver.valid('18.3-1.0.0')`. No amount of suffix
work fixes that; the left half is the problem.

Three options, in order of preference:

1. **Pin it as `18.3.0`.** One character, the chart is unchanged, and every
   consumer of the tag can parse it. The CloudNativePG Postgres images are
   published as `18.3`, so the manifest's `description:` should say so. This is
   what the rest of this document assumes.
2. **Leave it `18.3` and accept one unparseable tag.** `compose-oci-tag.sh` does
   not care, because its split regex only looks at the tail. The console's
   three-band sort keeps unparseable tags rather than dropping them, so the
   dropdown still works. But it is a known hole that will confuse the next
   person.
3. **Drop the package from the scheme.** Not worth it for one string.

Whichever is chosen, say so explicitly in the PR body. This was invisible under
the old design because every tag was normalised to `1.0.0`, and it is worth
surfacing now rather than discovering it at the first publish.

## Making the changes by hand

Six edits. Steps 1, 2 and 5 are mechanical; steps 3, 4 and 6 are where the work
is. The compose script in step 4 is byte-identical to PR 3's.

### 1. Replace `release-please-config.json`

Drop-in file: `generated-sd-release-please-config.json` in this directory,
**already updated** to the new scheme.

Fourteen components, one per package directory. Each entry is now:

```json
    "packages/system/kubocd-webhooks": {
      "component": "kubocd-webhooks",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md"
    },
```

**The `extra-files` block is gone from all fourteen entries.** That is what lets
the upstream half survive, and it is also what defuses the `webhooks.yaml` trap:
nothing in the config names a manifest filename any more.

Also note the old config pointed `extra-files` at `README.md`. That goes too,
which is consistent with step 6 removing the version table.

The `# x-release-please-version` markers are **not** added to the manifests.

### 2. Replace `.release-please-manifest.json`

Currently `{}`. Holds the OKDP half only.

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

Drop-in file: `generated-sd-release-please-manifest.json`.

### 3. Migrate the fourteen `tag:` lines

Swap the `-pNN` counter for `-1.0.0`, leave the upstream half alone:

```yaml
- tag: 24.4.11-p16
+ tag: 24.4.11-1.0.0
```

```sh
for f in packages/*/*/*.yaml; do
  grep -q '^modules:' "$f" || continue
  sed -i '' -E 's/^(tag: .*)-p[0-9]+$/\1-1.0.0/' "$f"
done
# then, separately, the 18.3 decision:
sed -i '' 's/^tag: 18\.3-1\.0\.0$/tag: 18.3.0-1.0.0/' packages/system/cnpg-postgresql/cnpg-postgresql.yaml
git diff --stat        # expect 14 files, one line each
grep -rn '^tag:' packages/ | grep -vE -- '-[0-9]+\.[0-9]+\.[0-9]+$' || echo "all fourteen migrated"
```

Expected result, all fourteen. Read off `origin/main` on 17 Sep 2026; re-read
the `before` column before applying, since the counters move constantly:

| package | before | after |
|---|---|---|
| seaweedfs | `4.17.0-p08` | `4.17.0-1.0.0` |
| cert-manager | `1.17.1-p08` | `1.17.1-1.0.0` |
| cloudnative-pg | `1.29.1-p01` | `1.29.1-1.0.0` |
| cnpg-postgresql | `18.3-p03` | `18.3.0-1.0.0` |
| coredns-patch | `1.0.0-p05` | `1.0.0-1.0.0` |
| dns-server | `1.0.0-p04` | `1.0.0-1.0.0` |
| external-secrets | `0.15.1-p03` | `0.15.1-1.0.0` |
| ingress-nginx | `4.12.1-p03` | `4.12.1-1.0.0` |
| keycloak | `24.4.11-p16` | `24.4.11-1.0.0` |
| kubauth | `0.3.0-snapshot-p03` | `0.3.0-snapshot-1.0.0` |
| kubocd-webhooks | `v0.3.2-p01` | `v0.3.2-1.0.0` |
| local-secrets-provider | `1.0.0-p06` | `1.0.0-1.0.0` |
| tools | `1.0.0-p01` | `1.0.0-1.0.0` |
| vault | `0.29.1-p03` | `0.29.1-1.0.0` |

`kubauth` and `kubocd-webhooks` are the ones to eyeball: `0.3.0-snapshot` and
the leading `v` must survive intact. `coredns-patch`, `dns-server`,
`local-secrets-provider` and `tools` all land on `1.0.0-1.0.0`, which looks odd
but is correct: their upstream version genuinely is `1.0.0`.

Note the four manifests whose `tag:` is not on line 19 (`local-secrets-provider`
line 23, `cnpg-postgresql` line 23, `kubauth` line 27, `keycloak` line 21,
`external-secrets` line 22, `vault` line 22, `seaweedfs` line 20). The `sed`
above is anchored on `^tag:` rather than a line number, so this does not matter,
but it rules out a line-based patch.

### 4. Add `.github/scripts/compose-oci-tag.sh`

Byte-identical to PR 3 step 4. Copy it rather than retyping it: the two repos'
workflows are already effectively identical, and divergence here would be a
latent bug.

```sh
cp ../platform-packages/.github/scripts/compose-oci-tag.sh .github/scripts/
chmod +x .github/scripts/compose-oci-tag.sh
diff .github/scripts/compose-oci-tag.sh ../platform-packages/.github/scripts/compose-oci-tag.sh && echo identical
```

It finds each package's manifest by grepping for `^modules:`, which is why
`webhooks.yaml` needs no special case.

### 5. Teach the package template to publish a subset

Identical to PR 3 step 5. The two repos' `kubocd-package-template.yml` differ
only in the `oci_package_prefix` description, one punctuation mark, and the
position of the `Install yq` and `Install oras` steps. The **Find KuboCD
packages** step is byte-identical, so the replacement block applies unchanged.

### 6. Replace `release-please.yml`, remove the guard, fix the README

**`release-please.yml`:** identical to PR 3 step 6, including the
`Compose the OCI tags` step, with one change:

```yaml
          values_path: sandbox-dependencies-values.yaml
```

The two files are byte-identical on `main` today, so they should stay so.

**`.github/workflows/ci.yml`:** delete the first job, lines 60 to 77 as `main`
stands today (the same range as `platform-packages`): the three comment lines
under `jobs:` through the `bash .github/scripts/tag-must-move.sh ...` line.
`get-package-oci-prefix:` becomes the first job and `kubocd-packages-ci` is
untouched. Unlike PR 3, nothing takes the vacated slot, because this repo has no
`charts/`. `ci.yml` ends with two jobs.

**`.github/scripts/tag-must-move.sh`:** delete the whole file.

```sh
git rm .github/scripts/tag-must-move.sh
grep -rn tag-must-move .github/ || echo "guard removed"
```

The `[no-publish]` escape hatch disappears with it. Worth a line in the
announcement, since reviewers have been told to use it.

**`README.md`, three corrections.** All three are made wrong by this change, and
fixing them is what lets the "Documentation updated if needed" box be ticked.

- **Drop the version column** from both package tables. It already disagrees
  with the manifests in five of fourteen rows, and once release-please owns the
  OKDP half it would drift on every release. The manifests are the source of
  truth.
- **Fix the example** at the "Example:" line.
  `quay.io/okdp/sandbox-dependencies/seaweedfs:4.17.0-p07` is both stale and in
  the format this pull request abolishes. Make it `seaweedfs:4.17.0-1.0.0`.
- **Fix the Release Publishing paragraph.** It still references
  `publish-on-merge.yml`, which #32 deleted, and says release-please *triggers*
  `publish.yml`. Neither is true after this change. Suggested replacement:

  > [`publish.yml`](./.github/workflows/publish.yml) can be dispatched manually
  > and publishes every package to Quay using `REGISTRY_USERNAME` and
  > `REGISTRY_ROBOT_TOKEN`. [`release-please.yml`](./.github/workflows/release-please.yml)
  > runs on every push to `main`; when merging its release pull request creates
  > releases, it publishes only the released packages.

  Consider also documenting the tag shape here, since this README is where
  someone will look: the published tag is `<upstream version>-<OKDP version>`,
  the upstream half is maintained by hand, and the OKDP half is
  release-please's.

### Check your work

```sh
python3 -c "import json;[json.load(open(f)) for f in ['release-please-config.json','.release-please-manifest.json']];print('json ok')"
for f in .github/workflows/*.yml; do python3 -c "import yaml;yaml.safe_load(open('$f'))" || echo "BAD $f"; done
bash -n .github/scripts/compose-oci-tag.sh
grep -rn tag-must-move .github/ || echo "guard removed"
grep -rn 'x-release-please-version' . || echo "no stale annotations"
grep -rn extra-files release-please-config.json || echo "no extra-files"
grep -rn '^tag:' packages/ | grep -vE -- '-[0-9]+\.[0-9]+\.[0-9]+$' || echo "all tags composite"
# the trap: confirm kubocd-webhooks is reachable by content, not by filename
grep -l '^modules:' packages/system/kubocd-webhooks/*.yaml
jq -r 'keys[]' .release-please-manifest.json | wc -l     # expect 14
git diff --stat        # expect 20 files, incl. the deleted tag-must-move.sh
```

---

## Before merging: create the fourteen baseline tags

Same reasoning as PR 3, and it has not been done on this repo yet.
`release-please.yml` fires on push to `main`, so the first run starts the
instant this merges. With no tags present release-please has no scan floor: it
reads every commit in each package's history and opens a release pull request
whose changelogs cover the entire repository.

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

Lightweight git tags and nothing else: no Releases, no workflow runs, no
publishes. Reversible with `git push origin :refs/tags/<name>`.

Note the git tag is `keycloak/v1.0.0`, the OKDP half only. The OCI tag is
`24.4.11-1.0.0`.

**Also close release PR #2 before this merges.** It proposes a repo-wide version
that means nothing under the new scheme.

## After merging: publish the baseline once

The registry has no composite tag for any package, so `main` declares a `tag:`
the registry does not have.

Actions → **publish** → Run workflow. It calls the template without
`on_existing_tag`, which defaults to `skip`. None of the fourteen composite tags
exist yet, so expect fourteen `build and push` and no skips.

---

## Verified

### Against `OKDP/sandbox-dependencies` at `12bb63a`

- **Fourteen** package manifests at the paths in step 2. Zero git tags.
  `.release-please-manifest.json` is `{}`; `release-please-config.json` is the
  root-package `initial-version: 0.3.0` shape. Release PR **#2** open since
  24 July. The repo has **no open issues**, so the `Fixes #` number must be
  filed first.
- **No `charts/` directory**, and `grep -rn "path: \.\./" packages/` returns
  nothing. PR 3's shared-chart guard is correctly omitted.
- `kubocd-webhooks` is the only package whose manifest filename differs from its
  directory name. Every manifest's `name:` matches its directory, so components
  are the directory names.
- Workflows compared file by file against `platform-packages@main`:
  `release-please.yml` and `tag-must-move.sh` are byte-identical; `ci.yml` and
  `publish.yml` differ only in `values_path`; `kubocd-package-template.yml`
  differs only in the `oci_package_prefix` description, one punctuation mark,
  and the position of the `Install yq` and `Install oras` steps.
  `on_existing_tag` and the `rc=0; out=$(...)` fix are both present. `ci.yml`'s
  `tag-must-move` job is at lines 60 to 77, the same range as in
  `platform-packages`.
- The README table was diffed against the manifests: five of fourteen rows are
  stale (`external-secrets`, `keycloak`, `kubauth`, `seaweedfs`, `vault`).
- Every manifest has exactly one `^tag:` line at column zero.

### Against release-please 17.11.2 and the real tags, 17 Sep 2026

- The two candidate release-please configurations both fail. See
  `pr-3-release-please.md`, **Evidence**.
- All fourteen of this repo's tags migrate cleanly under the step 3 `sed`, and
  all fourteen split correctly afterwards under
  `^(.+)-([0-9]+\.[0-9]+\.[0-9]+)$`, including `0.3.0-snapshot-1.0.0` and
  `v0.3.2-1.0.0`.
- `compose-oci-tag.sh` was exercised against four packages including
  `1.3.0-incubating-1.0.0`, a manifest still on `-p07`, and a directory with no
  manifest. It rewrote the valid ones, reported both failures as GitHub
  annotations, exited 1, and was silent and clean on a rerun.
- `semver.valid('18.3-1.0.0')` is `null`. Hence **The `18.3` decision**.

**Still untested:** `on_existing_tag: "fail"` (needs real quay credentials), and
the compose step on a real runner. Unlike PR 3, this repo has had no fork
dry-run at all, so consider one before merging.

## Not in this PR

- **A guard on the upstream half.** The natural successor to `tag-must-move`:
  fail a pull request that edits the upstream half of a `tag:` without a
  `feat!:` commit. Its own issue.
- Repointing `OKDP/okdp-sandbox`. Separate, and it needs the announcement.
- The automated bump PR into `okdp-sandbox`, which needs a machine account.
- Closing release PR **#2**. Do it before this merges.
