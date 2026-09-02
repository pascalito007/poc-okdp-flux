# Issue — the console's version list will order wrongly once packages restart at 1.0.0

> Org template: [`bug_report.yml`](https://github.com/OKDP/.github/blob/main/.github/ISSUE_TEMPLATE/bug_report.yml) — labels `bug`.
> File in `OKDP/okdp-control-plane-server`. Pairs with
> `pr-7-control-plane-server-version-order.md`, which supplies the `Fixes #`.
> **File and fix before the first `1.0.x` package is published**, not after.

### Title

```
Version dropdown orders tags as text, so releases will rank below the legacy -pNN tags
```

---

### Describe the Bug

`listOCITags` in `internal/service/package_schema_service.go` ends with:

```go
sort.Sort(sort.Reverse(sort.StringSlice(tagsResp.Tags)))
```

That is a reverse **lexicographic** sort, not a version sort. There is no SemVer
library among the module's direct dependencies, and the console does not re-sort
— `versionOptionsFor` in `okdp-control-plane-ui` maps the list in the order the
server supplies.

It works today only by accident: the `-pNN` suffixes are zero-padded, so
`p06 < p07 < … < p21` happens to sort correctly as text.

`OKDP/platform-packages#74` and `OKDP/sandbox-dependencies#37` hand versioning to
release-please and restart every package at `1.0.0`. The existing `-pNN` tags are
deliberately **not** deleted, so both schemes will sit in the registry together
and the accident stops holding.

Both paths that build the list are affected — `GetServiceVersions` and
`ListVersionsForServices` — because both go through `listOCITags`.

### Steps to Reproduce

1. Open a service's version dropdown in the console for a package that has both
   old and new tags — trino is the sharp case, published today as
   `480.0.0-p06/p07/p08/p21`.
2. Publish `1.0.0`, then a release or two: `1.0.1`, `1.0.9`, `1.0.10`.
3. Reopen the dropdown.

### Expected Behavior

The current release at the top, older versions below it, with the legacy `-pNN`
tags available but not ahead of the versions actually being released.

### Actual Behavior

```
480.0.0-p21   ← reads as "latest", but is obsolete
480.0.0-p08
480.0.0-p07
480.0.0-p06
1.0.9         ← newer than 1.0.10, but listed above it
1.0.10        ← the current release, sixth of eight
1.0.1
1.0.0
```

Two separate faults:

1. **`1.0.9` sorts above `1.0.10`.** Text ordering breaks at two digits. The
   current `-pNN` scheme is zero-padded, so this is a regression introduced by
   moving to SemVer.
2. **Every new release sits below every obsolete tag**, permanently. The entry a
   user reads as "latest" is a version nobody will ever update again.

### Note: a plain SemVer sort does not fix this

Worth stating, because it is the obvious fix and it is not sufficient. Sorting
by SemVer descending repairs fault 1 and leaves fault 2 exactly as it is:

```
480.0.0-p21  480.0.0-p08  480.0.0-p07  480.0.0-p06  1.0.10  1.0.9  1.0.1  1.0.0
```

That ordering is *correct*: `480.0.0-p21` really is a higher version than
`1.0.10`. The legacy tags carry a far larger major, and no correct version
comparison will rank the new releases above them.

What works is ordering in three bands, each newest-first: **stable releases**,
then **pre-releases**, then **anything that does not parse**. Every legacy OKDP
tag carries a `-pNN` pre-release (`480.0.0-p21`, `24.4.11-p16`,
`1.3.0-incubating-p07`, `0.3.0-snapshot-p03`); every release-please version is a
plain `X.Y.Z`. So the banding separates exactly the two populations without
hard-coding anything about `-p`, and it matches ordinary practice — a
pre-release is not offered ahead of a stable release.

Any parser used has to be the lenient one: `18.3-p03` (two segments) and
`v0.3.2-p01` (leading `v`) are real published OKDP tags that a strict SemVer
parser rejects.

### Environment

- `okdp-control-plane-server` at `9014410`; the sort is the only tag ordering in
  the repository.
- `okdp-control-plane-ui` `versionOptionsFor` does not re-sort.
- No SemVer library in the direct requires — though
  `github.com/Masterminds/semver/v3 v3.5.0` is already present in `go.sum` as a
  transitive dependency, so adopting it changes `go.mod` by one line and leaves
  `go.sum` untouched.

### Anything else we need to know?

**Timing matters more than size.** The fix is a no-op until release-please
publishes its first version: every tag on the registry today is a pre-release, so
all of them land in the same band in the same order. Merged now, nothing visible
changes. Merged after the first `1.0.x` ships, users will already have seen a
dropdown recommending an obsolete tag.

The *(recommended)* label is separate and unaffected — it comes from
`defaultVersion`, authored in `okdp-sandbox`'s `platform-context.yaml`.

Nothing else depends on the current order: `validateVersionsInRegistry` builds a
membership map from the tags, and no test asserts the ordering.
