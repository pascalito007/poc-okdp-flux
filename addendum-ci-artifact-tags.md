# Addendum — give CI artifacts a unique tag

> Applies to **both** package repositories, on top of Phase 2:
> `OKDP/platform-packages` #74 and `OKDP/sandbox-dependencies` #37.
> One new step in `kubocd-package-template.yml`, plus a README section.
> Checked against #74 `c89055e` and #37 `180aac6` on 2 Sep 2026.

## Why

`ci.yml` already builds **every** package on **every** run and pushes it to the
CI registry. The name each artifact gets is whatever sits on the manifest's
`tag:` line.

Today that is unique by accident: `tag-must-move` forces a developer to bump
`tag:` on every package pull request, so each change lands at its own address —
`trino:480.0.0-p21`, then `p22`, and so on.

Phase 2 removes that guard, correctly, and freezes `tag:` at `1.0.0` between
releases. From then on every run writes to the same address:

```
ghcr.io/okdp/platform-packages/platform-packages/trino:1.0.0
```

Three consequences, none of which affect the release path to quay.io:

**A build cannot be named.** Two colleagues' work cannot be pinned at the same
time, and neither can a specific commit. Whatever ran last is what that address
holds.

**Every run overwrites all packages, not just the changed one.** The CI job
builds the whole set, so a branch build replaces all thirteen (or fourteen)
artifacts. The address never reliably holds `main`; it holds whichever branch
finished most recently.

**A running test cluster drifts.** The sandbox `Release` carries
`interval: 30m`, so KuboCD re-resolves the OCI reference. Pin a mutable tag,
and somebody else's push silently swaps what you are running, within half an
hour, with nothing to indicate it.

This closes off a capability rather than breaking one in use — nothing consumes
these artifacts today, and "did the package build?" keeps working either way.
But the capability is wanted: testing a colleague's merged-but-unreleased change
alongside another colleague's open pull request, without building either
locally.

## The change

One step, in `.github/workflows/kubocd-package-template.yml`, in **each**
repository. Insert it immediately **before**:

```
      - name: Build and push KuboCD packages into CI registry (${{ inputs.ci_registry }}) 📦
```

That is line 207 in `platform-packages` and line 209 in `sandbox-dependencies`
as those branches stand — anchor on the step name, not the number: the two files
order `Install yq` and `Install oras` differently, so the surrounding context is
not identical.

```yaml
      # The CI registry is a scratch area. Now that release-please owns the
      # manifest tag, every run would otherwise build the same 1.0.0 artifact
      # over the top of the last one, from any branch. Stamp a unique,
      # obviously non-releasable version instead, so a specific build can be
      # pinned and cannot change under whoever pinned it.
      #
      # This rewrites the runner's checkout only. Nothing is committed, and the
      # release path to the public registry never runs this step.
      - name: Stamp a CI version on each manifest 🏷️
        if: inputs.publish_to_registry == 'false' && env.KUBOCD_PACKAGES != ''
        run: |
          set -uo pipefail

          # SemVer pre-release identifiers allow only letters, digits and
          # hyphens, so "chore/release-please" has to be flattened. Truncated
          # to keep the tag well inside the 128-character OCI limit.
          SLUG=$(echo "${GITHUB_REF_NAME}" \
                 | tr -c 'a-zA-Z0-9-' '-' \
                 | sed 's/-\{2,\}/-/g;s/^-//;s/-$//' \
                 | cut -c1-30 | sed 's/-$//')

          # The "g" is git-describe convention, and it also guarantees the
          # identifier is never all-digits: a short sha such as "0123456" would
          # otherwise be an invalid SemVer numeric identifier (leading zero).
          CI_TAG="0.0.0-ci.${SLUG}.g${GITHUB_SHA::7}"

          for package in ${KUBOCD_PACKAGES}
          do
            sed -i "s|^tag: .*|tag: ${CI_TAG}|" "${package}"
          done

          echo "CI tag: ${CI_TAG}"
          echo "::notice title=CI package tag::${CI_TAG}"
```

### Why `0.0.0`

The version number carries no meaning here; everything informative is in the
suffix. `0.0.0` was chosen because:

- it cannot be mistaken for a release, at a glance, anywhere it appears;
- `0.0.0-<anything>` is the lowest version SemVer can express, so a CI tag that
  leaks into a candidate list sorts last rather than looking newest;
- it claims nothing. Keeping the manifest's own version — `1.0.0-ci.…` — reads
  better but lies: a pre-release of `1.0.0` sorts *below* the released `1.0.0`,
  while the code in it is newer than `1.0.0` and heading for `1.0.1`.

It stays SemVer-shaped because `kubocd` reads this field as a package version,
and `trino.yaml` already carries a comment that the console requires SemVer
conformance — that is why `480` became `480.0.0`.

Verified against the SemVer and OCI tag grammars:

| branch | tag |
|---|---|
| `main` | `0.0.0-ci.main.gdee31fd` |
| `chore/release-please` | `0.0.0-ci.chore-release-please.gc89055e` |
| `fix/airflow-gitsync-schema` | `0.0.0-ci.fix-airflow-gitsync-schema.g73414db` |
| `dependabot/github_actions/actions/checkout-5` | `0.0.0-ci.dependabot-github-actions-acti.gabcdef1` |

All five test cases parse as valid SemVer and as valid OCI tags, including a
short sha with a leading zero.

## README section

Add under the existing `### CI Registry` heading in **both** repositories,
replacing `{tag}` in the current text. Substitute the repository name.

```markdown
### CI Registry

The `ci` workflow builds every package for validation and pushes it to the
repository-scoped GitHub Container Registry path:

```text
ghcr.io/okdp/platform-packages/platform-packages/{package-name}:0.0.0-ci.{branch}.g{short-sha}
```

These are throwaway build artifacts, never releases. The `0.0.0` prefix marks
them as such; the branch and commit identify the build. Releases go to the
public registry — see **Release Publishing** below.

**Where to find a build.** Which namespace it lands in depends on where the
branch lives:

| the change is | the artifact is at |
|---|---|
| merged to `main`, not yet released | `ghcr.io/okdp/platform-packages/...` |
| a branch pushed to this repository | `ghcr.io/okdp/platform-packages/...` |
| a pull request **from a fork** | `ghcr.io/<contributor>/platform-packages/...` |

A fork pull request cannot push to this repository's registry — GitHub gives it
a read-only token — so the `kubocd-packages-ci` job is skipped here. The
contributor's own fork builds it on push instead, into their namespace.
`gh pr view <number> --json headRepository` names the fork.

**How to test one.** Point a KuboCD `Release` at it:

```yaml
spec:
  package:
    repository: ghcr.io/okdp/platform-packages/platform-packages/trino
    tag: 0.0.0-ci.fix-trino-oidc.g73414db
```

The packages are private, so the cluster needs an image pull secret holding a
GitHub token with `read:packages`.
```

## Verify on the first run

1. The job log shows `CI tag: 0.0.0-ci.<branch>.g<sha>`, and the run summary
   carries the same value as a notice.
2. The `Build and push … into CI registry` step logs
   `push OCI image: ghcr.io/.../trino:0.0.0-ci.<branch>.g<sha>`.
3. Nothing new appears at `:1.0.0` in ghcr.
4. `git status` in the job is irrelevant — but confirm the committed
   `trino.yaml` on the branch still reads
   `tag: 1.0.0 # x-release-please-version`. The rewrite is runner-local.
5. On a **release** run (`publish_to_registry: "true"`), confirm the step is
   skipped and quay receives the version release-please wrote.
6. `kubocd` accepting a pre-release tag is the one thing not proven in advance.
   It is valid SemVer and a valid OCI tag, so it should pass — the first CI run
   is the proof. If `kubocd package` rejects it, fall back to
   `0.0.0-ci-<slug>-g<sha>` (no dot separators) and re-check.

## What this does not do

- **Does not change what quay.io receives.** The step is guarded
  `publish_to_registry == 'false'`; the release path never runs it.
- **Does not touch** `release-please-config.json`, `.release-please-manifest.json`,
  the committed manifests, or `ci.yml` — which already passes
  `publish_to_registry: "false"`.
- **Does not make the ghcr packages public.** Consumers still need a pull secret.
  Worth deciding separately; note that making *this* repository's packages public
  does nothing for fork pull requests, whose artifacts sit under the
  contributor's own account and visibility settings.
- **Does not un-skip `kubocd-packages-ci` for fork pull requests.** That is a
  GitHub restriction. It changes only if contributor branches are pushed to this
  repository instead of reviewed from forks — a separate question for the team,
  and the one that decides whether artifacts usually land in OKDP's namespace or
  in contributors'.

## Where to apply it

Both pull requests are open drafts, so folding this in is cleaner than a
follow-up: it is one step, and it is reviewed next to the change that creates
the need for it. If they are merged first, it lands as a small pull request
against both repositories, with no ordering constraint.
