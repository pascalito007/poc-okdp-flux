# Issue: `OKDP/okdp.io`

> Org template: [`bug_report.yml`](https://github.com/OKDP/.github/blob/main/.github/ISSUE_TEMPLATE/bug_report.yml), labels `bug`.
> Covers two defects with one root cause. The second was raised by `@PaulFarault`
> as a review comment on
> [#44](https://github.com/OKDP/okdp.io/pull/44#issuecomment-5598660153):
> *"The package sources should point to the appropriate versions (the links
> currently point to the `main` branches)."*

### Title

```
The stack inventory publishes references and links that do not resolve to what it describes
```

---

### Describe the Bug

`/stack/<version>` exists to be the authoritative record of what a release
contains. Two kinds of string on that page, image references and package
definition links, are produced by copying the input faithfully and are wrong for
a reader anyway. In five cases the input is not copied at all. Same root cause in `scripts/build-stack.mjs`: it transcribes what
the manifests happen to say, rather than resolving it to what a reader can act on.

#### A. References are in several notations, and two are wrong

The **Included modules** panel prints one line per image as `repository:tag`.
Those strings read as things you can `docker pull`. Superset is where a reviewer
first noticed the inconsistency:

```
main · quay.io/okdp/superset:6.0.0-dockerize · quay.io/okdp/superset:6.0.0-websocket · postgres:16-alpine
```

Two fully-qualified references and one bare word, describing the same kind of
thing. Classifying all **22 distinct image references** in
`src/data/stack/okdp-1-0.yaml`:

| Shape | Count | Example | Pullable as shown? |
|---|---|---|---|
| Fully qualified | 12 | `quay.io/okdp/superset:6.0.0-dockerize` | yes |
| Docker Hub, namespaced | 7 | `trinodb/trino:480` | yes, implicitly `docker.io` |
| Docker Hub, official | 1 | `postgres:16-alpine` | yes, implicitly `docker.io/library` |
| **Registry stripped** | **2** | `okdp/sandbox-images/keycloak:26.1.3-debian-12-r0` | **no** |

The first three rows are a consistency problem. The fourth is a straight bug.

`keycloak.yaml` splits the registry from the repository, as Bitnami charts do:

```yaml
image:
  registry: quay.io
  repository: okdp/sandbox-images/keycloak
  tag: 26.1.3-debian-12-r0
```

`readModule()` at `build-stack.mjs:247` pairs `repository:` with `tag:` and never
looks at `registry:`. The site therefore publishes
`okdp/sandbox-images/keycloak:26.1.3-debian-12-r0`, which is not a short form of
anything: it is a quay.io path with the host removed. It looks exactly like a Docker Hub
reference, so nothing distinguishes it from the seven legitimate ones above it.

**The charts beside them have the same problem, in a milder form.** They render
as `name version` with the repository dropped entirely, so Platform tools reads

```
replicator · kubernetes-replicator 2.9.2 · secret-generator · kubernetes-secret-generator 3.4.0
```

next to fully-qualified image references. Every chart already carries a
`repository` in the generated data (`quay.io/okdp/charts/superset` for the OCI
ones, a Helm repo URL for the rest); `ComponentRow.astro` simply does not print
it. Worse, the primary chart is filtered out of that panel altogether as
"duplication" of the Chart column, which has room for a name and a version but
not a repository. So `reloader` is missing from Platform tools entirely, and
CloudNativePG has no modules section at all: its chart repository appears nowhere
on the page.

There is a second symptom of the same gap, in the code rather than the output.
`build-stack.mjs:64` reads:

```js
const OKDP_IMAGE_PREFIXES = ["quay.io/okdp/", "okdp/"];
```

The bare `"okdp/"` exists only so `isOkdpImage()` still recognises these
registry-stripped references and tags Keycloak with the `okdp-image` provenance
badge. It is a workaround for the parsing gap rather than a fix, and it is a
latent false positive: a genuine Docker Hub image published under an `okdp`
namespace would be mislabelled as an OKDP rebuild.

#### A2. Five images are missing from the inventory altogether

The same extraction step requires `tag:` on the line immediately after
`repository:`. Charts routinely put `pullPolicy:` between them:

```yaml
image:
  repository: apache/polaris
  pullPolicy: IfNotPresent
  tag: "1.3.0-incubating"
```

Every such block is dropped silently. Five images do not appear on the page at
all, and two components render no images despite shipping them:

| Image | Component |
|---|---|
| `apache/polaris:1.3.0-incubating` | polaris, the Polaris server itself |
| `quay.io/okdp/spark:spark-3.5.6-scala-2.12-java-17` | spark-history-server |
| `quay.io/okdp/spark-web-proxy:0.2.1` | spark-history-server |
| `ghcr.io/cloudnative-pg/cloudnative-pg:1.29.1` | cloudnative-pg, the operator |
| `ghcr.io/cloudnative-pg/postgresql:18.3` | cnpg-postgresql |

This also corrupts `primaryImage`, which is chosen from the images that were
found. Polaris picked `quay.io/okdp/polaris-console`, a console add-on, because
the server image was invisible to it; three other components got no primary image
at all. Provenance is derived from the primary chart and image, so the badges
inherit the error.

#### B. Package definition links follow `main`, not the pinned commit

The page is a snapshot, and it records the commits it was generated from. The
footer's **Built from** links use them:

```yaml
sources:
  platform-packages:
    sha: 082e702722bcc395a2930bbd46f732c4486041c4
    date: "2026-09-04"
    url: https://github.com/OKDP/platform-packages/tree/082e702722bcc395a2930bbd46f732c4486041c4
```

Every per-component **Package definition** link ignores them:

```yaml
links:
  source: https://github.com/OKDP/platform-packages/blob/main/packages/services/superset/superset.yaml
```

All 27 components are affected. The two links are built a few lines apart, one
correctly and one not:

```js
// line 429: per-component link, branch hardcoded
source: `https://github.com/OKDP/${repoName}/blob/main/${relative(sources[repoName].path, file)}`,

// line 468: footer link, pinned
url: `${REPOS[name].url.replace(/\.git$/, "")}/tree/${source.head}`,
```

Line 429 already reads `sources[repoName]` for `.path`. It just does not take
`.head`, which is the same object and already in scope.

### Steps to Reproduce

**Defect A. Keycloak's references point at a registry the image is not on.**

1. Open <https://okdp.io/en/stack/okdp-1-0/> and expand **Keycloak**. It shows
   `okdp/sandbox-images/keycloak-config-cli:6.4.0-debian-12-r0`.
2. Resolve that reference against the registry it names, and against the one the
   image is really on:

```console
$ curl -s -o /dev/null -w "%{http_code}\n" \
    https://hub.docker.com/v2/repositories/okdp/sandbox-images/keycloak/
404

$ curl -s https://quay.io/api/v1/repository/okdp/sandbox-images/keycloak | head -c 60
{"namespace": "okdp", "name": "sandbox-images/keycloak", "kind"
```

Docker Hub has no nested repository paths, so that reference cannot ever resolve
there. For contrast, the bare-looking reference that *is* fine:

```console
$ curl -s -o /dev/null -w "%{http_code}\n" \
    https://hub.docker.com/v2/repositories/library/postgres/
200
```

**Defect B. JupyterHub is already wrong.**

1. Expand **JupyterHub**. The row states package tag `4.3.3-p06` and lists five
   notebook images, among them
   `quay.io/okdp/jupyter/minimal-notebook:python-3.12.12-hub-5.4.2-lab-4.5.0`.
2. Follow **Package definition**. It lands on
   `platform-packages/blob/main/packages/services/jupyterhub/jupyterhub.yaml`.
3. That file says `tag: 4.3.3-p07`, and the minimal-notebook image is not in it.

```console
$ git -C platform-packages log --oneline 082e702..origin/main -- packages/
f37c1fd refactor: remove disfunctioning minimal python image

$ git -C platform-packages show f37c1fd -- packages/services/jupyterhub/jupyterhub.yaml
-tag: 4.3.3-p06
+tag: 4.3.3-p07
@@
-          - display_name: "🪶 Minimal Python"
-            description: "Lightweight image with only Python 3.12"
-            kubespawner_override:
-              image: quay.io/okdp/jupyter/minimal-notebook:python-3.12.12-hub-5.4.2-lab-4.5.0
-              image_pull_policy: Always
```

`f37c1fd` is dated **9 Sep 2026 09:58 UTC**. PR #44 merged at **08:46 the same
day**. The links were pointing at the wrong revision within seventy-two minutes
of the page going live.

### Expected Behavior

- Every image reference is a complete reference that resolves to the image OKDP
  actually deploys, in one notation, so a reader can copy any of them without
  first working out which registry was left implicit and which was lost.
- Following **Package definition** shows the manifest **as it was when the
  inventory was generated**: the same file, at the same commit, that produced the
  version in the row above the link.

The page and its links should describe one consistent moment.

### Actual Behavior

**A.** Three notations, and two references that resolve to a registry the image is
not on. Ten of the twenty-two references are missing a registry host; in eight
cases Docker Hub is the correct default and the reference works anyway, and in two
it is the wrong default and the reference fails. Nothing distinguishes the two
cases visually, which is the part that matters. The page gives no signal about
which of its bare references are safe to trust.

**B.** The versions on the page are frozen at `082e702` / `12bb63a`. The links are
not. They follow `main`, so what a reader sees after clicking drifts away from
what they clicked on, silently. Two consequences, the first already realised:

1. **The page stops being self-consistent.** A reader checking JupyterHub's
   `4.3.3-p06` against the linked manifest finds `4.3.3-p07`, and an image listed
   on the page that is absent from the file the page sent them to. The reasonable
   conclusion is that the inventory is wrong, when it is accurate for the release
   it describes, and only the link is at fault.
2. **The links break outright on a rename.** A `blob/main/` URL is valid only
   while the path exists on `main`. Package manifests have already been moved
   once: `seaweedfs` sits under `packages/services/` in `sandbox-dependencies` while
   its siblings are under `packages/system/`. A SHA link keeps working regardless.

Defect B matters more once `/stack/<version>` holds several releases. A 1.0 page
and a 1.1 page would link to the same `main` file from two different sets of
versions, and at most one of them could be right.

### Environment

- `OKDP/okdp.io` `master` at `da8795d` (2026-09-09), the merge of #44
- Generated data: `src/data/stack/okdp-1-0.yaml`, stack `1.0`, 27 components
- Built from `platform-packages` `082e702` and `sandbox-dependencies` `12bb63a`
- `scripts/build-stack.mjs`: `readModule()` line 247 (defect A),
  `OKDP_IMAGE_PREFIXES` line 64 (defect A), line 429 vs line 468 (defect B)
- Affected source manifests: `sandbox-dependencies`
  `packages/system/keycloak/keycloak.yaml` (2 references, broken) and
  `platform-packages` `packages/services/trino/trino.yaml` (2 references,
  `registry: docker.io`, harmless to drop)

A repository-wide search finds exactly **four** `registry:` keys across both
package repos, so the parsing gap is fully bounded:

```console
$ gh search code 'registry:' --repo OKDP/sandbox-dependencies --repo OKDP/platform-packages
packages/services/trino/trino.yaml      registry: docker.io   (×2)
packages/system/keycloak/keycloak.yaml  registry: quay.io     (×2)
```

### Logs

Not applicable to either defect. `build-stack.mjs` completes without warnings:
the regex simply does not match `registry:`, so nothing signals that information
was dropped. The `main` links are well-formed URLs that resolve with HTTP 200;
they resolve to the wrong revision, which nothing can detect automatically.

### Anything else we need to know?

**These are website bugs, not packaging bugs.** The manifests are correct: the
Bitnami chart genuinely takes `registry` and `repository` as separate values, and
`image: postgres:16-alpine` in an init container is ordinary Kubernetes. It is the
inventory's flattening step that loses information and then mixes conventions.

**Suggested fix for A.** Read `registry:` when present, then normalise every
image reference to a fully-qualified form at build time:

| Today | After |
|---|---|
| `postgres:16-alpine` | `docker.io/library/postgres:16-alpine` |
| `trinodb/trino:480` | `docker.io/trinodb/trino:480` |
| `okdp/sandbox-images/keycloak:26.1.3-…` | `quay.io/okdp/sandbox-images/keycloak:26.1.3-…` |
| `quay.io/okdp/superset:6.0.0-dockerize` | unchanged |

Normalising rather than trimming is the right direction for a page whose purpose
is to be authoritative. `docker.io/library/` is more verbose than `postgres`, but
it is unambiguous, and the alternative, trimming the twelve good references down
to short form, would make the two broken ones indistinguishable from correct
output instead of fixing them. Once references are qualified, the `"okdp/"` entry
in `OKDP_IMAGE_PREFIXES` can go: `quay.io/okdp/` already matches the normalised
Keycloak references, so provenance badges come out identical.

For charts, print the `repository` that is already in the data, in one shape for
all of them: `name version (repository)`. Giving the OCI charts the image form
instead would make them indistinguishable from the container images beside them,
which is a fresh version of the same problem rather than a fix. The primary chart
and image should also stop being filtered out of the panel, since the summary
columns they supposedly duplicate cannot show a repository.

**Suggested fix for B.** One interpolation, using a value already computed and
already written into the same output file:

```diff
-          source: `https://github.com/OKDP/${repoName}/blob/main/${relative(sources[repoName].path, file)}`,
+          source: `https://github.com/OKDP/${repoName}/blob/${sources[repoName].head}/${relative(sources[repoName].path, file)}`,
```

**Worth deciding alongside B:** whether `build-stack.mjs` should refuse to generate
from a checkout that is not level with its remote. It already warns:
`checkLocal()` prints `warn: <repo> is not level with main`. But the warning is
easy to miss, and pinning links to a local SHA that was never pushed would produce
URLs that 404 for everyone else. Turning that warning into a hard failure, with an
opt-out flag for local previews, becomes more valuable once the SHA is
load-bearing rather than decorative.

**Unrelated but adjacent:** the committed `okdp-1-0.yaml` still carries 27 `logo:`
keys, although `d71d554` removed `logo` from the script, the metadata, the types
and the lib. The artifact was never regenerated after that commit. Whatever fixes
the above regenerates the file and clears them as a side effect.
