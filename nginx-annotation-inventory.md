# NGINX annotations across the OKDP organisation

**Ingress controller migration — impact inventory**

Every controller-specific Ingress annotation in the OKDP GitHub organisation, what it does, and what
happens to it under Traefik and under Cilium — plus the couplings that are not annotations at all and
will break just as loudly.

| | |
|---|---|
| Compiled | 19 August 2026 |
| Scope | 27 repositories, default branches, `github.com/OKDP` |
| Repos scanned | 27 |
| Distinct nginx annotation keys | **15** |
| Live annotation instances | **31** |
| Ingress objects hardcoding `nginx` | **16** |
| Repos carrying nginx annotations | **8** |
| Keys with no Gateway API equivalent | **5** |

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
**31 live occurrences** in 8 repositories. That number is smaller than it looks: two thirds of the
instances are three annotations — HTTPS redirect, proxy timeouts, and body-size limits — and all three
have clean answers under both Traefik and Gateway API.

The real exposure is concentrated in two places. **[HTTP Basic auth on the SeaweedFS filer](#reg-basic-auth)**
and **[CORS on the kubauth OIDC endpoint](#reg-cors)** are the only annotations that make the ingress
controller do security work on behalf of the application. Neither has a Cilium Ingress equivalent, and
neither is covered by stable Gateway API. Everything else is a translation exercise.

Two things matter more than the annotation list itself, and neither is an annotation:

- The class name `nginx` is still **[hardcoded in 16 Ingress objects](#reg-class-bindings)** rather than read
  from the platform context — two open PRs are fixing this right now, and both are incomplete.
- The platform's **CoreDNS patch, install-ordering graph and NodePort pinning** all name the nginx
  controller explicitly. These break on day one of any swap, regardless of how many annotations were translated.

> **The one-line answer**
>
> Moving to Traefik is a mechanical translation of 31 annotations into roughly 5 Traefik middlewares plus
> a global HTTPS redirect; every key has somewhere to go. Moving to Cilium is a different exercise: 12 of
> the 15 keys are simply ignored by Cilium Ingress, and even on Gateway API 5 of them have no equivalent
> and must be re-implemented as Envoy config or moved into the applications.

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
| **Cilium Ingress** | ⚠️ Cilium exposes `ingress.cilium.io/force-https`. Different key, same intent; confirm it exists in your pinned Cilium version. |
| **Gateway API** (Cilium / Envoy) | ✅ A `RequestRedirect` filter on an HTTP-listener HTTPRoute. Already proven in the sandbox Gateway API POC. |

### `proxy-body-size`

`"0"` and `"130m"` · 4 live — [see all occurrences ↓](#reg-proxy-body-size)

Caps the client request body. `0` disables the cap entirely (nginx defaults to 1 MB, which breaks file and DAG uploads); `130m` is a deliberate ceiling on object-storage uploads.

| Target | Outcome |
|---|---|
| **Traefik** | ✅ Traefik imposes no body limit by default, so the `"0"` cases need nothing. The `130m` ceiling needs a `buffering` Middleware with `maxRequestBodyBytes`. |
| **Cilium Ingress** | ❌ No annotation. Uploads stop being capped — the `"0"` intent survives by accident, the `130m` guardrail silently disappears. |
| **Gateway API** (Cilium / Envoy) | ❌ Not modelled by Gateway API. Re-imposing the cap means a CiliumEnvoyConfig with the Envoy buffer filter, or enforcing it in SeaweedFS. |

### `proxy-read-timeout`

300 / 600 / 3600 s · 4 live — [see all occurrences ↓](#reg-proxy-read-timeout)

How long nginx waits for a response from the backend. Raised well above the 60 s default so long-running Trino and Superset queries, and the OKDP UI's streaming endpoints, are not cut off mid-flight.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ Not a router annotation. Set on the entryPoint (`respondingTimeouts`) and per-service via a `ServersTransport` CRD attached with `service.serverstransport`. |
| **Cilium Ingress** | ❌ No annotation. Envoy's route timeout applies instead — its default is far shorter than 3600 s, so long queries fail rather than degrade. |
| **Gateway API** (Cilium / Envoy) | ⚠️ `HTTPRoute.spec.rules[].timeouts.request` covers this. Verify your Cilium version honours the field, and set it explicitly — do not rely on defaults. |

### `proxy-send-timeout`

300 / 3600 s · 3 live — [see all occurrences ↓](#reg-proxy-send-timeout)

Companion to the above, on the request-write side. Always set alongside `proxy-read-timeout` in this codebase.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ Same `ServersTransport` / entryPoint mechanism as the read timeout. |
| **Cilium Ingress** | ❌ No annotation. |
| **Gateway API** (Cilium / Envoy) | ⚠️ Folded into the single HTTPRoute request timeout — Gateway API does not split read and write. |

### `proxy-connect-timeout`

300 s · 1 live — [see all occurrences ↓](#reg-proxy-connect-timeout)

How long to wait to *establish* the upstream connection. 300 s is far beyond anything a healthy in-cluster connect needs — almost certainly copied from the upstream Superset chart's sample values.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ `ServersTransport.forwardingTimeouts.dialTimeout`. |
| **Cilium Ingress** | ❌ No annotation. |
| **Gateway API** (Cilium / Envoy) | ⚠️ Not separately modelled; covered by `timeouts.backendRequest`. Safe to drop given the value is unrealistic anyway. |

### `proxy-buffer-size`

`"128k"` · 1 live — [see all occurrences ↓](#reg-proxy-buffer-size)

Enlarges the buffer nginx uses for the first part of the upstream response. In practice this is the fix for "upstream sent too big header" when OIDC session cookies grow large.

| Target | Outcome |
|---|---|
| **Traefik** | ⚠️ No equivalent knob; Traefik's Go HTTP server has its own header limits. Re-test the Superset OIDC login with a fully-populated session cookie. |
| **Cilium Ingress** | ❌ No annotation. Envoy's own header limits apply; same re-test needed. |
| **Gateway API** (Cilium / Envoy) | ❌ Not modelled. Tunable only via CiliumEnvoyConfig if the login actually breaks. |

### `use-regex`

`"true"` · 2 live — [see all occurrences ↓](#reg-use-regex)

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
| **Gateway API** (Cilium / Envoy) | ⚠️ Gateway API has a CORS filter, but it is recent and support varies by implementation. Verify against your Cilium version; fall back to CiliumEnvoyConfig or serving CORS from kubauth itself. |

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

### `cert-manager.io/cluster-issuer` — 22 occurrences

Hands TLS certificate issuance for the Ingress host to cert-manager's ingress-shim, using the platform's
self-signed ClusterIssuer.

✅ **Direct** under Traefik or Cilium Ingress — cert-manager is controller-agnostic.
⚠️ **Rework** under Gateway API: ingress-shim does not watch Gateways unless cert-manager is started with
Gateway API support, and the annotation then belongs on the **Gateway**, not on each route. Twenty-two
annotations collapse into one wildcard certificate on a shared Gateway.

- **`platform-packages`** — [`airflow.yaml:208`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/airflow/airflow.yaml#L208) · [`jupyterhub.yaml:241`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/jupyterhub/jupyterhub.yaml#L241) · [`polaris.yaml:251`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/polaris/polaris.yaml#L251) · [`polaris.yaml:372`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/polaris/polaris.yaml#L372) · [`spark-history-server.yaml:128`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/spark-history-server/spark-history-server.yaml#L128) · [`spark-history-server.yaml:234`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/spark-history-server/spark-history-server.yaml#L234) · [`superset.yaml:351`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L351) · [`trino.yaml:467`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/trino/trino.yaml#L467) · [`okdp-server.yaml:190`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/system/okdp-server/okdp-server.yaml#L190) · [`okdp-server.yaml:205`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/system/okdp-server/okdp-server.yaml#L205) · [`okdp-ui.yaml:91`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/system/okdp-ui/okdp-ui.yaml#L91)
- **`sandbox-dependencies`** — [`keycloak.yaml:89`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/system/keycloak/keycloak.yaml#L89) · [`seaweedfs.yaml:243`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L243) · [`seaweedfs.yaml:284`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L284)
- **`okdp-control-plane-packages`** — [`airflow.yaml:266`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/airflow/airflow.yaml#L266) · [`jupyterhub.yaml:335`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/jupyterhub/jupyterhub.yaml#L335) · [`seaweedfs.yaml:130`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/seaweedfs/seaweedfs.yaml#L130) · [`superset.yaml:235`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/superset/superset.yaml#L235) · [`trino.yaml:177`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/trino/trino.yaml#L177) · [`ingress.yaml:6`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/polaris/charts/polaris/templates/ingress.yaml#L6) · [`ingress.yaml:7`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/spark-history-server/charts/spark-web-proxy/templates/ingress.yaml#L7)
- **`okdp-control-plane-dev-sandbox`** — [`vault.yaml:25`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/packages/system/vault/vault.yaml#L25)

### `kubernetes.io/ingress.class` — 2 occurrences

The pre-1.18 way of selecting a controller, superseded by the `ingressClassName` field. Still honoured by ingress-nginx.

❌ **Remove — a landmine.** Hardcoded to `nginx` on the Airflow and Superset Ingresses *alongside* a
templated class field. Change the class variable and these two objects still carry a contradictory nginx
marker. Both open class-variabilisation PRs leave it in place.

- **`platform-packages`** — [`airflow.yaml:207`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/airflow/airflow.yaml#L207) · [`superset.yaml:350`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L350)

### `acme.cert-manager.io/http01-edit-in-place` — 1 occurrence

Makes ACME HTTP-01 solve the challenge by editing the existing Ingress instead of creating a temporary one.

⬜ **Drop it** — inherited from the upstream Superset chart sample. The sandbox uses a self-signed issuer,
so no ACME challenge is ever solved.

- **`platform-packages`** — [`superset.yaml:352`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L352)

### `metallb.universe.tf/loadBalancerIPs` and `…/allow-shared-ip` — 4 occurrences

Service-level annotations on the nginx controller Service, applied only in the package's `metallb` exposure mode.

⚠️ **Rework** — they belong to the controller's own Service, so they move wholesale to whatever Service
exposes the replacement. Cilium replaces MetalLB entirely with `CiliumLoadBalancerIPPool` plus L2 announcements.

- **`sandbox-dependencies`** — [`ingress-nginx.yaml:67`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/system/ingress-nginx/ingress-nginx.yaml#L67) · [`ingress-nginx.yaml:68`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/system/ingress-nginx/ingress-nginx.yaml#L68)
- **`okdp-control-plane-dev-sandbox`** — [`ingress-nginx.yaml:51`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/packages/system/ingress-nginx/ingress-nginx.yaml#L51) · [`ingress-nginx.yaml:52`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/packages/system/ingress-nginx/ingress-nginx.yaml#L52)

---

## 4. Occurrence register

The audit trail behind every count in this document. Each location links to the exact line on GitHub,
pinned to the commit that was scanned, so the reference stays valid even after the files move.

Two parallel package generations are in play: `platform-packages` plus `sandbox-dependencies` serve
today's sandbox, while `okdp-control-plane-packages` plus `okdp-control-plane-dev-sandbox` are the
successor set. Both carry nginx annotations, so a migration has to cover both or the debt reappears.

### Live — annotations on Ingress objects the platform actually deploys

*31 occurrences. Keys shown without the `nginx.ingress.kubernetes.io/` prefix.*

<a id="reg-force-ssl-redirect"></a>

#### `force-ssl-redirect` — 8 occurrences

> Traefik: global entryPoint redirect · Cilium: `ingress.cilium.io/force-https` · Gateway API: `RequestRedirect` filter

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`jupyterhub.yaml:240`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/jupyterhub/jupyterhub.yaml#L240) | JupyterHub proxy |
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`polaris.yaml:250`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/polaris/polaris.yaml#L250) | Polaris API |
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`polaris.yaml:371`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/polaris/polaris.yaml#L371) | Polaris Console |
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`spark-history-server.yaml:127`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/spark-history-server/spark-history-server.yaml#L127) | Spark History Server |
| `force-ssl-redirect` | `"true"` | `platform-packages` | [`spark-history-server.yaml:233`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/spark-history-server/spark-history-server.yaml#L233) | Spark web proxy |
| `force-ssl-redirect` | `"true"` | `sandbox-dependencies` | [`keycloak.yaml:88`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/system/keycloak/keycloak.yaml#L88) | Keycloak |
| `force-ssl-redirect` | `"true"` | `okdp-control-plane-packages` | [`jupyterhub.yaml:334`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/jupyterhub/jupyterhub.yaml#L334) | JupyterHub proxy |
| `force-ssl-redirect` | `"true"` | `okdp-control-plane-packages` | [`ingress.yaml:6`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/spark-history-server/charts/spark-web-proxy/templates/ingress.yaml#L6) | Spark web proxy — chart template |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-body-size"></a>

#### `proxy-body-size` — 4 occurrences

> Traefik: `buffering` middleware · Cilium and Gateway API: no equivalent — the 130m cap is lost

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-body-size` | `"0"` | `platform-packages` | [`airflow.yaml:209`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/airflow/airflow.yaml#L209) | Airflow API server |
| `proxy-body-size` | `"130m"` | `sandbox-dependencies` | [`seaweedfs.yaml:242`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L242) | SeaweedFS filer console |
| `proxy-body-size` | `"130m"` | `sandbox-dependencies` | [`seaweedfs.yaml:283`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L283) | SeaweedFS S3 endpoint |
| `proxy-body-size` | `"0"` | `okdp-control-plane-packages` | [`seaweedfs.yaml:131`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/seaweedfs/seaweedfs.yaml#L131) | SeaweedFS |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-read-timeout"></a>

#### `proxy-read-timeout` — 4 occurrences

> Traefik: `ServersTransport` · Gateway API: `timeouts.request` — must be set explicitly or Envoy's short default applies

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-read-timeout` | `"300"` | `platform-packages` | [`superset.yaml:356`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L356) | Superset UI |
| `proxy-read-timeout` | `"3600"` | `platform-packages` | [`trino.yaml:468`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/trino/trino.yaml#L468) | Trino UI |
| `proxy-read-timeout` | `"3600"` | `platform-packages` | [`okdp-ui.yaml:92`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/system/okdp-ui/okdp-ui.yaml#L92) | OKDP UI |
| `proxy-read-timeout` | `"600"` | `okdp-control-plane-packages` | [`seaweedfs.yaml:132`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/seaweedfs/seaweedfs.yaml#L132) | SeaweedFS |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-send-timeout"></a>

#### `proxy-send-timeout` — 3 occurrences

> Folds into the same Gateway API request timeout — Gateway API does not split read and write

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-send-timeout` | `"300"` | `platform-packages` | [`superset.yaml:357`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L357) | Superset UI |
| `proxy-send-timeout` | `"3600"` | `platform-packages` | [`trino.yaml:469`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/trino/trino.yaml#L469) | Trino UI |
| `proxy-send-timeout` | `"3600"` | `platform-packages` | [`okdp-ui.yaml:93`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/system/okdp-ui/okdp-ui.yaml#L93) | OKDP UI |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-connect-timeout"></a>

#### `proxy-connect-timeout` — 1 occurrence

> Traefik: `dialTimeout` · the value is unrealistic for an in-cluster connect — safe to drop

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-connect-timeout` | `"300"` | `platform-packages` | [`superset.yaml:355`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L355) | Superset UI |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-proxy-buffer-size"></a>

#### `proxy-buffer-size` — 1 occurrence

> No equivalent anywhere — re-test the Superset OIDC login with a fully-populated session cookie

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `proxy-buffer-size` | `"128k"` | `platform-packages` | [`superset.yaml:358`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L358) | Superset UI |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-use-regex"></a>

#### `use-regex` — 2 occurrences

> Both uses sit on path `/` — does nothing today, delete before migrating

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `use-regex` | `"true"` | `platform-packages` | [`trino.yaml:470`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/trino/trino.yaml#L470) | Trino UI |
| `use-regex` | `"true"` | `platform-packages` | [`okdp-ui.yaml:94`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/system/okdp-ui/okdp-ui.yaml#L94) | OKDP UI |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-basic-auth"></a>

#### `auth-type` · `auth-secret` · `auth-realm` — 3 occurrences

> **The highest-impact group** — no Cilium Ingress equivalent, none in stable Gateway API

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `auth-type` | `basic` | `sandbox-dependencies` | [`seaweedfs.yaml:244`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L244) | SeaweedFS filer console |
| `auth-secret` | `creds-seaweedfs-filer-basic` | `sandbox-dependencies` | [`seaweedfs.yaml:245`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L245) | SeaweedFS filer console |
| `auth-realm` | `"Authentication Required"` | `sandbox-dependencies` | [`seaweedfs.yaml:246`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L246) | SeaweedFS filer console |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-cors"></a>

#### `enable-cors` · `cors-allow-origin` · `cors-allow-methods` · `cors-allow-credentials` — 4 occurrences

> Traefik: `headers` middleware, one-to-one · Cilium Ingress: ignored, console login breaks in the browser

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `enable-cors` | `"true"` | `okdp-control-plane-dev-sandbox` | [`kubauth.yaml:30`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/manifests/platform/kubauth.yaml#L30) | kubauth OIDC |
| `cors-allow-origin` | `"https://console.okdp.dev-sandbox"` | `okdp-control-plane-dev-sandbox` | [`kubauth.yaml:31`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/manifests/platform/kubauth.yaml#L31) | kubauth OIDC |
| `cors-allow-methods` | `"GET, PUT, POST, DELETE, PATCH, OPTIONS"` | `okdp-control-plane-dev-sandbox` | [`kubauth.yaml:32`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/manifests/platform/kubauth.yaml#L32) | kubauth OIDC |
| `cors-allow-credentials` | `"true"` | `okdp-control-plane-dev-sandbox` | [`kubauth.yaml:33`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/manifests/platform/kubauth.yaml#L33) | kubauth OIDC |

[↑ back to the matrix](#2-translation-matrix)

<a id="reg-backend-protocol"></a>

#### `backend-protocol` — 1 occurrence

> Already nginx's default — redundant, delete before migrating

| Key | Value | Repository | File and line | Ingress object |
|---|---|---|---|---|
| `backend-protocol` | `"HTTP"` | `sandbox-dependencies` | [`keycloak.yaml:87`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/system/keycloak/keycloak.yaml#L87) | Keycloak |

[↑ back to the matrix](#2-translation-matrix)

### Samples, chart defaults and documentation

Nothing here deploys, but this is what contributors copy from. Leaving it un-migrated is how nginx
annotations come back after the migration is signed off. *15 occurrences.*

| Key | Value | Repository | File and line | Context |
|---|---|---|---|---|
| `proxy-connect-timeout` | `"300"` | `okdp-superset` | [`sample-values.yaml:122`](https://github.com/OKDP/okdp-superset/blob/5230d594eb4753f732b636a159cafc5fd2c781c3/helm/superset/sample-values.yaml#L122) | sample values |
| `proxy-read-timeout` | `"300"` | `okdp-superset` | [`sample-values.yaml:123`](https://github.com/OKDP/okdp-superset/blob/5230d594eb4753f732b636a159cafc5fd2c781c3/helm/superset/sample-values.yaml#L123) | sample values |
| `proxy-send-timeout` | `"300"` | `okdp-superset` | [`sample-values.yaml:124`](https://github.com/OKDP/okdp-superset/blob/5230d594eb4753f732b636a159cafc5fd2c781c3/helm/superset/sample-values.yaml#L124) | sample values |
| `proxy-buffer-size` | `"128k"` | `okdp-superset` | [`sample-values.yaml:125`](https://github.com/OKDP/okdp-superset/blob/5230d594eb4753f732b636a159cafc5fd2c781c3/helm/superset/sample-values.yaml#L125) | sample values |
| `proxy-connect-timeout` | `"300" — commented out` | `okdp-superset` | [`values.yaml:510`](https://github.com/OKDP/okdp-superset/blob/5230d594eb4753f732b636a159cafc5fd2c781c3/helm/superset/values.yaml#L510) | chart default |
| `proxy-read-timeout` | `"300" — commented out` | `okdp-superset` | [`values.yaml:511`](https://github.com/OKDP/okdp-superset/blob/5230d594eb4753f732b636a159cafc5fd2c781c3/helm/superset/values.yaml#L511) | chart default |
| `proxy-send-timeout` | `"300" — commented out` | `okdp-superset` | [`values.yaml:512`](https://github.com/OKDP/okdp-superset/blob/5230d594eb4753f732b636a159cafc5fd2c781c3/helm/superset/values.yaml#L512) | chart default |
| `auth-realm` | `Authentication Required` | `spark-history-server` | [`TEST.md:479`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ecc573398e4007673d5db027dd36b3/docs/TEST.md#L479) | doc walkthrough |
| `auth-secret` | `creds-seaweedfs-filer-basic` | `spark-history-server` | [`TEST.md:480`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ecc573398e4007673d5db027dd36b3/docs/TEST.md#L480) | doc walkthrough |
| `auth-type` | `basic` | `spark-history-server` | [`TEST.md:481`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ecc573398e4007673d5db027dd36b3/docs/TEST.md#L481) | doc walkthrough |
| `proxy-body-size` | `130m` | `spark-history-server` | [`TEST.md:482`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ecc573398e4007673d5db027dd36b3/docs/TEST.md#L482) | doc walkthrough |
| `proxy-body-size` | `130m` | `spark-history-server` | [`TEST.md:510`](https://github.com/OKDP/spark-history-server/blob/8ae9eb68b7ecc573398e4007673d5db027dd36b3/docs/TEST.md#L510) | doc walkthrough |
| `auth-secret` | `<secret-name>` — doc | `helm-charts-utilities` | [`README.md:26`](https://github.com/OKDP/helm-charts-utilities/blob/c82dddb9afa640772d4853bc6850592f8105820d/charts/seaweedfs-auth-config/README.md#L26) | chart doc |
| `auth-secret` | `<secret-name>` — comment | `helm-charts-utilities` | [`values.yaml:176`](https://github.com/OKDP/helm-charts-utilities/blob/c82dddb9afa640772d4853bc6850592f8105820d/charts/seaweedfs-auth-config/values.yaml#L176) | chart doc |
| `auth-secret` | `referenced in a comment` | `helm-charts-utilities` | [`filer-auth-secret.yaml:20`](https://github.com/OKDP/helm-charts-utilities/blob/c82dddb9afa640772d4853bc6850592f8105820d/charts/seaweedfs-auth-config/templates/filer-auth-secret.yaml#L20) | chart doc |

<a id="reg-class-bindings"></a>

### Class bindings — every place `nginx` is named as the controller

The first sixteen rows are Ingress objects on deployable packages. The last two are the platform context
defaults — the single value each environment flips once every object above reads from it. *22 occurrences.*

| Field | Value | Repository | File and line | Ingress object | In-flight |
|---|---|---|---|---|---|
| `ingressClassName` | `nginx` | `platform-packages` | [`airflow.yaml:205`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/airflow/airflow.yaml#L205) | Airflow API server | PR #52 |
| `kubernetes.io/ingress.class` | `nginx` | `platform-packages` | [`airflow.yaml:207`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/airflow/airflow.yaml#L207) | Airflow API server | **PR #52 leaves it** |
| `ingressClassName` | `nginx` | `platform-packages` | [`jupyterhub.yaml:242`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/jupyterhub/jupyterhub.yaml#L242) | JupyterHub proxy | PR #52 |
| `className` | `"nginx"` | `platform-packages` | [`polaris.yaml:248`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/polaris/polaris.yaml#L248) | Polaris API | PR #52 |
| `className` | `"nginx"` | `platform-packages` | [`polaris.yaml:369`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/polaris/polaris.yaml#L369) | Polaris Console | PR #52 |
| `ingressClassName` | `"nginx"` | `platform-packages` | [`spark-history-server.yaml:125`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/spark-history-server/spark-history-server.yaml#L125) | Spark History Server | PR #52 |
| `className` | `"nginx"` | `platform-packages` | [`spark-history-server.yaml:231`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/spark-history-server/spark-history-server.yaml#L231) | Spark web proxy | PR #52 |
| `ingressClassName` | `"nginx"` | `platform-packages` | [`superset.yaml:348`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L348) | Superset UI | PR #52 |
| `kubernetes.io/ingress.class` | `nginx` | `platform-packages` | [`superset.yaml:350`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L350) | Superset UI | **PR #52 leaves it** |
| `className` | `nginx` | `platform-packages` | [`trino.yaml:465`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/trino/trino.yaml#L465) | Trino UI | PR #52 |
| `className` | `"nginx"` | `platform-packages` | [`okdp-server.yaml:188`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/system/okdp-server/okdp-server.yaml#L188) | okdp-server Swagger | PR #52 |
| `className` | `"nginx"` | `platform-packages` | [`okdp-server.yaml:203`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/system/okdp-server/okdp-server.yaml#L203) | okdp-server API | PR #52 |
| `className` | `"nginx"` | `platform-packages` | [`okdp-ui.yaml:89`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/system/okdp-ui/okdp-ui.yaml#L89) | OKDP UI | PR #52 |
| `className` | `nginx` | `sandbox-dependencies` | [`seaweedfs.yaml:240`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L240) | SeaweedFS filer console | PR #20 |
| `className` | `nginx` | `sandbox-dependencies` | [`seaweedfs.yaml:281`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L281) | SeaweedFS S3 endpoint | **missed by PR #20** |
| `ingressClassName` | `"nginx"` | `sandbox-dependencies` | [`keycloak.yaml:85`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/system/keycloak/keycloak.yaml#L85) | Keycloak | PR #20 |
| `ingressClassName` | `nginx` | `okdp-control-plane-packages` | [`jupyterhub.yaml:336`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/jupyterhub/jupyterhub.yaml#L336) | JupyterHub proxy | no PR open |
| `ingressClassName` | `nginx` | `okdp-control-plane-packages` | [`ingress.yaml:9`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/spark-history-server/charts/spark-web-proxy/templates/ingress.yaml#L9) | Spark web proxy | **hardcoded in template** |
| `className` | `"nginx"` | `okdp-control-plane-packages` | [`values.yaml:15`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/polaris/charts/polaris/values.yaml#L15) | Polaris chart default | package overrides it |
| `className` | `nginx` | `okdp-control-plane-ui` | [`values.yaml:21`](https://github.com/OKDP/okdp-control-plane-ui/blob/7b7f82bd3984011694645af6da3f0b2727d6f3f3/chart/values.yaml#L21) | Console chart default | no package override |
| `platform.ingress.className` | `nginx` | `okdp-sandbox` | [`10-platform-context.yaml:33`](https://github.com/OKDP/okdp-sandbox/blob/00570d45511cb49057ee6991dc69969840bbec89/clusters/sandbox/contexts/10-platform-context.yaml#L33) | platform-wide default | _the single switch_ |
| `ingress.className` | `nginx` | `okdp-control-plane-dev-sandbox` | [`default-context.yaml:11`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/clusters/dev/default-context.yaml#L11) | platform-wide default | _the single switch_ |

PRs are [OKDP/platform-packages#52](https://github.com/OKDP/platform-packages/pull/52) and
[OKDP/sandbox-dependencies#20](https://github.com/OKDP/sandbox-dependencies/pull/20), both open at time of scan.

---

## 5. Beyond annotations

*The couplings that break first.*

Annotations degrade quietly. These fail immediately and completely, and none of them appear in an
annotation grep.

### CoreDNS wildcard target

The sandbox patches CoreDNS so `*.okdp.sandbox` resolves to
[`ingress-nginx-main-controller.ingress-nginx.svc.cluster.local`](https://github.com/OKDP/okdp-sandbox/blob/00570d45511cb49057ee6991dc69969840bbec89/clusters/sandbox/releases/coredns-patch.yaml#L30). In-cluster OIDC calls to Keycloak depend on it.

**Required:** retarget to the new controller's Service. Miss this and every in-cluster OIDC redirect
fails while the browser-facing path looks perfectly healthy.

### Install-ordering graph

The controller package declares `roles: [ingress]`; every package with an Ingress declares
`dependencies: [ingress]`. The dependency exists to wait for nginx's `validate.nginx.ingress.kubernetes.io`
admission webhook — a comment in the [`Vault release`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/manifests/infrastructure/vault.yaml#L8) says so explicitly.

**Required:** the replacement package must claim the same `ingress` role, or the whole dependency graph
stalls. The webhook race disappears with Traefik and Cilium, which ship no equivalent validating webhook —
a simplification, once the role is transferred.

### NodePort pinning

The controller Service is pinned to NodePort [`30080 / 30443`](https://github.com/OKDP/okdp-sandbox/blob/00570d45511cb49057ee6991dc69969840bbec89/clusters/sandbox/releases/ingress-nginx.yaml#L31), matched by the kind host-port mapping.

**Required:** the replacement must claim the same two node ports, or the kind cluster definition changes
too. Cilium exposes this through `insecure-node-port` / `secure-node-port` settings.

### Controller-level nginx settings

[`allowSnippetAnnotations`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/system/ingress-nginx/ingress-nginx.yaml#L59) and [`extraArgs.enable-ssl-passthrough`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/system/ingress-nginx/ingress-nginx.yaml#L61) in the ingress-nginx package values.

Both are nginx-only chart settings and simply vanish. Note that **no Ingress in the organisation actually
uses `ssl-passthrough`** — the flag is enabled attack surface with no consumer.

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

### `CRITICAL` — Both open class-variabilisation PRs are incomplete

Two PRs are replacing the hardcoded `nginx` class with the platform context variable — exactly the right move, and a prerequisite for any migration. Both stop short.

**[platform-packages#52](https://github.com/OKDP/platform-packages/pull/52)** converts the class field on Airflow and Superset but leaves the legacy `kubernetes.io/ingress.class: nginx` annotation on both ([`airflow.yaml:207`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/airflow/airflow.yaml#L207), [`superset.yaml:350`](https://github.com/OKDP/platform-packages/blob/800a8fac33916abc63ae313b8e864b03f757bc41/packages/services/superset/superset.yaml#L350)). The result is an Ingress whose class field says one thing and whose annotation says nginx.

**[sandbox-dependencies#20](https://github.com/OKDP/sandbox-dependencies/pull/20)** converts the SeaweedFS *filer* Ingress ([`seaweedfs.yaml:240`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L240)) but not the SeaweedFS *S3* Ingress in the same file ([`seaweedfs.yaml:281`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/services/seaweedfs/seaweedfs.yaml#L281)), which keeps `className: nginx`. Changing the platform class would split SeaweedFS across two controllers.

Neither is a blocker to merge — but reviewing them now costs one comment each and saves a debugging session later.

→ [all 22 class bindings ↓](#reg-class-bindings)

### `HIGH` — The successor package set is repeating the same debt

`okdp-control-plane-packages` is largely clean — most packages already read the class from context and carry only cert-manager annotations. But JupyterHub still hardcodes both the class ([`jupyterhub.yaml:336`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/jupyterhub/jupyterhub.yaml#L336)) and `force-ssl-redirect` ([`jupyterhub.yaml:334`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/jupyterhub/jupyterhub.yaml#L334)), SeaweedFS carries two proxy annotations ([`seaweedfs.yaml:131`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/seaweedfs/seaweedfs.yaml#L131)), and the `spark-web-proxy` sub-chart hardcodes the class *and* the annotation directly in the Ingress template ([`ingress.yaml:6`](https://github.com/OKDP/okdp-control-plane-packages/blob/a6e3c299d7a1538a3b91eb252c7a93fda5da0622/spark-history-server/charts/spark-web-proxy/templates/ingress.yaml#L6)), with no values override to escape through.

Fixing these while the successor set is still small is dramatically cheaper than fixing them after it becomes the platform.

→ [live register ↓](#4-occurrence-register)

### `HIGH` — Timeouts are the most likely silent regression

Four Ingresses raise the backend timeout to between 300 and 3600 seconds because Trino queries, Superset queries and SeaweedFS transfers genuinely run that long. Under Cilium and Gateway API the annotations are ignored and Envoy's own route timeout applies — which is much shorter than any of these values.

Nothing fails at deploy time. The platform comes up green and then long queries start dying under load. Set `HTTPRoute.spec.rules[].timeouts.request` explicitly on these four routes and test with a query that genuinely exceeds a minute.

→ [4 timeout occurrences ↓](#reg-proxy-read-timeout)

### `HIGH` — CORS on kubauth breaks the console with a browser-side error

Four annotations let the console call the kubauth OIDC endpoint cross-origin with credentials. Under Cilium Ingress they are ignored outright; under Gateway API the CORS filter is recent enough that support needs verifying against the pinned Cilium version.

The failure surfaces only in the browser console as a CORS rejection, with nothing wrong in any pod log — worth writing into the migration runbook ahead of time.

→ [4 CORS occurrences ↓](#reg-cors)

### `CLEANUP` — Four annotations can be deleted today, before any migration

`use-regex` on Trino and the OKDP UI sits on a path of `/` and matches nothing. `backend-protocol: HTTP` on Keycloak restates nginx's default. `proxy-connect-timeout: 300` on Superset is an unrealistic value copied from an upstream sample. `acme.cert-manager.io/http01-edit-in-place` applies to an ACME flow the sandbox never runs.

Removing these is safe on nginx today and reduces the migration surface by four keys, from 15 to 11.

→ [use-regex ↓](#reg-use-regex) · [backend-protocol ↓](#reg-backend-protocol) · [proxy-connect-timeout ↓](#reg-proxy-connect-timeout)

### `CLEANUP` — The snippet-annotations setting is inconsistent between the two sandboxes

The current sandbox sets `allowSnippetAnnotations: "false"` ([`ingress-nginx.yaml:59`](https://github.com/OKDP/sandbox-dependencies/blob/4f5b209f5295964bc97e6d9e74e1d508e684abe8/packages/system/ingress-nginx/ingress-nginx.yaml#L59)) — a deliberate hardening change made to mitigate CVE-2026-42945. The successor sandbox's copy of the same package sets it to `"true"` ([`ingress-nginx.yaml:43`](https://github.com/OKDP/okdp-control-plane-dev-sandbox/blob/d54f3c05b67a2e0c04e315a9a39340ba2621aa84/packages/system/ingress-nginx/ingress-nginx.yaml#L43)).

Not a migration issue as such — the setting disappears with nginx — but the successor environment currently carries a risk the current one was explicitly fixed for.

---

## 7. Traefik versus Cilium

On annotations alone.

| | Traefik | Cilium Ingress | Gateway API on Cilium |
|---|---|---|---|
| **Redundant today** | 2 of 15 — `use-regex` and `backend-protocol` do nothing on nginx as configured | ← | ← |
| **Direct equivalent** | 1 — body size | 0 | 1 — HTTPS redirect |
| **Needs rework** | 12 — five middlewares and one ServersTransport cover all of them | 1 — force-https, under a different key | 7 — route timeouts and CORS |
| **No equivalent** | 0 | **12** | **5** — body size, buffer size, basic auth ×3 |
| **Infrastructure change** | Controller swap only. No CNI impact. | Requires Cilium as the cluster CNI, replacing kindnet and kube-proxy. | Same CNI requirement. |
| **Routing model** | Ingress objects kept; behaviour moves into Middleware CRDs. | Ingress objects kept; most behaviour is simply lost. | Ingress replaced by Gateway + HTTPRoute. Larger rewrite, but annotations become typed, reviewable fields. |

Read across the bottom rows: **Cilium Ingress is the weakest destination of the three.** It carries the
full cost of the CNI change while giving back less than Traefik does on annotations. If the destination is
Cilium, going to **Gateway API directly** rather than stopping at Cilium Ingress avoids translating the
same annotations twice — which matches the staging already chosen for the sandbox migration.

---

## 8. Method and confidence

**Method.** All 27 repositories in the OKDP GitHub organisation were cloned at their default branch on
19 August 2026 and searched exhaustively for controller-vendor annotation prefixes (nginx, Traefik,
HAProxy, Kong, ALB, Contour, Cilium), for `ingressClassName` and the legacy class annotation, and for the
nginx feature keywords *not* present in the inventory — snippets, external auth, rewrite targets, session
affinity, rate limits and TLS passthrough. Counts were cross-checked against GitHub code search. Open pull
requests in the five package and cluster repositories were reviewed for in-flight changes.

**Confidence.** The inventory itself — which annotations exist, with what values, in which files — is
exhaustive for default branches. The Traefik and Cilium mappings are based on each project's documented
feature set; where a capability is recent or version-dependent (Cilium's `force-https` annotation, Gateway
API CORS filter support, HTTPRoute timeout support), the text says so explicitly and those three should be
verified against the exact versions you pin before being relied on in a plan.

**Not covered.** Feature branches, forks outside the organisation, and any annotation applied at runtime
rather than committed to a repository.

**Pinned commits.** Every file:line link resolves against the commit that was scanned, so it stays correct
as the files move. Line numbers are only valid at these commits — re-run the scan before quoting them
against a later branch state.

| Repository | Commit |
|---|---|
| `helm-charts-utilities` | `c82dddb9afa6` |
| `okdp-control-plane-dev-sandbox` | `d54f3c05b67a` |
| `okdp-control-plane-packages` | `a6e3c299d7a1` |
| `okdp-control-plane-ui` | `7b7f82bd3984` |
| `okdp-sandbox` | `00570d45511c` |
| `okdp-superset` | `5230d594eb47` |
| `platform-packages` | `800a8fac3391` |
| `sandbox-dependencies` | `4f5b209f5295` |
| `spark-history-server` | `8ae9eb68b7ec` |

