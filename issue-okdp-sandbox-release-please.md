# Issue — restore release-please in `okdp-sandbox`

> Org template: [`feature_request.yml`](https://github.com/OKDP/.github/blob/main/.github/ISSUE_TEMPLATE/feature_request.yml) — labels `enhancement`.
> File in `OKDP/okdp-sandbox`. Pairs with `pr-5-okdp-sandbox-restore-release-please.md`,
> which supplies the `Fixes #` number.
> Agreed with `idirze` (1 Sep 2026), who removed it in #58 and confirmed the
> reason no longer applies.
> **Filed 2 Sep 2026 as `OKDP/okdp-sandbox#93`** — this document is kept for the
> reasoning and the `1.0.0` / `0.6.0` decision, which the filed issue summarises
> more briefly.

### Title

```
okdp-sandbox has not declared a version since v0.5.0
```

---

### Problem Statement

`okdp-sandbox` last released **`v0.5.0` on 27 May 2026**. There have been
**58 commits on `main` since** — 13 `feat`, 19 `fix`, 1 `refactor`, 2
`refactor!`, 8 `docs` — with no tag, no GitHub Release and no changelog entry.

This is the repository a user clones to install OKDP. Asked "which version am I
running?", the only honest answer today is `v0.5.0`, which is three months and
58 commits out of date.

### How it happened

Not a mistake. A premise that changed and was never revisited.

| when | what |
|---|---|
| 27 May 2026 | `v0.5.0` released by `github-actions[bot]` (`95de3e6 chore(main): release 0.5.0`). release-please working normally. |
| 5 Jun 2026 | **#57 / #58** reduce the repository to **7 files** — "after this cleanup, `okdp-sandbox` becomes a README-focused sandbox entry point". Packages had moved to `platform-packages`, charts to `helm-charts-utilities`. |
| | Removing `release-please.yml` and `release-please-config.json` was **correct** under that plan: a README that points elsewhere has nothing to version. |
| 8 Jul 2026 | `10a3f23 feat: restore the cluster deployment layer under clusters/sandbox`, plus `deploy-validation.yml`. `clusters/` comes back. |
| today | **41 files, 32 of them under `clusters/`.** The repository is the deployable definition of the sandbox again — but the release automation removed under the old premise was never restored with it. |

One artefact confirms the intent: **`.release-please-manifest.json` survived
#58.** That sweep removed `.github/`, `clusters/` and `packages/`; the manifest
sits at the repository root and slipped through. It still reads:

```json
{".":"0.5.0"}
```

— with no config and no workflow to read it.

### What this is not

This is **not** the per-package release-please work being done in
`platform-packages` (#74) and `sandbox-dependencies` (#37). This repository ships
one thing, so one version for the whole repository is correct — which is exactly
what it had. No per-package components, no `x-release-please-version`
annotations, no baseline tags to create.

The `v0.5.0` tag, the `CHANGELOG.md` entry and the manifest all already agree, so
the anchor is real and nothing needs back-filling.

### Proposed Solution

Restore the two files removed in #58:

1. **`release-please-config.json`** — as it was, minus two entries:
   - `extra-files: ["README.md"]` — the only version-looking string in the README
     is a **KuboCD** badge (`v0.3.2`), not this repository's version.
     release-please must not be aimed at it.
   - `initial-version: 0.4.0` — moot now `0.5.0` has shipped.

2. **`.github/workflows/release-please.yml`** — restored **without** its second
   job. The old file's `publish` job ran `gh workflow run publish.yml`, and
   `publish.yml` was legitimately deleted in #58 with the packages; restoring it
   verbatim would fail. Trigger moves to `push: branches: [main]`, matching what
   `platform-packages` and `sandbox-dependencies` adopt.

`.release-please-manifest.json` is left exactly as it is.

### Decision needed before the pull request merges

**Is the next release `1.0.0` or `0.6.0`?**

Two commits since `v0.5.0` carry a breaking-change marker:

```
e1dd213 refactor(context)!:  nest the catalog services under their console section
7a53a48 refactor(contexts)!: merge the context layers into a single platform Context
```

The old config carried `"bump-minor-pre-major": false`. On a `0.x` version that
makes a breaking change a **major** bump, so restoring it as-is means the first
release pull request proposes **`v1.0.0`**.

- **`1.0.0`** — both breaking changes are real: the context layers were merged
  into a single platform Context and the catalog services were re-nested. Anyone
  upgrading a sandbox across that boundary has to redo their context.
- **`0.6.0`** — set `"bump-minor-pre-major": true` and the same commits produce a
  minor bump instead.

Either is defensible. What is not defensible is discovering it from a surprise
pull request titled `chore(main): release 1.0.0`.

### Alternatives considered

**Leave it out and delete the orphaned manifest.** Defensible *if* `clusters/` is
temporary and the deployment layer is expected to move elsewhere again. If it is
staying, the repository needs its version back. Worth confirming before doing
either — the answer decides which change is correct, and doing neither leaves
the repository in the current inconsistent state.

**Tag by hand.** Works once, then rots. The repository already enforces
Conventional Commits (`conventional-commits.yml`), so the version is derivable;
nothing is gained by deriving it manually.

### Additional Context

- Verified against `1cf459e` (1 Sep 2026).
- Tags present: `v0.1.0` … `v0.5.0`. `release-please-config.json` absent.
  `.github/workflows/` holds only `conventional-commits.yml` and
  `deploy-validation.yml`.
- #58 deleted, in one commit: `release-please.yml`, `release-please-config.json`,
  `ci.yml`, `publish.yml`, `publish-on-merge.yml`,
  `kubocd-package-template.yml` and the `oci-package-prefix` action.
- Unrelated to the package version pins in `clusters/sandbox/` — those are
  repointed separately once #74 and #37 have released.
