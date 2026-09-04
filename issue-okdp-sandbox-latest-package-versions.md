# Issue — move the sandbox onto the package versions published on 4 September

> Org template: [`feature_request.yml`](https://github.com/OKDP/.github/blob/main/.github/ISSUE_TEMPLATE/feature_request.yml) — labels `enhancement`.
> File in `OKDP/okdp-sandbox`. Pairs with
> `pr-8-okdp-sandbox-latest-package-versions.md`, which supplies the `Fixes #`.
> **Not #95.** That one is the Phase 4 rename to `1.0.0`, blocked on
> release-please. This is the bump on the *current* `-pNN` scheme, and nothing
> blocks it — see *Why this is not #95* below.
> Verified against `okdp-sandbox` `70fe8f2`, `platform-packages` `082e702`,
> `sandbox-dependencies` `12bb63a` and the live quay.io registry on 4 Sep 2026.

### Title

```
Move every package pin onto the versions published on 4 September
```

---

### Problem Statement

The `publish` dispatch run in both package repositories on 4 September 2026
pushed the eight packages whose `tag:` on `main` had never reached quay.io:

| package | published | repo |
|---|---|---|
| `airflow` | `3.2.1-p07` | `platform-packages` |
| `okdp-control-plane-server` | `0.7.1-p02` | `platform-packages` |
| `polaris` | `1.3.0-incubating-p07` | `platform-packages` |
| `spark-history-server` | `3.5.1-p08` | `platform-packages` |
| `superset` | `6.0.0-p05` | `platform-packages` |
| `keycloak` | `24.4.11-p16` | `sandbox-dependencies` |
| `kubauth` | `0.3.0-snapshot-p03` | `sandbox-dependencies` |
| `vault` | `0.29.1-p03` | `sandbox-dependencies` |

The other nineteen were skipped as already published, so **all 27 packages are
now on the registry at the version their `main` branch declares**. `main` and
quay.io are in sync for the first time since the guard rails went in.

**This repository is not.** Its pins still name the previous version of each of
those eight, because until 4 September those tags did not exist. So the sandbox
installs a platform that is up to three patch levels behind the code that has
been reviewed, merged and published — and it is the artefact a new user clones
to install OKDP.

What the eight bumps actually carry, none of which is in the sandbox today:

| package | from → to | what it brings |
|---|---|---|
| `airflow` | `3.2.1-p04` → `p07` | `dagsGitSync.ref` mirrored into `branch` (`p05`), triggerer liveness probe given time to answer (`p06`), object-store connection handed to the DAGs (`p07`) |
| `keycloak` | `24.4.11-p14` → `p16` | realm SSO session timeouts exposed, idle timeout raised to the access-token lifespan (`p15`), users can join groups (`p16`) |
| `kubauth` | `0.3.0-snapshot-p02` → `p03` | `ingressClassName` read from the Context |
| `okdp-control-plane-server` | `0.7.1-p01` → `p02` | proxy settings forwarded from the Context |
| `polaris` | `1.3.0-incubating-p06` → `p07` | `polaris-console` v0.1.1 — fixes the non-root port 80 crash |
| `spark-history-server` | `3.5.1-p07` → `p08` | login redirected back to the history host; direct ingress dropped for the proxy |
| `superset` | `6.0.0-p04` → `p05` | chart locale parameter |
| `vault` | `0.29.1-p02` → `p03` | `ingressClassName` read from the Context |

The version lives in **three** places here, and all three drift together:

| # | where | affected |
|---|---|---|
| 1 | `spec.package.tag` on each Release — `releases/*.yaml`, `optional/**`, `project-demo/**` | **8 of 28 pins**, in 6 files |
| 2 | `versions:` in `spec.context.serviceCatalog` — `contexts/platform-context.yaml` | 4 of 7 services |
| 3 | `default:` in the same block, which the console labels *(recommended)* | the same 4 lines |

Leave copy 2 and 3 behind and the console's *(recommended)* label keeps naming a
tag that nothing updates any more.

### Why this is not #95

[#95](https://github.com/OKDP/okdp-sandbox/issues/95) is **Phase 4**: the rename
of every pin to `1.0.0` once release-please owns the package versions. It is
blocked on `platform-packages` #74 and `sandbox-dependencies` #37 merging *and*
on a baseline `1.0.0` publish, neither of which has happened.

This issue is on the **current `-pNN` scheme** and is blocked on nothing — the
tags are on the registry today. The two do not compete:

- Doing this one **shrinks** #95. Once every pin names the published version, the
  Phase 4 change is a pure rename with no version movement hidden inside it, and
  the "seven pins are upgrades, not renames" warning in #95 disappears.
- Skipping it makes #95 worse. Phase 4 would then have to ship both the rename
  *and* three patch levels of behaviour change in one pull request, behind one
  `deploy-validation` run, with no way to tell which half broke it.

Closing this issue does not close #95.

### Proposed Solution

One pull request moving all three copies to the published versions, gated by
`deploy-validation.yml`. `pr-8-okdp-sandbox-latest-package-versions.md` carries
the eight pins with file and line, the four catalog lines, the per-package
substitutions and the verification script. Expected diff: **6 files, 12
insertions, 12 deletions**.

**One trap worth stating here:** there are **29** `tag:` lines under `clusters/`,
and one of them is not a package pin —

```
clusters/sandbox/flux/kubocd.yaml:30    tag: v0.3.2
```

— that is the KuboCD controller's own version. A blind search-and-replace on
`tag:` breaks the install. This is the same trap #95 carries, and the reason the
pull request edits per file rather than sweeping `tag:`.

### Prerequisites

None. All eight tags resolve on quay.io today:

```sh
for r in platform-packages/airflow:3.2.1-p07 \
         platform-packages/polaris:1.3.0-incubating-p07 \
         platform-packages/superset:6.0.0-p05 \
         platform-packages/spark-history-server:3.5.1-p08 \
         platform-packages/okdp-control-plane-server:0.7.1-p02 \
         sandbox-dependencies/keycloak:24.4.11-p16 \
         sandbox-dependencies/kubauth:0.3.0-snapshot-p03 \
         sandbox-dependencies/vault:0.29.1-p03
do oras manifest fetch --descriptor "quay.io/okdp/$r" >/dev/null \
     && echo "ok   $r" || echo "MISSING $r"; done
```

### Alternatives Considered

**Wait and do it once, as part of Phase 4.** Tempting, and worse. It bundles a
mechanical rename with three patch levels of real behaviour change — a new
`polaris` console image, `spark-history-server` losing its direct ingress,
`keycloak` and `vault` taking `ingressClassName` from the Context — behind a
single `deploy-validation` run. When that run goes red, nothing tells you which
half caused it. Phase 4 also has no date: it is blocked on two unmerged pull
requests and a baseline publish.

**Bump only the pins, leave the console catalog.** Halves the diff and breaks the
console: `default:` is what renders *(recommended)*, so it would recommend a tag
the platform no longer runs. The three copies have to move together or not at
all.

**Bump package by package.** Each pull request pays a full Kind + Flux + KuboCD
run for a one-line change, and a half-migrated sandbox is harder to reason about
than one that moves in a single reviewed step. The eight bumps were also
published together, in one dispatch, from one known state of both repositories.

**Float the pins so this never recurs.** Not possible. KuboCD's `Release` type
declares `Tag string` — "Part of OCI url `oci://<repository>:<tag>`" — and
exposes no SemVer range, so exact pins are the only mechanism available. Keeping
them current is a repeating job until an automated bump pull request exists,
which needs a machine account: `GITHUB_TOKEN` cannot write across repositories.

### Additional Context

- Verified against `okdp-sandbox` `70fe8f2` on 4 Sep 2026 against the live
  registry: **28 pins, 26 distinct packages, 8 behind, 20 already correct**, and
  all 30 YAML files under `clusters/` parse.
- **This is the version the platform release ships.** Whatever is pinned here
  when the release is cut is what "OKDP" means to anyone installing it.
- `deploy-validation.yml` runs Kind + Flux + KuboCD on any pull request touching
  `clusters/**`, pulling the pinned packages from quay. That is the gate, and it
  is why the eight can move in one step.
- **`spark-defaults` is published but deployed by nothing here.**
  `quay.io/okdp/platform-packages/spark-defaults:1.0.0-p01` is maintained in
  `platform-packages` and appears in zero files under `clusters/`. It is the only
  one of the 27 packages the sandbox does not consume. Worth a decision — archive
  it, or add the Release it is missing — before the platform release, not after.
  Also flagged in #95; still unanswered.
- Related, and deliberately out of scope: the console's version dropdown orders
  tags as text. Harmless here, because every tag in play is still `-pNN` and the
  zero-padded scheme sorts correctly by accident. It breaks the moment the first
  `1.0.x` is published, which is `okdp-control-plane-server`'s own issue and
  should land before Phase 4.
- Also related: copies 2 and 3 duplicating copy 1 is the standing catalog drift
  problem. This bump keeps the duplication alive; removing it is separate.
