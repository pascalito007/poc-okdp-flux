# Stack inventory page, handoff

The component inventory page for okdp.io, built and verified.
**4 commits** on `feat/stack-inventory` in `/Users/scalp/okdp-live/okdp.io`,
based on `e696776`. **Nothing is pushed.**

```
848f954  feat(stack): parse both package tag formats
c0ee60a  feat(stack): add the OKDP component inventory page
34f93db  fix(stack): clone from OKDP by default and guard stale local checkouts
2ddbb19  feat(stack): generate the OKDP component inventory
```

`17 files changed, 2673 insertions(+), 3 deletions(-)`. The 3 deletions are
`package.json` gaining the `yaml` devDependency.

`okdp.io`'s default branch is **`master`**, not `main`. The PR targets `master`.

For a beginner-friendly explanation of the whole design, see `EXPLAINER.md`
in this folder.

## Accounts, read this first

| | |
| --- | --- |
| Fork | `jpmewenemesse/okdp.io` |
| Fork's `master` | `e696776`, **level with `OKDP/okdp.io`**, so the branch applies cleanly |
| `gh` on this laptop | authenticated as `pascalito007`, which has **READ only** on that fork |

**Pushing has to happen from the laptop authenticated as `jpmewenemesse`.** A
push from here will be rejected.

The local clone already has both remotes configured, so if you copy the
directory across they travel with it:

```
origin  ->  OKDP/okdp.io            (pull from, PR into)
fork    ->  jpmewenemesse/okdp.io   (push to)
```

## What is verified

Run on the real repo:

| Check | Result |
| --- | --- |
| `npm ci` | clean |
| Generator over the 27 packages | 27 components, 11 / 2 / 14 |
| Generator determinism | byte-identical across runs |
| Tag parsing | 18 shapes, both `-pNN` and `-X.Y.Z` |
| `npm run format:check` (CI gate) | passes |
| `npm run build` (CI gate) | 14 pages, 4 new routes |
| Rendered EN and FR HTML | versions, badges, headings and counts correct |
| i18n diff | purely additive, 69 lines each, zero removals |

The one build warning, `/404.htmlEntry docs → 404 was not found`, is
**pre-existing**. Confirmed by building the base commit with the branch stashed:
the same warning appears without any of these changes.

Not run: `astro check`. It is not in the repo's CI (`deploy.yml` runs
`format:check` then `build`) and it prompts to install extra packages.

**Not verified: the visual result.** The Chrome extension was not connected, so
the page was checked from its rendered HTML, never looked at. Layout and spacing
need your eyes.

## On the other laptop

**Option A, the bundle.** Copy `stack-inventory.bundle` across:

```sh
git clone https://github.com/jpmewenemesse/okdp.io.git
cd okdp.io
git fetch /path/to/stack-inventory.bundle feat/stack-inventory:feat/stack-inventory
git switch feat/stack-inventory
npm ci && npm run build
```

**Option B, no bundle.** Recreate nothing: just push from wherever you are
authenticated as `jpmewenemesse`, having moved the four commits across by any
means (bundle, patch, or re-cloning this working copy).

Then:

```sh
git push -u origin feat/stack-inventory
```

## Previewing

Locally:

```sh
npm run dev
```

| URL | Page |
| --- | --- |
| http://localhost:4321/en/stack/okdp-1-0 | the inventory, English |
| http://localhost:4321/fr/stack/okdp-1-0 | the inventory, French |
| http://localhost:4321/en/stack/ | the version index |

Worth clicking: expand the Trino row (it shows OPA, OPAL, opal-secrets and
oidc-dcr underneath), type `spark` in the filter, try it with JavaScript
disabled (rows are `<details>`, so they still expand), and resize narrow.

On the fork: pushing a non-`master` branch triggers `preview.yml`, which
publishes to GitHub Pages at

```
https://jpmewenemesse.github.io/okdp.io/previews/feat-stack-inventory/
```

That needs Pages enabled once in the fork: **Settings > Pages**, deploy from the
`gh-pages` branch, root. Paste that URL into the PR description.

## The PR

Title:

```
feat(stack): add the OKDP component inventory page
```

Body:

```markdown
## What

Adds `/stack` and `/stack/<version>`, an inventory of every component shipped in
an OKDP release, with the version, where it comes from, and links to source.
Both locales. Inspired by TDP's stack page and adapted to a Kubernetes platform:
OKDP composes Helm charts and OCI images rather than compiling from source, so
the columns are Version / Package / Provenance / Chart rather than TDP's
Base version / Type / Source / Binaries.

## Why

There is no single place that says what OKDP 1.0 contains. A package tag gives
one number; it does not say that Trino 480 runs on chart `trino v1.42.1`
alongside OPA 1.16.1 and OPAL 0.9.4, nor which Spark / Python / Java / Scala
combinations are built, nor whether a component is used as published upstream or
rebuilt by OKDP. Occasionally a tag misleads outright: keycloak's tag is
`24.4.11`, the Bitnami chart version, while the Keycloak inside is 26.1.3.

The same data is currently duplicated by hand in the console catalog, the
sandbox pins and repository READMEs, and those copies drift. okdp-sandbox #99 is
open right now to re-synchronise eight tags across six files. This page derives
the data instead of transcribing it, so it cannot join that list.

## How

`scripts/build-stack.mjs` reads the 27 KubOCD Package manifests from
`platform-packages` and `sandbox-dependencies` and flattens them into
`src/data/stack/okdp-1-0.yaml`, which is committed. The generator runs when a
release is cut, not during `astro build`, so:

- the site build stays offline and deterministic
- every version change lands as a reviewable diff
- `/stack/okdp-1-0` stays frozen once 1.0 ships

It understands both package tag shapes, `<upstream>-pNN` today and
`<upstream>-X.Y.Z` after the release-please rework, so the tag change needs no
follow-up here.

Presentation metadata that cannot be derived (display names, project homepages,
logos) lives in `scripts/stack-metadata.yaml`.

Rows are `<details>` elements, so expansion works with JavaScript disabled. The
filter and the copy-to-clipboard buttons are progressive enhancement on top.

## How to Test

```sh
npm ci
npm run build
npm run preview   # then open /en/stack/okdp-1-0 and /fr/stack/okdp-1-0
```

To regenerate the data (clones the package repos from OKDP):

```sh
node scripts/build-stack.mjs --stack 1.0
git diff src/data/stack/   # expect no change unless a package moved
```

## Breaking change

No.
```

## What the generator found

Version data is duplicated by hand in several places, and on `main` those copies
disagree. okdp-sandbox #99 closes exactly these:

| Component | Package repo | `serviceCatalog` seed | Sandbox `Release` pin |
| --- | --- | --- | --- |
| polaris | `1.3.0-incubating-p07` | `-p06` | `-p06` |
| superset | `6.0.0-p05` | `6.0.0-p04` | `6.0.0-p04` |
| airflow | `3.2.1-p07` | `3.2.1-p04` | `3.2.1-p04` |
| spark-history-server | `3.5.1-p08` | `3.5.1-p07` | not pinned |
| keycloak | `24.4.11-p16` | not listed | `24.4.11-p14` |
| okdp-control-plane-server | `0.7.1-p02` | not listed | `0.7.1-p01` |

Two more things it surfaced, both worth their own issue:

1. **`okdp-examples` is internally inconsistent.** Package tag `1.3.0-p08` and
   chart `okdp-examples 1.3.0`, but the image pinned inside is
   `quay.io/okdp/okdp-examples:1.2.0`. The GitHub release is
   `helm-okdp-examples/v1.2.0`. The page currently shows **1.2.0**, derived from
   the image. If 1.3.0 is right, the image pin in `platform-packages` is stale.

2. **A stale local checkout silently produces a different platform.**
   `/Users/scalp/okdp-live/platform-packages` is 74 commits behind and still
   contains `trinodb`, `okdp-server` and `okdp-ui` from before the repo split.
   It generates **38** components instead of 27. The generator now refuses to
   use a local checkout unless `--repo` names it explicitly, and warns when it
   is not level with `main`.

## Worth checking before reworking the release-please PR

`pr-7-control-plane-server-version-order.md` orders the console's versions by
banding stable releases above pre-releases, on the premise that "every
release-please version is a plain `X.Y.Z`". With the agreed `3.5.1-1.0.0` shape
that premise no longer holds: in SemVer everything after the hyphen is a
pre-release identifier, so the new tags are pre-releases too.

SemVer rule 11.4 also ranks numeric identifiers **below** alphanumeric ones, so
`3.5.1-1.0.0` sorts *below* the `3.5.1-p08` it replaces, and the console could
offer the older tag as newest. Reasoned from the tag format, not from the PR's
code, so please check it against the implementation.

Separately, `release-mechanism/README.md` still records the superseded decision
("Package SemVer, not `<upstream>-pNN`", "Every package starts at `1.0.0`"), and
`pr-3` / `pr-4` describe that target. Worth updating before the rework.

## Still open, answers change only `scripts/stack-metadata.yaml`

1. **`okdp-examples`**: show 1.2.0 (image, current behaviour) or 1.3.0
   (chart and package)? File an issue against `platform-packages`?
2. **Keycloak**: showing **26.1.3**, the Keycloak in the rebuilt image, not
   `24.4.11` which is the Bitnami chart the tag tracks. Confirm.
3. **Trino**: showing **480**, not `480.0.0-p21`. Confirm.
4. **`tools`** is a bundle (reloader 1.0.72, kubernetes-replicator 2.9.2,
   kubernetes-secret-generator 3.4.0). Its "1.0.0" is the package version and
   means nothing to a reader. One row with no headline version, or three rows?
5. **`kubauth 0.3.0-snapshot`** is the only non-GA pin in 1.0. It currently
   renders with a "Pre-release" badge, alongside `polaris 1.3.0-incubating`.
   Keep that visible?

Each is a couple of lines in `stack-metadata.yaml`, then re-run the generator.

## Files

New:

```
scripts/build-stack.mjs                    the generator
scripts/stack-metadata.yaml                curated names, homepages, logos, overrides
src/data/stack/okdp-1-0.yaml               generated, committed
src/types/stack.ts
src/lib/stack.ts
src/components/stack/{ProvenanceBadge,ComponentRow,StackSection}.astro
src/pages/[lang]/stack/{index,[version]}.astro
```

Modified:

```
README.md                                       + Stack inventory section
src/content.config.ts                           + stacks collection (glob loader, zod)
src/i18n/{en,fr}.json                           + nav.stack, + stackPage
src/components/common/MarketingNavLinks.astro   + one nav item
package.json / package-lock.json                + yaml (devDependency, generator only)
```

`yaml` is dev-only and pure JS with no install script, so it needs no entry in
the repo's `allowScripts` guard.

## Next steps, after 1.0

1. **Drift detector.** A scheduled workflow re-runs the generator and opens a PR
   when the stack has moved, the same shape as `tag-must-move`. Closes
   `issue-catalog-drift.md`.
2. **Manifest as a release asset.** The package repos emit `okdp-stack.json`
   from the same release-please run that mints the tags. okdp.io consumes it by
   tag, and the `serviceCatalog` seed in `platform-context.yaml` is generated
   from it too. That is what makes the drift above structurally impossible.
