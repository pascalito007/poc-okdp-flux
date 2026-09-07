# OKDP stack inventory: how it works

A walkthrough of the component inventory page for okdp.io, written to be read by
someone who has not seen the code.

---

## 1. The problem

Someone asks: **"what is actually inside OKDP 1.0?"**

Today there is no single place that answers that. The version numbers exist, but
they are spread across several places, and those places disagree with each
other. Here is what was true on `main` when this work started:

| Component | Package repo says | Console catalog says | Sandbox pin says |
| --- | --- | --- | --- |
| polaris | `1.3.0-incubating-p07` | `-p06` | `-p06` |
| superset | `6.0.0-p05` | `6.0.0-p04` | `6.0.0-p04` |
| airflow | `3.2.1-p07` | `3.2.1-p04` | `3.2.1-p04` |
| spark-history-server | `3.5.1-p08` | `3.5.1-p07` | not pinned |
| keycloak | `24.4.11-p16` | not listed | `24.4.11-p14` |
| okdp-control-plane-server | `0.7.1-p02` | not listed | `0.7.1-p01` |

Six mismatches, plus a version table in the `sandbox-dependencies` README that
is wrong in 5 of its 14 rows.

**Why they disagree:** each of those places is maintained by a person typing a
version number. People forget. That is not a criticism of anyone, it is simply
what happens to hand-copied data over time.

### "But the tags are getting better"

True, and worth being precise about. After the release-please rework, a tag will
read `3.5.1-1.0.0` instead of `3.5.1-p08`. The upstream version stays in front,
so the tag still tells you it is Spark 3.5.1.

That is a real improvement, and it is **not** what this page is for.

A tag gives you exactly one number. It does not tell you:

- that **Trino 480** runs on Helm chart `trino v1.42.1`, alongside OPA 1.16.1,
  OPAL 0.9.4 and two helper charts
- which **Spark / Python / Java / Scala** combinations OKDP actually builds
- whether we use a component **as published upstream** or rebuild it ourselves

And occasionally a tag actively misleads. Keycloak's tag says `24.4.11`, which is
the version of the *Bitnami chart*. The Keycloak inside is **26.1.3**. Someone
reading the tag gets the wrong answer.

**The page is the full bill of materials, not a nicer way to read one tag.**

---

## 2. What was built

Two pages on okdp.io, in English and French:

- `/stack/` lists the OKDP releases
- `/stack/okdp-1-0` lists all **27 components** in release 1.0

Each row shows the component, the version you actually get, the package tag,
where it came from, and the Helm chart. Clicking a row expands it to show
everything bundled inside.

**The important part is not the page. It is that nobody types those version
numbers.**

---

## 3. How it works: three steps

```
  STEP 1                     STEP 2               STEP 3
  the truth                  the copier           the snapshot

  platform-packages     ->   build-stack.mjs  ->  okdp-1-0.yaml  ->  web page
  sandbox-dependencies       (a script)           (saved in git)
  27 YAML files
```

**Step 1, the truth.** The two package repositories already describe every
component: its tag, its Helm chart, its container images. That information is
real and well maintained, because it is what actually deploys. It is just not
readable by a human in a hurry.

**Step 2, the copier.** `scripts/build-stack.mjs` is a single script, about 500
lines including its comments and licence header. It reads all 27 files, pulls out
the version information, and writes one tidy file. It runs on a laptop when
someone prepares a release. It does **not** run when the website builds.

**Step 3, the snapshot.** The result is saved as
`src/data/stack/okdp-1-0.yaml` and committed to git like any other file. The
website reads that file and turns it into HTML.

Think of a printed catalogue. The warehouse (step 1) is the truth. The catalogue
(step 3) is a snapshot of it. The script (step 2) prints the catalogue so that
nobody transcribes it by hand.

---

## 4. Two design decisions worth defending

Colleagues are likely to question these two, so here is the reasoning.

### "Why not just write the table by hand? It is only 27 rows."

Because we already know how that ends. Compare the two halves of OKDP:

- **Generated**: the Spark and Jupyter build matrices in `spark-images` and
  `jupyterlab-docker`. No drift. They are correct because nobody retypes them.
- **Hand-maintained**: the console catalog, the sandbox pins, the
  `sandbox-dependencies` README. Six mismatches and a table stale in 5 of 14 rows.

There is live proof of the cost. **okdp-sandbox PR #99** exists right now to close
exactly those six mismatches, and it does it by hand-editing eight tags across
six files. That PR *is* the argument: re-synchronising numbers that a script can
derive is recurring manual work, and it will drift again next release. This page
removes the transcription step instead of repeating the correction.

It is also worth saying that this approach is not new to OKDP. `spark-images` has
a GitHub Action that builds its version matrix from a YAML file, and
`jupyterlab-docker` has an entire Python module doing the same thing.
"Declare it once in YAML, derive the rest with a script" is already the house
style. We are pointing it at the website.

### "Why save the file? Why not fetch the versions live when the site builds?"

Four reasons:

1. The website build stays **offline**. No network call means no failed deploy
   when GitHub is slow.
2. Every version change becomes a **visible diff** in a pull request. A human
   approves "Trino 480 became 481" before it goes public.
3. The 1.0 page stays **frozen**. If it read live data, the 1.0 page would
   silently change whenever someone merged something, which defeats the purpose
   of documenting a release.
4. The website does not break when someone commits invalid YAML in another repo.

---

## 5. How it evolves

This is the part colleagues will care about most. Four scenarios.

### A. A component is updated inside 1.0

Say Trino goes from 480 to 481 in `platform-packages`.

```bash
cd okdp.io
node scripts/build-stack.mjs --stack 1.0
git diff src/data/stack/
```

The diff shows exactly what changed. Commit it, open a PR, merge. The page
updates on deploy.

**Total effort: one command and a pull request.**

### B. OKDP 2.0 ships

```bash
node scripts/build-stack.mjs --stack 2.0
```

This writes a **new** file, `okdp-2-0.yaml`. The page `/stack/okdp-2-0` appears
automatically, with no code changes. The index page lists both releases newest
first and puts a "Current" badge on 2.0.

The 1.0 file is never touched, so `/stack/okdp-1-0` keeps showing what 1.0
actually contained, permanently. That is deliberate: a release inventory that
changes after the release is worthless.

### C. A brand new component is added to the platform

Nothing to do in the website code. The script scans whole directories, so it
finds new packages automatically. It prints a reminder:

```
warn: my-new-thing: no entry in stack-metadata.yaml (using defaults)
```

That is the cue to add a display name, project homepage and logo.

### D. Changing how something is displayed

There is exactly one hand-written file: **`scripts/stack-metadata.yaml`**. It
holds only what a computer cannot work out, such as the fact that `superset`
should display as "Apache Superset", that its homepage is superset.apache.org,
and which logo to use.

Edit that file, re-run the script, commit.

> **Important:** you must re-run the script after editing it, because those names
> are copied into the snapshot.

That file is also where two special cases are handled, each with a comment
explaining why:

- **Trino** shows as `480`, not `480.0.0-p21`. The odd tag exists only because
  the console's version parser demands a SemVer shape.
- **Keycloak** shows as `26.1.3`, not `24.4.11`. The tag tracks the Bitnami
  chart, but the Keycloak inside is 26.1.3, and that is the number people mean.

### E. The tag format changes

Already handled. The script understands both shapes, so the release-please
rework needs no change here:

| Tag | Version shown |
| --- | --- |
| `3.5.1-p08` (today) | `3.5.1` |
| `3.5.1-1.0.0` (after the rework) | `3.5.1` |
| `1.3.0-incubating-1.0.0` | `1.3.0-incubating` |

Verified against 18 tag forms, including the awkward ones such as
`0.3.0-snapshot-1.0.0` and `v0.3.2-1.0.0`.

---

## 6. The honest limitation

**If nobody runs the script, the page goes stale.**

It is better than a hand-typed table, because updating means one command instead
of retyping 27 rows, but it is not automatic yet.

The fix is planned, and it is worth mentioning because it shows the direction:

1. **Next:** a scheduled job re-runs the script and opens a pull request
   automatically whenever the platform has moved. Same idea as the existing
   `tag-must-move` guard.
2. **After that:** the package repositories publish this inventory themselves as
   a release artifact. The website, the control plane's service catalog, and the
   sandbox then all read the same file, and the six mismatches in section 1
   become impossible rather than merely fixed.

That is the real destination. This page is the first consumer of it.

---

## 7. Two things the work uncovered

Useful to mention, because they show the script earns its keep.

**`okdp-examples` contradicts itself.** The package says version 1.3.0 and its
chart is 1.3.0, but the image pinned inside is 1.2.0, and the GitHub release is
`v1.2.0`. Probably a stale image pin, worth an issue.

**A stale checkout produces a different platform.** A local copy of
`platform-packages` that was 74 commits behind still contained `trinodb`,
`okdp-server` and `okdp-ui` from before the repository was split. It generated
**38** components instead of 27. The script now refuses to use a local copy
unless explicitly asked, and warns loudly when that copy is out of date.

---

## 8. Small glossary

| Term | Meaning |
| --- | --- |
| **Helm chart** | A package that installs an application into Kubernetes |
| **OCI / registry** | Where container images and charts are stored, e.g. `quay.io/okdp/...` |
| **KubOCD Package** | OKDP's YAML file describing one deployable component |
| **Upstream** | The original open source project, for example the Trino community |
| **Provenance** | Our column saying whether we use the upstream chart as-is, or build our own |
| **YAML** | A plain text format for structured data |
| **Astro** | The tool that builds the okdp.io website |
| **i18n** | Internationalisation, the French and English versions |
| **SemVer** | Version numbering of the form `MAJOR.MINOR.PATCH` |

---

## 9. Presenting it

Two suggestions.

**Lead with the table in section 1.** The six mismatches make the case better
than any argument about tooling, and PR #99 shows the cost is real and current.

**Demo section 5A live.** Run the command, show the diff. That is the whole idea
in ten seconds, and it answers "how much work is this to maintain" before anyone
asks.

If someone challenges the approach, the strongest single line is: *the parts of
OKDP that generate their version data do not drift, and the parts that hand-
maintain it do. We already ran the experiment.*
