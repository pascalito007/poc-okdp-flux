# Issue — repoint the sandbox at the released package versions

> Org template: [`feature_request.yml`](https://github.com/OKDP/.github/blob/main/.github/ISSUE_TEMPLATE/feature_request.yml) — labels `enhancement`.
> File in `OKDP/okdp-sandbox`. Pairs with
> `pr-6-okdp-sandbox-repoint-packages.md`, which supplies the `Fixes #`.
> **File this early.** It is the announcement, and the work it describes cannot
> start until the packages have actually been released.

### Title

```
Repoint every package pin at the released versions once release-please owns them
```

---

### Problem Statement

`platform-packages` #74 and `sandbox-dependencies` #37 hand package versioning to
release-please. Every published tag changes shape: `trino:480.0.0-p21` becomes
`trino:1.0.0`, `keycloak:24.4.11-p16` becomes `keycloak:1.0.0`, and so on for all
27 packages.

**Nothing breaks the moment those merge.** The existing `-pNN` tags are not
deleted, so this repository keeps installing exactly as it does today. But from
that point on the old tags are frozen: every fix and feature lands under the new
scheme, and a sandbox still pinned to `-pNN` silently stops receiving them.

This repository is where that has to be fixed, in **three** places:

| # | where | count |
|---|---|---|
| 1 | `spec.package.tag` on each Release — `clusters/sandbox/releases/*.yaml`, `optional/**`, `project-demo/**` | **28 pins across 22 files** |
| 2 | `versions:` in `spec.context.serviceCatalog` — `clusters/sandbox/contexts/platform-context.yaml` | 7 services |
| 3 | `default:` in the same block, which the console labels *(recommended)* | the same 7 lines |

### It is not a rename — seven pins are upgrades

`1.0.0` is built from each package repository's current `main`, and seven pins
are behind that today. Repointing ships code this sandbox has never deployed:

| package | pinned here | what `1.0.0` will contain |
|---|---|---|
| `airflow` | `3.2.1-p04` | main, i.e. `p06` |
| `keycloak` | `24.4.11-p14` | main, i.e. `p16` |
| `kubauth` | `0.3.0-snapshot-p02` | main, i.e. `p03` |
| `okdp-control-plane-server` | `0.7.1-p01` | main, i.e. `p02` |
| `polaris` | `1.3.0-incubating-p06` | main, i.e. `p07` |
| `spark-history-server` | `3.5.1-p07` | main, i.e. `p08` |
| `vault` | `0.29.1-p02` | main, i.e. `p03` |

The other 21 already match `main`, so for those it really is only a rename.
`deploy-validation.yml` stands the whole platform up on a Kind cluster for any
pull request touching `clusters/**`, so a broken upgrade fails the pull request
rather than a user.

### Proposed Solution

One pull request moving all three copies to the released versions, gated by
`deploy-validation`. `pr-6-okdp-sandbox-repoint-packages.md` carries the full
table of 28 pins with file and line, the 7 catalog lines, and a scoped `sed`.

**One trap worth stating here:** there are **29** `tag:` lines under `clusters/`,
and one of them is not a package pin —

```
clusters/sandbox/flux/kubocd.yaml:30    tag: v0.3.2
```

— that is the KuboCD controller's own version. A blind search-and-replace on
`tag:` breaks the install.

### Prerequisites

Both must be true before the pull request can open, and the second is the one
that gets forgotten:

1. `platform-packages` #74 and `sandbox-dependencies` #37 are **merged**.
2. The baseline has been **published** in both — Actions → *publish* → Run
   workflow. Merging alone publishes nothing: release-please finds only `chore:`
   commits and cuts no release, so `1.0.0` does not exist on quay.io until that
   dispatch runs. Until then every pin in the pull request points at a tag that
   is not there.

### Alternatives considered

**Leave the pins on `-pNN`.** They keep working, but permanently: those tags stop
receiving updates the moment the new scheme is live, so the sandbox would quietly
freeze at the last pre-release build of every package.

**Float the pins instead of repointing.** Not possible. KuboCD's `Release` type
declares `Tag string` — "Part of OCI url `oci://<repository>:<tag>`" — and
exposes no SemVer range, so exact pins are the only mechanism available.

**Repoint package by package.** Possible, but each pull request pays a full
Kind + Flux + KuboCD run, and a half-migrated sandbox is harder to reason about
than one that moves in a single step.

### Additional Context

- Verified against `okdp-sandbox` `1cf459e` on 2 Sep 2026: 28 pins, 22 files,
  7 catalog services, and the 7 stale pins listed above.
- `spark-defaults` is published by `platform-packages` but deployed by nothing
  here — worth confirming that is intentional while the pins are being reviewed.
- **This needs an announcement, not just a pull request.** Anyone running their
  own sandbox from these manifests, or consuming these packages elsewhere, has
  to repoint too.
- Related, and deliberately out of scope: the console's version dropdown orders
  tags as text, so the legacy `-pNN` tags will rank above the new releases until
  `okdp-control-plane-server` is fixed. That is its own issue and should land
  before the first `1.0.x` is published.
- Also related: copy 2 and copy 3 duplicating copy 1 is the standing catalog
  drift problem. Repointing keeps the duplication alive; removing it is separate.
