# platform-packages: PR plan (packages-only + drop OCI shelf version)

> Scratch/working doc. Do NOT include this file in any commit or the PR.
> Covers `platform-packages` only. `okdp-sandbox` changes are tackled separately, later.

## Context

`main` today publishes packages to `quay.io/okdp/platform-packages-v0.3` and owns
**both** the packages and the deployment layer (releases, contexts, Flux/KuboCD
bootstrap, plus an in-CI deployment test). This PR re-scopes the repository to be a
**package producer only**:

- deployment moves to `okdp-sandbox` (the consumer),
- the in-CI deployment test is removed (it only existed because this repo held the
  deployment layer; end-to-end install validation belongs in `okdp-sandbox`),
- the OCI publish target drops its version suffix: `platform-packages-v0.3` ->
  `platform-packages` (the versioned shelf was a workaround for the old okdp-ui that
  lacked module-compatibility; the current UI integrates it, so the version is obsolete).

## Branch name

```
feat/packages-only-drop-oci-shelf-version
```

## PR title

```
feat!: re-scope platform-packages to packages-only and drop the OCI shelf version
```

## PR description

```
## What

Re-scope this repository to a package **producer** only and drop the version
suffix from the OCI publish target.

- New `platform-packages-values.yaml` is the single source of truth for the OCI
  publish target (`packageRepository`). CI reads it via the `oci-package-prefix`
  action; `ci.yml` and `publish.yml` pass `values_path`.
- Publish target drops its version: `quay.io/okdp/platform-packages-v0.3` ->
  `quay.io/okdp/platform-packages`.
- The package workflow builds and pushes packages only. The Kind/Flux/KuboCD
  deployment test is removed.
- The deployment layer (KuboCD bootstrap, context layers, releases) is deleted.
  It now lives in `OKDP/okdp-sandbox`.
- README re-scoped to packages-only.

## Why

This repository used to own both the packages and the deployment layer, which is
why a full deployment test lived in its CI. Moving deployment back to
`okdp-sandbox` removes that duplication: building still covers every package, and
end-to-end install validation belongs with the consumer. The versioned OCI shelf
(`-v0.3`) was a workaround for the old okdp-ui that lacked the
module-compatibility feature; the current UI integrates it, so the version is
obsolete.

## Breaking change

Packages now publish to `quay.io/okdp/platform-packages` (no `-v0.3`). Consumers
must update their package references. Previously published
`quay.io/okdp/platform-packages-v0.3` artifacts are not deleted but are no longer
updated.

## Sequencing

Merge this PR first so CI republishes packages at the new no-version path. The
matching `okdp-sandbox` PR that flips its package references to the new path is
gated on that republish (flipping it before republish would break reconciliation).
```

## Commit sequence (apply in this order)

Each commit leaves the repo coherent (no commit references a file deleted by a
later commit). Start clean on the new branch and unstage everything first:

```bash
git checkout -b feat/packages-only-drop-oci-shelf-version
git reset            # unstage the pre-staged deletions so we can commit in order
```

### Commit 1 - publish source of truth + version drop (breaking)

Files:
- `platform-packages-values.yaml` (new)
- `.github/actions/oci-package-prefix/action.yml`
- `.github/workflows/ci.yml`
- `.github/workflows/publish.yml`

```bash
git add platform-packages-values.yaml \
        .github/actions/oci-package-prefix/action.yml \
        .github/workflows/ci.yml \
        .github/workflows/publish.yml
```

Message:

```
feat!: publish from a values file and drop the OCI shelf version

Introduce platform-packages-values.yaml as the single source of truth for the
OCI publish target (packageRepository). The oci-package-prefix composite action
now reads .packageRepository from this file instead of
spec.context.platform.portal.packageRepository in 10-platform-context.yaml;
ci.yml and publish.yml pass values_path accordingly.

The publish target also drops its version suffix: packages now publish to
quay.io/okdp/platform-packages instead of quay.io/okdp/platform-packages-v0.3.
The versioned shelf name was a workaround for the old okdp-ui that lacked the
module-compatibility feature; the current UI integrates it, so the version is
obsolete.

BREAKING CHANGE: packages now publish to quay.io/okdp/platform-packages (no
-v0.3 suffix). Consumers must update their package references. The previously
published quay.io/okdp/platform-packages-v0.3 artifacts are not deleted but are
no longer updated.
```

### Commit 2 - build and push only, drop the deployment test

Files:
- `.github/workflows/kubocd-package-template.yml`

```bash
git add .github/workflows/kubocd-package-template.yml
```

Message:

```
refactor(ci): build and push packages only, drop the deployment test

The package workflow no longer spins up a Kind cluster, installs Flux and the
KuboCD controller, or deploys and waits on releases. It now only builds every
package under packages/ and pushes them (to the CI registry on push/PR, to the
public registry on publish).

The in-CI deployment test existed only because this repository used to own both
the packages and the deployment layer. With deployment moving to okdp-sandbox,
end-to-end install validation belongs there. Building still covers every
package, so packaging errors remain caught repo-wide.
```

### Commit 3 - remove the deployment layer

Files (deletions):
- `10-platform-context.yaml`, `20-provider-context.yaml`, `30-service-context.yaml`, `99-examples-context.yaml`
- `kubocd.yaml`
- `releases/` (all 14 files)

```bash
git add 10-platform-context.yaml 20-provider-context.yaml \
        30-service-context.yaml 99-examples-context.yaml \
        kubocd.yaml releases
```

Message:

```
refactor: remove the deployment layer

Delete the KuboCD bootstrap (kubocd.yaml), the context layers
(10/20/30/99-*-context.yaml), and all releases under releases/. These resources
move to okdp-sandbox, which owns deployment. This repository is now packages
only.
```

### Commit 4 - README re-scope

Files:
- `README.md`

```bash
git add README.md
```

Message:

```
docs: re-scope README to packages-only

Describe the repository as a package producer: drop the deployment narrative and
the install-smoke description, remove the deployment paths from the structure,
and remove the now-irrelevant Flux and Kind badges. Point readers to
okdp-sandbox for deployment.
```

## After committing

```bash
git status        # should be clean except for work-to-do.md (do not commit it)
git log --oneline -4
```

Then push the branch and open the PR with the title/description above.
```
