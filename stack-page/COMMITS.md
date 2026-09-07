# Reproducing the work commit by commit

Four commits, `2673 insertions`. That number is misleading: **1112 of those lines
are produced by a command, not typed.** What actually has to be written by hand
is closer to 1200 lines, almost all of it in new files.

| | Lines | How it comes into being |
| --- | ---: | --- |
| `src/data/stack/okdp-1-0.yaml` | 1093 | `node scripts/build-stack.mjs` |
| `package-lock.json` | 19 | `npm install --save-dev yaml` |
| Everything else | ~1560 | written by hand |

Work through the four commits in order. Each section lists the commands to run,
the files to create, and the exact edits to existing files.

## If you would rather not retype anything

`patches/` in this folder holds the four commits as patch files:

```sh
git am /Users/scalp/okdp-live/stack-page/patches/*.patch
```

Or take a single one:

```sh
git am patches/0002-fix-stack-clone-from-OKDP-by-default-and-guard-stale.patch
```

The branch is also on the fork already, so
`git switch feat/stack-inventory` after cloning gets you the finished state.
Use this document when you want to understand or rebuild it, not to save typing.

---

# Commit 1 of 4

```
feat(stack): generate the OKDP component inventory
```

**5 files, 1661 insertions.** Only 548 lines are hand-written.

### Step 1. Add the one dependency

```sh
npm install --save-dev yaml
```

This edits `package.json` and `package-lock.json` for you. The `package.json`
change is a single line:

```diff
   "devDependencies": {
     "prettier": "3.9.6",
     "prettier-plugin-astro": "0.14.1",
-    "prettier-plugin-tailwindcss": "^0.8.1"
+    "prettier-plugin-tailwindcss": "^0.8.1",
+    "yaml": "^2.9.0"
   }
```

`yaml` is dev-only and pure JavaScript with no install script, so it needs no
entry in the repo's `allowScripts` guard.

### Step 2. Create the generator

**`scripts/build-stack.mjs`**, 419 lines at this commit (it grows to 500 by
commit 4). Reads the 27 KubOCD Package manifests and flattens them into one data
file.

Its shape, top to bottom:

| Section | Job |
| --- | --- |
| `REPOS` constant | the two package repos, their registries, and which section each folder maps to |
| `parseArgs` | `--stack`, `--out`, `--repo` |
| `resolveSources` | clone or locate each package repo |
| `walk` | find every `.yaml` under `packages/` |
| `readModule` | pull chart and image coordinates out of one module |
| `selectPrimary` | decide which chart and image *are* the component |
| `provenanceOf` | upstream chart / OKDP chart / OKDP image |
| `upstreamVersionOf` | the version a reader wants, e.g. Trino 480 |
| `collect` | loop the packages, assemble the components |
| write | serialise to YAML, print counts and warnings |

### Step 3. Create the metadata file

**`scripts/stack-metadata.yaml`**, 129 lines. Hand-written, one entry per
component, holding only what cannot be derived: display name, homepage, logo,
and the two version overrides for `trino` and `keycloak`.

### Step 4. Generate the data

```sh
node scripts/build-stack.mjs --stack 1.0
```

This writes **`src/data/stack/okdp-1-0.yaml`**, 1093 lines. Never edit it by
hand. Expected output:

```
27 components  data-services=11 dependencies=14 control-plane=2
warn: okdp-examples: derived upstream 1.2.0 from image ..., package tag suggests 1.3.0
```

That warning is real and still unresolved. See the open questions in `README.md`.

---

# Commit 2 of 4

```
fix(stack): clone from OKDP by default and guard stale local checkouts
```

**1 file, 68 insertions, 14 deletions.** All in `scripts/build-stack.mjs`. The
smallest commit to reproduce by hand, and worth understanding.

### Why

The first version looked for the package repos as sibling directories. Pointed
at a local checkout 74 commits behind `main`, it silently produced **38**
components instead of 27, because that checkout still contained `trinodb`,
`okdp-server` and `okdp-ui` from before the repo split. It parsed fine and gave
the wrong platform.

### The changes

1. **Drop `--clone`, make cloning the default.** Remove `clone` from `parseArgs`.
   `resolveSources` now clones from OKDP unless `--repo` names a local checkout.
2. **Add `remoteOf(path)`** returning the `origin` URL, or `null`.
3. **Add `sameRepo(a, b)`** comparing two remotes while ignoring protocol,
   credentials and a trailing `.git`.
4. **Add `git(path, ...args)`**, a small wrapper returning trimmed stdout or
   `null` on failure.
5. **Add `checkLocal(name, path, url)`** warning when a local checkout's origin
   is not the OKDP repo, and when its `HEAD` is not level with the remote's
   `main`, including how many commits behind.

The exact hunks are in `patches/0002-*.patch`.

---

# Commit 3 of 4

```
feat(stack): add the OKDP component inventory page
```

**14 files, 961 insertions.** The bulk of the work, and almost all of it new
files.

### New files, in dependency order

| File | Lines | What it is |
| --- | ---: | --- |
| `src/types/stack.ts` | 82 | TypeScript shapes: `StackComponent`, `Provenance`, `LocalizedStack` |
| `src/lib/stack.ts` | 85 | reads the collection, resolves locale, groups into sections, counts |
| `src/components/stack/ProvenanceBadge.astro` | 30 | one badge, coloured only when OKDP-authored |
| `src/components/stack/StackSection.astro` | 44 | section heading and column labels |
| `src/components/stack/ComponentRow.astro` | 188 | one row plus its expandable detail |
| `src/pages/[lang]/stack/index.astro` | 69 | the release list at `/stack/` |
| `src/pages/[lang]/stack/[version].astro` | 167 | the inventory page and the filter script |

Copy these from the branch. Retyping 665 lines of markup gains nothing.

### Edits to existing files

**`src/content.config.ts`**, +63. Import `glob` alongside `file`, then add a
`stacks` collection and register it:

```diff
-import { file } from "astro/loaders";
+import { file, glob } from "astro/loaders";
```

The collection uses `glob({ pattern: "*.yaml", base: "src/data/stack" })` with a
zod schema mirroring `src/types/stack.ts`, and is added to the exported
`collections` object next to `docs` and `events`.

**`src/i18n/en.json` and `src/i18n/fr.json`**, +69 each, purely additive.

- `nav.stack`, inserted directly after `nav.roadmap`
- a `stackPage` block after `roadmapPage`, holding meta, title, subtitle,
  summary, section titles, column labels, provenance labels, filter strings,
  detail labels, badges, copy button text, and an `index` sub-block

> Add these by hand or with a text splice. Do **not** rewrite the files with a
> JSON dump: Prettier preserves object wrapping in JSON, so a reformat expands
> unrelated pre-existing lines and turns a 69-line addition into a 124-line diff
> full of unrelated churn.

**`src/components/common/MarketingNavLinks.astro`**, +9:

```diff
 const docsUrl = getRelativeLocaleUrl(locale, "/guides/example");
+const stackUrl = getRelativeLocaleUrl(locale, "/stack/");
```

and a nav item after the roadmap one:

```diff
         {content.nav.roadmap}
       </a>
     </li>
+    <li>
+      <a
+        href={stackUrl}
+        class="hover:text-primary focus-visible:text-primary block rounded-lg px-3 py-2 whitespace-nowrap text-inherit no-underline transition-colors duration-200 hover:bg-current/8 focus-visible:bg-current/8"
+      >
+        {content.nav.stack}
+      </a>
+    </li>
```

**`README.md`**, +51. A `Stack inventory` section between `Build` and
`Preview deployments from forks`, covering how to regenerate, how to add a
release, and the `--repo` stale-checkout caveat.

**`scripts/build-stack.mjs`**, +37/-12. Emits richer source provenance: each
entry in `generated.sources` becomes `{sha, date, url}` instead of a bare SHA.
The date is written as a **quoted** scalar, because an unquoted `2026-09-04`
parses back as a timestamp and the collection schema rejects it.

**`src/data/stack/okdp-1-0.yaml`**, +10/-2. Not hand-edited. Re-run the script.

### Check it

```sh
npx prettier --write "src/**/*.{astro,ts,json}" scripts/
npm run format:check    # the CI gate
npm run build           # expect 4 new routes
```

---

# Commit 4 of 4

```
feat(stack): parse both package tag formats
```

**1 file, 13 insertions, 5 deletions.** Forward compatibility with the
release-please rework, which keeps the upstream version in the tag and drops the
`p` prefix: `3.5.1-p08` becomes `3.5.1-1.0.0`.

In `scripts/build-stack.mjs`, replace the single-format strip with a constant
covering both:

```diff
-  const derived = pkg.tag.replace(/-p\d+$/, "");
+const PACKAGE_SUFFIX = /-(?:p\d+|\d+\.\d+\.\d+)$/;
+
+function upstreamVersionOf(pkg, primary, override) {
+  const derived = pkg.tag.replace(PACKAGE_SUFFIX, "");
```

and update the doc comment above it to describe both shapes.

### Check it

Regenerating after this change must produce **no diff**, because today's tags
all still use `-pNN`:

```sh
node scripts/build-stack.mjs --stack 1.0
git diff src/data/stack/     # expect nothing
```

Both shapes resolve identically:

| Tag | Version shown |
| --- | --- |
| `3.5.1-p08` | `3.5.1` |
| `3.5.1-1.0.0` | `3.5.1` |
| `1.3.0-incubating-1.0.0` | `1.3.0-incubating` |
| `0.3.0-snapshot-1.0.0` | `0.3.0-snapshot` |

---

# Final verification

With all four applied:

```sh
npm ci
npm run format:check     # CI gate, must pass
npm run build            # CI gate, 14 pages
npm run dev              # open /en/stack/okdp-1-0
```

Expected: 27 components in 11 / 2 / 14, the summary line reading
`27 components · 12 upstream charts used unmodified`, Trino showing `480` and
Keycloak showing `26.1.3`.

One pre-existing build warning, `/404.htmlEntry docs → 404 was not found`,
appears with or without these changes.
