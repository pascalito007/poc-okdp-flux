# Issue — `OKDP/okdp-sandbox`

> Org template: [`bug_report.yml`](https://github.com/OKDP/.github/blob/main/.github/ISSUE_TEMPLATE/bug_report.yml) — labels `bug`.

### Title

```
The console catalog and the deployed package pins are two hand-kept lists, and they drift
```

---

### Describe the Bug

A package version is written in **three** places across two repositories, and
nothing keeps them in step:

| # | Where | Field |
|---|---|---|
| 1 | `platform-packages` or `sandbox-dependencies` | `tag:` in the package manifest |
| 2 | `okdp-sandbox` | `spec.package.tag` on each Release (`clusters/…/50-services.yaml`, `releases/*.yaml`) |
| 3 | `okdp-sandbox` | `versions:` **and** `default:` in `spec.context.serviceCatalog`, `clusters/sandbox/contexts/platform-context.yaml` |

Bumping one package therefore means four edits. Copy 3 is what the Control Plane
server serves to the console: `context_repository.go` reads `versions` and
`default` straight off the Context, and the console renders them in the order the
server supplies (`versionOptionsFor`, `service-utils.ts`, which does not sort).

**Corrected 2 Sep 2026 — the sentence here previously read "Nothing queries the
registry and nothing sorts".** That stopped being true on 20 Aug. At
`okdp-control-plane-server` `9014410`, `GetServiceVersions` and
`ListVersionsForServices` both list tags **live from the registry** via
`listOCITags`, and copy 3's `versions:` is only the fallback used when that call
fails. `default:` is still read straight from the Context and is what the console
labels *(recommended)*.

That makes the duplication worse, not better: copy 3's `versions:` list is
largely dead weight — the registry is already the source of truth for what exists
— while `default:` remains hand-maintained and is the copy that actually drifts.
The server also sorts those tags lexicographically, which is its own defect;
see the version-ordering issue and `pr-7-control-plane-server-version-order.md`.

When copy 3 lags behind copy 2, the console offers a version that is not the one
the cluster is running — and because each service currently lists exactly one
version, it is the *only* version on offer.

### Steps to Reproduce

Comparing `serviceCatalog.default` against the `spec.package.tag` actually pinned,
at each commit that touched the Context. Saved as `catalog-drift.py`:

```python
#!/usr/bin/env python3
"""Compare serviceCatalog defaults against the package tags actually pinned."""
import subprocess, yaml
CTX = "clusters/sandbox/contexts/platform-context.yaml"
sh = lambda *a: subprocess.run(a, capture_output=True, text=True).stdout

for line in sh("git","log","--format=%H|%ad","--date=short","origin/main","--",CTX).strip().split("\n"):
    h, date = line.split("|")
    catalog = {}
    for doc in yaml.safe_load_all(sh("git","show",f"{h}:{CTX}")):
        sc = ((doc or {}).get("spec", {}) or {}).get("context", {}).get("serviceCatalog")
        if not sc: continue
        services = [s for c in sc["categories"] for s in c.get("services", [])] \
                   if "categories" in sc else sc.get("services", [])
        catalog.update({s["name"]: s.get("default") for s in services if s.get("name")})

    pins = {}
    for f in sh("git","ls-tree","-r","--name-only",h,"clusters/").split():
        if not f.endswith((".yaml", ".yml")): continue
        try: docs = list(yaml.safe_load_all(sh("git","show",f"{h}:{f}")))
        except yaml.YAMLError: continue
        for doc in docs:
            pkg = ((doc or {}).get("spec", {}) or {}).get("package") if isinstance(doc, dict) else None
            if isinstance(pkg, dict) and "repository" in pkg:
                pins[str(pkg["repository"]).rsplit("/", 1)[-1]] = pkg.get("tag")

    bad = [f"{k}: catalog={catalog[k]} pin={pins[k]}"
           for k in sorted(catalog) if k in pins and catalog[k] != pins[k]]
    print(f"{date}  {h[:8]}  {' | '.join(bad) if bad else 'in sync'}")
```

```console
$ git clone https://github.com/OKDP/okdp-sandbox && cd okdp-sandbox
$ python3 catalog-drift.py
2026-08-23  208da159  in sync
2026-08-23  e1dd2134  spark-history-server: catalog=3.5.1-p06 pin=3.5.1-p05
2026-08-22  b7135125  airflow: catalog=3.2.1-p03 pin=3.2.1-p04 | jupyterhub: catalog=4.3.3-p04 pin=4.3.3-p05 | polaris: catalog=1.3.0-incubating-p03 pin=1.3.0-incubating-p06 | superset: catalog=6.0.0-p03 pin=6.0.0-p04 | trino: catalog=480.0.0-p20 pin=480.0.0-p21
2026-08-21  ba8a2def  in sync
2026-08-13  7a53a480  in sync
```

### Expected Behavior

The version the console offers is the version the cluster runs. Ideally the catalog
is generated from the pins rather than maintained beside them, so the two cannot
disagree.

### Actual Behavior

They disagreed for at least two days last week. At `b7135125` (22 Aug), five of
seven services were wrong:

| Service | Catalog offered | Actually deployed |
|---|---|---|
| `trino` | `480.0.0-p20` | `480.0.0-p21` |
| `superset` | `6.0.0-p03` | `6.0.0-p04` |
| `polaris` | `1.3.0-incubating-p03` | `1.3.0-incubating-p06` |
| `jupyterhub` | `4.3.3-p04` | `4.3.3-p05` |
| `airflow` | `3.2.1-p03` | `3.2.1-p04` |

and again at `e1dd2134` (23 Aug), `spark-history-server` offered `3.5.1-p06` while
`3.5.1-p05` was deployed — the catalog ahead of the pin that time.

Anyone deploying Trino from the console during that window got `p20`, three
revisions behind the running platform. It is back in sync at `HEAD`, but it
self-corrected as a side effect of the next bump, not through any mechanism.

### Environment

- `okdp-sandbox` `origin/main` as of 2026-08-26 (`84acc00`)
- `okdp-control-plane-server` v0.7.1 — no semver dependency in `go.mod`; the
  catalog is served verbatim from the Context
- `okdp-control-plane-ui` v0.7.0 — `versionOptionsFor()` does not sort; the
  ordering comes from the server

### Logs

Not applicable — nothing logs a warning. Both copies are valid YAML and the
platform reconciles cleanly with either.

### Anything else we need to know?

**Two aggravating factors, both worth their own discussion:**

1. `platform-context.yaml` carries the comment
   `# Written by the console too: a re-apply resets the catalog to this seed.`
   So copy 3 has two writers — this repository and the Control Plane server — with
   no conflict resolution. `84acc00` ("apply the contexts server-side") addresses
   the destructive half of that; the drift described here is separate and survives it.

2. Every service currently lists a single version, which makes the console's
   version picker decoration rather than a control.

**This gets easier, not harder, once packages are released properly.** With
per-package releases, the automated bump PR that updates the Release pins can
append to `versions:` and move `default:` in the same commit — one edit, both
copies, reviewable as a diff. The picker then becomes a real choice: deploy
`trino 1.3.0` or stay on `1.2.0`.

Related: `OKDP/platform-packages#56`, `OKDP/sandbox-dependencies#23` (tag
overwrites), and `OKDP/okdp-sandbox#87` (a package bump that broke the sandbox).
