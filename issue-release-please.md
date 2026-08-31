# Issue — adopt per-package release-please versioning

> Org template: [`feature_request.yml`](https://github.com/OKDP/.github/blob/main/.github/ISSUE_TEMPLATE/feature_request.yml) — labels `enhancement`.
> **File this twice**, once in `OKDP/platform-packages` and once in
> `OKDP/sandbox-dependencies`. The body is identical apart from the package list
> and the counts, marked `‹…›` below.

### Title

```
Derive the published package version from a release instead of a hand-edited tag
```

---

### Problem Statement

The version a package is published under is a literal typed into its manifest:

```yaml
apiVersion: v1alpha1
name: trino
tag: 480.0.0-p21     # <- edited by hand, on every change, by whoever remembers
```

`kubocd package` has no tag override — `--ociRepoPrefix` is the only flag — so
whatever is in that field is what reaches the registry. Four things follow from
that, and #56 / #23 only cover the first.

**1. The tag is not immutable.** Covered by #56 / #23 and fixed by the guard added
there. Not this issue.

**2. Nothing derives the version, so it goes backwards.** Reading `trino`'s `tag:`
forward through git history:

```
p06 → p07 ×5 → p17 → p18 ×3 → p19 ×3 → p20 → p07 → p08 → p21
```

After `p20` shipped, the manifest was set back to `p07` and merged.
`okdp-control-plane-server` went `0.8.0-p01 → 0.7.0-p01 → 0.7.1-p01`, and
`okdp-control-plane-ui` went `0.8.0-p02 → 0.7.0-p01`.

**3. `-pNN` is not a usable version.** Under SemVer a hyphen introduces a
*pre-release*, so `3.2.1-p04` ranks **below** plain `3.2.1`. `trino.yaml` already
carries a comment about this — the version was inflated from `480` to `480.0.0`
because "the UI requires the version to conform to SemVer". Separately, `airflow`
has shipped both `3.2.1-p2` and `3.2.1-p03`: unpadded and padded are different
tags in the registry and they sort against each other wrongly (`p3` > `p10`).

**4. There is no release, so there is no changelog and nothing to point at.** This
repo has **zero git tags and zero GitHub Releases**. `.release-please-manifest.json`
is `{}`. `release-please-config.json` and `release-please.yml` are both present and
have never produced anything, because they are configured for the wrong repo shape
— a single root package with `release-type: simple`, which mints one repo-wide
`v0.3.0` that has no relationship to the ‹13 | 14› per-package tags that actually
reach the registry. Its release PR ‹#18 | #2› has been open since ‹26 June | the
same day› and nobody has been willing to merge a number that means nothing.

Downstream, `okdp-sandbox` has to be told by hand which tag to pin. Of the 116
package tags published across the two repos, **57 were never referenced by
`okdp-sandbox` at all**, and for those that were, the median gap between publishing
and pinning is 56 hours.

### Proposed Solution

Make release-please own the version, one release unit per package.

**1. One component per package.** The pattern already exists in the org, in
`OKDP/helm-charts-utilities`, which produces tags like `helm-spark-rbac/v1.0.1`:

```json
{
  "separate-pull-requests": false,
  "include-v-in-tag": true,
  "packages": {
    "packages/services/trino": {
      "component": "trino",
      "initial-version": "1.0.0",
      "release-type": "simple",
      "include-component-in-tag": true,
      "tag-separator": "/",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        { "type": "generic", "path": "trino.yaml" }
      ]
    }
  }
}
```

The file is **strict JSON — no comments allowed**, and there is no auto-discovery:
release-please never scans for packages, so every one gets its own block, written
by hand once. Three details that are easy to get wrong:

- `separate-pull-requests: false` groups every pending package into one release PR.
  Cross-cutting commits are normal here — `9f28ef6` touched eight packages — so
  this is one review instead of eight.
- `extra-files` must use the **object** form with `"type": "generic"`. The bare
  string `["trino.yaml"]` selects release-please's default YAML updater, which
  looks for a `version:` key; these manifests have `tag:`, so it would silently do
  nothing and the published tag would never move.
- `path` inside `extra-files` is resolved **relative to the package path** above,
  so it is just the filename (verified in release-please's base strategy:
  `path: this.addPath(path)`).

**2. release-please writes the OCI tag.** The `generic` updater does a line-level
text replacement on any line carrying an `x-release-please-version` annotation —
it does not parse the YAML, so the rest of the manifest is untouched. The field is
rewritten on every release PR and never edited by hand again:

```yaml
apiVersion: v1alpha1
name: trino
tag: 1.0.0 # x-release-please-version
protected: false
```

**3. The version scheme becomes package SemVer.** This is Helm's
`version` / `appVersion` split in spirit: the package has its own lifecycle ("we
rewired how Trino connects") and the application has another ("Trino went
480 → 481"). Conflating them is what forced `480` to become `480.0.0`.

The upstream version goes in `description:`, **not** in a new field. Verified
against `kubocd` v0.3.2: the Package manifest is parsed with
`yaml.UnmarshalStrict`, so any unknown key is a hard error —

```console
$ kubocd package with-appversion.yaml --ociRepoPrefix localhost:5000/test
ERROR: error unmarshaling JSON: while decoding JSON: json: unknown field "appVersion"
```

`description` already exists on every package and already carries the product name
("Apache Superset - Enterprise business intelligence platform…"), so the upstream
version belongs there:

```yaml
description: |
  Apache Trino 480 - Distributed SQL query engine...
```

The generated `CHANGELOG.md` records it per release as well.

Verified safe: there is no semver library in `okdp-control-plane-server`'s `go.mod`
and none in `okdp-control-plane-ui`. The console's version picker
(`versionOptionsFor`, `service-utils.ts`) renders the list in the order the server
gives it and marks one `(recommended)`. Nothing computes "latest", so the numbers
can restart at `1.0.0` without breaking resolution.

**4. Publishing is triggered by a release, for the released packages only:**

```yaml
publish:
  needs: [release-please]
  if: needs.release-please.outputs.paths_released != '[]'
  strategy:
    matrix:
      path: ${{ fromJson(needs.release-please.outputs.paths_released) }}
  uses: ./.github/workflows/kubocd-package-template.yml
  with:
    publish_to_registry: "true"
    on_existing_tag: "fail"     # a brand-new version existing means a real bug
    package_path: ${{ matrix.path }}
```

**5. Start every package at `1.0.0`.** Uniform and easy to explain; the changelog
carries the history from there. The existing `-pNN` tags stay on the registry
untouched, and since nothing sorts across the two schemes there is no ordering
hazard.

### Alternatives Considered

**Keep `<upstream>-pNN` and have release-please manage `NN`.** Needs a custom
updater, and keeps both the pre-release inversion and the zero-padding trap. The
scheme is the thing causing the problem, so preserving it is the wrong trade.

**`<upstream>-okdp.<semver>`, e.g. `480.0.0-okdp.1.3.0`.** Readable and keeps the
upstream version in the tag, but it is still a SemVer pre-release and the tags get
long. Worth reconsidering only if losing `480` from the tag turns out to hurt in
practice — `description` and the changelog are meant to cover that.

**One release unit for the whole repo.** Simpler to configure, but bumping Trino
would re-release Superset, which is close to the problem being left behind. Note
this is *not* the same as `separate-pull-requests: false` above: that still gives
each package its own version and its own tag, and only groups the release PR.

**`separate-pull-requests: true`**, one release PR per package, as
`helm-charts-utilities` does. Right when charts move independently; wrong here.
`9f28ef6` ("variabilize the ingressClassName") touched eight packages, and
`45137e9` touched two — that would have been eight and two separate release PRs to
merge one at a time. The cost of grouping is that merging the PR ships everything
pending, so a package cannot be held back on its own.

**Merge the existing release PR ‹#18 | #2› as-is.** It would cut `v0.3.0` and fire
`publish.yml`, publishing at whatever hand-written tags happen to be in the YAML.
It fixes nothing. That PR should be closed as part of this work.

### Additional Context

Depends on ‹#56 | #23› landing first — the immutability guard is what makes
`on_existing_tag: fail` meaningful on the release path.

**Migration cost lands outside this repo.** Every pin in `okdp-sandbox` changes
shape, in two places: the `tag:` on each Release *and* the `versions:` / `default:`
entries in `spec.context.serviceCatalog` in `platform-context.yaml`. Anyone with a
private overlay pinning `quay.io/okdp/…:3.2.1-p04` keeps working, since old tags
are not deleted, but stops receiving updates. This needs an announcement, not just
a PR.

**Not in scope, tracked separately:**

- Automatically opening the bump PR against `okdp-sandbox` when a release is cut.
  Needs a credential that can write to another repository — `GITHUB_TOKEN` is
  scoped to the repo the workflow runs in — so it needs a machine account or a
  GitHub App first.
- The reusable e2e deploy gate (`OKDP/okdp-sandbox#89`). Deferred by the team.
- Making the `Conventional Commits` check *required* rather than advisory. Once
  versions are derived from commit messages, a PR merged with a non-conventional
  title means release-please silently does not bump, or bumps wrong.
