# PR 8 — `OKDP/okdp-sandbox` — move every pin to the published package versions

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> **Not Phase 4.** This is the interim alignment on the current `-pNN` scheme,
> filed *before* Phase 2 merges. `pr-6-okdp-sandbox-repoint-packages.md` is still
> the Phase 4 document and still applies afterwards — this one makes it smaller.
> Pairs with `issue-okdp-sandbox-latest-package-versions.md` — **file that
> first**, so this pull request has a `Fixes #` number.
> Verified against `okdp-sandbox` `70fe8f2`, `platform-packages` `082e702`,
> `sandbox-dependencies` `12bb63a` and the live quay.io registry on 4 Sep 2026.

---

## Part 1 — did the publish guard hold?

**Yes.** Two `workflow_dispatch` runs on 4 Sep 2026, both green, both with
`on_existing_tag: skip`. Twenty-seven packages were considered; **eight were
built and pushed, nineteen were skipped as already published, nothing was
overwritten.**

| | `platform-packages` | `sandbox-dependencies` |
|---|---|---|
| Run | [`33878436789`](https://github.com/OKDP/platform-packages/actions/runs/33878436789) | [`33878461896`](https://github.com/OKDP/sandbox-dependencies/actions/runs/33878461896) |
| Head | `082e702` | `12bb63a` |
| Started | 4 Sep 13:30:22 UTC | 4 Sep 13:30:37 UTC |
| Conclusion | success | success |
| Packages considered | 13 | 14 |
| **Built and pushed** | **5** | **3** |
| **Skipped, already published** | **8** | **11** |
| `::error` annotations | 0 | 0 |

### What was pushed

| package | tag | repo |
|---|---|---|
| `spark-history-server` | `3.5.1-p08` | `platform-packages` |
| `polaris` | `1.3.0-incubating-p07` | `platform-packages` |
| `superset` | `6.0.0-p05` | `platform-packages` |
| `airflow` | `3.2.1-p07` | `platform-packages` |
| `okdp-control-plane-server` | `0.7.1-p02` | `platform-packages` |
| `keycloak` | `24.4.11-p16` | `sandbox-dependencies` |
| `kubauth` | `0.3.0-snapshot-p03` | `sandbox-dependencies` |
| `vault` | `0.29.1-p03` | `sandbox-dependencies` |

### What was skipped

`hive-metastore`, `jupyterhub`, `okdp-examples`, `spark-defaults`,
`spark-operator`, `spark-rbac`, `trino`, `okdp-control-plane-ui`,
`seaweedfs`, `cert-manager`, `cloudnative-pg`, `cnpg-postgresql`,
`coredns-patch`, `dns-server`, `external-secrets`, `ingress-nginx`,
`kubocd-webhooks`, `local-secrets-provider`, `tools`.

### The hard evidence — registry timestamps

The run log is one thing; the registry is the proof. Quay's per-tag
`last_modified` after the dispatch:

| group | count | `last_modified` |
|---|---|---|
| Pushed on 4 Sep | 8 | `Fri, 04 Sep 2026 13:30:50` → `13:31:20 -0000` |
| Skipped, `platform-packages` | 8 | unchanged at `Thu, 27 Aug 2026 07:26:39` → `07:27:00 -0000` |
| Skipped, `sandbox-dependencies` | 11 | unchanged at `Mon, 24 Aug 2026 12:04:49` → `12:05:18 -0000` |

The nineteen skipped tags kept the timestamp they had **before** the dispatch.
No silent replacement. Under the pre-#67 / pre-#32 behaviour this same dispatch
would have re-pushed all 27 and re-stamped every one of them — and note the
shape of those old timestamps: eight `platform-packages` tags all within
**21 seconds** of each other on 27 Aug, eleven `sandbox-dependencies` tags
within **29 seconds** on 24 Aug. That is exactly the bulk re-push the guard rails
were written to stop.

### The mechanism, as it actually ran

`kubocd-package-template.yml` resolves `KUBOCD_PACKAGES` by `find`ing every
manifest with a `modules:` key, then for each one:

```sh
out=$(oras manifest fetch --descriptor "${OCI_REPO_PREFIX}/${name}:${tag}") || rc=$?
if   [[ ${rc} -eq 0 ]];              then SKIPPED=…   # tag exists → do not touch it
elif grep -qE ': not found|404' <<<"$out"; then KEEP=…  # tag is free → build and push
else exit 1                                            # cannot tell → hard fail
fi
```

Three properties worth naming, because they are the ones under review:

1. **A published tag is never rewritten.** The `skip` branch is unconditional.
2. **"Cannot determine tag state" is a hard error**, not a silent skip — an auth
   failure or a registry outage stops the run instead of quietly publishing
   nothing.
3. **One broken package does not stop the rest**: the build loop collects
   `FAILED` and reports at the end. Both runs reported an empty `FAILED`.

### Is "only changed packages" actually what it publishes?

Strictly, the guard publishes *a package whose declared `tag:` is not yet on the
registry*. "Only changed packages" is the emergent result of pairing it with
`tag-must-move.sh`, which fails a pull request that edits a package without
bumping its `tag:`. I checked the join rather than assuming it:

- **All 27 packages now match.** For every package in both repositories, the
  `tag:` on `main` exists on quay.io. `main` and the registry are in sync for
  the first time in this series.
- **Every post-guard-rail change bumped its tag.** Eight package manifests have
  been touched on `main` since the guard rails merged on 28 Aug 12:26/12:27 UTC
  — `airflow`, `polaris`, `superset`, `spark-history-server` and
  `okdp-control-plane-server` in `platform-packages`, `keycloak`, `kubauth` and
  `vault` in `sandbox-dependencies` — and every one carries a `+tag:` line in
  its pull request. (Individual commits within a pull request do not each bump:
  `b7b484f` and `6c2b71f` for `spark-history-server`, `4c2d806` for `keycloak`.
  That is correct — `tag-must-move.sh` is given the whole `FETCH_HEAD...HEAD`
  diff, not one commit at a time.)

**Verdict: the work is good.** The behaviour matches what
`pr-1-platform-packages.md` and `pr-2-sandbox-dependencies.md` set out to do, and
this dispatch is the first one under production credentials that proves it.

### Three caveats, for the record

1. **The guard proves "no overwrite", not "content matches".** It compares tag
   *names*, never digests. A package whose files changed with no tag bump is
   silently never published — `tag-must-move` is the only thing that catches it,
   and **it is not a required check** on either repository. That gap is
   Phase 2's to close, when release-please owns the tag.
2. **`[no-publish]` in a pull request body disables `tag-must-move` entirely.**
   It is still the one path in this series never exercised on a runner.
3. **`on_existing_tag: fail` remains untested.** `publish.yml` does not set the
   input, so both runs used the `skip` default. `fail` is the mode the release
   path will want, and it has still never run with real credentials.

Pre-guard-rail drift exists but is not a live problem: seven packages had a
directory change land after their last tag bump (`okdp-examples`,
`spark-history-server`, `spark-operator`, `trino`, `seaweedfs`, `ingress-nginx`,
`tools`). All of them pre-date 28 Aug, when publish-on-merge was still
re-pushing everything on every merge — so that content did reach the registry,
as one of the 213 silent replacements. Nothing to do; noted so nobody
re-discovers it as a bug.

---

## Part 2 — every package `okdp-sandbox` references

The team's question, answered in full. **28 pins, 26 distinct packages**, plus
7 console catalog entries naming 7 of those packages a second time.

`repository` prefixes are `quay.io/okdp/platform-packages/…` (PP) and
`quay.io/okdp/sandbox-dependencies/…` (SD). Paths are relative to
`clusters/sandbox/`.

| # | package | repo | file | line | pin today | published | action |
|---|---|---|---|---|---|---|---|
| 1 | `kubauth` | SD | `optional/kubauth/kubauth.yaml` | 29 | `0.3.0-snapshot-p02` | `0.3.0-snapshot-p03` | **bump** |
| 2 | `seaweedfs` | SD | `optional/storage/storage.yaml` | 26 | `4.17.0-p08` | `4.17.0-p08` | — |
| 3 | `vault` | SD | `optional/vault/vault.yaml` | 29 | `0.29.1-p02` | `0.29.1-p03` | **bump** |
| 4 | `local-secrets-provider` | SD | `project-demo/10-secrets.yaml` | 28 | `1.0.0-p06` | `1.0.0-p06` | — |
| 5 | `seaweedfs` | SD | `project-demo/20-storage-demo.yaml` | 31 | `4.17.0-p08` | `4.17.0-p08` | — |
| 6 | `hive-metastore` | PP | `project-demo/50-services.yaml` | 33 | `4.0.1-p02` | `4.0.1-p02` | — |
| 7 | `polaris` | PP | `project-demo/50-services.yaml` | 56 | `1.3.0-incubating-p06` | `1.3.0-incubating-p07` | **bump** |
| 8 | `trino` | PP | `project-demo/50-services.yaml` | 96 | `480.0.0-p21` | `480.0.0-p21` | — |
| 9 | `superset` | PP | `project-demo/50-services.yaml` | 145 | `6.0.0-p04` | `6.0.0-p05` | **bump** |
| 10 | `airflow` | PP | `project-demo/50-services.yaml` | 178 | `3.2.1-p04` | `3.2.1-p07` | **bump** |
| 11 | `jupyterhub` | PP | `project-demo/50-services.yaml` | 215 | `4.3.3-p06` | `4.3.3-p06` | — |
| 12 | `spark-history-server` | PP | `project-demo/50-services.yaml` | 357 | `3.5.1-p07` | `3.5.1-p08` | **bump** |
| 13 | `okdp-examples` | PP | `project-demo/examples/okdp-examples.yaml` | 35 | `1.3.0-p08` | `1.3.0-p08` | — |
| 14 | `cert-manager` | SD | `releases/cert-manager.yaml` | 26 | `1.17.1-p08` | `1.17.1-p08` | — |
| 15 | `cloudnative-pg` | SD | `releases/cloudnative-pg.yaml` | 30 | `1.29.1-p01` | `1.29.1-p01` | — |
| 16 | `cnpg-postgresql` | SD | `releases/cnpg-postgresql.yaml` | 26 | `18.3-p03` | `18.3-p03` | — |
| 17 | `coredns-patch` | SD | `releases/coredns-patch.yaml` | 26 | `1.0.0-p05` | `1.0.0-p05` | — |
| 18 | `dns-server` | SD | `releases/dns-server.yaml` | 28 | `1.0.0-p04` | `1.0.0-p04` | — |
| 19 | `external-secrets` | SD | `releases/external-secrets.yaml` | 26 | `0.15.1-p03` | `0.15.1-p03` | — |
| 20 | `ingress-nginx` | SD | `releases/ingress-nginx.yaml` | 26 | `4.12.1-p03` | `4.12.1-p03` | — |
| 21 | `keycloak` | SD | `releases/keycloak.yaml` | 26 | `24.4.11-p14` | `24.4.11-p16` | **bump** |
| 22 | `local-secrets-provider` | SD | `releases/local-secrets-provider.yaml` | 26 | `1.0.0-p06` | `1.0.0-p06` | — |
| 23 | `okdp-control-plane-server` | PP | `releases/okdp-control-plane-server.yaml` | 28 | `0.7.1-p01` | `0.7.1-p02` | **bump** |
| 24 | `okdp-control-plane-ui` | PP | `releases/okdp-control-plane-ui.yaml` | 28 | `0.7.0-p01` | `0.7.0-p01` | — |
| 25 | `spark-operator` | PP | `releases/spark-operator.yaml` | 10 | `2.4.0-p04` | `2.4.0-p04` | — |
| 26 | `spark-rbac` | PP | `releases/spark-rbac.yaml` | 10 | `1.0.1-p02` | `1.0.1-p02` | — |
| 27 | `tools` | SD | `releases/tools.yaml` | 26 | `1.0.0-p01` | `1.0.0-p01` | — |
| 28 | `kubocd-webhooks` | SD | `releases/webhooks.yaml` | 28 | `v0.3.2-p01` | `v0.3.2-p01` | — |

**Eight bumps. Twenty pins already correct.** The eight are exactly the eight
packages the 4 September dispatch published — the sandbox was pinned to the
previous version of each, which is what you would expect: those tags did not
exist until yesterday afternoon.

### Two findings the team should see

**`spark-defaults` is published and referenced nowhere.**
`quay.io/okdp/platform-packages/spark-defaults:1.0.0-p01` exists, is maintained
in `platform-packages` (last touched `ad85467`, 6 Jul 2026), and appears in
**zero** files under `clusters/`. It is the only one of the 27 packages the
sandbox does not consume. Either it is dead and should be archived, or the
sandbox is missing a Release it ought to have. Worth a decision before the
platform release, not after.

**The console catalog is a third copy of the same versions.** Seven of the
services above carry their version *again* in
`contexts/platform-context.yaml`, in both `versions:` and `default:`. Four of
those seven are among the eight bumps, so this pull request has to move them too
or the console's *(recommended)* label points at a tag nothing updates any more.
This duplication is `issue-catalog-drift.md`, still unfiled.

### The one `tag:` that is not a package pin

```
clusters/sandbox/flux/kubocd.yaml:30    tag: v0.3.2
```

The KuboCD controller's own version. There are **29** `tag:` lines under
`clusters/`; 28 are package pins and this is the 29th. **A blind
search-and-replace on `tag:` breaks the install.**

---

## Part 3 — the pull request

### Branch

```
feat/bump-packages-to-published
```

Off `main` (`70fe8f2`). Matches this repository's `<commit-type>/<kebab-description>`
convention (`fix/jupyterhub-storage-endpoint`, `chore/bump-local-secrets-provider-p05`).

### Title

```
feat(packages): move every pin to the published package versions
```

**`feat:`, not `chore(deps):`.** `release-please` came back to this repository in
`70fe8f2`, with `changelog-type: default` — which **hides** `chore` entirely.
A `chore(deps):` would put the platform's package moves nowhere in
`CHANGELOG.md`, on the release where they matter most. The bumps also carry real
features (`keycloak` group membership, `superset` chart locale) and real fixes
(`polaris` console crash, `airflow` object-store connection), so `feat` is
honest, not just convenient.

Version consequence: the manifest reads `{".":"0.5.0"}` with
`bump-minor-pre-major: false`, so a `feat` proposes **`0.6.0`** — unless one of
the two pending `refactor!` commits already in the backlog forces `1.0.0` first.
See `pr-5-okdp-sandbox-restore-release-please.md`; that decision is not this
pull request's to make.

### Related Issue

```
Fixes #NN
```

`#NN` is the issue from `issue-okdp-sandbox-latest-package-versions.md` — **file
it first**, so this pull request has a number to close.

**Not #95.** [#95](https://github.com/OKDP/okdp-sandbox/issues/95) is the
*Phase 4* rename to `1.0.0`, blocked on release-please, and must stay open for
`pr-6`. This pull request is on the current `-pNN` scheme and blocks on nothing.
Do not close #95 with it — but do say in review that this one shrinks it: once
every pin names the published version, Phase 4 is a pure rename with no version
movement hidden inside it.

### Commit

One commit, subject matching the title. `conventional-commits.yml` validates
**every** commit in the pull request, so each must be conventional on its own.

```
feat(packages): move every pin to the published package versions

The 4 September publish dispatch pushed the eight packages whose tag on main
had not yet reached quay.io: airflow 3.2.1-p07, keycloak 24.4.11-p16, kubauth
0.3.0-snapshot-p03, okdp-control-plane-server 0.7.1-p02, polaris
1.3.0-incubating-p07, spark-history-server 3.5.1-p08, superset 6.0.0-p05 and
vault 0.29.1-p03. The other nineteen were skipped as already published.

All 27 packages of platform-packages and sandbox-dependencies are now on the
registry at the version their main branch declares. This moves the sandbox
onto them: eight of the twenty-eight Release pins, and the four console
catalog entries that name the same versions a second time.

The twenty remaining pins already point at the published version and are
untouched, as is the KuboCD controller's own tag in flux/kubocd.yaml.
```

### Body

```markdown
## Description

Every package in `platform-packages` and `sandbox-dependencies` is now published
on quay.io at the version its `main` branch declares — the 4 September `publish`
dispatch closed the last gap by pushing the eight that were behind. This moves
the sandbox onto them, so that a fresh install runs the platform as it stands
today rather than as it stood in August.

We are cutting a whole-platform release, and this is the pull request that makes
"which OKDP am I running?" have one answer.

**Eight of the twenty-eight package pins move:**

| package | from | to | what it brings |
|---|---|---|---|
| `airflow` | `3.2.1-p04` | `3.2.1-p07` | three fixes: `dagsGitSync.ref` mirrored into `branch` (`p05`), triggerer liveness probe given time to answer (`p06`), object-store connection handed to the DAGs (`p07`) |
| `keycloak` | `24.4.11-p14` | `24.4.11-p16` | realm SSO session timeouts exposed and the idle timeout raised to the access-token lifespan (`p15`); users can join groups (`p16`) |
| `kubauth` | `0.3.0-snapshot-p02` | `0.3.0-snapshot-p03` | `ingressClassName` taken from the Context |
| `okdp-control-plane-server` | `0.7.1-p01` | `0.7.1-p02` | proxy settings forwarded from the Context |
| `polaris` | `1.3.0-incubating-p06` | `1.3.0-incubating-p07` | `polaris-console` v0.1.1 — fixes the non-root port 80 crash |
| `spark-history-server` | `3.5.1-p07` | `3.5.1-p08` | login redirected back to the history host; direct ingress dropped in favour of the proxy |
| `superset` | `6.0.0-p04` | `6.0.0-p05` | chart locale parameter |
| `vault` | `0.29.1-p02` | `0.29.1-p03` | `ingressClassName` taken from the Context |

The other twenty pins already point at the published version and are untouched.

**Four console catalog entries move with them.**
`clusters/sandbox/contexts/platform-context.yaml` repeats the version of seven
services in `versions:` and `default:`. `polaris`, `superset`, `airflow` and
`spark-history-server` are updated there too — otherwise the console's
*(recommended)* label keeps naming a tag nothing updates any more.

**Not touched:** `clusters/sandbox/flux/kubocd.yaml:30`, `tag: v0.3.2`. That is
the KuboCD controller's own version, not a package pin, and rewriting it breaks
the install. It is the reason this change was made per-file rather than with a
blanket `sed` on `tag:`.

**Not a rename to `1.0.0`.** That is Phase 4, after release-please takes over the
package versions in both package repositories. This pull request is on the
current `-pNN` scheme and makes Phase 4 smaller: every pin will then be at the
published version, so the rename becomes purely mechanical.

**Also worth a decision, out of scope here:**
`quay.io/okdp/platform-packages/spark-defaults:1.0.0-p01` is published and
maintained but referenced by nothing under `clusters/`. It is the only one of the
27 packages the sandbox does not consume.

## Related Issue

Fixes #NN

Not #95. That one is the Phase 4 rename to `1.0.0`, once release-please owns the
package versions in both package repositories, and it stays open. This pull
request removes the version drift from that change so the rename stays purely
mechanical.

## Type of Change

- [ ] Bug fix
- [x] New feature
- [ ] Documentation update
- [ ] Refactor / chore
- [ ] Breaking change

## How to Test

1. `deploy-validation` is the real test. It stands up Kind + Flux + KuboCD and
   applies `clusters/sandbox/{contexts,releases}` against the new pins, pulling
   each package from quay. A tag that is not there, or a package that has
   genuinely broken, fails here.

2. Confirm the eight new tags resolve before reviewing:

   ```sh
   for r in platform-packages/airflow:3.2.1-p07 \
            platform-packages/polaris:1.3.0-incubating-p07 \
            platform-packages/superset:6.0.0-p05 \
            platform-packages/spark-history-server:3.5.1-p08 \
            platform-packages/okdp-control-plane-server:0.7.1-p02 \
            sandbox-dependencies/keycloak:24.4.11-p16 \
            sandbox-dependencies/kubauth:0.3.0-snapshot-p03 \
            sandbox-dependencies/vault:0.29.1-p03
   do oras manifest fetch --descriptor "quay.io/okdp/$r" >/dev/null \
        && echo "ok   $r" || echo "MISSING $r"; done
   ```

3. Watch the four with behaviour changes, not just version changes:
   `spark-history-server` lost its direct ingress and now answers only through
   the proxy; `polaris` moves to a console image that no longer needs root;
   `keycloak` and `vault` take `ingressClassName` from the Context rather than a
   literal. If the run fails, it is almost certainly one of these.

4. In the console, open the version dropdown for `airflow` or `superset`. It
   lists tags live from the registry, so the older `-pNN` tags are still there —
   confirm the new one carries *(recommended)*, which comes from `default:`.
   Ordering is a separate known problem (`okdp-control-plane-server` sorts tags
   reverse-lexicographically); do not treat it as a fault in this pull request.

5. A clean install from scratch, not only the CI run.

## Checklist

- [x] I have tested my changes
- [ ] Documentation updated if needed
- [ ] If breaking change: migration path described above
- [x] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [x] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
```

---

## Making the changes by hand

Twelve lines, six files. Every edit is one version string.

### 1. The eight package pins

| file | line | package | from | to |
|---|---|---|---|---|
| `clusters/sandbox/optional/kubauth/kubauth.yaml` | 29 | `kubauth` | `0.3.0-snapshot-p02` | `0.3.0-snapshot-p03` |
| `clusters/sandbox/optional/vault/vault.yaml` | 29 | `vault` | `0.29.1-p02` | `0.29.1-p03` |
| `clusters/sandbox/project-demo/50-services.yaml` | 56 | `polaris` | `1.3.0-incubating-p06` | `1.3.0-incubating-p07` |
| `clusters/sandbox/project-demo/50-services.yaml` | 145 | `superset` | `6.0.0-p04` | `6.0.0-p05` |
| `clusters/sandbox/project-demo/50-services.yaml` | 178 | `airflow` | `3.2.1-p04` | `3.2.1-p07` |
| `clusters/sandbox/project-demo/50-services.yaml` | 357 | `spark-history-server` | `3.5.1-p07` | `3.5.1-p08` |
| `clusters/sandbox/releases/keycloak.yaml` | 26 | `keycloak` | `24.4.11-p14` | `24.4.11-p16` |
| `clusters/sandbox/releases/okdp-control-plane-server.yaml` | 28 | `okdp-control-plane-server` | `0.7.1-p01` | `0.7.1-p02` |

Each old string is unique within its file, so a plain substitution is safe
here — unlike the Phase 4 change, which rewrites every pin at once:

```sh
cd clusters/sandbox
# macOS; drop the '' on Linux
sed -i '' 's/0\.3\.0-snapshot-p02/0.3.0-snapshot-p03/' optional/kubauth/kubauth.yaml
sed -i '' 's/0\.29\.1-p02/0.29.1-p03/'                 optional/vault/vault.yaml
sed -i '' 's/24\.4\.11-p14/24.4.11-p16/'               releases/keycloak.yaml
sed -i '' 's/0\.7\.1-p01/0.7.1-p02/'                   releases/okdp-control-plane-server.yaml
sed -i '' -e 's/1\.3\.0-incubating-p06/1.3.0-incubating-p07/' \
          -e 's/6\.0\.0-p04/6.0.0-p05/' \
          -e 's/3\.2\.1-p04/3.2.1-p07/' \
          -e 's/3\.5\.1-p07/3.5.1-p08/' project-demo/50-services.yaml
```

### 2. The four console catalog entries

`clusters/sandbox/contexts/platform-context.yaml`, lines 74, 82, 90 and 94. Each
carries the version **twice** — in `versions:` and in `default:` — and both must
move. Keep the inline flow style already used:

```yaml
            - { name: polaris, versions: ["1.3.0-incubating-p07"], default: "1.3.0-incubating-p07", description: Apache Polaris Iceberg catalog }
            - { name: superset, versions: ["6.0.0-p05"], default: "6.0.0-p05", description: Superset }
            - { name: airflow, versions: ["3.2.1-p07"], default: "3.2.1-p07", description: Apache Airflow }
            - { name: spark-history-server, versions: ["3.5.1-p08"], default: "3.5.1-p08", description: Spark History Server }
```

`hive-metastore` (73), `trino` (78) and `jupyterhub` (86) do not change.

```sh
sed -i '' -e 's/1\.3\.0-incubating-p06/1.3.0-incubating-p07/g' \
          -e 's/6\.0\.0-p04/6.0.0-p05/g' \
          -e 's/3\.2\.1-p04/3.2.1-p07/g' \
          -e 's/3\.5\.1-p07/3.5.1-p08/g' clusters/sandbox/contexts/platform-context.yaml
```

### 3. Nothing else

`defaultRepository` does not change. Package names do not change.
`flux/kubocd.yaml` does not change.

---

## Check your work

Expected: **6 files changed, 12 insertions(+), 12 deletions(-)**.

```sh
git diff --stat
```

Every pin equals the tag its package declares on `main`, and the KuboCD
controller version is the only `tag:` left that is not a package pin:

```sh
grep -rn 'tag:' clusters/ | wc -l          # 29
grep -rn 'tag: v0.3.2$' clusters/          # exactly clusters/sandbox/flux/kubocd.yaml:30

# no stale version string survives anywhere
grep -rnE '3\.2\.1-p04|24\.4\.11-p14|0\.3\.0-snapshot-p02|0\.7\.1-p01|1\.3\.0-incubating-p06|3\.5\.1-p07|6\.0\.0-p04|0\.29\.1-p02' clusters/ \
  || echo "no stale pins left"
```

Every pin resolves on the registry, and the catalog agrees with the pins:

```sh
python3 - <<'PY'
import re,glob,pathlib,urllib.request,json,yaml
pins={}
for f in glob.glob('clusters/**/*.yaml',recursive=True):
    L=pathlib.Path(f).read_text().split('\n')
    for i,l in enumerate(L):
        m=re.search(r'repository:\s*quay\.io/okdp/(platform-packages|sandbox-dependencies)/([\w.-]+)',l)
        if not m: continue
        for j in range(i+1,i+6):
            t=re.match(r'^\s*tag:\s*(\S+)',L[j])
            if t: pins[(m.group(1),m.group(2))]=t.group(1); break
print(len(pins),"distinct package pins")
for (repo,pkg),tag in sorted(pins.items()):
    u=f"https://quay.io/v2/okdp/{repo}/{pkg}/tags/list"
    tags=json.load(urllib.request.urlopen(u,timeout=30)).get("tags") or []
    print(("ok   " if tag in tags else "FAIL "),f"{repo}/{pkg}:{tag}")

for d in yaml.safe_load_all(open('clusters/sandbox/contexts/platform-context.yaml')):
    sc=((d or {}).get('spec',{}).get('context',{}) or {}).get('serviceCatalog')
    if not sc: continue
    for c in sc['categories']:
        for s in c.get('services',[]):
            assert s['versions']==[s['default']], s
            assert pins[('platform-packages',s['name'])]==s['default'], s
    print("catalog agrees with the pins")
PY
```

All 28 `tag:` lines under a `quay.io/okdp/…` repository were checked this way on
4 Sep 2026 against the live registry: **28 pins, 26 distinct packages, zero
mismatches**, and all 30 YAML files under `clusters/` parse.

---

## Not in this PR

- **The rename to `1.0.0`.** Phase 4, `pr-6-okdp-sandbox-repoint-packages.md`,
  after `platform-packages` #74 and `sandbox-dependencies` #37 merge and the
  baseline is published. This pull request does not replace it — it removes the
  version drift from it, so Phase 4 becomes a pure rename.
- **`spark-defaults`.** Published, maintained, referenced nowhere. Needs a
  decision (archive it, or add the missing Release), not a pin.
- **The catalog being a third copy of every version.** `issue-catalog-drift.md`,
  still unfiled. Note the server already lists versions live from the registry,
  so `versions:` is arguably redundant already and only `default:` needs
  authoring.
- **The console tag ordering fix**, `pr-7-control-plane-server-version-order.md`.
  Not yet a live problem: every tag in play here is still `-pNN`, so the existing
  reverse-lexicographic sort happens to be right. It breaks the moment the first
  `1.0.x` is published.
- **Making `Conventional Commits` and `tag-must-move` required checks** on the
  two package repositories. Load-bearing from Phase 2 on, and still not enforced.
