# Issue: `OKDP/okdp.io`

> Org template: [`feature_request.yml`](https://github.com/OKDP/.github/blob/main/.github/ISSUE_TEMPLATE/feature_request.yml), labels `enhancement`.

### Title

```
Flag on /stack that OKDP 1.0 ships a retired Ingress NGINX
```

---

### Problem Statement

`/stack/okdp-1-0` lists Ingress NGINX the way it lists everything else (name,
version, provenance, chart) with nothing to say that the project behind it no
longer exists.

That is not a small omission. The Kubernetes project **retired Ingress NGINX on
19 March 2026**. SIG Network and the Security Response Committee
[announced it in November 2025](https://www.kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)
and [restated it in January 2026](https://www.kubernetes.io/blog/2026/01/29/ingress-nginx-statement/).
Since the final release there have been no releases, no bugfixes, and **no fixes
for any security vulnerability discovered from that date onward**. Existing
deployments keep running and the artifacts stay downloadable; nothing is coming to
repair them.

Shipping it in 1.0 is a deliberate, defensible decision. The team has agreed the
controller stays as-is for 1.0 and the migration (Gateway API, or another
controller such as Traefik) is decided after v1. What is not defensible is an
inventory page that presents that decision as an ordinary dependency. The page
exists to tell people what they are running. Someone evaluating OKDP, or auditing
it for a security review, should learn this from the inventory rather than from a
CVE feed.

**There is a second fact the notice has to reckon with.** The retired version and
the shipped version are not the same thing:

| | Chart | Controller | Date |
|---|---|---|---|
| OKDP 1.0 ships | `4.12.1` | `v1.12.1` | Mar 2025 |
| Upstream's final release | `4.15.1` | `v1.15.1` | 19 Mar 2026 |

So OKDP is not on "the last Ingress NGINX". It is three minor versions and roughly
a year of fixes behind the last one, including everything published across
`1.13.x`, `1.14.x` and `1.15.x` during the wind-down, when the project was
explicitly triaging security work ahead of retirement.

Those are two separate statements, and only the first is a decision:

- *We ship a retired controller*: agreed, post-v1 migration.
- *We ship a version a year behind the last retired release*: not agreed
  anywhere; it is drift.

### Proposed Solution

**On the site: a per-component notice, driven by data rather than hardcoded.**

`scripts/stack-metadata.yaml` already exists for exactly this class of thing,
curated presentation facts that cannot be derived from the manifests. Add an
optional `notice` there:

```yaml
  ingress-nginx:
    name: Ingress NGINX
    upstream: https://github.com/kubernetes/ingress-nginx
    notice:
      level: warning
      key: ingress-nginx-retired
```

carry it through `build-stack.mjs` → `StackComponent` → `ComponentRow.astro`, and
keep the wording in `src/i18n/{en,fr}.json` under `stackPage.notices.*` so it is
translated like everything else. The next component that needs a caveat then costs
three lines of YAML.

Draft wording (EN):

> **Retired upstream.** The Kubernetes project retired Ingress NGINX in March 2026;
> it receives no further releases, bugfixes or security updates. OKDP 1.0 ships it
> deliberately and existing deployments keep working. The migration path, whether
> Gateway API or another controller, will be decided after 1.0.

**One design question for the team.** `d71d554` removed the pre-release badge from
the summary row, so the appetite for badges there is unclear. Two options:

1. **Callout in the expanded panel only.** Quieter, consistent with `d71d554`.
   Costs a click to discover.
2. **Callout plus a small marker in the summary row.** Visible while scanning,
   which is how someone auditing the stack actually reads the page, but it
   reintroduces the row decoration that was just taken out.

Recommendation: option 2 for this specific case, since a security-relevant fact
that needs a click is doing half a job, but this is the team's call and the data
model above supports either without change.

### Alternatives Considered

- **A page-level banner.** Wrong scope: it is one component out of 27, and a
  banner would attach the warning to the whole release.
- **Hardcode the notice in `ComponentRow.astro`.** Smallest diff, but it puts
  English prose in a component (breaking FR), and the second component needing a
  caveat forces the refactor anyway.
- **Say nothing until the migration is decided.** This is what the feedback is
  pushing back on. The decision is deferred to post-v1; the shipping is happening
  now. The page describes what ships.
- **Bump to `4.15.1` and skip the notice.** Not an alternative. It is a separate
  and additional action. `4.15.1` is still retired; it just carries a year more
  fixes. The notice is needed either way.

### Additional Context

- Retirement announcement: <https://www.kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/>
- Steering / SRC statement: <https://www.kubernetes.io/blog/2026/01/29/ingress-nginx-statement/>
- Final releases (`helm-chart-4.15.1`, `controller-v1.15.1`, 19 Mar 2026):
  <https://github.com/kubernetes/ingress-nginx/releases>
- Migration tooling, if useful when the post-v1 decision is taken:
  [Ingress2Gateway 1.0](https://kubernetes.io/blog/2026/03/20/ingress2gateway-1-0-release)

**Current state in the inventory** (`src/data/stack/okdp-1-0.yaml`):

```yaml
- id: ingress-nginx
  name: Ingress NGINX
  section: dependencies
  upstreamVersion: 4.12.1
  package:
    repository: quay.io/okdp/sandbox-dependencies/ingress-nginx
    tag: 4.12.1-p03
  primaryChart:
    name: ingress-nginx
    version: 4.12.1
    repository: https://kubernetes.github.io/ingress-nginx
    origin: upstream
```

**Out of scope for this issue, but worth a decision before 1.0:** whether to bump
`sandbox-dependencies` to chart `4.15.1`. It is a version bump of an upstream chart
with no controller swap, so it does not touch the post-v1 migration question at
all, and it collects every fix upstream ever shipped. Belongs in
`OKDP/sandbox-dependencies`, not here. This issue only covers telling people what
we ship.
