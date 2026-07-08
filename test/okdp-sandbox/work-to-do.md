# okdp-sandbox: PR plan (restore the cluster deployment layer)

> Scratch/working doc. Do NOT commit this file or include it in the PR.
> This is the `okdp-sandbox` counterpart to `platform-packages/work-to-do.md`.
> Covers `okdp-sandbox` only. The `platform-packages` side is PR OKDP/platform-packages#19.

## Context

After the package/chart migration (`OKDP/okdp-sandbox#58`, "clean up sandbox after
package and chart migration"), `okdp-sandbox` was stripped down to documentation only.
The two-repo split we agreed on is:

- **`platform-packages`** = package **producer** only (build/test/publish OCI artifacts).
  This is PR #19 (removes the deployment layer, drops the `-v0.3` OCI shelf suffix).
- **`okdp-sandbox`** = cluster **deployment** only. It consumes published packages and
  describes how to deploy OKDP onto a local Kubernetes (Kind) cluster.

This PR delivers the second half: it **restores the deployment layer** under
`clusters/sandbox/`, reusing the improved namings introduced in platform-packages
(split `contexts/`, flat `releases/` instead of `releases/addons/`, single
`default-context.yaml` replaced by the four layered contexts). It closes issue
**OKDP/okdp-sandbox#64**.

The restored files are a faithful copy of platform-packages `main` (verified
byte-identical by git blob SHA), with the OCI package path already flipped to the
new **unversioned** target (`quay.io/okdp/platform-packages/<pkg>`) to match PR #19.

## Current local state (what you already have)

- Branch `main` is 1 commit ahead of `origin/main`: `297d390` "Add initial release
  configurations…" — this holds the full deployment layer **and** the README re-scope.
- Working tree also has the uncommitted **ref flip** (`-v0.3` → no suffix) on 15 files.
- Everything else showing as "modified" is **filemode noise** (`100644→100755` from the
  external drive) on `README.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore`,
  `.release-please-manifest.json`, `.github/workflows/conventional-commits.yml`,
  `docs/*.md`, and the new `clusters/` files. These must NOT land in the PR.

Net: content is ready. The remaining work is git hygiene + opening the PR.

## Branch name

```
feat/restore-deployment-layer
```

## PR title (conventional commits)

```
feat: restore the cluster deployment layer under clusters/sandbox
```

## PR description

```
## Description

Restore the OKDP cluster deployment layer under `clusters/sandbox/`, re-scoping this
repository to a deployment **consumer** only. This is the counterpart to
OKDP/platform-packages#19, which re-scopes that repo to a package producer only.

- `clusters/sandbox/flux/kubocd.yaml` : Flux bootstrap of the KuboCD controller.
- `clusters/sandbox/contexts/` : the four layered KuboCD Context files
  (`10-platform`, `20-provider`, `30-service`, `99-examples`).
- `clusters/sandbox/releases/` : the 14 KuboCD Release manifests.
- README re-scoped to deployment-only (manual Flux + KuboCD bootstrap, repo-ownership
  table, related repositories).

Files are restored with the improved namings introduced in platform-packages
(split contexts, flat `releases/`) and reference packages at the new unversioned
OCI path `quay.io/okdp/platform-packages/<pkg>`.

Closes #64.

## Type of Change

- [x] New feature
- [x] Documentation update
- [x] Refactor / chore

## Why

After the package/chart migration (#58), this repository was reduced to docs only.
Deployment belongs here (the consumer), packages belong in platform-packages (the
producer). This PR brings the deployment layer back so the sandbox can be deployed
end to end from this repo again.

## Sequencing

The package references use the unversioned path `quay.io/okdp/platform-packages/<pkg>`,
which only exists once OKDP/platform-packages#19 merges and CI republishes. Merge
platform-packages#19 first (republish at the new path), then merge this PR. Merging
this before republish would leave releases unable to resolve their packages.
```

## Commit sequence (apply in this order)

Run everything from inside the `okdp-sandbox` repo.

### Step 0 — kill the filemode noise (do this first)

```bash
cd okdp-sandbox
git config core.fileMode false     # 100755 mode changes disappear from all diffs
git status                          # should now show only: 297d390 ahead + the 15 flipped files
```

### Step 1 — start the feature branch and un-commit 297d390 (keep the files)

```bash
git switch -c feat/restore-deployment-layer   # branch off current main (carries the flip)
git reset --soft origin/main                  # undo the 297d390 commit, keep all changes staged
git restore --staged .                        # unstage, so we can commit in logical order
```

After this: `clusters/…` appear as new/untracked files (already carrying the
unversioned refs), `README.md` shows as modified, nothing else.

### Step 2 — commit the deployment layer

All files below are **(new)** — `origin/main` has no `clusters/` directory at all, so
this commit is a pure addition:

- `clusters/sandbox/flux/kubocd.yaml` (new)
- `clusters/sandbox/contexts/10-platform-context.yaml` (new)
- `clusters/sandbox/contexts/20-provider-context.yaml` (new)
- `clusters/sandbox/contexts/30-service-context.yaml` (new)
- `clusters/sandbox/contexts/99-examples-context.yaml` (new)
- `clusters/sandbox/releases/*.yaml` — 14 files, all (new): cert-manager,
  cloudnative-pg, cnpg-postgresql, coredns-patch, dns-server, ingress-nginx,
  keycloak, local-secrets-provider, okdp-server, okdp-ui, spark-operator,
  spark-rbac, tools, webhooks

```bash
git add clusters/sandbox/contexts clusters/sandbox/flux clusters/sandbox/releases
git commit -m "feat: restore the cluster deployment layer under clusters/sandbox

Restore the KuboCD deployment layer stripped out in #58, re-scoping this
repository to a deployment consumer only:

- clusters/sandbox/flux/kubocd.yaml : Flux bootstrap of the KuboCD controller
- clusters/sandbox/contexts/        : the four layered Context files
                                      (10-platform, 20-provider, 30-service, 99-examples)
- clusters/sandbox/releases/        : the 14 KuboCD Release manifests

Files use the improved namings introduced in platform-packages (split contexts,
flat releases/) and reference packages at the new unversioned OCI path
quay.io/okdp/platform-packages/<pkg>, coordinated with OKDP/platform-packages#19.

Closes #64."
```

### Step 3 — commit the README re-scope

Files:
- `README.md` (modified) — the only file that already exists on `origin/main` and
  changes here

```bash
git add README.md
git commit -m "docs: re-scope README to the deployment-only sandbox

Describe the repository as the single-cluster sandbox deployment: manual Flux +
KuboCD bootstrap, the clusters/sandbox layout, the repo-ownership table pointing
package build/release at platform-packages, and the related-repositories table."
```

### Step 4 — verify the branch is clean

```bash
git status                 # clean; nothing left except this work-to-do.md (do not commit it)
git log --oneline -3
git diff origin/main --stat # only clusters/** additions + README.md; NO filemode/LICENSE/docs noise
```

### Step 5 — reset local main (optional tidy-up)

```bash
git branch -f main origin/main   # drop the orphaned 297d390 from main; work lives on the branch
```

### Step 6 — push and open the PR (you do this)

Push `feat/restore-deployment-layer` and open the PR against `OKDP/okdp-sandbox:main`
with the title/description above. Do not merge until platform-packages#19 has merged
and republished (see Sequencing).

## Verification

Sanity (no cluster needed):

```bash
# no stale versioned refs remain
grep -rn "platform-packages-v0.3" clusters/ ; echo "expect: no matches"
# every release points at the unversioned path
grep -rn "quay.io/okdp/platform-packages" clusters/ | grep -c repository   # expect 14
```

End-to-end (satisfies #64 "all releases deploy on a sandbox cluster") — follow the
README quick start: `kind create cluster …` → `flux install` →
`kubectl apply -f clusters/sandbox/flux/kubocd.yaml` →
`kubectl apply -f clusters/sandbox/contexts/` → `kubectl apply -f clusters/sandbox/releases/`
→ `kubectl get releases -A --watch` until all `READY`.

> Note: the e2e run only works once platform-packages#19 has republished packages at
> the unversioned path (see Sequencing). Before then, validate against `-v0.3` locally
> by temporarily reverting the refs, or wait for republish.

## Out of scope (follow-ups, not this PR)

- **CI e2e install-validation workflow.** platform-packages#19 removed the in-CI
  Kind/Flux/KuboCD deploy test, noting install validation "belongs in okdp-sandbox."
  Issue #64 does not require a CI workflow (its criterion is that releases deploy on a
  sandbox cluster), so adding a GitHub Actions e2e workflow here is tracked separately.
- Broadening beyond the sandbox cluster (dev/prod contexts).
