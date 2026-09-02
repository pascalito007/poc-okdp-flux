# PR 6 — `OKDP/okdp-sandbox` — repoint every package pin to the released versions

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> **Phase 4.** The consumer half of the release-please work. Nothing else in this
> series touches `okdp-sandbox`'s package pins.
> Verified against `okdp-sandbox` `1cf459e` on 2 Sep 2026.

### Branch

```
chore/repoint-packages-to-releases
```

### Title

```
chore(deps): repoint every package to its released version
```

### Related Issue

`Fixes #<number>` — file `issue-okdp-sandbox-repoint-packages.md` first. It is
also the announcement: anyone running their own sandbox from these manifests has
to repoint too.

### Commit

`chore(deps):` — non-bumping, so it adds no changelog entry of its own. The
sandbox's version comes from the work it deploys, not from a pin update.

---

## Do not open this until both are true

**1. `platform-packages` #74 and `sandbox-dependencies` #37 are merged.**

**2. The baseline has been published in *both* repos** — Actions → **publish** →
Run workflow. Merging alone publishes nothing: release-please finds only
`chore:` commits and cuts no release. Until the dispatch runs, `1.0.0` does not
exist on quay.io and every pin in this pull request points at a tag that is not
there.

Check before starting, for both registries:

```sh
for p in airflow hive-metastore jupyterhub okdp-examples polaris spark-defaults \
         spark-history-server spark-operator spark-rbac superset trino \
         okdp-control-plane-server okdp-control-plane-ui
do
  printf '%-28s %s\n' "$p" "$(curl -s https://quay.io/v2/okdp/platform-packages/$p/tags/list | grep -o '1\.0\.0' | head -1 || echo MISSING)"
done

for p in seaweedfs cert-manager cloudnative-pg cnpg-postgresql coredns-patch \
         dns-server external-secrets ingress-nginx keycloak kubauth \
         kubocd-webhooks local-secrets-provider tools vault
do
  printf '%-28s %s\n' "$p" "$(curl -s https://quay.io/v2/okdp/sandbox-dependencies/$p/tags/list | grep -o '1\.0\.0' | head -1 || echo MISSING)"
done
```

All 27 must print `1.0.0`. Any `MISSING` means the baseline publish has not run,
or did not cover that package.

## This is an upgrade, not a rename

Say this in review, because the diff looks mechanical and is not.

`1.0.0` is built from each package repository's current `main`. **Seven pins are
behind that today**, so repointing ships whatever landed on main since they were
last pinned:

| package | sandbox pin today | what `1.0.0` contains |
|---|---|---|
| `airflow` | `3.2.1-p04` | main, i.e. `p06` |
| `keycloak` | `24.4.11-p14` | main, i.e. `p16` |
| `kubauth` | `0.3.0-snapshot-p02` | main, i.e. `p03` |
| `okdp-control-plane-server` | `0.7.1-p01` | main, i.e. `p02` |
| `polaris` | `1.3.0-incubating-p06` | main, i.e. `p07` |
| `spark-history-server` | `3.5.1-p07` | main, i.e. `p08` |
| `vault` | `0.29.1-p02` | main, i.e. `p03` |

The other 21 pins already match main, so for those this really is only a rename.

`deploy-validation.yml` runs a full Kind + Flux + KuboCD deploy on any pull
request touching `clusters/**`, pulling the pinned packages from quay. That is
the gate: if one of those seven upgrades breaks the platform, this pull request
fails rather than the user.

---

## The changes

Three groups. **28 package pins**, **7 catalog `versions:` lists** and the **7
matching `default:` values** — the last two live on the same seven lines.

### 1. The 28 package pins

Every one becomes `tag: 1.0.0`.

| file | line | package | today |
|---|---|---|---|
| `optional/kubauth/kubauth.yaml` | 29 | kubauth | `0.3.0-snapshot-p02` |
| `optional/storage/storage.yaml` | 26 | seaweedfs | `4.17.0-p08` |
| `optional/vault/vault.yaml` | 29 | vault | `0.29.1-p02` |
| `project-demo/10-secrets.yaml` | 28 | local-secrets-provider | `1.0.0-p06` |
| `project-demo/20-storage-demo.yaml` | 31 | seaweedfs | `4.17.0-p08` |
| `project-demo/50-services.yaml` | 33 | hive-metastore | `4.0.1-p02` |
| `project-demo/50-services.yaml` | 56 | polaris | `1.3.0-incubating-p06` |
| `project-demo/50-services.yaml` | 96 | trino | `480.0.0-p21` |
| `project-demo/50-services.yaml` | 145 | superset | `6.0.0-p04` |
| `project-demo/50-services.yaml` | 178 | airflow | `3.2.1-p04` |
| `project-demo/50-services.yaml` | 215 | jupyterhub | `4.3.3-p06` |
| `project-demo/50-services.yaml` | 357 | spark-history-server | `3.5.1-p07` |
| `project-demo/examples/okdp-examples.yaml` | 35 | okdp-examples | `1.3.0-p08` |
| `releases/cert-manager.yaml` | 26 | cert-manager | `1.17.1-p08` |
| `releases/cloudnative-pg.yaml` | 30 | cloudnative-pg | `1.29.1-p01` |
| `releases/cnpg-postgresql.yaml` | 26 | cnpg-postgresql | `18.3-p03` |
| `releases/coredns-patch.yaml` | 26 | coredns-patch | `1.0.0-p05` |
| `releases/dns-server.yaml` | 28 | dns-server | `1.0.0-p04` |
| `releases/external-secrets.yaml` | 26 | external-secrets | `0.15.1-p03` |
| `releases/ingress-nginx.yaml` | 26 | ingress-nginx | `4.12.1-p03` |
| `releases/keycloak.yaml` | 26 | keycloak | `24.4.11-p14` |
| `releases/local-secrets-provider.yaml` | 26 | local-secrets-provider | `1.0.0-p06` |
| `releases/okdp-control-plane-server.yaml` | 28 | okdp-control-plane-server | `0.7.1-p01` |
| `releases/okdp-control-plane-ui.yaml` | 28 | okdp-control-plane-ui | `0.7.0-p01` |
| `releases/spark-operator.yaml` | 10 | spark-operator | `2.4.0-p04` |
| `releases/spark-rbac.yaml` | 10 | spark-rbac | `1.0.1-p02` |
| `releases/tools.yaml` | 26 | tools | `1.0.0-p01` |
| `releases/webhooks.yaml` | 28 | kubocd-webhooks | `v0.3.2-p01` |

Paths are relative to `clusters/sandbox/`.

**Do not run a blind search-and-replace on `tag:`.** There are **29** `tag:`
lines under `clusters/`, and one of them is not a package pin:

```
clusters/sandbox/flux/kubocd.yaml:30    tag: v0.3.2
```

That is the KuboCD controller's own version. Rewriting it breaks the install.

The safe form scopes the edit to a `tag:` line that directly follows a
`repository: quay.io/okdp/...` line:

```sh
# macOS; drop the '' on Linux
find clusters -name '*.yaml' -exec \
  sed -i '' -E '/repository: quay\.io\/okdp\//{n;s/^( *tag: ).*/\11.0.0/;}' {} +
```

That covers **27 of the 28**. One pin has a comment between the two lines and is
missed:

```
clusters/sandbox/releases/webhooks.yaml
  26:     repository: quay.io/okdp/sandbox-dependencies/kubocd-webhooks
  27:     # Follows the controller: the package wraps the matching kubocd-wh chart.
  28:     tag: v0.3.2-p01
```

Edit that one by hand, then confirm:

```sh
grep -rn 'tag:' clusters/ | grep -v 'tag: 1.0.0' 
# expect exactly one line: clusters/sandbox/flux/kubocd.yaml:30:    tag: v0.3.2
```

### 2. The console catalog

`clusters/sandbox/contexts/platform-context.yaml`, lines 73–94. Seven services,
each carrying a `versions:` list **and** a `default:` — both must move, or the
console's "(recommended)" label keeps pointing at a tag nothing updates any more.

| line | service | today |
|---|---|---|
| 73 | hive-metastore | `4.0.1-p02` |
| 74 | polaris | `1.3.0-incubating-p06` |
| 78 | trino | `480.0.0-p21` |
| 82 | superset | `6.0.0-p04` |
| 86 | jupyterhub | `4.3.3-p06` |
| 90 | airflow | `3.2.1-p04` |
| 94 | spark-history-server | `3.5.1-p07` |

Each becomes, in the inline flow style already used:

```yaml
            - { name: trino, versions: ["1.0.0"], default: "1.0.0", description: Trino }
```

Note the catalog covers only the seven `platform-packages` services — its
`defaultRepository` is `quay.io/okdp/platform-packages`. The `sandbox-dependencies`
packages have no catalog entry and need no change here.

### 3. Nothing else

`defaultRepository` does not change. Package names do not change. Only versions.

## Check your work

```sh
# every pin is 1.0.0, and the KuboCD controller version is untouched
grep -rn 'tag:' clusters/ | grep -v 'tag: 1.0.0'
# expect exactly: clusters/sandbox/flux/kubocd.yaml:30:    tag: v0.3.2

# no -pNN survives anywhere
grep -rn -E '\-p[0-9]{2}|incubating|snapshot' clusters/ || echo "no legacy tags left"

# the context still parses
python3 -c "import yaml;list(yaml.safe_load_all(open('clusters/sandbox/contexts/platform-context.yaml')));print('context ok')"

# catalog versions and defaults agree
python3 - <<'PY'
import yaml
for d in yaml.safe_load_all(open('clusters/sandbox/contexts/platform-context.yaml')):
    if not d: continue
    sc=(d.get('spec',{}).get('context',{}) or {}).get('serviceCatalog')
    if not sc: continue
    for c in sc['categories']:
        for s in c.get('services',[]):
            assert s['versions']==["1.0.0"] and s['default']=="1.0.0", s
    print("catalog ok")
PY

git diff --stat   # expect 23 files: 22 pin files + platform-context.yaml
```

## How to Test

1. **`deploy-validation` is the real test.** It stands up Kind + Flux + KuboCD
   and applies `clusters/sandbox/{contexts,releases}` against the new pins. A
   missing tag on quay, or a package that has genuinely broken, fails here.

2. **Watch the seven upgrades.** `airflow`, `keycloak`, `kubauth`,
   `okdp-control-plane-server`, `polaris`, `spark-history-server` and `vault`
   move to code that has not been deployed in the sandbox before. If the run
   fails, it is almost certainly one of these, not the rename.

3. **The console.** After deploying, open the version dropdown for a service.
   It lists tags live from the registry, so it will show **both** `1.0.0` and the
   legacy `-pNN` tags — the old ones are not deleted. Confirm `1.0.0` is marked
   *(recommended)*, which comes from `default:`.

   Ordering is a separate known problem: the server sorts tags
   reverse-lexicographically, so `480.0.0-p21` sits above `1.0.0` until that is
   fixed. Do not treat that as a fault in this pull request.

4. **A clean install from scratch**, not just the CI run — this is what a new
   user does, and it is the last chance to catch a pin that resolves only
   because something was already cached.

## If a package has moved past `1.0.0`

If a real release lands in either package repository between the baseline
publish and this pull request, that package's pin is `1.0.1` or `1.1.0`, not
`1.0.0`. Check before opening:

```sh
curl -s https://quay.io/v2/okdp/platform-packages/trino/tags/list
```

and use the highest released version for each. The tables above assume the
baseline is the newest thing published.

## Not in this PR

- **The catalog being a third copy of every version.** Repointing it keeps the
  duplication alive. `issue-catalog-drift.md` covers removing it — and note the
  server already lists versions live from the registry, so the `versions:` list
  is arguably redundant already and only `default:` needs authoring.
- **The automated bump pull request** into this repository when a package
  releases. Needs a machine account: `GITHUB_TOKEN` cannot write across repos.
- **The console tag ordering fix**, which belongs in
  `okdp-control-plane-server`.
