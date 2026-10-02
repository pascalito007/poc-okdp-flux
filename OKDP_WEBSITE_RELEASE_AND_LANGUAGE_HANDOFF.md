# OKDP website: release information and language navigation

Prepared for the **2 October 2026 contributors meeting**, revised to use a
**normal, manually coordinated website PR for each release update**.
Target: [`OKDP/okdp.io`](https://github.com/OKDP/okdp.io), branch **`master`**.

This file contains two issue drafts, two PR drafts, complete Git diffs and
application instructions. Copy it to the other laptop; it has no dependency on
the temporary checkouts used to prepare the changes.

The structure follows `~/okdp-live/stack-page-2/` and
`~/okdp-live/release-mechanism/`: title, paste-ready body, implementation and
verification. Drafts use the public organisation templates:

- [Feature request](https://github.com/OKDP/.github/blob/main/.github/ISSUE_TEMPLATE/feature_request.yml)
- [Pull request](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
- [Contributing](https://github.com/OKDP/.github/blob/main/CONTRIBUTING.md)

Templates were inspected at `.github` commit
`e0717ea5b9a947e69a1ed09875034b3b5d9138af`. The guide uses `main` generically;
this website uses **`master`**. Two PRs keep the concerns independently reviewable.

**Status:** the release change is committed locally as `1f86a73` on
`codex/current-release-summary` in `/tmp/okdp-review.aXsBOr/okdp.io`. Its working
tree is clean. Nothing was pushed, filed on GitHub or deployed. The embedded
patches let you recreate the changes and commits on the other laptop, then create
the issues and PRs yourself. The existing source checkout under
`~/okdp-live/okdp.io` remains untouched.

This revision replaces the earlier draft that included a release updater. Apply
the revised release patch to the recorded base, not on top of the old patch. The
prepared `/tmp/okdp-review.aXsBOr/okdp.io` checkout has already been updated. The
language patch is unchanged. If you previously extracted the patches, choose a
fresh output directory; the helper refuses to overwrite a different older file.

## Start here

| Order | Issue | PR / branch | Patch |
| --- | --- | --- | --- |
| 1 | Maintain homepage release information through website PRs | `feat(home): show manually maintained release information` / `codex/current-release-summary` | `release-summary.patch` |
| 2 | Use language names and preserve the page when switching languages | `fix(i18n): use language names and preserve the current page` / `codex/language-navigation` | `language-navigation.patch` |

Both patches start from website commit
`6f7478fee8cae668f10837489eec67d8c51ddb12` and touch disjoint files. They can be
reviewed and merged in either order.

1. Save the embedded patches and apply each on its own branch in your fork.
2. File the two issues with the **Feature Request** form, pasting each section
   into its matching field. GitHub supplies the `enhancement` label.
3. Create the PRs manually and replace `#RELEASE_ISSUE` and `#LANGUAGE_ISSUE`.
4. Review and submit the already prepared v1.1.0 change for the meeting.

PR checklist boxes remain unchecked for the submitter. Completed preparation
checks are listed below; the licence and copyright declarations are yours to make.

## Agreed behaviour

### Release information: a small manual edit

The homepage reads one record, `src/data/release.json`, shared by both languages:

```json
{
  "product": "OKDP Sandbox",
  "version": "1.1.0",
  "publishedOn": "2026-10-02",
  "notesUrl": "https://github.com/OKDP/okdp-sandbox/releases/tag/v1.1.0",
  "stackId": null
}
```

This record is already prepared for v1.1.0 and the 2 October release meeting.
For future releases, maintainers update the same fields through a website PR:

| Field | What to enter |
| --- | --- |
| `product` | The displayed product name, such as `OKDP Sandbox` or another OKDP component |
| `version` | Its version, without the `v` prefix |
| `publishedOn` | The actual publication date as `YYYY-MM-DD` |
| `notesUrl` | The matching release notes, in whichever repository or location hosts them |
| `stackId` | The verified inventory ID, or `null` when no corresponding inventory applies |

The team owns the choice of release and the timing of its website PR. There is
no GitHub lookup, release updater, scheduled synchronisation, or repository-specific
restriction. The site renders the committed record; ordinary build checks validate
its shape and any inventory reference.

The display is a compact current-release summary with a product name, version,
localized date and release-notes link. The inventory link is conditional. Its
association also determines the stack index's current badge. Existing inventories
remain accessible from Stack.

The original countdown and launch celebration are removed. There is no upcoming
release or “coming next” state. Historical roadmap milestones remain historical;
the homepage roadmap teaser becomes timeless.

### v1.1.0 is already prepared in this branch

The branch and embedded release patch already contain `OKDP Sandbox v1.1.0`,
`publishedOn: "2026-10-02"`, the exact v1.1.0 release-notes URL, and
`stackId: null`. Applying the patch and starting the dev server previews v1.1.0
immediately. No metadata edit or updater command is required to see it.

The release record uses 2 October 2026 for the meeting release. The branch is
ready to preview and submit with those values. There is no upcoming-release
banner or countdown.

There is no verified 1.1 inventory in this repository yet, so the homepage shows
the release-notes link without a stack CTA. Existing inventories remain available
through Stack, without incorrectly labelling 1.0 as the current 1.1 inventory.

Use `npm run dev` to inspect the prepared state; rebuild before `npm run preview`.
Merging the website PR triggers the existing deployment workflow. Check both
languages on the deployed homepage and stack index afterwards.

A release of a different OKDP product is the same edit: change its name, version,
date and notes URL. Use `stackId: null` when the stack inventory does not apply.
The record describes the product named on the card, not a common version inferred
across unrelated repositories.

The existing inventory generator is separate from this change. It reads package
repositories, so generating a new inventory from their moving branches is not
proof of what a particular release contains. Link an inventory after the team
has verified its contents; this handoff does not fabricate a 1.1 inventory.

### Language navigation

Show **Français | English**, with the active language visibly selected. Use the
existing locale names, `lang`, `hreflang`, `aria-current`, a labelled navigation
landmark and visible keyboard focus.

Switching from `/en/stack/okdp-1-0/` opens `/fr/stack/okdp-1-0/`. The same rule
applies to the roadmap and stack index, including fork-preview base paths.
This preserves page paths; query parameters, anchors and filter state are outside
this change.

The unused flag assets are removed. At narrow widths the header shows the logo
without its wordmark and hides the standalone GitHub icon so the full language
names and menu button fit. GitHub remains reachable in the Community section.
Starlight's documentation selector is separate from this marketing component.

## Issue 1 — manually maintained release information

**Repository:** `OKDP/okdp.io`  
**Template:** Feature Request (`enhancement`)

### Title

```text
Maintain homepage release information through website PRs
```

### Problem Statement

The homepage still presents the one-time v1.0.0 launch announcement. Its version
and publication date are embedded in both translation files, while its stack
button independently selects the newest inventory. This can make the advertised
version and link disagree.

As the project releases new versions, the team needs a straightforward way to
update the homepage in a normal website PR. The information may describe the
sandbox or a different OKDP product.

### Proposed Solution

Replace the launch announcement and countdown with a persistent release summary.
Store the product name, version, publication date, release-notes URL and optional
inventory association in one manually edited record shared by French and English.

Maintainers select the release and coordinate the website PR with its publication.
The notes link can point to the relevant product's repository. When an inventory
applies, use the explicit association for both the homepage link and the stack
index's current badge. Otherwise omit the inventory link.

Keep the existing static build and deployment workflow. The release information
requires no GitHub API call or maintenance script.

### Alternatives Considered

- Edit version-specific strings in both translations: duplicates release facts
  and makes inconsistencies easier to introduce.
- Infer the release from the highest inventory filename: an inventory file does
  not define which release the team wants to feature.
- Fetch or synchronise release information from one repository: unnecessarily
  constrains the editorial workflow when the team already coordinates website PRs.

### Additional Context

- Website: https://okdp.io/
- Component: `src/components/home/ReleaseBanner.astro`
- Translations: `src/i18n/en.json` and `src/i18n/fr.json`
- Stack index: `src/pages/[lang]/stack/index.astro`

Acceptance: one shared release record, explicit product and matching links,
localized date, ordinary manual PR updates, and no countdown or upcoming state.

## PR 1 — manually maintained release information

### Branch

```text
codex/current-release-summary
```

### Title

```text
feat(home): show manually maintained release information
```

### Body

Paste the following, replacing `#RELEASE_ISSUE`.

````markdown
## Description

Replace the one-time v1.0.0 launch announcement with a persistent release summary.
Both languages read the product name, version, publication date, release-notes URL
and optional stack association from one manually maintained record.

The team updates that record through ordinary website PRs, coordinating merges
with releases. The displayed product and notes URL support releases across OKDP
projects. The build validates the record and any referenced inventory.

Remove the countdown and launch-specific translations. The homepage inventory
link and the stack index's current badge use the same explicit association.
The branch includes the v1.1.0 record dated 2 October 2026, with no linked
inventory until one is verified. The README documents how to maintain the same
record for future releases.

## Related Issue

Fixes #RELEASE_ISSUE

## Type of Change

- [x] Bug fix
- [x] New feature
- [x] Documentation update
- [x] Refactor / chore
- [ ] Breaking change

## How to Test

1. Run `npm ci`, `npm run format:check` and `npm run build`.
2. Run `npm run preview`. Open `/`, `/en/` and `/fr/`. Check the product name,
   version, localized date and release-notes link against `src/data/release.json`.
   The launch celebration and countdown should be absent.
3. Use `npm run dev` and edit the record locally: change the product, version,
   date and notes URL, then set `stackId` to `null`. Confirm both languages reflect
   the edit and the homepage omits the inventory link. This should work without
   querying GitHub or requiring a published release for the local preview.
4. Check both stack indexes: only the explicitly associated inventory is labelled
   current; with `stackId: null`, none is. Existing inventories remain accessible.
5. Restore or enter the agreed publication values, review the diff and rebuild
   before merging. A nonexistent inventory ID should fail the build.

## Checklist

- [ ] I have tested my changes
- [ ] Documentation updated if needed
- [ ] If breaking change: migration path described above
- [ ] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [ ] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
````

### Files changed

| File | Change |
| --- | --- |
| `src/data/release.json` | Manually maintained product, version, date and links |
| `src/lib/release.ts` | Basic record validation and inventory lookup |
| `src/components/home/ReleaseBanner.astro` | Render the shared record in a compact summary |
| `src/components/home/Hero.astro` | Update the obsolete comment |
| `src/i18n/en.json`, `src/i18n/fr.json` | Generic labels and neutral roadmap teaser |
| `src/pages/[lang]/stack/index.astro` | Current badge follows the explicit association |
| `README.md` | Manual release-edit and preview instructions |

## Issue 2 — language navigation

**Repository:** `OKDP/okdp.io`  
**Template:** Feature Request (`enhancement`)

### Title

```text
Use language names and preserve the page when switching languages
```

### Problem Statement

The marketing header uses the UK and French flags to select English and French.
These languages are used across many countries, so country flags are ambiguous
language labels. The switcher also always links to a language's homepage: changing
language on a roadmap or stack page loses the page the visitor was reading.

### Proposed Solution

Replace the flags with the self-names `Français` and `English`, keeping the current
language visibly selected. Use ordinary links with `lang`, `hreflang`,
`aria-current`, a labelled navigation landmark and visible keyboard focus.

Switch to the equivalent localized page and retain the site's configured base
path, including fork previews. Keep the full names and menu button usable on small
screens. Remove the unused flag assets.

### Alternatives Considered

- Different country flags: still conflate language with territory.
- `FR | EN`: compact, but less explicit than the full names for two languages.
- A dropdown: adds an interaction that is unnecessary for two short options.

### Additional Context

- Component: `src/components/common/LocaleSwitcher.astro`
- Header: `src/components/common/Header.astro`
- Existing locale labels: `src/i18n/config.ts`
- [W3C internationalization guidance](https://www.w3.org/International/techniques/authoring-html)

Acceptance: no flags in the marketing language selector; clear selected language;
keyboard access; equivalent homepage, roadmap and stack destinations in both
languages; working fork-preview URLs; no narrow-header overflow.

## PR 2 — language navigation

### Branch

```text
codex/language-navigation
```

### Title

```text
fix(i18n): use language names and preserve the current page
```

### Body

Paste the following as the PR description, replacing `#LANGUAGE_ISSUE`.

````markdown
## Description

Replace the country flags with `Français` and `English`, using the existing locale
labels. Mark the selected language and provide language metadata, a labelled
navigation landmark and visible keyboard focus.

Switching languages now retains the page path: `/en/stack/okdp-1-0/` links to
`/fr/stack/okdp-1-0/` instead of the French homepage. URL generation accounts for
fork-preview base paths.

Remove the unused flag assets and adjust the narrow header to keep the full names
and menu button visible. Below the small breakpoint, the logo stands on its own
and the standalone GitHub icon is hidden; the Community section retains its
GitHub link.

## Related Issue

Fixes #LANGUAGE_ISSUE

## Type of Change

- [x] Bug fix
- [ ] New feature
- [ ] Documentation update
- [x] Refactor / chore
- [ ] Breaking change

## How to Test

1. Run `npm ci`, `npm run format:check` and `npm run build`, then
   `npm run preview`.
2. On `/`, `/en/` and `/fr/`, check that both full language names are visible and
   the selected language is identified. Navigate to the links with Tab and
   activate them with Enter.
3. Switch language in both directions on `/en/roadmap/`, `/en/stack/` and
   `/en/stack/okdp-1-0/`. The matching French page should open, and vice versa.
4. At a 320 CSS-pixel viewport, confirm the language links and menu button fit
   and remain usable. Check the wider desktop header as well.
5. Build a fork preview with the command below. Verify that the language links
   include the preview prefix once and retain the current page path.

   ```sh
   ASTRO_SITE=https://example.github.io \
   ASTRO_BASE=/okdp.io/previews/language-navigation/ npm run build
   ```

## Checklist

- [ ] I have tested my changes
- [ ] Documentation updated if needed
- [ ] If breaking change: migration path described above
- [ ] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [ ] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
````

### Files changed

- `src/components/common/LocaleSwitcher.astro`: text links and equivalent page URLs.
- `src/components/common/Header.astro`: responsive spacing and compact branding.
- `src/assets/flags/fr.svg`, `src/assets/flags/gb.svg`: delete unused assets.

## Transfer to the other laptop

Requirements: Git and Node/npm compatible with the repository. Python 3 is only
needed if you use the optional patch-extraction helper below. The existing
deployment workflow selects Node 22.12.0; preparation used Node 24.18.0.

### 1. Save the embedded patches

Copy each complete diff block at the end into its named `.patch` file, or use
the optional helper below. The helper only unpacks this document; it is not part
of the website or release process. Replace the input path and output directory.
It checks patch hashes before writing. Keep the transfer files outside the
website checkout.

```sh
python3 - /path/to/OKDP_WEBSITE_RELEASE_AND_LANGUAGE_HANDOFF.md /path/to/okdp-website-patches <<'PYTHON'
from pathlib import Path
import hashlib
import re
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
target = Path(sys.argv[2])
expected = {
    "release-summary.patch": "25618ab3d7437e92dafb8f140ecca930f16f5f5df037cbe897269a5842f6f1c7",
    "language-navigation.patch": "96dc5585427153ace383ec9dca7c5388d3bda400ce2012abe6ea397dfd0bc90a",
}
patches = {}
for name, digest in expected.items():
    pattern = (
        r"<!-- BEGIN PATCH " + re.escape(name) + r" -->\n```diff\n"
        r"(.*?)```\n<!-- END PATCH " + re.escape(name) + r" -->"
    )
    matches = re.findall(pattern, source, flags=re.S)
    if len(matches) != 1:
        raise SystemExit(f"Expected one complete patch block: {name}")
    data = matches[0].encode("utf-8")
    if hashlib.sha256(data).hexdigest() != digest:
        raise SystemExit(f"Hash mismatch: {name}; recover the unchanged document")
    patches[name] = data
for name, data in patches.items():
    path = target / name
    if path.exists() and path.read_bytes() != data:
        raise SystemExit(f"Refusing to overwrite different file: {path}")
target.mkdir(parents=True, exist_ok=True)
for name, data in patches.items():
    (target / name).write_bytes(data)
    print(f"Verified and wrote {target / name}")
PYTHON
```

### 2. Start from your fork

Replace `YOUR_LOGIN` with the GitHub account that owns your fork. These commands
assume a new local clone and leave the existing laptop's checkouts alone.

```sh
git clone https://github.com/YOUR_LOGIN/okdp.io.git okdp-website-review
cd okdp-website-review
git remote add upstream https://github.com/OKDP/okdp.io.git
git fetch upstream master
```

### 3. Apply the release patch

```sh
git switch -c codex/current-release-summary upstream/master
git apply --check /path/to/okdp-website-patches/release-summary.patch
git apply /path/to/okdp-website-patches/release-summary.patch
npm ci
npm run format:check
npm run build
git diff --check
git status --short
git add README.md src/data/release.json \
  src/lib/release.ts src/components/home/ReleaseBanner.astro \
  src/components/home/Hero.astro src/i18n/en.json src/i18n/fr.json \
  'src/pages/[lang]/stack/index.astro'
git diff --cached --stat
git commit -m "feat(home): show manually maintained release information"
```

The release patch already includes the v1.1.0 metadata. It is ready for review
and submission. Manual editing of the shared record is the process for future
release updates, not an unfinished step in this handoff.

### 4. Apply the language patch independently

After committing the release branch, start this one from upstream, not from the
release branch:

```sh
git switch -c codex/language-navigation upstream/master
git apply --check /path/to/okdp-website-patches/language-navigation.patch
git apply /path/to/okdp-website-patches/language-navigation.patch
npm run format:check
npm run build
git diff --check
git add src/components/common/Header.astro \
  src/components/common/LocaleSwitcher.astro src/assets/flags
git diff --cached --stat
git commit -m "fix(i18n): use language names and preserve the current page"
```

If `git apply --check` fails because upstream changed after the recorded base,
inspect the conflicting files before applying anything. The exact base above is
provided for reproduction; do not blindly force a patch onto a newer tree.

### 5. Publish manually when ready

Push the branches to your fork, then create PRs in the GitHub UI targeting
**`OKDP/okdp.io:master`**, using the two bodies above.

```sh
git push -u origin codex/current-release-summary
git push -u origin codex/language-navigation
```

No `gh issue create` or `gh pr create` command is needed. If the release PR was
already pushed before the meeting, push its additional metadata commit normally.

The existing fork preview workflow publishes non-master branches when GitHub
Pages is enabled on the fork. For example:

```text
https://YOUR_LOGIN.github.io/okdp.io/previews/codex-current-release-summary/en/
https://YOUR_LOGIN.github.io/okdp.io/previews/codex-language-navigation/fr/stack/okdp-1-0/
```

## What was verified during preparation

- The revised release change passes `npm run format:check` and `npm run build`.
- A separate verification checkout applied both patches and built with a non-root
  preview base using a synthetic record for a different product, a different
  release-notes host and no inventory. Both languages rendered the entered product,
  version, date and URL, and omitted the inventory link. This was a rendering
  fixture, not a claim that another release had been published.
- The release patch contains no updater script or GitHub API call. The source
  repository and product name are not enforced by the renderer.
- The language patch is unchanged from its prior verification: formatting/build
  passed; root, localized homepage, roadmap and stack links were checked with a
  preview prefix; browser navigation retained the stack page; the full names and
  menu button fit at 320 CSS pixels.
- Extracted patches are checked against SHA-256 and reapplied to clean checkouts
  of the recorded base. Their resulting trees are compared with the prepared
  sources. Both PR drafts retain the organisation template's section order.

The prepared record and patch show v1.1.0 dated 2 October 2026. Both localized
release cards were checked in the built HTML, including their release-notes URL
and the absence of a misleading 1.0 inventory link. Remote CI, deployment and
maintainer review remain part of your normal submission process.

## Complete Git diffs

These are ordinary `git apply` patches, including additions and deletions.
Keep the embedded diffs unchanged if you use the extraction helper, so their
hashes remain valid. Make your release-information edits in the checkout.

### Patch 1: `release-summary.patch`

<!-- BEGIN PATCH release-summary.patch -->
```diff
diff --git a/README.md b/README.md
index dfb918c..8fef3d2 100644
--- a/README.md
+++ b/README.md
@@ -32,6 +32,37 @@ npm run build
 npm run preview
 ```
 
+## Homepage release information
+
+Update `src/data/release.json` in a normal website PR when the team wants to
+feature a release. The same record supplies both the French and English homepage:
+
+```json
+{
+  "product": "OKDP Sandbox",
+  "version": "1.1.0",
+  "publishedOn": "2026-10-02",
+  "notesUrl": "https://github.com/OKDP/okdp-sandbox/releases/tag/v1.1.0",
+  "stackId": null
+}
+```
+
+Set the product name, version (without the `v` prefix), publication date
+(`YYYY-MM-DD`) and release-notes URL together. Maintainers choose the release and
+coordinate the website PR with its publication. The record can describe a sandbox
+release or another OKDP product; it is not tied to a repository or API.
+
+`stackId` is optional: use `null` for a release without a corresponding inventory.
+When present, it must identify a verified file in `src/data/stack/`, such as
+`okdp-1-0`. It controls the homepage's stack link and the stack index's current
+badge. Review this association when changing releases rather than retaining an
+old inventory accidentally. Historical inventories remain accessible from Stack.
+
+Preview with `npm run dev`. Before merging, run `npm run format:check` and
+`npm run build`, then inspect both languages. The build validates the record and
+any inventory reference; publication details and relevance are reviewed by the
+team. Merging the website PR triggers the existing deployment workflow.
+
 ## Stack inventory
 
 `/stack/<version>` lists every component shipped in an OKDP release, with its
diff --git a/src/components/home/Hero.astro b/src/components/home/Hero.astro
index 801aed6..8e90eeb 100644
--- a/src/components/home/Hero.astro
+++ b/src/components/home/Hero.astro
@@ -35,7 +35,7 @@ const docsUrl = getRelativeLocaleUrl(locale, "/installation-requirements");
         </a>
       </div>
 
-      <!-- v1.0.0 release announcement -->
+      <!-- Current release selected by the maintainers -->
       <ReleaseBanner content={content} />
     </div>
   </div>
diff --git a/src/components/home/ReleaseBanner.astro b/src/components/home/ReleaseBanner.astro
index a16abd3..ba1e80d 100644
--- a/src/components/home/ReleaseBanner.astro
+++ b/src/components/home/ReleaseBanner.astro
@@ -2,256 +2,55 @@
 import { getRelativeLocaleUrl } from "astro:i18n";
 import { defaultLocale, type Locale } from "@/i18n/config";
 import type { HomeTranslations } from "@/i18n/translations";
-import { getStackEntries } from "@/lib/stack";
+import { getCurrentRelease } from "@/lib/release";
 
 interface Props {
   content: HomeTranslations;
 }
 
-// The moment the next release goes public. This is the only line to change for
-// the next one: set it to the new date to bring the countdown back, and the
-// banner returns to its released state on its own once the date passes.
-//
-// Keep the offset. Without it the string is parsed as the *visitor's* local
-// time, so the switch would happen at a different absolute moment per timezone.
-const RELEASE_AT = "2026-09-14T10:00:00+02:00";
-
 const { content } = Astro.props;
 const locale = (Astro.currentLocale ?? defaultLocale) as Locale;
-const { release, countdown } = content.hero;
-
-// The site is built statically and redeployed only on push to master, so this
-// is the state at *build* time, not at visit time. That is enough for the
-// released state, which is terminal. While a release is still pending the
-// countdown script below owns the switch, because no build is guaranteed to
-// run at the moment the timer reaches zero.
-const target = Date.parse(RELEASE_AT);
-const isPending = Date.now() < target;
-
-// The inventory of the newest shipped stack. getStackEntries sorts newest
-// first, so the banner follows the release without another hardcoded version.
-const [latestStack] = await getStackEntries();
-const stackUrl = getRelativeLocaleUrl(locale, `/stack/${latestStack.id}`);
-const roadmapUrl = getRelativeLocaleUrl(locale, "/roadmap");
-
-const units = [
-  { key: "days", label: countdown.days },
-  { key: "hours", label: countdown.hours },
-  { key: "minutes", label: countdown.minutes },
-  { key: "seconds", label: countdown.seconds },
-] as const;
+const copy = content.hero.release;
+const release = await getCurrentRelease();
+const publishedDate = new Intl.DateTimeFormat(locale, {
+  day: "numeric",
+  month: "long",
+  year: "numeric",
+  timeZone: "UTC",
+}).format(new Date(release.publishedOn));
+const stackUrl = release.stackId
+  ? getRelativeLocaleUrl(locale, `/stack/${release.stackId}`)
+  : null;
 ---
 
-<div class="group relative mx-auto mb-12 max-w-2xl" data-release-banner>
-  <span
-    class="from-primary/30 via-primary-light/20 to-accent-alt/60 absolute -inset-6 rounded-[2.5rem] bg-linear-to-br blur-3xl"
-  ></span>
-  <span
-    class="from-primary via-primary-light to-primary-dark absolute -inset-0.5 rounded-[1.8rem] bg-linear-to-r opacity-95"
-  ></span>
-  <div
-    class="bg-background/92 ring-background/90 relative overflow-hidden rounded-[1.7rem] px-5 py-8 shadow-[0_30px_90px_-38px_rgba(65,144,141,0.95)] ring-1 backdrop-blur sm:px-8 sm:py-10"
-  >
-    <div
-      class="from-background/95 via-background/80 to-background-alt absolute inset-0 bg-linear-to-br"
+<aside
+  class="border-primary/20 bg-background/90 mx-auto mb-12 max-w-2xl rounded-2xl border px-6 py-6 text-center shadow-sm sm:px-8"
+  aria-label={copy.label}
+>
+  <p class="text-primary-dark mb-2 text-sm font-semibold">{copy.label}</p>
+  <p class="text-text text-2xl font-bold sm:text-3xl">
+    {release.product} v{release.version}
+  </p>
+  <p class="text-text-light mt-2 text-sm">
+    {copy.published}{" "}
+    <time datetime={release.publishedOn}>{publishedDate}</time>
+  </p>
+  <div class="mt-4 flex flex-wrap justify-center gap-x-6 gap-y-3">
+    <a
+      href={release.notesUrl}
+      class="text-primary-dark font-semibold underline underline-offset-4"
     >
-    </div>
-    <div
-      class="via-background absolute inset-x-10 top-0 h-px bg-linear-to-r from-transparent to-transparent opacity-90"
-    >
-    </div>
-    <div
-      class="bg-primary/10 absolute inset-x-8 -bottom-12 h-20 rounded-full blur-2xl"
-    >
-    </div>
-
-    {
-      /* Pending: only emitted while a release is still ahead, so a shipped
-         site carries neither this markup nor the script at the bottom. */
-    }
+      {copy.notesCta}
+    </a>
     {
-      isPending && (
-        <div
-          class="relative flex flex-col items-center gap-5"
-          data-release-pending
-          data-release-at={RELEASE_AT}
+      stackUrl && (
+        <a
+          href={stackUrl}
+          class="text-primary-dark font-semibold underline underline-offset-4"
         >
-          <div class="border-primary/15 bg-background/90 ring-background/70 inline-flex items-center gap-2.5 rounded-full border px-4 py-2.5 shadow-sm ring-1">
-            <span class="bg-primary relative inline-flex h-2.5 w-2.5 shrink-0 rounded-full" />
-            <span class="text-primary-dark text-sm font-bold tracking-[0.01em] sm:text-[0.95rem]">
-              {countdown.label}
-            </span>
-          </div>
-
-          <div class="grid w-full grid-cols-4 gap-2 sm:gap-3">
-            {units.map((unit) => (
-              <div class="border-primary/10 bg-background/80 rounded-2xl border px-2 py-4 shadow-sm sm:px-3">
-                <span
-                  class:list={[
-                    "block text-4xl leading-none font-black tracking-tight tabular-nums sm:text-5xl",
-                    unit.key === "seconds" ? "text-primary" : "text-text",
-                  ]}
-                  data-cd={unit.key}
-                >
-                  --
-                </span>
-                <span class="text-text-light mt-2 block text-[10px] font-bold tracking-[0.22em] uppercase">
-                  {unit.label}
-                </span>
-              </div>
-            ))}
-          </div>
-
-          <a
-            href={roadmapUrl}
-            class="group/button from-primary to-primary-dark shadow-primary/20 focus:ring-primary/40 inline-flex items-center justify-center gap-2 rounded-full bg-linear-to-r px-5 py-3 text-sm font-bold text-white shadow-md transition-all duration-200 focus:ring-2 focus:ring-offset-2 focus:outline-none"
-            aria-label={countdown.cta}
-          >
-            <span>{countdown.cta}</span>
-            <svg
-              class="h-4 w-4 transition-transform duration-200 group-hover:translate-x-1 group-hover/button:translate-x-1 hover:translate-x-1"
-              fill="none"
-              stroke="currentColor"
-              viewBox="0 0 24 24"
-            >
-              <path
-                stroke-linecap="round"
-                stroke-linejoin="round"
-                stroke-width="2"
-                d="M14 5l7 7m0 0l-7 7m7-7H3"
-              />
-            </svg>
-          </a>
-        </div>
+          {copy.stackCta}
+        </a>
       )
     }
-
-    {
-      /* Released. Rendered hidden alongside the countdown while one is pending,
-         so the swap at zero needs no network round trip. */
-    }
-    <div
-      class:list={[
-        "relative flex-col items-center gap-5 text-center",
-        isPending ? "hidden" : "flex",
-      ]}
-      data-release-live
-    >
-      <div
-        class="border-primary/15 bg-background/90 ring-background/70 inline-flex items-center gap-2.5 rounded-full border px-4 py-2.5 shadow-sm ring-1"
-      >
-        <span
-          class="bg-primary relative inline-flex h-2.5 w-2.5 shrink-0 rounded-full"
-        >
-          <span
-            class="bg-primary absolute inline-flex h-full w-full animate-ping rounded-full opacity-75"
-          ></span>
-        </span>
-        <span
-          class="text-primary-dark text-sm font-bold tracking-[0.01em] sm:text-[0.95rem]"
-        >
-          {release.badge}
-        </span>
-      </div>
-
-      <p
-        class="text-text text-4xl leading-none font-black tracking-tight sm:text-5xl"
-      >
-        {release.title}
-      </p>
-
-      <p class="text-text-light max-w-md text-base sm:text-lg">
-        {release.subtitle}
-      </p>
-
-      <a
-        href={stackUrl}
-        class="group/button from-primary to-primary-dark shadow-primary/20 focus:ring-primary/40 inline-flex items-center justify-center gap-2 rounded-full bg-linear-to-r px-5 py-3 text-sm font-bold text-white shadow-md transition-all duration-200 focus:ring-2 focus:ring-offset-2 focus:outline-none"
-        aria-label={release.cta}
-      >
-        <span>{release.cta}</span>
-        <svg
-          class="h-4 w-4 transition-transform duration-200 group-hover:translate-x-1 group-hover/button:translate-x-1 hover:translate-x-1"
-          fill="none"
-          stroke="currentColor"
-          viewBox="0 0 24 24"
-        >
-          <path
-            stroke-linecap="round"
-            stroke-linejoin="round"
-            stroke-width="2"
-            d="M14 5l7 7m0 0l-7 7m7-7H3"></path>
-        </svg>
-      </a>
-
-      <a
-        href={roadmapUrl}
-        class="text-text-light hover:text-primary-dark text-sm font-semibold underline underline-offset-4 transition-colors duration-200"
-      >
-        {release.roadmapCta}
-      </a>
-    </div>
   </div>
-</div>
-
-<!--
-  Drives the switch while a release is still pending. It is a no-op on a shipped
-  site: the pending block is not rendered, the query returns null and it exits.
-
-  The build-time check above cannot own this on its own. The site is static and
-  only rebuilt on push to master, so nothing is guaranteed to run at the moment
-  the timer reaches zero.
--->
-<script>
-  const pending = document.querySelector<HTMLElement>("[data-release-pending]");
-  const live = document.querySelector<HTMLElement>("[data-release-live]");
-
-  if (pending && live) {
-    const reveal = () => {
-      pending.classList.add("hidden");
-      live.classList.remove("hidden");
-      live.classList.add("flex");
-    };
-
-    const target = Date.parse(pending.dataset.releaseAt ?? "");
-    const cells = {
-      days: pending.querySelector<HTMLElement>('[data-cd="days"]'),
-      hours: pending.querySelector<HTMLElement>('[data-cd="hours"]'),
-      minutes: pending.querySelector<HTMLElement>('[data-cd="minutes"]'),
-      seconds: pending.querySelector<HTMLElement>('[data-cd="seconds"]'),
-    };
-
-    // A malformed date must not leave four dashes on screen forever. Falling
-    // back to the released state is the safer of the two failures.
-    if (
-      !Number.isFinite(target) ||
-      !cells.days ||
-      !cells.hours ||
-      !cells.minutes ||
-      !cells.seconds
-    ) {
-      reveal();
-    } else {
-      const pad = (value: number) => String(value).padStart(2, "0");
-      let timer: number | undefined;
-
-      const tick = () => {
-        const remaining = Math.floor((target - Date.now()) / 1000);
-
-        if (remaining <= 0) {
-          if (timer !== undefined) window.clearInterval(timer);
-          reveal();
-          return false;
-        }
-
-        cells.days!.textContent = String(Math.floor(remaining / 86400));
-        cells.hours!.textContent = pad(Math.floor((remaining % 86400) / 3600));
-        cells.minutes!.textContent = pad(Math.floor((remaining % 3600) / 60));
-        cells.seconds!.textContent = pad(remaining % 60);
-        return true;
-      };
-
-      if (tick()) timer = window.setInterval(tick, 1000);
-    }
-  }
-</script>
+</aside>
diff --git a/src/data/release.json b/src/data/release.json
new file mode 100644
index 0000000..eb1febc
--- /dev/null
+++ b/src/data/release.json
@@ -0,0 +1,7 @@
+{
+  "product": "OKDP Sandbox",
+  "version": "1.1.0",
+  "publishedOn": "2026-10-02",
+  "notesUrl": "https://github.com/OKDP/okdp-sandbox/releases/tag/v1.1.0",
+  "stackId": null
+}
diff --git a/src/i18n/en.json b/src/i18n/en.json
index 140e849..3a5dd5e 100644
--- a/src/i18n/en.json
+++ b/src/i18n/en.json
@@ -21,19 +21,10 @@
     "ctaPrimary": "Get started",
     "ctaSecondary": "Join Community",
     "release": {
-      "badge": "v1.0.0 available",
-      "title": "OKDP v1.0.0 is here 🎉",
-      "subtitle": "The first release of the sandbox, published on 14 September 2026.",
-      "cta": "See what ships in 1.0",
-      "roadmapCta": "What comes next"
-    },
-    "countdown": {
-      "label": "Release v1.0.0 — 14 September 2026",
-      "days": "Days",
-      "hours": "Hours",
-      "minutes": "Minutes",
-      "seconds": "Seconds",
-      "cta": "Discover the roadmap"
+      "label": "Latest stable release",
+      "published": "Released on",
+      "notesCta": "Release notes",
+      "stackCta": "Explore the stack"
     }
   },
   "stats": {
@@ -230,7 +221,7 @@
   },
   "roadmap": {
     "title": "Roadmap",
-    "teaser": "First release <strong class=\"text-text\">v1.0.0</strong> shipped on <strong class=\"text-text\">the 14th September 2026</strong>.",
+    "teaser": "Explore the project milestones and development priorities.",
     "cta": "View the full roadmap"
   },
   "community": {
diff --git a/src/i18n/fr.json b/src/i18n/fr.json
index 874d7fe..ea0b6dc 100644
--- a/src/i18n/fr.json
+++ b/src/i18n/fr.json
@@ -21,19 +21,10 @@
     "ctaPrimary": "Démarrer",
     "ctaSecondary": "Rejoindre la communauté",
     "release": {
-      "badge": "v1.0.0 disponible",
-      "title": "OKDP v1.0.0 est là 🎉",
-      "subtitle": "La première version de la sandbox, publiée le 14 Septembre 2026.",
-      "cta": "Découvrir la stack 1.0",
-      "roadmapCta": "La suite de la roadmap"
-    },
-    "countdown": {
-      "label": "Release v1.0.0 — 14 septembre 2026",
-      "days": "Jours",
-      "hours": "Heures",
-      "minutes": "Minutes",
-      "seconds": "Secondes",
-      "cta": "Découvrir la roadmap"
+      "label": "Dernière version stable",
+      "published": "Publiée le",
+      "notesCta": "Notes de version",
+      "stackCta": "Découvrir la stack"
     }
   },
   "stats": {
@@ -230,7 +221,7 @@
   },
   "roadmap": {
     "title": "Roadmap",
-    "teaser": "Première release <strong class=\"text-text\">v1.0.0</strong> publiée le <strong class=\"text-text\">14 septembre 2026</strong>.",
+    "teaser": "Découvrez les étapes du projet et les priorités de développement.",
     "cta": "Consulter la roadmap complète"
   },
   "community": {
diff --git a/src/lib/release.ts b/src/lib/release.ts
new file mode 100644
index 0000000..cb9218d
--- /dev/null
+++ b/src/lib/release.ts
@@ -0,0 +1,28 @@
+import { z } from "astro/zod";
+import releaseData from "@/data/release.json";
+import { getStackEntries } from "@/lib/stack";
+
+const release = z
+  .object({
+    product: z.string().min(1),
+    version: z.string().min(1),
+    publishedOn: z.string().date(),
+    notesUrl: z.string().url(),
+    stackId: z
+      .string()
+      .regex(/^okdp-\d+(?:-\d+)+$/)
+      .nullable(),
+  })
+  .parse(releaseData);
+
+export async function getCurrentRelease() {
+  if (release.stackId) {
+    const stacks = await getStackEntries();
+    if (!stacks.some((entry) => entry.id === release.stackId)) {
+      throw new Error(
+        `Missing inventory for release.stackId: ${release.stackId}`,
+      );
+    }
+  }
+  return release;
+}
diff --git a/src/pages/[lang]/stack/index.astro b/src/pages/[lang]/stack/index.astro
index 124c493..2089b89 100644
--- a/src/pages/[lang]/stack/index.astro
+++ b/src/pages/[lang]/stack/index.astro
@@ -6,6 +6,7 @@ import MarketingLayout from "@/layouts/MarketingLayout.astro";
 import { localeCodes, type Locale } from "@/i18n/config";
 import { getTranslations } from "@/i18n/translations";
 import { getStackEntries } from "@/lib/stack";
+import { getCurrentRelease } from "@/lib/release";
 
 export const getStaticPaths = (() => {
   return localeCodes.map((lang) => ({ params: { lang } }));
@@ -15,8 +16,9 @@ const locale = Astro.currentLocale as Locale;
 const content = getTranslations(locale);
 const copy = content.stackPage.index;
 
-// Sorted newest first by getStackEntries, so the first entry is the current one.
+// Inventory order does not determine which release is featured.
 const entries = await getStackEntries();
+const release = await getCurrentRelease();
 ---
 
 <MarketingLayout
@@ -38,7 +40,7 @@ const entries = await getStackEntries();
       <div class="container">
         <div class="mx-auto grid max-w-4xl gap-4 md:grid-cols-2">
           {
-            entries.map((entry, index) => (
+            entries.map((entry) => (
               <a
                 href={getRelativeLocaleUrl(locale, `/stack/${entry.id}`)}
                 class="bg-background border-accent hover:border-primary group block rounded-lg border p-6 no-underline transition-colors"
@@ -47,7 +49,7 @@ const entries = await getStackEntries();
                   <h2 class="group-hover:text-primary text-xl font-bold transition-colors">
                     OKDP {entry.data.stack}
                   </h2>
-                  {index === 0 && (
+                  {entry.id === release.stackId && (
                     <span class="bg-primary/10 text-primary rounded-full px-3 py-0.5 text-xs font-semibold">
                       {copy.current}
                     </span>
```
<!-- END PATCH release-summary.patch -->

### Patch 2: `language-navigation.patch`

<!-- BEGIN PATCH language-navigation.patch -->
```diff
diff --git a/src/assets/flags/fr.svg b/src/assets/flags/fr.svg
deleted file mode 100644
index 4186682..0000000
--- a/src/assets/flags/fr.svg
+++ /dev/null
@@ -1,5 +0,0 @@
-<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3 2">
-  <rect width="3" height="2" fill="#ED2939"/>
-  <rect width="2" height="2" fill="#fff"/>
-  <rect width="1" height="2" fill="#002395"/>
-</svg>
diff --git a/src/assets/flags/gb.svg b/src/assets/flags/gb.svg
deleted file mode 100644
index e4e9999..0000000
--- a/src/assets/flags/gb.svg
+++ /dev/null
@@ -1,10 +0,0 @@
-<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 30">
-<clipPath id="t">
-	<path d="M30,15 h30 v15 z v15 h-30 z h-30 v-15 z v-15 h30 z"/>
-</clipPath>
-<path d="M0,0 v30 h60 v-30 z" fill="#00247d"/>
-<path d="M0,0 L60,30 M60,0 L0,30" stroke="#fff" stroke-width="6"/>
-<path d="M0,0 L60,30 M60,0 L0,30" clip-path="url(#t)" stroke="#cf142b" stroke-width="4"/>
-<path d="M30,0 v30 M0,15 h60" stroke="#fff" stroke-width="10"/>
-<path d="M30,0 v30 M0,15 h60" stroke="#cf142b" stroke-width="6"/>
-</svg>
diff --git a/src/components/common/Header.astro b/src/components/common/Header.astro
index 212b681..53cd13d 100644
--- a/src/components/common/Header.astro
+++ b/src/components/common/Header.astro
@@ -24,14 +24,14 @@ const homeUrl =
   class="bg-background/80 text-text shadow-soft fixed inset-x-0 top-0 z-50 h-14 border-b border-current/10 backdrop-blur-md md:h-16"
 >
   <div
-    class="mx-auto flex h-full w-full max-w-384 items-center gap-4 px-4 sm:gap-6"
+    class="mx-auto flex h-full w-full max-w-384 items-center gap-2 px-2 sm:gap-6 sm:px-4"
   >
     <a
       href={homeUrl}
       class="flex min-w-0 shrink-0 items-center gap-2 font-sans text-base font-semibold text-inherit no-underline"
     >
       <Image src={OkdpLogo} alt="OKDP logo" class="h-10 w-auto shrink-0" />
-      <span class="xl:hidden">OKDP</span>
+      <span class="hidden sm:inline xl:hidden">OKDP</span>
       <span class="hidden xl:block">Open Kubernetes Data Platform</span>
     </a>
 
@@ -42,7 +42,7 @@ const homeUrl =
     <div class="ml-auto flex items-center gap-2 md:gap-4">
       <a
         href="https://github.com/OKDP/"
-        class="hover:text-primary focus-visible:text-primary flex size-9 items-center justify-center rounded-full text-inherit transition-colors duration-200 hover:bg-current/8 focus-visible:bg-current/8"
+        class="hover:text-primary focus-visible:text-primary hidden size-9 items-center justify-center rounded-full text-inherit transition-colors duration-200 hover:bg-current/8 focus-visible:bg-current/8 sm:flex"
         aria-label="GitHub"
         title="GitHub"
       >
diff --git a/src/components/common/LocaleSwitcher.astro b/src/components/common/LocaleSwitcher.astro
index c5ce776..feba852 100644
--- a/src/components/common/LocaleSwitcher.astro
+++ b/src/components/common/LocaleSwitcher.astro
@@ -1,9 +1,11 @@
 ---
 import { getRelativeLocaleUrl } from "astro:i18n";
-import InlineSvg from "@/components/common/InlineSvg.astro";
-import FrFlag from "@/assets/flags/fr.svg?raw";
-import GbFlag from "@/assets/flags/gb.svg?raw";
-import { defaultLocale, type Locale } from "@/i18n/config";
+import {
+  defaultLocale,
+  localeCodes,
+  locales,
+  type Locale,
+} from "@/i18n/config";
 
 interface Props {
   label: string;
@@ -11,35 +13,36 @@ interface Props {
 
 const { label } = Astro.props;
 const locale = (Astro.currentLocale ?? defaultLocale) as Locale;
-const otherLocale: Locale = locale === "fr" ? "en" : "fr";
-const currentLocaleUrl = getRelativeLocaleUrl(locale, "/");
-const otherLocaleUrl = getRelativeLocaleUrl(otherLocale, "/");
+// Strip the preview base before the locale, preserving the current page path.
+const base = import.meta.env.BASE_URL.replace(/\/$/, "");
+const pathname = Astro.url.pathname.slice(base.length);
+const [, firstSegment, ...segments] = pathname.split("/");
+const pagePath = localeCodes.includes(firstSegment as Locale)
+  ? `/${segments.join("/")}`
+  : pathname;
+const displayOrder: Locale[] = ["fr", "en"];
 ---
 
-<div
+<nav
   class="flex shrink-0 items-center gap-1 rounded-full border border-current/15 bg-current/5 p-1"
   aria-label={label}
 >
-  <a
-    href={locale === "fr" ? currentLocaleUrl : otherLocaleUrl}
-    class:list={[
-      "flex size-7 items-center justify-center overflow-hidden rounded-full opacity-50 transition-opacity duration-200 hover:opacity-100 focus-visible:opacity-100",
-      locale === "fr" && "ring-primary opacity-100 ring-2",
-    ]}
-    aria-label="Français"
-    aria-current={locale === "fr" ? "page" : undefined}
-  >
-    <InlineSvg source={FrFlag} class="size-full object-cover" label="FR" />
-  </a>
-  <a
-    href={locale === "en" ? currentLocaleUrl : otherLocaleUrl}
-    class:list={[
-      "flex size-7 items-center justify-center overflow-hidden rounded-full opacity-50 transition-opacity duration-200 hover:opacity-100 focus-visible:opacity-100",
-      locale === "en" && "ring-primary opacity-100 ring-2",
-    ]}
-    aria-label="English"
-    aria-current={locale === "en" ? "page" : undefined}
-  >
-    <InlineSvg source={GbFlag} class="size-full object-cover" label="EN" />
-  </a>
-</div>
+  {
+    displayOrder.map((language) => (
+      <a
+        href={getRelativeLocaleUrl(language, pagePath)}
+        lang={language}
+        hreflang={language}
+        class:list={[
+          "focus-visible:outline-primary rounded-full px-2 py-2 text-sm font-medium no-underline transition-colors focus-visible:outline-2 focus-visible:outline-offset-2",
+          language === locale
+            ? "bg-primary text-white"
+            : "text-inherit hover:bg-current/10",
+        ]}
+        aria-current={language === locale ? "page" : undefined}
+      >
+        {locales[language].label}
+      </a>
+    ))
+  }
+</nav>
```
<!-- END PATCH language-navigation.patch -->

