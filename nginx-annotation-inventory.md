# NGINX annotations across the OKDP organisation

**Ingress controller migration — impact inventory**

Every controller-specific Ingress annotation in the OKDP GitHub organisation, what it does, and what
happens to it under Traefik and under Cilium — plus the couplings that are not annotations at all and
will break just as loudly.

| | |
|---|---|
| Compiled | 24 August 2026 |
| Scope | 27 repositories, default branches, `github.com/OKDP` |
| Repos scanned | 27 |
| Distinct nginx annotation keys | **15** |
| Live annotation instances | **29** |
| Ingress objects hardcoding `nginx` | **3** |
| Repos carrying nginx annotations | **7** |
| Keys with no Gateway API equivalent | **9** |

---

## Contents

1. [The short version](#1-the-short-version)
2. [Translation matrix](#2-translation-matrix)
3. [Adjacent annotations](#3-adjacent-annotations)
4. [Occurrence register](#4-occurrence-register)
5. [Beyond annotations](#5-beyond-annotations)
6. [Findings, in priority order](#6-findings-in-priority-order)
7. [Traefik versus Cilium](#7-traefik-versus-cilium)
8. [Method and confidence](#8-method-and-confidence)

---

## 1. The short version

The organisation uses **15 distinct `nginx.ingress.kubernetes.io/*` annotation keys** across
**29 live occurrences**, in just 4 repositories. That number is smaller than it looks: two thirds of the
instances are three annotations — HTTPS redirect, proxy timeouts, and body-size limits — and all three
have clean answers under both Traefik and Gateway API.

The real exposure is concentrated in two places. **[HTTP Basic auth on the SeaweedFS filer](#reg-basic-auth)**
and **[CORS on the kubauth OIDC endpoint](#reg-cors)** are the only annotations that make the ingress
controller do security work on behalf of the application. Neither has a Cilium Ingress equivalent, and
neither survives the move to Gateway API on Cilium: basic auth is not in the specification at all, and
Cilium 1.19 lists the Gateway API `HTTPRouteCORS` filter among its *unsupported* features. Everything else
is a translation exercise.

Two things matter more than the annotation list itself, and neither is an annotation:

- The class name is now read from the platform context nearly everywhere — the variabilisation landed on
  21 August. Only **[3 Ingress objects still hardcode `nginx`](#reg-class-bindings)**: two in the successor
  package set, and one fresh regression in the sandbox's new Vault package. Keeping it at zero is now a
  review problem, not a migration problem.
- The platform's **CoreDNS patch, install-ordering graph and NodePort pinning** all name the nginx
  controller explicitly. These break on day one of any swap, regardless of how many annotations were translated.

> **The one-line answer**
>
> Moving to Traefik is a mechanical translation of 29 annotations into roughly 5 Traefik middlewares plus
> a global HTTPS redirect; every key but `proxy-buffer-size` has somewhere to go, and that one is a re-test
> rather than a rebuild. Moving to Cilium is a different exercise: 10 of the 15 keys are simply ignored by
> Cilium Ingress, and even on Gateway API 9 of them have no equivalent on the pinned 1.19 — body size,
> buffer size, basic auth ×3 and CORS ×4 — and must be re-implemented as Envoy config or moved into the
> applications.

---

## 2. Translation matrix

Ordered by number of live occurrences. "Live" means an Ingress object actually rendered by a package or
chart — documentation samples and commented-out examples are counted separately in
[the register](#4-occurrence-register).

| Status | Meaning |
|---|---|
| ✅ **Direct** | Equivalent exists, mechanical change |
| ⚠️ **Rework** | Different mechanism, behaviour must be re-tested |
| ❌ **None** | Capability is lost unless re-implemented |
| ⬜ **Drop** | Annotation is redundant today |

### `force-ssl-redirect`

`"true"` · 8 live — [see all occurrences ↓](#reg-force-ssl-redirect)

Forces a 308 redirect from HTTP to HTTPS **even when the Ingress has no usable TLS certificate**. Distinct from `ssl-redirect`, which nginx already applies by default once TLS is configured.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ No annotation. Either a `redirectScheme` Middleware per router, or — better — one global `web → websecure` entryPoint redirect that deletes all 8 at once. |
| **Cilium Ingress** | ⚠️ Cilium exposes [`ingress.cilium.io/force-https`](https://github.com/cilium/cilium/blob/v1.19.6/operator/pkg/ingress/annotations/annotations.go#L27). Different key, same intent — confirmed present in the pinned 1.19. |
| **Gateway API** (Cilium / Envoy) | ✅ A `RequestRedirect` filter on an HTTP-listener HTTPRoute. Already proven in the sandbox Gateway API POC. |

### `proxy-body-size`

`"0"`, `"64m"` and `"130m"` · 5 live — [see all occurrences ↓](#reg-proxy-body-size)

Caps the client request body. `0` disables the cap entirely (nginx defaults to 1 MB, which breaks file and DAG uploads); `130m` is a deliberate ceiling on object-storage uploads.

| Target | Outcome |
|---|---|
| **Traefik** | ✅ Traefik imposes no body limit by default, so the `"0"` cases need nothing. The `130m` ceiling needs a `buffering` Middleware with `maxRequestBodyBytes`. |
| **Cilium Ingress** | ❌ No annotation. Uploads stop being capped — the `"0"` intent survives by accident, the `130m` guardrail silently disappears. |
| **Gateway API** (Cilium / Envoy) | ❌ Not modelled by Gateway API. Re-imposing the cap means a CiliumEnvoyConfig with the Envoy buffer filter, or enforcing it in SeaweedFS. |

### `proxy-read-timeout`

300 / 600 / 3600 s · 3 live — [see all occurrences ↓](#reg-proxy-read-timeout)

How long nginx waits for a response from the backend. Raised well above the 60 s default so long-running Trino and Superset queries, and SeaweedFS transfers, are not cut off mid-flight.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ Not a router annotation. Set on the entryPoint (`respondingTimeouts`) and per-service via a `ServersTransport` CRD attached with `service.serverstransport`. |
| **Cilium Ingress** | ✅ [`ingress.cilium.io/request-timeout`](https://github.com/cilium/cilium/blob/v1.19.6/operator/pkg/ingress/annotations/annotations.go#L28) covers this — one timeout rather than nginx's read/send pair. Set it explicitly: unset, Envoy's own route default applies and is far shorter than 3600 s. |
| **Gateway API** (Cilium / Envoy) | ✅ `HTTPRoute.spec.rules[].timeouts.request`. Cilium 1.19 passes the `HTTPRouteRequestTimeout` conformance feature ([report](https://github.com/kubernetes-sigs/gateway-api/blob/main/conformance/reports/v1.4.0/cilium/experimental-v1.19.0-pre.2-default-report.yaml)). Set it explicitly — do not rely on defaults. |

### `proxy-send-timeout`

300 / 3600 s · 2 live — [see all occurrences ↓](#reg-proxy-send-timeout)

Companion to the above, on the request-write side. Always set alongside `proxy-read-timeout` in this codebase.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ Same `ServersTransport` / entryPoint mechanism as the read timeout. |
| **Cilium Ingress** | ⚠️ Folded into [`ingress.cilium.io/request-timeout`](https://github.com/cilium/cilium/blob/v1.19.6/operator/pkg/ingress/annotations/annotations.go#L28) alongside the read timeout — Cilium does not split the two. |
| **Gateway API** (Cilium / Envoy) | ⚠️ Folded into the single HTTPRoute request timeout — Gateway API does not split read and write. |

### `proxy-connect-timeout`

300 s · 1 live — [see all occurrences ↓](#reg-proxy-connect-timeout)

How long to wait to *establish* the upstream connection. 300 s is far beyond anything a healthy in-cluster connect needs — almost certainly copied from the upstream Superset chart's sample values.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ `ServersTransport.forwardingTimeouts.dialTimeout`. |
| **Cilium Ingress** | ❌ No annotation. |
| **Gateway API** (Cilium / Envoy) | ⚠️ Not separately modelled; covered by `timeouts.backendRequest`, which Cilium 1.19 does support ([`HTTPRouteBackendTimeout`](https://github.com/kubernetes-sigs/gateway-api/blob/main/conformance/reports/v1.4.0/cilium/experimental-v1.19.0-pre.2-default-report.yaml)). Safe to drop given the value is unrealistic anyway. |

### `proxy-buffer-size`

`"128k"` · 1 live — [see all occurrences ↓](#reg-proxy-buffer-size)

Enlarges the buffer nginx uses for the first part of the upstream response. In practice this is the fix for "upstream sent too big header" when OIDC session cookies grow large.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ No equivalent knob; Traefik's Go HTTP server has its own header limits. Re-test the Superset OIDC login with a fully-populated session cookie. |
| **Cilium Ingress** | ❌ No annotation. Envoy's own header limits apply; same re-test needed. |
| **Gateway API** (Cilium / Envoy) | ❌ Not modelled. Tunable only via CiliumEnvoyConfig if the login actually breaks. |

### `use-regex`

`"true"` · 1 live — [see all occurrences ↓](#reg-use-regex)

Tells nginx to interpret the Ingress `path` as a regular expression. **Both uses sit on a path of `/`** — there is no regex to interpret, so the annotation does nothing today.

| Target | Outcome |
|---|---|
| **Traefik** | ⬜ Delete before migrating. Traefik matches by path prefix on Ingress; the annotation is ignored. |
| **Cilium Ingress** | ⬜ Ignored. |
| **Gateway API** (Cilium / Envoy) | ⬜ Gateway API has explicit `PathPrefix` / `RegularExpression` match types; the intent is expressed in the route, not an annotation. |

### `auth-type` / `auth-secret` / `auth-realm`

basic · 3 live, one Ingress — [see all occurrences ↓](#reg-basic-auth)

**HTTP Basic authentication performed by the ingress controller** in front of the SeaweedFS filer console, against an htpasswd Secret. The Secret is generated by OKDP's own `seaweedfs-auth-config` chart, which exists purely to feed this annotation.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ A `BasicAuth` Middleware CRD attached via `router.middlewares`. Note the Secret key differs from nginx's — the generator chart needs a small change. |
| **Cilium Ingress** | ❌ Cilium Ingress has no authentication annotations. The filer console becomes **unauthenticated** the moment the class changes. |
| **Gateway API** (Cilium / Envoy) | ❌ Basic auth is not in stable Gateway API. Options: Envoy ext_authz via CiliumEnvoyConfig, an oauth2-proxy sidecar, or drop the console from the ingress entirely. |

### `enable-cors` / `cors-allow-origin` / `cors-allow-methods` / `cors-allow-credentials`

4 live, one Ingress — [see all occurrences ↓](#reg-cors)

**CORS headers injected at the edge** so the OKDP console browser app can call the kubauth OIDC endpoint cross-origin with credentials. Without these the console's login flow fails in the browser, not the cluster.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ A `headers` Middleware with `accessControlAllowOriginList`, `…AllowMethods`, `…AllowCredentials`. Direct one-to-one mapping of the four values. |
| **Cilium Ingress** | ❌ No CORS annotations. Console login breaks with an opaque browser-side CORS error — the hardest failure mode here to diagnose. |
| **Gateway API** (Cilium / Envoy) | ❌ Gateway API defines a CORS filter, but **Cilium 1.19 lists `HTTPRouteCORS` under `unsupportedFeatures`** in its own conformance report ([report](https://github.com/kubernetes-sigs/gateway-api/blob/main/conformance/reports/v1.4.0/cilium/experimental-v1.19.0-pre.2-default-report.yaml)). The filter is accepted by the API server and then silently ignored — preflight is forwarded upstream. Use CiliumEnvoyConfig, or serve CORS from kubauth itself. |

### `backend-protocol`

`"HTTP"` · 1 live — [see all occurrences ↓](#reg-backend-protocol)

Tells nginx to speak plain HTTP to the Keycloak pod rather than HTTPS. **This is already nginx's default** — the annotation is defensive, not functional.

| Target | Outcome |
|---|---|
| **Traefik** | ⬜ Traefik's default service scheme is `http`. Nothing to carry over. |
| **Cilium Ingress** | ⬜ Plain HTTP to the backend is the default. |
| **Gateway API** (Cilium / Envoy) | ⬜ HTTPS-to-backend would be a `BackendTLSPolicy`; plain HTTP needs nothing. |

---

## 3. Adjacent annotations

Portable across Ingress controllers, so easy to overlook — yet two of them change behaviour the moment
the platform moves from Ingress to Gateway API.

### `cert-manager.io/cluster-issuer` — 21 live, 2 in samples

Hands TLS certificate issuance for the Ingress host to cert-manager's ingress-shim, using the platform's
self-signed ClusterIssuer.

✅ **Direct** under Traefik or Cilium Ingress — cert-manager is controller-agnostic.
⚠️ **Rework** under Gateway API: ingress-shim does not watch Gateways unless cert-manager is started with
Gateway API support, and the annotation then belongs on the **Gateway**, not on each route. Twenty-one
annotations collapse into one wildcard certificate on a shared Gateway.

- **`platform-packages`** — [`airflow.yaml:276`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/airflow/airflow.yaml#L276) · [`jupyterhub.yaml:321`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/jupyterhub/jupyterhub.yaml#L321) · [`polaris.yaml:269`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/polaris/polaris.yaml#L269) · [`polaris.yaml:363`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/polaris/polaris.yaml#L363) · [`spark-history-server.yaml:115`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/spark-history-server/spark-history-server.yaml#L115) · [`spark-history-server.yaml:232`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/spark-history-server/spark-history-server.yaml#L232) · [`superset.yaml:398`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/superset/superset.yaml#L398) · [`trino.yaml:444`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/trino/trino.yaml#L444)
- **`sandbox-dependencies`** — [`seaweedfs.yaml:261`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/services/seaweedfs/seaweedfs.yaml#L261) · [`seaweedfs.yaml:302`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/services/seaweedfs/seaweedfs.yaml#L302) · [`keycloak.yaml:174`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/keycloak/keycloak.yaml#L174) · [`vault.yaml:67`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/vault/vault.yaml#L67)
- **`okdp-control-plane-packages`** — [`airflow.yaml:266`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/airflow/airflow.yaml#L266) · [`jupyterhub.yaml:335`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/jupyterhub/jupyterhub.yaml#L335) · [`seaweedfs.yaml:130`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/seaweedfs/seaweedfs.yaml#L130) · [`superset.yaml:235`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/superset/superset.yaml#L235) · [`trino.yaml:177`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/trino/trino.yaml#L177) · [`polaris/…/ingress.yaml:6`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/polaris/charts/polaris/templates/ingress.yaml#L6) · [`spark-web-proxy/…/ingress.yaml:7`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/spark-history-server/charts/spark-web-proxy/templates/ingress.yaml#L7)
- **`okdp-control-plane-dev-sandbox`** — [`vault.yaml:25`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/packages/system/vault/vault.yaml#L25)
- **`okdp-control-plane-ui`** — [`chart/templates/ingress.yaml:8`](https://github.com/OKDP/okdp-control-plane-ui/blob/047e8ff09ec1/chart/templates/ingress.yaml#L8)
- *Samples* — [`okdp-superset/sample-values.yaml:118`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/sample-values.yaml#L118) · [`polaris-console/values.yaml:84`](https://github.com/OKDP/polaris-console/blob/541027b592c5/helm/polaris-console/values.yaml#L84) (commented)

### `kubernetes.io/ingress.class` — 2 live, 8 in charts and samples

The pre-1.18 way of selecting a controller, superseded by the `ingressClassName` field. Honoured by
ingress-nginx, ignored by everything else.

⬜ **Drop it — no longer a landmine.** Both live uses were pinned to `nginx` alongside an already-templated
class field until [`45137e9`](https://github.com/OKDP/platform-packages/commit/45137e928afca8f6d34fcbf46e5e5f93c4c57ad6)
variabilised them on 21 August. They now render from the same context key as `ingressClassName`, so they can
no longer contradict it — but they are dead weight on any non-nginx controller and should simply be deleted.

- **`platform-packages`** — [`airflow.yaml:275`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/airflow/airflow.yaml#L275) · [`superset.yaml:397`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/superset/superset.yaml#L397) — both now `{{ .Context.ingress.className }}`

Three standalone charts re-create the annotation on their own, setting it from `.Values.ingress.className`
whenever the caller has not supplied one — so it reappears on every Ingress they render:

- [`okdp-server/templates/ingress.yaml:6`](https://github.com/OKDP/okdp-server/blob/174c5e83de2c/helm/okdp-server/templates/ingress.yaml#L6) · [`okdp-ui/templates/ingress.yaml:6`](https://github.com/OKDP/okdp-ui/blob/0ad1e75f84d6/helm/okdp-ui/templates/ingress.yaml#L6) · [`spark-web-proxy/templates/ingress.yaml:22`](https://github.com/OKDP/spark-web-proxy/blob/547e02ac3f19/helm/spark-web-proxy/templates/ingress.yaml#L22)

One literal `nginx` survives in a sample, plus four commented-out examples contributors copy from:
[`okdp-superset/sample-values.yaml:117`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/sample-values.yaml#L117) ·
[`okdp-server/values.yaml:282`](https://github.com/OKDP/okdp-server/blob/174c5e83de2c/helm/okdp-server/values.yaml#L282) ·
[`okdp-ui/values.yaml:97`](https://github.com/OKDP/okdp-ui/blob/0ad1e75f84d6/helm/okdp-ui/values.yaml#L97) ·
[`polaris-console/values.yaml:83`](https://github.com/OKDP/polaris-console/blob/541027b592c5/helm/polaris-console/values.yaml#L83) ·
[`spark-web-proxy/values.yaml:129`](https://github.com/OKDP/spark-web-proxy/blob/547e02ac3f19/helm/spark-web-proxy/values.yaml#L129)

### `acme.cert-manager.io/http01-edit-in-place` — 2 occurrences

Makes ACME HTTP-01 solve the challenge by editing the existing Ingress instead of creating a temporary one.

⬜ **Drop it** — inherited from the upstream Superset chart sample. The sandbox uses a self-signed issuer,
so no ACME challenge is ever solved.

- **`platform-packages`** — [`superset.yaml:399`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/superset/superset.yaml#L399)
- **`okdp-superset`** — [`sample-values.yaml:119`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/sample-values.yaml#L119) — the sample it was copied from

### `metallb.universe.tf/loadBalancerIPs` and `…/allow-shared-ip` — 6 occurrences

Service-level annotations, applied only in the package's `metallb` exposure mode. Four sit on the nginx
controller Service; two more sit on the Hive metastore chart's own Service, which the original scan missed.

⚠️ **Rework** — the controller's four move wholesale to whatever Service exposes the replacement. Cilium
replaces MetalLB entirely with `CiliumLoadBalancerIPPool` plus L2 announcements, so the Hive metastore pair
needs the same treatment even though it has nothing to do with ingress.

- **`sandbox-dependencies`** — [`ingress-nginx.yaml:67`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/ingress-nginx/ingress-nginx.yaml#L67) · [`ingress-nginx.yaml:68`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/ingress-nginx/ingress-nginx.yaml#L68)
- **`okdp-control-plane-dev-sandbox`** — [`ingress-nginx.yaml:51`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/packages/system/ingress-nginx/ingress-nginx.yaml#L51) · [`ingress-nginx.yaml:52`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/packages/system/ingress-nginx/ingress-nginx.yaml#L52)
- **`hive-metastore`** — [`service.yaml:33`](https://github.com/OKDP/hive-metastore/blob/b3f1eb6e31ee/helm/hive-metastore/templates/service.yaml#L33) · [`service.yaml:36`](https://github.com/OKDP/hive-metastore/blob/b3f1eb6e31ee/helm/hive-metastore/templates/service.yaml#L36) — not an ingress concern, but the same MetalLB dependency

---

## 4. Occurrence register

The audit trail behind every count in this document. Each location links to the exact line on GitHub,
pinned to the commit that was scanned, so the reference stays valid even after the files move.

Two parallel package generations are in play: `platform-packages` plus `sandbox-dependencies` serve
today's sandbox, while `okdp-control-plane-packages` plus `okdp-control-plane-dev-sandbox` are the
successor set. Both carry nginx annotations, so a migration has to cover both or the debt reappears.

### Live — annotations on Ingress objects the platform actually deploys

*29 occurrences, in 4 repositories. Keys shown without the `nginx.ingress.kubernetes.io/` prefix.*

<a id="reg-force-ssl-redirect"></a>

#### `force-ssl-redirect` — 8 occurrences

> Traefik: global entryPoint redirect · Cilium: `ingress.cilium.io/force-https` · Gateway API: `RequestRedirect` filter

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`jupyterhub.yaml:317`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/jupyterhub/jupyterhub.yaml#L317) | JupyterHub proxy |
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`polaris.yaml:268`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/polaris/polaris.yaml#L268) | Polaris API |
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`polaris.yaml:362`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/polaris/polaris.yaml#L362) | Polaris Console |
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`spark-history-server.yaml:114`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/spark-history-server/spark-history-server.yaml#L114) | Spark History Server |
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`spark-history-server.yaml:231`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/spark-history-server/spark-history-server.yaml#L231) | Spark web proxy |
| `force-ssl-redirect` | `"true"` | `sandbox-dependencies` | [`keycloak.yaml:173`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/keycloak/keycloak.yaml#L173) | Keycloak |
| `force-ssl-redirect` | `"true"` | `okdp-control-plane-packages` | [`jupyterhub.yaml:334`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/jupyterhub/jupyterhub.yaml#L334) | JupyterHub proxy |
| `force-ssl-redirect` | `"true"` | `okdp-control-plane-packages` | [`ingress.yaml:6`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/spark-history-server/charts/spark-web-proxy/templates/ingress.yaml#L6) | Spark web proxy — chart template |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-body-size"></a>

#### `proxy-body-size` — 5 occurrences

> Traefik: `buffering` middleware · Cilium and Gateway API: no equivalent — the `64m` and `130m` caps are lost

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-body-size` | `"0"` | `platform-packages` | [`airflow.yaml:277`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/airflow/airflow.yaml#L277) | Airflow API server |
| `proxy-body-size` | `"64m"` | `platform-packages` | [`jupyterhub.yaml:320`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/jupyterhub/jupyterhub.yaml#L320) | JupyterHub proxy — **added since 19 Aug** |
| `proxy-body-size` | `"130m"` | `sandbox-dependencies` | [`seaweedfs.yaml:260`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/services/seaweedfs/seaweedfs.yaml#L260) | SeaweedFS filer console |
| `proxy-body-size` | `"130m"` | `sandbox-dependencies` | [`seaweedfs.yaml:301`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/services/seaweedfs/seaweedfs.yaml#L301) | SeaweedFS S3 endpoint |
| `proxy-body-size` | `"0"` | `okdp-control-plane-packages` | [`seaweedfs.yaml:131`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/seaweedfs/seaweedfs.yaml#L131) | SeaweedFS |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-read-timeout"></a>

#### `proxy-read-timeout` — 3 occurrences

> Traefik: `ServersTransport` · Cilium Ingress: `ingress.cilium.io/request-timeout` · Gateway API: `timeouts.request` — set explicitly or Envoy's short default applies

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-read-timeout` | `"300"` | `platform-packages` | [`superset.yaml:403`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/superset/superset.yaml#L403) | Superset UI |
| `proxy-read-timeout` | `"3600"` | `platform-packages` | [`trino.yaml:445`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/trino/trino.yaml#L445) | Trino UI |
| `proxy-read-timeout` | `"600"` | `okdp-control-plane-packages` | [`seaweedfs.yaml:132`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/seaweedfs/seaweedfs.yaml#L132) | SeaweedFS |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-send-timeout"></a>

#### `proxy-send-timeout` — 2 occurrences

> Folds into the single Cilium / Gateway API request timeout — neither splits read and write

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-send-timeout` | `"300"` | `platform-packages` | [`superset.yaml:404`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/superset/superset.yaml#L404) | Superset UI |
| `proxy-send-timeout` | `"3600"` | `platform-packages` | [`trino.yaml:446`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/trino/trino.yaml#L446) | Trino UI |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-connect-timeout"></a>

#### `proxy-connect-timeout` — 1 occurrence

> Traefik: `dialTimeout` · the value is unrealistic for an in-cluster connect — safe to drop

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-connect-timeout` | `"300"` | `platform-packages` | [`superset.yaml:402`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/superset/superset.yaml#L402) | Superset UI |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-buffer-size"></a>

#### `proxy-buffer-size` — 1 occurrence

> No equivalent anywhere — re-test the Superset OIDC login with a fully-populated session cookie

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-buffer-size` | `"128k"` | `platform-packages` | [`superset.yaml:405`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/superset/superset.yaml#L405) | Superset UI |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-use-regex"></a>

#### `use-regex` — 1 occurrence

> Sits on path `/` — does nothing today, delete before migrating. The OKDP UI's copy went away with the `okdp-ui` package.

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `use-regex` | `"true"` | `platform-packages` | [`trino.yaml:447`](https://github.com/OKDP/platform-packages/blob/f2a6c0871d6a/packages/services/trino/trino.yaml#L447) | Trino UI |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-basic-auth"></a>

#### `auth-type` · `auth-secret` · `auth-realm` — 3 occurrences

> **The highest-impact group** — no Cilium Ingress equivalent, none in Gateway API

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `auth-type` | `basic` | `sandbox-dependencies` | [`seaweedfs.yaml:262`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/services/seaweedfs/seaweedfs.yaml#L262) | SeaweedFS filer console |
| `auth-secret` | `creds-seaweedfs-filer-basic` | `sandbox-dependencies` | [`seaweedfs.yaml:263`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/services/seaweedfs/seaweedfs.yaml#L263) | SeaweedFS filer console |
| `auth-realm` | `"Authentication Required"` | `sandbox-dependencies` | [`seaweedfs.yaml:264`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/services/seaweedfs/seaweedfs.yaml#L264) | SeaweedFS filer console |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-cors"></a>

#### `enable-cors` · `cors-allow-origin` · `cors-allow-methods` · `cors-allow-credentials` — 4 occurrences

> Traefik: `headers` middleware, one-to-one · Cilium Ingress **and** Gateway API on Cilium 1.19: ignored, console login breaks in the browser

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `enable-cors` | `"true"` | `okdp-control-plane-dev-sandbox` | [`kubauth.yaml:30`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/manifests/platform/kubauth.yaml#L30) | kubauth OIDC |
| `cors-allow-origin` | `"https://console.okdp.dev-sandbox"` | `okdp-control-plane-dev-sandbox` | [`kubauth.yaml:31`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/manifests/platform/kubauth.yaml#L31) | kubauth OIDC |
| `cors-allow-methods` | `"GET, PUT, POST, DELETE, PATCH, OPTIONS"` | `okdp-control-plane-dev-sandbox` | [`kubauth.yaml:32`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/manifests/platform/kubauth.yaml#L32) | kubauth OIDC |
| `cors-allow-credentials` | `"true"` | `okdp-control-plane-dev-sandbox` | [`kubauth.yaml:33`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/manifests/platform/kubauth.yaml#L33) | kubauth OIDC |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-backend-protocol"></a>

#### `backend-protocol` — 1 occurrence

> Already nginx's default — redundant, delete before migrating

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `backend-protocol` | `"HTTP"` | `sandbox-dependencies` | [`keycloak.yaml:172`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/keycloak/keycloak.yaml#L172) | Keycloak |

[↑ back to the matrix](#2-translation-matrix)

### Samples, chart defaults and documentation

Nothing here deploys, but this is what contributors copy from. Leaving it un-migrated is how nginx
annotations come back after the migration is signed off. *15 occurrences.*

| Key | Value | Repository | File and line | Context |
|---|---|---|---|---|
| `proxy-connect-timeout` | `"300"` | `okdp-superset` | [`sample-values.yaml:122`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/sample-values.yaml#L122) | sample values |
| `proxy-read-timeout` | `"300"` | `okdp-superset` | [`sample-values.yaml:123`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/sample-values.yaml#L123) | sample values |
| `proxy-send-timeout` | `"300"` | `okdp-superset` | [`sample-values.yaml:124`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/sample-values.yaml#L124) | sample values |
| `proxy-buffer-size` | `"128k"` | `okdp-superset` | [`sample-values.yaml:125`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/sample-values.yaml#L125) | sample values |
| `proxy-connect-timeout` | `"300" — commented out` | `okdp-superset` | [`values.yaml:510`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/values.yaml#L510) | chart default |
| `proxy-read-timeout` | `"300" — commented out` | `okdp-superset` | [`values.yaml:511`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/values.yaml#L511) | chart default |
| `proxy-send-timeout` | `"300" — commented out` | `okdp-superset` | [`values.yaml:512`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/values.yaml#L512) | chart default |
| `auth-realm` | `Authentication Required` | `spark-history-server` | [`TEST.md:479`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ec/docs/TEST.md#L479) | doc walkthrough |
| `auth-secret` | `creds-seaweedfs-filer-basic` | `spark-history-server` | [`TEST.md:480`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ec/docs/TEST.md#L480) | doc walkthrough |
| `auth-type` | `basic` | `spark-history-server` | [`TEST.md:481`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ec/docs/TEST.md#L481) | doc walkthrough |
| `proxy-body-size` | `130m` | `spark-history-server` | [`TEST.md:482`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ec/docs/TEST.md#L482) | doc walkthrough |
| `proxy-body-size` | `130m` | `spark-history-server` | [`TEST.md:510`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ec/docs/TEST.md#L510) | doc walkthrough |
| `auth-secret` | `<secret-name>` — doc | `helm-charts-utilities` | [`README.md:26`](https://github.com/OKDP/helm-charts-utilities/blob/c82dddb9afa6/charts/seaweedfs-auth-config/README.md#L26) | chart doc |
| `auth-secret` | `<secret-name>` — comment | `helm-charts-utilities` | [`values.yaml:176`](https://github.com/OKDP/helm-charts-utilities/blob/c82dddb9afa6/charts/seaweedfs-auth-config/values.yaml#L176) | chart doc |
| `auth-secret` | `referenced in a comment` | `helm-charts-utilities` | [`filer-auth-secret.yaml:20`](https://github.com/OKDP/helm-charts-utilities/blob/c82dddb9afa6/charts/seaweedfs-auth-config/templates/filer-auth-secret.yaml#L20) | chart doc |

<a id="reg-class-bindings"></a>

### Class bindings — every place `nginx` is named as the controller

Twenty sites now read the class from the platform context. **Fifteen still name `nginx` literally, and only
three of those are Ingress objects the platform actually deploys** — the rest are the two context defaults
themselves, two chart defaults, and eight samples and doc snippets. The variabilisation PRs merged on
21 August; the `In-flight` column they used to need is gone.

**The single switch** — the one value each environment flips.

| Field | Value | Repository | File and line | What it is | Status |
|---|---|---|---|---|---|
| `platform.ingress.className` | `nginx` | `okdp-sandbox` | [`10-platform-context.yaml:33`](https://github.com/OKDP/okdp-sandbox/blob/6650e737d351/clusters/sandbox/contexts/10-platform-context.yaml#L33) | platform-wide default | ⚠️ still nested under `platform:`; [PR #90](https://github.com/OKDP/okdp-sandbox/pull/90) flattens it to `ingress.className` |
| `ingress.className` | `nginx` | `okdp-control-plane-dev-sandbox` | [`default-context.yaml:11`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/clusters/dev/default-context.yaml#L11) | platform-wide default | ✅ already flat |

**Still hardcoded on a deployable Ingress** — the only three that block a class change.

| Field | Value | Repository | File and line | What it is | Status |
|---|---|---|---|---|---|
| `ingressClassName` | `nginx` | `sandbox-dependencies` | [`vault.yaml:65`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/vault/vault.yaml#L65) | Vault | ❌ **new since the 19 Aug scan** — package added after the PRs merged |
| `ingressClassName` | `nginx` | `okdp-control-plane-packages` | [`jupyterhub.yaml:336`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/jupyterhub/jupyterhub.yaml#L336) | JupyterHub proxy | ❌ never converted, no PR open |
| `ingressClassName` | `nginx` | `okdp-control-plane-packages` | [`ingress.yaml:9`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/spark-history-server/charts/spark-web-proxy/templates/ingress.yaml#L9) | Spark web proxy | ❌ in the template; `values.yaml` exposes no `className` to override |

**Chart defaults** — literal, but a package may override them.

| Field | Value | Repository | File and line | What it is | Status |
|---|---|---|---|---|---|
| `className` | `"nginx"` | `okdp-control-plane-packages` | [`polaris/…/values.yaml:15`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/polaris/charts/polaris/values.yaml#L15) | Polaris chart default | ⬜ package overrides it from context |
| `className` | `nginx` | `okdp-control-plane-ui` | [`chart/values.yaml:42`](https://github.com/OKDP/okdp-control-plane-ui/blob/047e8ff09ec1/chart/values.yaml#L42) | Console chart default | ⚠️ no package override — the console is installed by hand |

**Samples and documentation** — nothing deploys, but this is what contributors copy from.

| Field | Value | Repository | File and line | What it is | Status |
|---|---|---|---|---|---|
| `className` | `"nginx"` | `okdp-server` | [`values.keycloak.yaml:208`](https://github.com/OKDP/okdp-server/blob/174c5e83de2c/helm/okdp-server/values.keycloak.yaml#L208) | sample values | ⬜ |
| `className` | `"nginx"` | `okdp-server` | [`values.keycloak.yaml:217`](https://github.com/OKDP/okdp-server/blob/174c5e83de2c/helm/okdp-server/values.keycloak.yaml#L217) | sample values | ⬜ |
| `className` | `"nginx"` | `okdp-ui` | [`values.keycloak.yaml:28`](https://github.com/OKDP/okdp-ui/blob/0ad1e75f84d6/helm/okdp-ui/values.keycloak.yaml#L28) | sample values | ⬜ |
| `ingressClassName` | `"nginx"` | `okdp-superset` | [`sample-values.yaml:115`](https://github.com/OKDP/okdp-superset/blob/5230d594eb47/helm/superset/sample-values.yaml#L115) | sample values | ⬜ |
| `className` | `"nginx"` | `spark-web-proxy` | [`values.sample.yaml:21`](https://github.com/OKDP/spark-web-proxy/blob/547e02ac3f19/helm/spark-web-proxy/values.sample.yaml#L21) | sample values | ⬜ |
| `className` | `nginx` | `spark-history-server` | [`TEST.md:474`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ec/docs/TEST.md#L474) | doc walkthrough | ⬜ |
| `className` | `nginx` | `spark-history-server` | [`TEST.md:505`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ec/docs/TEST.md#L505) | doc walkthrough | ⬜ |
| `ingressClassName` | `nginx` | `spark-history-server` | [`TEST.md:588`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ec/docs/TEST.md#L588) | doc walkthrough | ⬜ |

The two variabilisation PRs — [platform-packages#52](https://github.com/OKDP/platform-packages/pull/52) and
[sandbox-dependencies#20](https://github.com/OKDP/sandbox-dependencies/pull/20) — both merged on 21 August.
`#20` was force-pushed before merge to pick up the SeaweedFS S3 Ingress it had originally missed.

---

## 5. Beyond annotations

*The couplings that break first.*

Annotations degrade quietly. These fail immediately and completely, and none of them appear in an
annotation grep.

### CoreDNS wildcard target

The sandbox patches CoreDNS so `*.okdp.sandbox` resolves to
[`ingress-nginx-main-controller.ingress-nginx.svc.cluster.local`](https://github.com/OKDP/okdp-sandbox/blob/6650e737d351/clusters/sandbox/releases/coredns-patch.yaml#L30). In-cluster OIDC calls to Keycloak depend on it.

**Required:** retarget to the new controller's Service. Miss this and every in-cluster OIDC redirect
fails while the browser-facing path looks perfectly healthy.

### Install-ordering graph

The controller package declares `roles: [ingress]`; every package with an Ingress declares
`dependencies: [ingress]`. The dependency exists to wait for nginx's `validate.nginx.ingress.kubernetes.io`
admission webhook — a comment in the [`Vault release`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/manifests/infrastructure/vault.yaml#L8) says so explicitly.

**Required:** the replacement package must claim the same `ingress` role, or the whole dependency graph
stalls. The webhook race disappears with Traefik and Cilium, which ship no equivalent validating webhook —
a simplification, once the role is transferred.

### NodePort pinning

The controller Service is pinned to NodePort [`30080 / 30443`](https://github.com/OKDP/okdp-sandbox/blob/6650e737d351/clusters/sandbox/releases/ingress-nginx.yaml#L31), matched by the kind host-port mapping.

**Required:** the replacement must claim the same two node ports, or the kind cluster definition changes
too. Cilium exposes this through `insecure-node-port` / `secure-node-port` settings.

### Controller-level nginx settings

[`allowSnippetAnnotations`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/ingress-nginx/ingress-nginx.yaml#L59) and [`extraArgs.enable-ssl-passthrough`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/ingress-nginx/ingress-nginx.yaml#L61) in the ingress-nginx package values.

Both are nginx-only chart settings and simply vanish. Note that **no Ingress in the organisation actually
uses `ssl-passthrough`** — the flag is enabled attack surface with no consumer.

### The platform context is being reshaped underneath all of this

The packages no longer read `.Context.platform.ingress.className`; since the connections refactor they read a
**flat** `.Context.ingress.className` — 14 uses across `platform-packages` and `sandbox-dependencies`, plus 41
uses of `.Context.ingress.suffix`. But [`okdp-sandbox`](https://github.com/OKDP/okdp-sandbox/blob/6650e737d351/clusters/sandbox/contexts/10-platform-context.yaml#L33)
still nests both keys under `platform:`. The cluster-side counterpart is
[okdp-sandbox#90](https://github.com/OKDP/okdp-sandbox/pull/90) (`refactor!: run the sandbox on typed
connections`), still open, whose diff moves the block to a flat `ingress:` key.

**Required:** land `#90` before treating the context as the single switch — until it merges, packages `main`
and sandbox `main` disagree on the shape of the key every Ingress now depends on. Note also that
[okdp-sandbox#86](https://github.com/OKDP/okdp-sandbox/pull/86) is integrating Cilium as the sandbox CNI, so
the CNI change below is already in flight.

### Cilium is a CNI change, not a controller swap

Cilium Ingress and Cilium Gateway API both require Cilium to be the cluster CNI, replacing kindnet and
kube-proxy. By far the largest item in this document, and the reason the sandbox migration is staged
CNI-first. Traefik, by contrast, is a genuine drop-in controller swap with no CNI implications.

---

## 6. Findings, in priority order

Ranked by how much migration pain each one removes, not by how hard it is.

### `CRITICAL` — Basic auth on the SeaweedFS filer has no path forward under Cilium

Three annotations, one Ingress, and an entire OKDP-authored Helm chart (`seaweedfs-auth-config`) exist to put a password in front of the filer console. Under Cilium Ingress there is no equivalent, and stable Gateway API has none either — so the console would be exposed unauthenticated by a class change that otherwise looks cosmetic.

Decide the destination before migrating this host: Traefik `BasicAuth` middleware, Envoy ext_authz, an oauth2-proxy sidecar, or removing the console from the ingress. This is the one item that warrants a management decision rather than an engineering choice.

→ [3 basic-auth occurrences ↓](#reg-basic-auth)

### `HIGH` — The successor package set is now the only place the class debt survives

`okdp-control-plane-packages` is largely clean: Airflow, Polaris, SeaweedFS, Superset and Trino all read the
class from context. Two packages do not — and since the 21 August merges they hold **two of the only three
Ingress objects in the organisation that still hardcode `nginx`** (the third is Vault, below).

**JupyterHub** pins both the class ([`jupyterhub.yaml:336`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/jupyterhub/jupyterhub.yaml#L336)) and `force-ssl-redirect`
([`jupyterhub.yaml:334`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/jupyterhub/jupyterhub.yaml#L334)). A one-line change — the same one `platform-packages` already made.

**The `spark-web-proxy` sub-chart** is the harder one. The class ([`ingress.yaml:9`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/spark-history-server/charts/spark-web-proxy/templates/ingress.yaml#L9)) and the
annotation ([`ingress.yaml:6`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/spark-history-server/charts/spark-web-proxy/templates/ingress.yaml#L6)) are written straight into the Ingress template, and its `values.yaml`
exposes only `host`, `clusterIssuer` and `tlsSecretName` — there is no override to escape through. Fixing it
means editing the chart, not the package that consumes it.

SeaweedFS additionally carries two proxy annotations ([`seaweedfs.yaml:131`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/seaweedfs/seaweedfs.yaml#L131),
[`seaweedfs.yaml:132`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1/seaweedfs/seaweedfs.yaml#L132)) needing the same translation as their `platform-packages` equivalents.

Fixing this while the successor set is still small was always the cheap option. It is now also nearly the only
class work left — everything else closed on 21 August — so these two objects, plus Vault, are what stand
between the organisation and a controller change that is genuinely one value in one file.

→ [the 3 live hardcodes ↓](#reg-class-bindings) · [live register ↓](#4-occurrence-register)

### `HIGH` — Timeouts are the most likely silent regression

Three Ingresses raise the backend read timeout to between 300 and 3600 seconds — two of them also raise the send timeout — because Trino queries, Superset queries and SeaweedFS transfers genuinely run that long. The nginx annotations are ignored on both Cilium paths, and unless a replacement timeout is set explicitly Envoy's own route default applies, which is far shorter than any of these values.

Nothing fails at deploy time. The platform comes up green and then long queries start dying under load. The good news is that the fix is available on the pinned version: Cilium 1.19 supports `HTTPRoute.spec.rules[].timeouts.request` ([conformance report](https://github.com/kubernetes-sigs/gateway-api/blob/main/conformance/reports/v1.4.0/cilium/experimental-v1.19.0-pre.2-default-report.yaml)), and Cilium Ingress offers `ingress.cilium.io/request-timeout`. Set one of them explicitly on these three routes and test with a query that genuinely exceeds a minute.

→ [3 read-timeout occurrences ↓](#reg-proxy-read-timeout) · [2 send-timeout ↓](#reg-proxy-send-timeout)

### `HIGH` — CORS on kubauth breaks the console with a browser-side error

Four annotations let the console call the kubauth OIDC endpoint cross-origin with credentials. Under Cilium Ingress they are ignored outright — and Gateway API is **not** the escape hatch here: Cilium 1.19 lists `HTTPRouteCORS` under `unsupportedFeatures` in its own conformance report ([report](https://github.com/kubernetes-sigs/gateway-api/blob/main/conformance/reports/v1.4.0/cilium/experimental-v1.19.0-pre.2-default-report.yaml)). An `HTTPRoute` CORS filter is accepted by the API server and then does nothing; the browser preflight is forwarded upstream to kubauth.

The failure surfaces only in the browser console as a CORS rejection, with nothing wrong in any pod log — worth writing into the migration runbook ahead of time.

→ [4 CORS occurrences ↓](#reg-cors)

### `HIGH` — A hardcoded class has already come back in the current sandbox

[`sandbox-dependencies/packages/system/vault/vault.yaml:65`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/vault/vault.yaml#L65) sets
`ingressClassName: nginx` directly. The package did not exist at the previous scan — it landed *after* the
variabilisation PRs merged, writing back the exact pattern they had just removed across the rest of the repo.

Everything else in `platform-packages` and `sandbox-dependencies` now reads the class from context, so this
one object would be left pointing at nginx while the rest of the sandbox moved — the same split-across-two-
controllers failure the SeaweedFS S3 Ingress nearly caused. The fix is one line: `{{ .Context.ingress.className }}`,
as in [`keycloak.yaml:170`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/keycloak/keycloak.yaml#L170).

The recurrence is the real finding. A grep for `ingressClassName:\s*nginx` in CI would have caught this at PR
time and would keep catching it; review demonstrably did not.

→ [the 3 live hardcodes ↓](#reg-class-bindings)

### `CLEANUP` — Four annotations can be deleted today, before any migration

`use-regex` on Trino sits on a path of `/` and matches nothing. `backend-protocol: HTTP` on Keycloak restates nginx's default. `proxy-connect-timeout: 300` on Superset is an unrealistic value copied from an upstream sample. `acme.cert-manager.io/http01-edit-in-place` applies to an ACME flow the sandbox never runs.

Removing these is safe on nginx today. Three of the four are nginx keys, so the migration surface drops from
15 keys to 12; the fourth belongs to cert-manager and disappears from the adjacent list.

→ [use-regex ↓](#reg-use-regex) · [backend-protocol ↓](#reg-backend-protocol) · [proxy-connect-timeout ↓](#reg-proxy-connect-timeout)

### `CLEANUP` — The snippet-annotations setting is inconsistent between the two sandboxes

The current sandbox sets `allowSnippetAnnotations: "false"` ([`ingress-nginx.yaml:59`](https://github.com/OKDP/sandbox-dependencies/blob/0da14d14cb21/packages/system/ingress-nginx/ingress-nginx.yaml#L59)) — a deliberate hardening change made to mitigate CVE-2026-42945. The successor sandbox's copy of the same package sets it to `"true"` ([`ingress-nginx.yaml:43`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a/packages/system/ingress-nginx/ingress-nginx.yaml#L43)).

Not a migration issue as such — the setting disappears with nginx — but the successor environment currently carries a risk the current one was explicitly fixed for.

### `RESOLVED` — Class variabilisation, closed 21 August 2026

Kept for the audit trail. At the 19 August scan the class name was hardcoded in 16 Ingress objects and two
PRs were open to variabilise it, both incomplete: [platform-packages#52](https://github.com/OKDP/platform-packages/pull/52)
left the legacy `kubernetes.io/ingress.class: nginx` annotation on Airflow and Superset, and
[sandbox-dependencies#20](https://github.com/OKDP/sandbox-dependencies/pull/20) converted the SeaweedFS filer
Ingress but not the S3 Ingress in the same file.

Both gaps were closed before merge. `#20` was force-pushed on 21 August to pick up the S3 Ingress; the leftover
legacy annotations were variabilised by
[`45137e9`](https://github.com/OKDP/platform-packages/commit/45137e928afca8f6d34fcbf46e5e5f93c4c57ad6) the same
day. Sixteen hardcoded Ingress objects became three, none of them in `platform-packages` or the current
sandbox's own services.

What remains is upkeep, not migration work — and it is already slipping: `vault.yaml` landed in
`sandbox-dependencies` after the merges with `ingressClassName: nginx` written straight back in. A CI check on
`ingressClassName:\s*nginx` would hold the line more reliably than review will.

→ [all 15 class bindings ↓](#reg-class-bindings)

---

## 7. Traefik versus Cilium

On annotations alone. Cilium columns are scored against the pinned **Cilium 1.19 / Gateway API v1.4**, not
against the specifications in the abstract — see [method](#8-method-and-confidence).

| | Traefik | Cilium Ingress | Gateway API on Cilium |
|---|---|---|---|
| **Redundant today** | 2 of 15 — `use-regex` and `backend-protocol` do nothing on nginx as configured | ← | ← |
| **Direct equivalent** | 1 — body size | 1 — read timeout, via `request-timeout` | 2 — HTTPS redirect, request timeout |
| **Needs rework** | 12 — five middlewares and one ServersTransport cover all of them | 2 — force-https under a different key; send timeout folds into the read timeout | 2 — send timeout folds in; connect timeout becomes `backendRequest` |
| **No equivalent** | 0 | **10** | **9** — body size, buffer size, basic auth ×3, CORS ×4 |
| **Infrastructure change** | Controller swap only. No CNI impact. | Requires Cilium as the cluster CNI, replacing kindnet and kube-proxy. | Same CNI requirement. |
| **Routing model** | Ingress objects kept; behaviour moves into Middleware CRDs. | Ingress objects kept; most behaviour is simply lost. | Ingress replaced by Gateway + HTTPRoute. Larger rewrite, but annotations become typed, reviewable fields. |

Read across the bottom rows: **Cilium Ingress is still the weakest destination of the three.** It carries the
full cost of the CNI change while giving back far less than Traefik does on annotations — though less badly
than the 19 August scan suggested, because `ingress.cilium.io/request-timeout` does cover the timeout case.

Between the two Cilium routes, **Gateway API is the better target**: it answers the timeout question properly
and turns annotations into typed fields. But it does not rescue the two security annotations. Cilium 1.19
reports `HTTPRouteCORS` as unsupported ([conformance report](https://github.com/kubernetes-sigs/gateway-api/blob/main/conformance/reports/v1.4.0/cilium/experimental-v1.19.0-pre.2-default-report.yaml)), and basic auth is not in Gateway API
at all — so **CORS and basic auth need a destination decided independently of which Cilium mode is chosen.**
That is the one conclusion that does not change with the version you pin.

---

## 8. Method and confidence

**Method.** All 27 repositories in the OKDP GitHub organisation were cloned at their default branch on
24 August 2026 and searched exhaustively for controller-vendor annotation prefixes (nginx, Traefik,
HAProxy, Kong, ALB, Contour, Cilium), for `ingressClassName` and the legacy class annotation, and for the
nginx feature keywords *not* present in the inventory — snippets, external auth, rewrite targets, session
affinity, rate limits and TLS passthrough. None of those keywords appears anywhere in the organisation, and
no non-nginx controller annotation does either. Pull requests in the package and cluster repositories were
reviewed for in-flight changes, including force-pushes that post-date an earlier scan.

**Cilium claims are version-pinned, not documentation-derived.** The sandbox migration targets **Cilium
1.19.6** with **Gateway API v1.4.1** CRDs. Annotation support is read from Cilium's own
[ingress annotation table](https://github.com/cilium/cilium/blob/v1.19.6/operator/pkg/ingress/annotations/annotations.go) — which is where `force-https`, `request-timeout`, `tls-passthrough` and
`insecure-node-port` / `secure-node-port` are defined. Gateway API feature support is read from Cilium's
[conformance report for Gateway API v1.4](https://github.com/kubernetes-sigs/gateway-api/blob/main/conformance/reports/v1.4.0/cilium/experimental-v1.19.0-pre.2-default-report.yaml), published for the 1.19 line (`1.19.0-pre.2`), which lists `HTTPRouteRequestTimeout` and
`HTTPRouteBackendTimeout` as supported and `HTTPRouteCORS` as **unsupported**. Re-check both if you pin a
different Cilium version; they are the two inputs that would change this document's conclusions.

**Confidence.** The inventory itself — which annotations exist, with what values, in which files — is
exhaustive for default branches. Traefik mappings are based on documented feature sets and have not been
exercised on a cluster.

**Not covered.** Feature branches, forks outside the organisation, and any annotation applied at runtime
rather than committed to a repository.

**Pinned commits.** Every file:line link resolves against the commit below, so it stays correct as the files
move. Line numbers are only valid at these commits — re-run the scan before quoting them against a later
branch state. All 113 links were verified to resolve against these commits at compile time.

| Repository | Commit | Note |
|---|---|---|
| `helm-charts-utilities` | `c82dddb9afa6` | |
| `hive-metastore` | `b3f1eb6e31ee` | MetalLB annotations only |
| `okdp-control-plane-dev-sandbox` | `d54f3c05b67a` | |
| `okdp-control-plane-packages` | `a6e3c299d7a1` | |
| `okdp-control-plane-ui` | `047e8ff09ec1` | |
| `okdp-sandbox` | `6650e737d351` | |
| `okdp-server` | `174c5e83de2c` | chart samples only |
| `okdp-superset` | `5230d594eb47` | |
| `okdp-ui` | `0ad1e75f84d6` | chart samples only |
| `platform-packages` | `f2a6c0871d6a` | |
| `polaris-console` | `541027b592c5` | commented sample only |
| `sandbox-dependencies` | `0da14d14cb21` | |
| `spark-history-server` | `8ae9eb68b7ec` | |
| `spark-web-proxy` | `547e02ac3f19` | chart samples only |

**Superseded scan.** This document replaces a 19 August 2026 inventory. The material differences: the class
variabilisation PRs merged on 21 August, taking hardcoded Ingress classes from 16 to 3; the `okdp-ui`
package was replaced by `okdp-control-plane-ui`, removing three annotations; JupyterHub gained a
`proxy-body-size`; and `sandbox-dependencies` gained a Vault package that reintroduced a hardcoded class.
Live annotation instances went from 31 to 29.
