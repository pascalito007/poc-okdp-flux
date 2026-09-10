# PR: `OKDP/okdp.io`, follow-ups from the #44 review

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> One PR, ten commits, closing both follow-up issues. About 100 hand-written
> lines across 7 files, plus a regenerated data file.
> Written against `OKDP/okdp.io` `master` at `da8795d` (the merge of #44).
> **Status: applied and verified on branch `feat/stack-inventory-followups`,
> not pushed.** Ten commits, `origin/master..HEAD`. The site builds, Prettier is
> clean, every commit builds independently, and the generated diff was checked
> line-class by line-class. See "What was verified".
> The design question is **resolved: neither option**. The notice renders as
> plain text, with no badge anywhere. See "The design question".

### Branch

```
feat/stack-inventory-followups
```

### Title

```
feat(stack): pin source links, qualify image references, flag retired components
```

`feat:` because it is the highest type present. **Type of Change** ticks both
*Bug fix* and *New feature*; the template allows it.

### Commits

Ten, each conventional on its own. `conventional-commits.yml` validates every
commit in the pull request, not just the title. This is where reviewability lives:
three of them are a handful of lines, and the large mechanical diff is isolated in
the last one so nobody has to read it.

```
352b4b3  fix(stack): pin package definition links to the commit the inventory was built from
996b125  fix(stack): read the registry key and fully qualify every image reference
be77738  feat(stack): carry a per-component notice through the inventory
8407d1d  chore(stack): drop the dead pre-release badge leftovers
5b4ca47  chore(stack): regenerate the 1.0 inventory
2456706  fix(stack): show the retired-upstream notice as plain text
cb44d71  fix(stack): qualify chart references and stop hiding the primary chart
98b1768  fix(stack): drop the module name when a component renders one module
4955698  fix(stack): match image blocks where pullPolicy separates repository from tag
8d7804d  fix(stack): list references flat, one full reference per line
```

The last three came out of a second review pass: drop the notice badge, finish
the qualification job on charts as well as images, and stop printing a module
name that says nothing.

Every one of them builds on its own, checked by walking the branch and running
`npm run build` at each, so the history stays bisectable.

### Body

```markdown
## Description

Three follow-ups from the #44 review, plus the leftovers that surfaced while
checking them.

### Package definition links followed `main`

`/stack/<version>` is a snapshot. It records the commits it was generated from,
and the footer's **Built from** links use them. Every per-component **Package
definition** link ignored them and pointed at `main` instead.

This is already visible. JupyterHub's row states package tag `4.3.3-p06` and
lists a `minimal-notebook` image; the linked manifest on `main` says `4.3.3-p07`
and no longer contains that image. `platform-packages` moved 72 minutes after
#44 merged.

The SHA was already in scope at the call site: line 429 reads
`sources[repoName].path` and simply did not read `.head`.

### Image references were in three notations, and two were wrong

The modules panel prints `repository:tag`, which reads as something you can
`docker pull`. Of 22 distinct references: 12 were fully qualified, 8 were Docker
Hub short forms that resolve correctly by default, and **2 were neither**.

`keycloak.yaml` splits the registry from the repository, as Bitnami charts do:

    image:
      registry: quay.io
      repository: okdp/sandbox-images/keycloak
      tag: 26.1.3-debian-12-r0

The extraction regex paired `repository:` with `tag:` and discarded `registry:`,
so the site published `okdp/sandbox-images/keycloak:26.1.3-debian-12-r0`, a
quay.io path with the host removed, indistinguishable from a Docker Hub
reference and resolving to one, where it does not exist.

Every reference is now normalised to a fully-qualified form:

| Before | After |
|---|---|
| `postgres:16-alpine` | `docker.io/library/postgres:16-alpine` |
| `trinodb/trino:480` | `docker.io/trinodb/trino:480` |
| `okdp/sandbox-images/keycloak:26.1.3-…` | `quay.io/okdp/sandbox-images/keycloak:26.1.3-…` |
| `quay.io/okdp/superset:6.0.0-dockerize` | unchanged |

Normalising rather than trimming is deliberate. Trimming the 12 good references
to short form would make the 2 broken ones blend in instead of standing out; the
page's job is to be the authoritative record of a release, so unambiguous beats
terse.

The charts beside them needed the same treatment. They printed a bare name and
version, so Platform tools read `replicator · kubernetes-replicator 2.9.2` next
to fully-qualified image references: the same inconsistency, one column over.
Every chart already carried its repository in the generated data and the
template discarded it. Charts now take one shape, whatever they are published
to:

    keycloak 24.4.11 (registry-1.docker.io/bitnamicharts/keycloak)
    reloader 1.0.72 (https://stakater.github.io/stakater-charts)

Giving the OCI ones the `repository:tag` form instead was tempting, since that
is how Helm addresses them, but it made a chart indistinguishable from a
container image: Keycloak would list a Bitnami chart and two OKDP images as
three identical-looking strings. A chart is a different kind of thing from an
image, so it reads like one.

The primary chart is also no longer filtered out of the panel. It was excluded
as duplication of the Chart column, but that column has room for a name and a
version and not for a repository, so the exclusion left the primary chart's
source printed nowhere at all. That is why Platform tools listed replicator and
secret-generator but not reloader, and why CloudNativePG had no modules section.
62 references now render across the page, 40 charts and 22 images, none of them
a bare name and none ambiguous about which it is.

The `"okdp/"` entry in `OKDP_IMAGE_PREFIXES` goes away with it. It existed only
so `isOkdpImage()` still recognised the registry-stripped Keycloak references:
a workaround for this bug, and a latent false positive for any real Docker Hub
image in an `okdp` namespace. Normalised references match `quay.io/okdp/`, so
every provenance badge is byte-identical before and after.

### Ingress NGINX is flagged as retired

The page listed Ingress NGINX like any other dependency. The Kubernetes project
retired it on 19 March 2026: no further releases, no bugfixes, and no fixes for
any vulnerability found from that date on.

OKDP 1.0 ships it deliberately. The team agreed the controller stays as-is for
1.0, with the migration decided after v1. The decision is sound; presenting it
as an ordinary dependency is not. Someone evaluating or auditing OKDP should
learn this from the inventory rather than from a CVE feed.

A component may now carry an optional notice. It is data, not markup:
`stack-metadata.yaml` already exists for curated facts that cannot be derived
from the manifests, so the notice lives there and travels through
`build-stack.mjs` → `StackComponent` → `ComponentRow.astro`. Wording sits in
`src/i18n/{en,fr}.json` under `stackPage.notices.*` and is translated like
everything else.

    ingress-nginx:
      name: Ingress NGINX
      upstream: https://github.com/kubernetes/ingress-nginx
      notice:
        level: warning
        key: ingress-nginx-retired

It renders as plain text in the expanded panel, with no badge or label.
`d71d554` removed the pre-release badge from the summary row and nothing here
puts one back: the sentence carries the meaning on its own.

One component uses it today. The next costs three lines of YAML and one
translation.

### Leftovers from `d71d554`

`d71d554` removed the logo and the pre-release badge but left the scaffolding:
`ComponentRow.astro:16` still computed an `isPrerelease` that nothing read, and
`badges.prerelease` was still in both locale files with no consumer.

It also left `logo` **required** in the content collection schema
(`src/content.config.ts`), while removing it from the script, the metadata, the
types and the lib. That is why the committed `okdp-1-0.yaml` still carried 27
`logo:` keys: regenerating the file would have failed the build, so the artifact
was left stale instead. The schema is fixed here, which is what lets the
generated file match its generator again. No rendering change, since nothing has read
`logo` since `d71d554`.

## Related Issue

Fixes #<generated-data defects issue>
Fixes #<ingress-nginx notice issue>

## Type of Change

- [x] Bug fix
- [x] New feature
- [ ] Documentation update
- [ ] Refactor / chore
- [ ] Breaking change

## How to Test

1. **Regenerate and diff.** Regenerate at the *pinned* sources, not the current
   branch heads, so the diff carries no content change:

       node scripts/build-stack.mjs --stack 1.0 \
         --repo platform-packages=<worktree at 082e702> \
         --repo sandbox-dependencies=<worktree at 12bb63a>

   `git diff src/data/stack/okdp-1-0.yaml` shows exactly four kinds of change,
   and this was verified by classifying every changed line:

   | Count | Change |
   |---|---|
   | 27 | `links.source` moved from `blob/main/` to `blob/082e702…/` |
   | 10 | image references gained a registry host |
   | 27 | stale `logo:` keys removed |
   | 27 | `notice:` emitted, 1 populated and 26 `null` |

   Nothing else. No `upstreamVersion`, no `package.tag`, no `provenance`, no
   `name` and no `section` moves.

2. **The two broken references now resolve.** Before, `okdp/sandbox-images/keycloak`
   is a Docker Hub path that 404s; after, `quay.io/okdp/sandbox-images/keycloak`
   is the public repository the image is actually on:

       curl -s -o /dev/null -w "%{http_code}\n" \
         https://hub.docker.com/v2/repositories/okdp/sandbox-images/keycloak/   # 404
       curl -s https://quay.io/api/v1/repository/okdp/sandbox-images/keycloak | head -c 40

3. **Follow a link.** Expand JupyterHub, follow **Package definition**: it lands
   on the manifest at `082e702`, where `tag: 4.3.3-p06` matches the row.

4. **Provenance is unchanged.** Keycloak still shows **Upstream chart** and
   **OKDP image**. This is the one thing the `OKDP_IMAGE_PREFIXES` edit could
   plausibly break.

5. **The notice renders, in both locales.** `/en/stack/okdp-1-0/` and
   `/fr/stack/okdp-1-0/`: expand Ingress NGINX, confirm the callout is plain text
   with no badge or label, and that the FR page is not showing English. No other
   component gained one.

6. **No bare references anywhere.** Expand Platform tools: all three modules
   appear, each with its Helm repository. Expand CloudNativePG: it now has a
   modules section. Across the page, 62 references render and none is a bare
   name.

7. **Nothing regressed from the cleanup.** No component shows a pre-release badge
   (none did after `d71d554`), and `grep -r prerelease src/` returns nothing.

8. **Build.** `npm run build` clean, `npm run format:check` clean.

## Checklist

- [x] I have tested my changes
- [ ] Documentation updated if needed
- [ ] If breaking change: migration path described above
- [x] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [x] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
```

---

## The design question, resolved: neither option

`d71d554` deliberately removed the pre-release badge from the summary row, so
this was a reversal either way and worth asking rather than assuming.

| | Where the notice appears | Verdict |
|---|---|---|
| **A** | Expanded panel only | closer, but still opened with a bold label |
| **B** | Panel and a marker in the summary row | tried first, rejected on review |
| **C** | Panel, plain text, no label or marker | **shipped** |

Option B went in first and was rejected: the flag added no information the
sentence did not already carry, and a state exactly one component is in is not
worth colour-coding. The label string is gone from both locale files too, so the
notice is a `text` and nothing else.

That also settles the data model question the other way from how it started. A
`level` field is still on the type, unused by the template today, and the honest
options are to keep it for a future notice that genuinely needs distinguishing or
to drop it. It is kept, because dropping it is a one-line change later and adding
it back means touching the schema, the script and the metadata again.


## Commit 1: pin the source links

`scripts/build-stack.mjs`, line 429. One interpolation, using a value the same
object already carries and the footer already writes:

```diff
         links: {
           upstream: meta.upstream ?? null,
-          source: `https://github.com/OKDP/${repoName}/blob/main/${relative(sources[repoName].path, file)}`,
+          source: `https://github.com/OKDP/${repoName}/blob/${sources[repoName].head}/${relative(sources[repoName].path, file)}`,
         },
```

For comparison, the footer at line 468, which was always right:

```js
url: `${REPOS[name].url.replace(/\.git$/, "")}/tree/${source.head}`,
```

## Commit 2: read `registry:`, qualify everything

`scripts/build-stack.mjs`, `readModule()` at lines 246-253. The first regex gains
an optional `registry:` line before `repository:`; both push through a normaliser.

```diff
-  const values = typeof module.values === "string" ? module.values : "";
-  for (const [, repository, tag] of values.matchAll(
-    /repository:\s*"?([\w./-]+)"?\s*\n\s*tag:\s*"?([\w.-]+)"?/g,
-  )) {
-    entry.images.push({ repository, tag: String(tag) });
-  }
+  const values = typeof module.values === "string" ? module.values : "";
+  // Charts split the host from the path (`registry:` + `repository:`, the
+  // Bitnami convention) as often as they inline it. Dropping the host silently
+  // turns a quay.io path into a Docker Hub one that does not exist.
+  for (const [, registry, repository, tag] of values.matchAll(
+    /(?:registry:\s*"?([\w.:-]+)"?\s*\n\s*)?repository:\s*"?([\w./-]+)"?\s*\n\s*tag:\s*"?([\w.-]+)"?/g,
+  )) {
+    entry.images.push({
+      repository: qualify(repository, registry),
+      tag: String(tag),
+    });
+  }
   for (const [, ref] of values.matchAll(
     /image:\s*"?([\w./-]+:[\w.-]+)"?\s*$/gm,
   )) {
     const index = ref.lastIndexOf(":");
     entry.images.push({
-      repository: ref.slice(0, index),
+      repository: qualify(ref.slice(0, index)),
       tag: ref.slice(index + 1),
     });
   }
```

The normaliser, alongside the other small helpers:

```js
/**
 * Expands an image repository to its fully-qualified form.
 *
 * A reference on the page reads as something to `docker pull`, so it has to name
 * its registry. Manifests leave that implicit three different ways: an explicit
 * `registry:` key beside `repository:`, a Docker Hub namespace (`trinodb/trino`),
 * or a bare official image (`postgres`). Only the first is dangerous: dropping
 * an explicit `quay.io` produces a Docker Hub path that resolves to nothing.
 */
function qualify(repository, registry) {
  if (registry) return `${registry.replace(/\/$/, "")}/${repository}`;
  const [head] = repository.split("/");
  if (head.includes(".") || head.includes(":") || head === "localhost") {
    return repository;
  }
  return repository.includes("/")
    ? `docker.io/${repository}`
    : `docker.io/library/${repository}`;
}
```

And the prefix list at line 64, which no longer needs its workaround:

```diff
 const OKDP_CHART_PREFIXES = ["quay.io/okdp/charts/"];
-const OKDP_IMAGE_PREFIXES = ["quay.io/okdp/", "okdp/"];
+const OKDP_IMAGE_PREFIXES = ["quay.io/okdp/"];
```

## Commit 3: per-component notices

### `src/types/stack.ts`

```diff
 export type SectionId = "data-services" | "control-plane" | "dependencies";
+
+/** A curated caveat about a component, keyed into the locale files. */
+export interface Notice {
+  level: "info" | "warning";
+  key: string;
+}
```

```diff
   modules: ModuleRef[];
   links: { upstream: string | null; source: string };
+  notice: Notice | null;
 }
```

### `scripts/stack-metadata.yaml`

```diff
   ingress-nginx:
     name: Ingress NGINX
     upstream: https://github.com/kubernetes/ingress-nginx
+    # Retired by the Kubernetes project on 19 Mar 2026: no releases, no bugfixes,
+    # no security updates. Shipped in 1.0 by decision; migration decided post-v1.
+    notice:
+      level: warning
+      key: ingress-nginx-retired
```

The file's header comment already says it holds what cannot be derived from the
manifests, but it enumerates "display names, project homepages", worth extending
to mention notices.

### `scripts/build-stack.mjs`

Alongside the other `meta.*` reads, near line 427:

```diff
         links: {
           upstream: meta.upstream ?? null,
           source: `…`,
         },
+        notice: meta.notice ?? null,
```

### `src/i18n/en.json`

```diff
     "details": { … },
-    "badges": { "prerelease": "Pre-release" },
+    "notices": {
+      "ingress-nginx-retired": {
+        "label": "Retired upstream",
+        "text": "The Kubernetes project retired Ingress NGINX in March 2026; it receives no further releases, bugfixes or security updates. OKDP 1.0 ships it deliberately and existing deployments keep working. The migration path, whether Gateway API or another controller, will be decided after 1.0."
+      }
+    },
     "copy": { "label": "Copy", "done": "Copied" },
```

### `src/i18n/fr.json`

```diff
     "details": { … },
-    "badges": { "prerelease": "Pré-version" },
+    "notices": {
+      "ingress-nginx-retired": {
+        "label": "Abandonné en amont",
+        "text": "Le projet Kubernetes a mis fin à Ingress NGINX en mars 2026 : plus aucune version, correction de bogue ni mise à jour de sécurité. OKDP 1.0 l'embarque délibérément et les déploiements existants continuent de fonctionner. La stratégie de migration, Gateway API ou un autre contrôleur, sera décidée après la 1.0."
+      }
+    },
     "copy": { "label": "Copier", "done": "Copié" },
```

The `badges.*` removal above is commit 4's, shown here so the resulting shape is
readable in one place.

### `src/components/stack/ComponentRow.astro`

The callout, at the top of the expanded panel above the description. This is the
final shape, after commit 6 stripped the label; the version that first went in
had a bold `{notice.label}` opening it and a matching badge in the summary row.

```diff
   <div class="bg-background-alt border-accent border-t px-4 py-4 md:ps-11">
+    {
+      notice && (
+        <div class="mb-4 max-w-3xl rounded border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900">
+          {notice.text}
+        </div>
+      )
+    }
     {
       component.description && (
```

`HomeTranslations` is `typeof en`, so the key needs narrowing before it can index
`copy.notices`. `fr.json` is checked against the same shape by the `satisfies`
in `translations.ts`, which is what guarantees the French string exists:

```ts
const notice = component.notice
  ? copy.notices[component.notice.key as keyof typeof copy.notices]
  : null;
```

## Commit 4: the `d71d554` leftovers

`ComponentRow.astro`, the variable whose consumer was removed:

```diff
-const isPrerelease = /-(snapshot|rc|alpha|beta|incubating)/i.test(
-  component.upstreamVersion,
-);
-
```

and `badges.prerelease` out of both locale files, as shown in commit 3.

The third leftover, `logo` still **required** in `src/content.config.ts`, lands
in commit 5 instead, because the schema and the data it validates have to move
together for every commit to keep building.

## Commit 5: regenerate, and unblock the schema

`src/content.config.ts` still required `logo`, which `d71d554` had removed
everywhere else. That is why the data file had gone stale: regenerating it would
have failed the build. The build caught this immediately.

```diff
         links: z.object({
           upstream: z.string().nullable(),
           source: z.string(),
         }),
-        logo: z.string().nullable(),
+        notice: z
+          .object({
+            level: z.enum(["info", "warning"]),
+            key: z.string(),
+          })
+          .nullable(),
       }),
```

Then regenerate at the **pinned** sources, so the commit carries no content
change:

```
node scripts/build-stack.mjs --stack 1.0 \
  --repo platform-packages=<worktree at 082e702> \
  --repo sandbox-dependencies=<worktree at 12bb63a>
```

Running it without `--repo` clones the current default branches and would pick up
`f37c1fd`, silently advancing JupyterHub to `4.3.3-p07`. `checkLocal()` only
warns about a non-level checkout, so the pinning has to be deliberate.

Large, mechanical, and the reason it is last: 27 links repointed, 10 references
qualified, 27 `logo:` keys dropped, 27 `notice:` keys added. Nothing in it should
be read line by line, and nothing in it is hand-edited.

## Commit 6: drop the notice badge

Both the summary-row marker and the bold label opening the callout are removed,
leaving the text alone, and the now-unused `label` string goes from both locale
files. The notice entry becomes a `text` and nothing else:

```diff
     "notices": {
       "ingress-nginx-retired": {
-        "label": "Retired upstream",
         "text": "The Kubernetes project retired Ingress NGINX in March 2026; …"
       }
     },
```

`level` stays on the type and in the metadata, unused by the template. Keeping it
costs nothing; adding it back later would mean touching the schema, the script
and the metadata again.

## Commits 7, 8 and 10: the references list, arrived at in three passes

The panel's list went through three shapes under review. Only the last matters
for reading the diff; the first two are recorded because they explain why the
final one looks the way it does.

**Pass one (commit 7).** Images were fully qualified but the charts beside them
still printed a bare name and version, so Platform tools read
`replicator · kubernetes-replicator 2.9.2` next to fully-qualified references.
Charts gained their repository. The primary chart and image also stopped being
filtered out, since the summary columns they supposedly duplicated have room for
a name and a version but not a repository, which had left `reloader` missing from
Platform tools and CloudNativePG with no list at all.

**Pass two (commit 8).** The module name in front of each row was `main` on 18 of
the 27 components, distinguishing a single row from nothing. It was hidden where
only one row rendered.

**Pass three (commit 10), the shipped shape.** Module names go entirely. Which
module a reference belongs to is structure, not identity, and the package
definition carries it authoritatively. Every line is one full reference:

```
quay.io/okdp/charts/polaris-admin:1.0.0
polaris:1.3.0-incubating (https://downloads.apache.org/incubator/polaris/helm-chart/)
docker.io/apache/polaris:1.3.0-incubating
docker.io/curlimages/curl:8.18.0
quay.io/okdp/polaris-console:v0.1.1
```

Anything published to a registry is complete on its own. A chart served from a
Helm repository is not, so its repository follows it: the reference and its
website, nothing more.

```ts
const chartRef = (entry: ChartRef) =>
  entry.repository!.startsWith("http")
    ? `${entry.name}:${entry.version} (${entry.repository})`
    : `${entry.repository}:${entry.version}`;

const references = [
  ...new Set([
    ...component.charts
      .filter((entry) => entry.version && entry.repository)
      .map(chartRef),
    ...component.images.map((image) => `${image.repository}:${image.tag}`),
  ]),
];
```

Flattening also collapses duplicates that the module boundaries preserved:
Polaris used `polaris-admin` in both its bootstrap and principals modules and
listed it twice. 69 entries render, 67 distinct, every one matching
`repo:tag` or `name:version (url)`.

Local charts stay out throughout. They are vendored in the package repo and have
no reference to show.

The heading follows the content: **Included modules** becomes **Included
references** (**Références incluses**), and the i18n key moves from
`details.modules` to `details.references`, since it no longer describes modules
either.

**A shape that was tried and rejected:** giving OCI charts the plain
`repository:tag` form. It reads well until Keycloak, where a Bitnami chart and
two OKDP images then render as three identical-looking strings with nothing to
say which is which. The Helm-repository charts keeping a visible `(website)` is
what stops charts and images collapsing into one another.

## Commit 9: image blocks where `pullPolicy` separates `repository` from `tag`

Found while answering a question about the Polaris modules list. The extraction
regex required `tag:` on the line immediately after `repository:`, and charts
routinely write:

```yaml
image:
  repository: apache/polaris
  pullPolicy: IfNotPresent
  tag: "1.3.0-incubating"
```

Every one of those was dropped silently. **Five images were missing from the
inventory**, and two components rendered no images at all:

| Image | Component | Was |
|---|---|---|
| `docker.io/apache/polaris:1.3.0-incubating` | polaris | the Polaris server, invisible |
| `quay.io/okdp/spark:spark-3.5.6-scala-2.12-java-17` | spark-history-server | `images: []` |
| `quay.io/okdp/spark-web-proxy:0.2.1` | spark-history-server | `images: []` |
| `ghcr.io/cloudnative-pg/cloudnative-pg:1.29.1` | cloudnative-pg | `images: []` |
| `ghcr.io/cloudnative-pg/postgresql:18.3` | cnpg-postgresql | `images: []` |

Intervening keys are now allowed, but not another `repository:`, so two adjacent
image blocks can never be paired across. Bounded at four lines.

### Two provenance badges move, and the team should look at one of them

Provenance is derived from the primary chart and image. Picking up the missing
images corrected three primary images that were empty and one that was wrong, so
two badges follow:

| Component | Provenance was | now | Why |
|---|---|---|---|
| `spark-history-server` | `okdp-chart` | `okdp-chart`, `okdp-image` | it always shipped `quay.io/okdp/spark`; the image was invisible |
| `polaris` | `upstream-chart`, `okdp-image` | `upstream-chart` | its primary image is now `apache/polaris`, correctly, and only the console is an OKDP rebuild |

The first is plainly a correction. **The second is worth a decision.** Polaris
does rebuild `quay.io/okdp/polaris-console`, and the page no longer says so,
because provenance reads the primary image only and the primary image is now the
upstream server, which is the accurate answer to "what is Polaris". If the badge
is meant to answer "does OKDP rebuild anything in this package" then provenance
should look at every image and not just the primary one. That is a change to what
the column means, so it is not made here.

No `upstreamVersion` value changes; only `upstreamVersionSource` labels, from
`package tag` to the image they are now read from.

## The upstream facts behind the notice

Not "deprecated". Retired, and already past.

| | Chart | Controller | Date |
|---|---|---|---|
| OKDP 1.0 ships | `4.12.1` | `v1.12.1` | Mar 2025 |
| Upstream's final release | `4.15.1` | `v1.15.1` | 19 Mar 2026 |

- Announced Nov 2025: <https://www.kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/>
- Restated Jan 2026: <https://www.kubernetes.io/blog/2026/01/29/ingress-nginx-statement/>
- Final releases: <https://github.com/kubernetes/ingress-nginx/releases>

Two separate statements, and the notice makes only the first:

- *We ship a retired controller*: agreed, post-v1 migration.
- *We ship a version a year behind the last retired release*: not agreed
  anywhere. That is drift, it belongs in `OKDP/sandbox-dependencies`, and it is
  out of scope here.

## What was verified

Everything below was run, not predicted. The branch builds, Prettier is clean,
and each of the five commits builds on its own.

| Verification | Result |
|---|---|
| `npm run build` on the branch | **14 pages built, clean** |
| `npm run format:check` | **clean** |
| `npm run build` at each of the 10 commits | **all OK**, history is bisectable |
| Generated diff, every changed line classified | **27 / 10 / 27 / 27**, nothing else |
| Versions, tags, provenance, names, sections in the diff | **no changes** |
| Keycloak provenance after dropping the `okdp/` prefix | **`[upstream-chart, okdp-image]`**, unchanged |
| Keycloak `primaryImage` after normalisation | **`quay.io/okdp/sandbox-images/keycloak:26.1.3-debian-12-r0`** |
| `blob/main/` links left in the built HTML | **0** |
| JupyterHub link in the built HTML | **`blob/082e702…/…/jupyterhub.yaml`** |
| Notice badge in built HTML, either locale | **0 occurrences**, text only |
| Notice text renders | **EN and FR**, each once, in the expanded panel |
| `postgres` / `keycloak-config-cli` in built HTML | **`docker.io/library/postgres:16-alpine`**, **`quay.io/okdp/sandbox-images/keycloak-config-cli:6.4.0-…`** |
| References rendered in the panel, per locale | **69 entries, 67 distinct**, every one matching `repo:tag` or `name:version (url)`, EN and FR identical |
| Platform tools, the case the review named | all three modules shown, each with its Helm repository |
| Keycloak, the case the second review named | chart and images now visually distinct |
| CloudNativePG, previously no modules section | now shows its chart and repository |
| `grep -rn prerelease src/` | **no matches** |
| `logo` keys remaining in the data file | **0** |
| The `qualify()` rule against all 7 real manifest shapes | correct for each: explicit `registry:`, Docker Hub namespaced, Docker Hub official, and already-qualified |

And the facts the change rests on, checked against the real repositories and the
upstream announcements.

| Check | Result |
|---|---|
| Distinct image references in `okdp-1-0.yaml` | **22**: 12 qualified, 7 Docker Hub namespaced, 1 Docker Hub official, 2 registry-stripped |
| Every `registry:` key in both package repos | **4**: 2 in `trino.yaml` (`docker.io`, harmless), 2 in `keycloak.yaml` (`quay.io`, dropped) |
| `okdp/sandbox-images/keycloak` on Docker Hub | **HTTP 404** |
| `quay.io/okdp/sandbox-images/keycloak` on quay.io | **exists, public** |
| `library/postgres` on Docker Hub | **HTTP 200**, so `postgres:16-alpine` was pullable; only its notation was inconsistent |
| Components with `links.source` on `blob/main/` | **27 of 27** |
| Commits on `platform-packages` `main` past the pinned `082e702` | **1**: `f37c1fd`, which bumped `jupyterhub` `4.3.3-p06` → `p07` and removed an image the page lists |
| Components whose provenance depends on the bare `okdp/` prefix | **1** (`keycloak`), and it matches `quay.io/okdp/` once normalised |
| Ingress NGINX retirement | **19 Mar 2026**, final `helm-chart-4.15.1` / `controller-v1.15.1` |
| Chart version OKDP ships | **`4.12.1`** (`…/ingress-nginx:4.12.1-p03`), controller `v1.12.1`, Mar 2025 |
| `isPrerelease` after `d71d554` | computed at `ComponentRow.astro:16`, **never read** |
| `badges.prerelease` after `d71d554` | present in `en.json` and `fr.json`, **no consumer** |
| `logo` after `d71d554` | absent from script, metadata, types and lib; **27 keys** still in the committed data file |
| Components needing a notice today | **1** of 27 |

## Not in this PR

- **Refreshing the inventory to the current package heads.** Running the generator
  without `--repo` clones the default branches and would pick up `f37c1fd`,
  advancing JupyterHub from `4.3.3-p06` to `p07` and dropping the
  `minimal-notebook` image. That is a *content* change, a decision about what
  OKDP 1.0 contains, and it does not belong in a bugfix PR. It is regenerated at
  the pinned `082e702` / `12bb63a` instead, so this PR changes how the page links
  and names things and nothing about what it says. **Whether 1.0 should now pin
  `p07` is a separate question for the team.**

- **Bumping Ingress NGINX to chart `4.15.1`.** Different repository
  (`OKDP/sandbox-dependencies`) and a different decision. `4.15.1` is still
  retired; it just carries a year more fixes. The notice is needed either way.
- **The post-v1 migration.** Gateway API vs. another controller is the decision
  this notice exists to make visible, not to pre-empt.
- **A page-level banner for the notice.** One component out of 27; a banner would
  attach the warning to the whole release.
- **Making notice text searchable.** The filter haystack is built from name, id,
  version, tag, chart and description. Adding notice text is defensible but is a
  behaviour change to the filter, so it should be asked for rather than smuggled
  in.
- **Failing hard on a checkout that is not level with its remote.** `checkLocal()`
  warns today. Now that a SHA is load-bearing, generating from an unpushed commit
  would mint links that 404 for everyone else, worth turning into an error with
  an opt-out for local previews, but it is a behaviour change to the script's
  contract and deserves its own discussion.
