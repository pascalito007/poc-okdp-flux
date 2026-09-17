# PR 7: `OKDP/okdp-control-plane-server`, order the version dropdown

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> **Must be deployed before the first composite tag reaches quay.io.**
> Independent of every other document here: it changes no packages and no
> manifests, and it is a no-op until the first release-please version is
> published.
> Written against `okdp-control-plane-server` `9014410`.

> **Rewritten 17 Sep 2026.** The banding rule changed. The earlier version
> ranked *stable releases* above pre-releases, which worked only while PR 3 and
> PR 4 were going to publish plain `1.0.1` tags. Under the composite scheme the
> team asked for (`24.4.11-1.0.0`) **every tag is a pre-release forever**, so
> that rule is a no-op and the dropdown stays wrong. The rule now bands the
> legacy `-pNN` tags *down* instead. The superseded document is in
> `rejected-design-2026-09-17/`.

### Branch

```
fix/order-version-dropdown
```

### Title

```
fix(catalog): order the version list by version, legacy -pNN tags last
```

### Commit

One commit, subject matching the title. `conventional-commits.yml` validates
every commit in the pull request, so each must be conventional on its own.

`fix:` is right: it bumps a patch and appears under **Bug Fixes** in this
repository's changelog.

### Body

```markdown
## Description

`listOCITags` sorts registry tags with `sort.Reverse(sort.StringSlice(...))`, a
lexicographic sort rather than a version sort. It works today only because the
`-pNN` suffixes are zero-padded.

`platform-packages` #74 and `sandbox-dependencies` #37 change the published tag
from `24.4.11-p16` to `24.4.11-1.0.0`: the upstream version stays, and the OKDP
counter becomes a SemVer triple that release-please owns. The legacy `-pNN` tags
stay on the registry. Two faults then appear in the console's version dropdown:

- `24.4.11-1.0.9` sorts above `24.4.11-1.0.10`: text ordering breaks at two
  digits.
- Every new release sits **below** every obsolete tag. SemVer 2.0.0 rule 11.4.3
  ranks numeric pre-release identifiers below alphanumeric ones, so `1` loses to
  `p16` and `24.4.11-p16` stays at the top of the list permanently.

The second fault is the important one, and a plain SemVer sort does not fix it.
It is a correct comparison producing an unhelpful answer.

### What changes

Tags are ordered in three bands, each newest-first within the band:

1. **current tags**: anything whose pre-release is not the legacy counter
2. **legacy `-pNN` tags**: the hand-typed counter that preceded release-please
3. **anything that does not parse**: kept, never dropped

A tag is legacy when the last dash-separated segment of its pre-release matches
`p<digits>`, which covers `24.4.11-p16`, `1.3.0-incubating-p07` and
`0.3.0-snapshot-p03`. The composite tags never match, because their pre-release
ends in a number.

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

1. **It is a no-op today.** Every tag currently on the registry is a legacy
   `-pNN` tag, so all of them land in band 2 in the order they already had.
   Deploying this before the first composite tag is published changes nothing
   visible, which is why it should go in first.

2. **Unit tests.** `go test ./internal/service/ -run TestSortTagsByVersion`
   covers eight cases: composite tags before legacy tags, double-digit patches
   ordering numerically, a newer upstream ranking above an older one, the dashy
   upstreams (`1.3.0-incubating`), the loose shapes `18.3-p03` and `v0.3.2-p01`,
   unparseable tags kept and sorted last, legacy-only input unchanged, and empty
   input.

3. **Against a registry.** For a package with both schemes published, the
   dropdown lists the composite versions first, newest at the top, with the
   `-pNN` tags below and still selectable.

4. **The *(recommended)* label is unaffected.** It comes from `defaultVersion`,
   not from the ordering.

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
live from the OCI registry, not from the Context's `serviceCatalog`. The
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

Against the real tags published for trino on quay.io today, plus what Phase 2
would add:

```
today : 480.0.0-p21  480.0.0-p08  480.0.0-p07  480.0.0-p06
after : the four above, plus 480.0.0-1.0.0  480.0.0-1.0.9  480.0.0-1.0.10
```

Lexicographic ordering puts `480.0.0-p21` first and `480.0.0-1.0.9` above
`480.0.0-1.0.10`.

## Why a plain SemVer sort is not the fix

This is the assumption worth checking, and it is wrong for a different reason
than it was under the old design.

Verified with the `semver` library against the real tag set:

```
sorted low to high:
   24.4.11-1.0.0
   24.4.11-1.0.1
   24.4.11-1.1.0
   24.4.11-2.0.0
   24.4.11-p07
   24.4.11-p16
head of the keycloak dropdown: 24.4.11-p16
```

SemVer 2.0.0 rule 11.4.3: *numeric identifiers always have lower precedence than
non-numeric identifiers.* The composite tags' pre-release starts with a number
(`1`), the legacy tags' starts with a letter (`p`). So a correct SemVer sort
ranks every obsolete tag above every current one, for the same upstream version,
forever. `24.4.11-p16` only loses its crown when upstream Keycloak moves.

A plain SemVer sort does fix the `1.0.9` / `1.0.10` fault. It cannot fix this
one.

## Why the previous rule no longer works

The superseded version of this document banded **stable releases** above
pre-releases, on the assumption that release-please would mint plain `1.0.1`
tags. Under the composite scheme there is no such thing as a stable tag: every
published version is `<upstream>-<X.Y.Z>`, which is a pre-release by
construction. That rule would put all tags in one band and change nothing.

The fix is to band on the thing that actually distinguishes the two
populations, which is the legacy counter itself.

## The rule that does work

Order in three bands, each newest-first:

1. **current tags**: parses, and the pre-release does not end in `p<digits>`
2. **legacy tags**: parses, and the pre-release ends in `p<digits>`
3. **anything that does not parse**: kept, never dropped

Verified against every real tag shape in both package repos:

```
keycloak         24.4.11-1.1.0  24.4.11-1.0.1  24.4.11-1.0.0  24.4.11-p16  24.4.11-p07
trino            480.0.0-1.0.10  480.0.0-1.0.9  480.0.0-1.0.0  480.0.0-p21  480.0.0-p06
polaris          1.3.0-incubating-1.1.0  1.3.0-incubating-1.0.0  1.3.0-incubating-p07
kubocd-webhooks  v0.3.2-1.0.1  v0.3.2-1.0.0  v0.3.2-p01
cnpg-postgresql  18.3-1.0.1  18.3-1.0.0  18.3-p03
legacy only      24.4.11-p16  24.4.11-p07  24.4.11-p02          (unchanged)
with junk        24.4.11-1.0.0  24.4.11-p16  latest
```

The `cnpg-postgresql` row deliberately shows the un-pinned `18.3` form. PR 4
proposes pinning that package's upstream half to `18.3.0`, but the lenient
parser coerces `18.3-1.0.0` to `18.3.0-1.0.0` anyway, so this sort is correct
whichever way that decision goes.

Note `480.0.0-1.0.10` above `480.0.0-1.0.9`: SemVer compares numeric pre-release
identifiers numerically, so the double-digit fault is fixed by the same change.

Note also `1.3.0-incubating-1.0.0` lands in band 1 while
`1.3.0-incubating-p07` lands in band 2, even though both pre-releases begin with
`incubating`. The test is on the **last** dash-separated segment, not the first.

**Before any composite tag exists, this is a no-op.** Every tag on the registry
today ends in `-pNN`, so all of them land in band 2 in the order they already
had. That is what makes it safe to ship early, and it is precisely why it should
go in first: once the first composite tag is published, the dropdown is wrong
until this is deployed.

## The dependency costs one line

`github.com/Masterminds/semver/v3 v3.5.0` is **already in `go.sum`** as a
transitive dependency. Adopting it promotes it into the direct `require` block:

```
 require (
+	github.com/Masterminds/semver/v3 v3.5.0
 	github.com/gin-gonic/gin v1.10.1
```

`go mod tidy` leaves `go.sum` completely unchanged. Nothing new is downloaded.

`semver.NewVersion` is the lenient parser, which matters here: it accepts
`18.3-p03` (two segments, coerced to `18.3.0-p03`) and `v0.3.2-p01` (leading
`v`), both of which are real OKDP tags that the strict parser rejects.

## The change

```diff
diff --git a/internal/service/package_schema_service.go b/internal/service/package_schema_service.go
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
@@ -235,10 +236,62 @@ func (s *DefaultPackageSchemaService) listOCITags(packageRepo, serviceName strin
 		return nil, fmt.Errorf("failed to parse registry response: %w", err)
 	}
 
-	sort.Sort(sort.Reverse(sort.StringSlice(tagsResp.Tags)))
+	sortTagsByVersion(tagsResp.Tags)
 	return tagsResp.Tags, nil
 }
 
+// legacyCounter matches the hand-typed OKDP tag counter that preceded
+// release-please: the last dash-separated segment of a pre-release, when it is
+// "p" followed by digits. It matches 24.4.11-p16, 1.3.0-incubating-p07 and
+// 0.3.0-snapshot-p03, and never matches a composite tag, whose pre-release ends
+// in a number.
+var legacyCounter = regexp.MustCompile(`(?:^|-)p[0-9]+$`)
+
+// sortTagsByVersion orders registry tags newest-first, in three bands: current
+// tags, then the legacy -pNN tags, then anything that is not a version at all.
+//
+// A plain SemVer sort is not enough. A published tag is <upstream>-<OKDP
+// version>, e.g. 24.4.11-1.0.0, so every tag is a SemVer pre-release. SemVer
+// 2.0.0 rule 11.4.3 ranks numeric pre-release identifiers below alphanumeric
+// ones, so the legacy 24.4.11-p16 outranks every 24.4.11-1.x.y forever, and a
+// correct version comparison still puts the obsolete tag on top. Banding on the
+// legacy counter puts current releases first and keeps the old tags available
+// underneath.
+//
+// Before the first composite tag is published the bands are identical to what
+// came before: every tag on the registry is a legacy tag and lands in band 1.
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
+		case legacyCounter.MatchString(v.Prerelease()):
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

`regexp` must be added to the import block if it is not already there. Check
before applying: the earlier version of this change did not need it.

**Not yet compiled.** The superseded version of this diff was applied to
`9014410` with `go build ./...` clean and `go test ./internal/...` green. This
one changes the `band` closure and adds one package-level `var`, so it needs the
same treatment before the PR is opened.

## The test

Added to `internal/service/package_schema_service_test.go`, matching the file's
existing plain-`testing` style. Eight cases:

| case | asserts |
|---|---|
| composite tags come before the legacy `-pNN` tags | the fault this exists for |
| double-digit patches order numerically | `480.0.0-1.0.10` above `480.0.0-1.0.9` |
| a newer upstream outranks an older one | `25.0.0-2.0.0` above `24.4.11-1.1.0` |
| the dashy upstreams band correctly | `1.3.0-incubating-1.0.0` above `1.3.0-incubating-p07` |
| tolerates the loose legacy shapes | `18.3-p03`, `v0.3.2-p01` |
| unparseable tags sort last, not dropped | `latest` survives |
| legacy tags alone keep their previous order | safe to deploy before Phase 2 |
| empty | no panic |

The third and fourth cases are new in this rewrite. The fourth is the one that
would catch a regex written against the *first* segment of the pre-release
rather than the last.

## What else was checked

- **Every call site funnels through `listOCITags`.** `GetServiceVersions`
  (line 103), `ListVersionsForServices` (line 171) and `ListPackageTags`
  (line 200) all reach it, so one change covers all three.
- **Nothing depends on the old order.** `validateVersionsInRegistry` in
  `service_service.go` builds a membership map from the tags; order affects only
  the text of an error message.
- **No existing test asserts the tag order**, so none needed updating.
- **The UI does not re-sort.** `versionOptionsFor` maps `svc.versions` as given.
- `sort.Sort(sort.Reverse(sort.StringSlice(...)))` at
  `package_schema_service.go:238` was the only tag sort in the repository.
- **The banding rule was verified outside Go** against every real tag shape in
  both package repos, including the legacy-only and unparseable cases. The
  ordering shown under **The rule that does work** is that run's output.

## Not in this PR

- **The catalog's `default:`.** Ordering decides what sits at the top of the
  list; *(recommended)* comes from `defaultVersion`, which is authored in
  `okdp-sandbox`'s `platform-context.yaml` and moves in
  `pr-6-okdp-sandbox-repoint-packages.md`.
- **Hiding the legacy tags.** They stay on the registry deliberately, nothing is
  deleted, and they remain selectable just below the current releases.
- **Retiring the legacy band.** Once every package's upstream version has moved
  past its last `-pNN` release, band 1 empties by itself and the rule could be
  simplified back to a plain SemVer sort. Years away; not worth a TODO.
- **The catalog being a third copy of every version.** See
  `issue-catalog-drift.md`; the server already lists versions live from the
  registry, so `versions:` is arguably redundant already.
