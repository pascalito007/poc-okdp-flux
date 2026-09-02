# PR 7 — `OKDP/okdp-control-plane-server` — order the version dropdown

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> **Must be deployed before the first `1.0.x` package reaches quay.io.**
> Independent of every other document here: it changes no packages and no
> manifests, and it is a no-op until release-please publishes its first version.
> Written against `okdp-control-plane-server` `9014410`, applied and tested
> locally on 2 Sep 2026 — the diff below is the one that compiled and passed.

### Branch

```
fix/order-version-dropdown
```

### Title

```
fix(catalog): order the version list by version, releases before legacy tags
```

### Commit

One commit, subject matching the title. `conventional-commits.yml` validates
every commit in the pull request, so each must be conventional on its own.

`fix:` is right: it bumps a patch and appears under **Bug Fixes** in this
repository's changelog, which is what this is.

### Body

```markdown
## Description

`listOCITags` sorts registry tags with `sort.Reverse(sort.StringSlice(...))` — a
lexicographic sort, not a version sort. It works today only because the `-pNN`
suffixes are zero-padded.

Once `platform-packages` #74 and `sandbox-dependencies` #37 hand versioning to
release-please, packages restart at `1.0.0` while the legacy `-pNN` tags stay on
the registry. Two faults then appear in the console's version dropdown:

- `1.0.9` sorts above `1.0.10` — text ordering breaks at two digits
- every new release sits below every obsolete tag, so the entry that reads as
  "latest" is `480.0.0-p21`, which nobody will ever update again

A plain SemVer sort fixes only the first. `480.0.0-p21` genuinely *is* a higher
version than `1.0.10`, so correct version comparison still ranks the obsolete
tags on top.

### What changes

Tags are ordered in three bands, each newest-first: **stable releases**, then
**pre-releases**, then **anything that does not parse** (kept, never dropped).

Every legacy OKDP tag carries a `-pNN` pre-release; every release-please version
is a plain `X.Y.Z`. The banding separates exactly those two populations without
hard-coding anything about `-p`, and it matches ordinary practice — a
pre-release is not offered ahead of a stable release.

`github.com/Masterminds/semver/v3` was already in `go.sum` as a transitive
dependency, so this promotes it to a direct require and leaves `go.sum`
unchanged. Its lenient parser is required: `18.3-p03` and `v0.3.2-p01` are real
published tags that a strict parser rejects.

## Related Issue

Fixes #<number of the version-ordering issue>

## Type of Change

- [x] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactor / chore
- [ ] Breaking change

## How to Test

1. **It is a no-op today.** Every tag currently on the registry is a
   pre-release, so all of them land in one band in the order they already had.
   Deploying this before the first `1.0.x` is published changes nothing visible
   — which is why it should go in first.

2. **Unit tests.** `go test ./internal/service/ -run TestSortTagsByVersion`
   covers six cases: releases before legacy tags, `1.0.10` above `1.0.9`, the
   loose shapes `18.3-p03` and `v0.3.2-p01`, unparseable tags kept and sorted
   last, legacy-only input unchanged, and empty input.

3. **Against a registry.** For a package with both schemes published, the
   dropdown lists the `1.0.x` versions first, newest at the top, with the
   `-pNN` tags below and still selectable.

4. **The *(recommended)* label is unaffected** — it comes from
   `defaultVersion`, not from the ordering.

## Checklist

- [x] I have tested my changes
- [ ] Documentation updated if needed
- [x] If breaking change: migration path described above
- [x] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [x] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
```

---

## The problem

`GetServiceVersions` and `ListVersionsForServices` both list a service's versions
live from the OCI registry, not from the Context's `serviceCatalog` — the
catalog's `versions:` is only a fallback for when the registry call fails. Both
funnel through `listOCITags`, which ends with:

```go
sort.Sort(sort.Reverse(sort.StringSlice(tagsResp.Tags)))
```

A reverse **lexicographic** sort. There is no SemVer library among the module's
direct dependencies, and the console does not re-sort: `versionOptionsFor` in
`okdp-control-plane-ui` maps `svc.versions` in the order the server supplies,
labelling whichever entry matches `defaultVersion` as *(recommended)*.

Today that happens to work, because the `-pNN` suffixes are zero-padded:
`p06 < p07 < … < p21` sorts correctly as text. Phase 2 removes that accident.

**Two distinct faults appear once packages restart at `1.0.0`.** Against the real
tags published for trino on quay.io today, plus what release-please would add:

```
today : 480.0.0-p21  480.0.0-p08  480.0.0-p07  480.0.0-p06  1.0.9  1.0.10  1.0.1  1.0.0
```

1. **`1.0.9` sorts above `1.0.10`.** Lexicographic ordering breaks at two digits.
2. **Every new release sits below every obsolete tag.** The top of the dropdown —
   which reads as "latest" — stays `480.0.0-p21` permanently.

## Why a plain SemVer sort is not the fix

This was the assumption worth checking, and it is wrong. Sorting by SemVer
descending fixes fault 1 and leaves fault 2 untouched:

```
semver only : 480.0.0-p21  480.0.0-p08  480.0.0-p07  480.0.0-p06  1.0.10  1.0.9  1.0.1  1.0.0
```

That ordering is *correct*: `480.0.0-p21` genuinely is a higher version than
`1.0.10`. The legacy tags carry a much larger major, and no amount of correct
version comparison will rank `1.0.10` above them.

## The rule that does work

Order in three bands, each newest-first:

1. **stable releases** — a parseable version with no pre-release
2. **pre-releases** — a parseable version with one
3. **anything that does not parse** — kept, never dropped

Every legacy OKDP tag carries a `-pNN` pre-release (`480.0.0-p21`,
`24.4.11-p16`, `1.3.0-incubating-p07`, `0.3.0-snapshot-p03`). Every
release-please version is a plain `X.Y.Z`. So the banding separates exactly the
two populations, without hard-coding anything about `-p`:

```
fixed : 1.0.10  1.0.9  1.0.1  1.0.0  480.0.0-p21  480.0.0-p08  480.0.0-p07  480.0.0-p06
```

It is also ordinary practice: a pre-release is not offered ahead of a stable
release.

**Before the first release-please version exists, the bands are identical to
what came before.** Every current tag is a pre-release, so it all lands in band
2 in the same order. That is what makes this safe to ship early — it changes
nothing visible until the first `1.0.x` is published, which is precisely why it
should go in first.

## The dependency costs one line

`github.com/Masterminds/semver/v3 v3.5.0` is **already in `go.sum`** as a
transitive dependency. Adopting it promotes it into the direct `require` block:

```
 require (
+	github.com/Masterminds/semver/v3 v3.5.0
 	github.com/gin-gonic/gin v1.10.1
```

`go mod tidy` leaves **`go.sum` completely unchanged** — verified. Nothing new is
downloaded.

`semver.NewVersion` is the lenient parser, which matters here: it accepts
`18.3-p03` (two segments, coerced to `18.3.0-p03`) and `v0.3.2-p01` (leading
`v`), both of which are real OKDP tags that the strict parser rejects.

## The change

Applied to `9014410`, `go build ./...` clean, `go test ./internal/...` green.

```diff
diff --git a/internal/service/package_schema_service.go b/internal/service/package_schema_service.go
index 41986a2..02c69d9 100644
--- a/internal/service/package_schema_service.go
+++ b/internal/service/package_schema_service.go
@@ -5,6 +5,7 @@ import (
 	"encoding/json"
 	"errors"
 	"fmt"
+	"github.com/Masterminds/semver/v3"
 	"io"
 	"net/http"
 	"net/url"
@@ -235,10 +236,52 @@ func (s *DefaultPackageSchemaService) listOCITags(packageRepo, serviceName strin
 		return nil, fmt.Errorf("failed to parse registry response: %w", err)
 	}
 
-	sort.Sort(sort.Reverse(sort.StringSlice(tagsResp.Tags)))
+	sortTagsByVersion(tagsResp.Tags)
 	return tagsResp.Tags, nil
 }
 
+// sortTagsByVersion orders registry tags newest-first, in three bands: stable
+// releases, then pre-releases, then anything that is not a version at all.
+//
+// A plain SemVer sort is not enough here. The legacy OKDP tags carry a much
+// higher major (trino shipped 480.0.0-p21), so once release-please restarts the
+// packages at 1.0.0 a correct SemVer ordering still puts the obsolete tags on
+// top. Every legacy tag is a pre-release (-pNN) and every release-please
+// version is a plain X.Y.Z, so banding on that puts current releases first and
+// keeps the old tags available underneath.
+//
+// Before the first release-please version is published the bands are identical
+// to what came before, so this changes nothing until then.
+func sortTagsByVersion(tags []string) {
+	parsed := make(map[string]*semver.Version, len(tags))
+	for _, t := range tags {
+		if v, err := semver.NewVersion(t); err == nil {
+			parsed[t] = v
+		}
+	}
+	band := func(t string) int {
+		v, ok := parsed[t]
+		switch {
+		case !ok:
+			return 2
+		case v.Prerelease() != "":
+			return 1
+		default:
+			return 0
+		}
+	}
+	sort.SliceStable(tags, func(i, j int) bool {
+		a, b := tags[i], tags[j]
+		if ba, bb := band(a), band(b); ba != bb {
+			return ba < bb
+		}
+		if va, vb := parsed[a], parsed[b]; va != nil && vb != nil {
+			return va.GreaterThan(vb)
+		}
+		return a > b
+	})
+}
+
 // registryGet performs a Docker Registry v2 GET, honoring the anonymous
 // bearer-token challenge some registries issue even for public repositories
 // (ghcr.io always does; quay.io serves public reads without it): on 401,
```

## The test

Added to `internal/service/package_schema_service_test.go`, matching the file's
existing plain-`testing` style. Six cases, all passing:

| case | asserts |
|---|---|
| released versions come before the legacy `-pNN` tags | the fault this exists for |
| double-digit patches order numerically | `1.0.10` above `1.0.9` |
| tolerates the loose legacy shapes | `18.3-p03`, `v0.3.2-p01` |
| unparseable tags sort last, not dropped | `latest` survives |
| legacy tags alone keep their previous order | safe to deploy before Phase 2 |
| empty | no panic |

## What else was checked

- **Every call site funnels through `listOCITags`** — `GetServiceVersions`
  (line 103), `ListVersionsForServices` (line 171) and `ListPackageTags`
  (line 200) all reach it, so one change covers all three.
- **Nothing depends on the old order.** `validateVersionsInRegistry` in
  `service_service.go` builds a membership map from the tags; order affects only
  the text of an error message.
- **No existing test asserts the tag order**, so none needed updating.
- **The UI does not re-sort.** `versionOptionsFor` maps `svc.versions` as given.
- `sort.Sort(sort.Reverse(sort.StringSlice(...)))` at
  `package_schema_service.go:238` was the only tag sort in the repository.

## Not in this PR

- **The catalog's `default:`.** Ordering decides what sits at the top of the
  list; *(recommended)* comes from `defaultVersion`, which is authored in
  `okdp-sandbox`'s `platform-context.yaml` and moves in
  `pr-6-okdp-sandbox-repoint-packages.md`.
- **Hiding the legacy tags.** They stay on the registry deliberately — nothing
  is deleted — and they remain selectable, just below the current releases.
- **The catalog being a third copy of every version.** See
  `issue-catalog-drift.md`; the server already lists versions live from the
  registry, so `versions:` is arguably redundant already.
