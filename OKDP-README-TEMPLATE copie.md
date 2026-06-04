# OKDP README Template — Documentation Audit Canvas

> **Purpose:** This document is a common canvas for auditing and improving documentation across all OKDP repositories.
> It was agreed upon during a team workshop (June 2026) and lives in [OKDP/OKDP](https://github.com/OKDP/OKDP) as the reference.
>
> **How to use it:**
> - Use the [Section Reference Table](#section-reference-table) to audit an existing README.
> - Use the [Full Template](#full-template) as a starting point when writing or rewriting a README.
> - Remove all annotation comments (`<!-- ... -->`) before publishing.
> - Sections marked **[CONDITIONAL]** apply depending on the repo type (see table).

---

## Section Reference Table

| # | Section | Required? | Repo type | What to audit / check |
|---|---------|:---------:|-----------|------------------------|
| 0 | Visual header (screenshot or OKDP banner) | Conditional | UI repos only | Does the repo have a web UI? If yes: is there a screenshot stored in `docs/assets/`? If no UI: is the section omitted or replaced with an OKDP-branded banner? **Never use upstream project logos** (trademark restrictions). |
| 1 | Badges (CI, Release, License, OKDP logo) | **Mandatory** | All | Are all 4 badges present and links working? |
| 2 | Project name + one-line description + status | **Mandatory** | All | Clear to someone unfamiliar with the tool? Status (alpha/beta/stable) shown? |
| 3 | What does this project provide? | **Mandatory** | All | Are delivered components listed (image/chart/SDK)? OKDP-specific additions highlighted? |
| — | Alternatives (sub-section) | Optional | All | Are competing/upstream tools mentioned? |
| 4 | Architecture diagram | **Mandatory** | All | Is a diagram present? Format: Mermaid, draw.io SVG, or Excalidraw SVG? Does it reflect the **OKDP deployment scenario** (not just upstream)? Is there a note explaining OKDP-specific choices and clarifying that other options exist? Is there a link to the upstream architecture docs? |
| 5 | Prerequisites | **Mandatory** | All | Are versions, tools, credentials all listed explicitly? Is there a **"Tested with"** subsection showing exact validated versions (not just ranges)? |
| 6 | Quick start | Conditional | Helm, Image+Chart, Sandbox | Does it work with one command? Is expected result shown? |
| 7 | Installation (full, step-by-step) | **Mandatory** | All | Every step has a command + expected result? |
| 8 | Configuration | Conditional | Helm, Image+Chart, SDK | Is there a parameter/env var table? Separated from auto-generated chart values? |
| 9 | Usage examples | Conditional | SDK, Examples | Are examples realistic? Do they show expected output? |
| 10 | Images / Components | Conditional | Image, Image+Chart | Tag format documented? `quay.io/okdp` link present? |
| 11 | OKDP Integration | **Mandatory** | All | Sandbox linked? Service URL in sandbox mentioned? Ecosystem context explained? |
| 12 | Troubleshooting | **Mandatory** | Helm, Image+Chart, Sandbox | Are the **top 3** most common errors documented with symptom → cause → fix? |
| 13 | Contributing / Development | Optional | All | Dev setup, build, and test — each with expected result? Points to CONTRIBUTING.md? |
| 14 | Uninstall / Teardown | **Mandatory** | Helm, Image+Chart, Sandbox | Is there a clean uninstall procedure (Helm release + namespace)? For sandbox: full cluster teardown? |
| 15 | Contributing & License | **Mandatory** | All | CONTRIBUTING.md link present? License is Apache 2.0? |
| 16 | "Built for OKDP Community" footer | **Mandatory** | All | Footer + OKDP logo SVG present? |

**Repo type legend:** `All` · `Image` (Docker image only) · `Helm` (chart only) · `Image+Chart` · `SDK` · `Sandbox` · `Examples`

---

## Full Template

```markdown
<!--
  OKDP README Template — v1.1
  Remove all annotation comments before publishing.
  Sections marked [CONDITIONAL] can be omitted if not applicable to the repo type.

  Changelog v1.1 (June 2026):
  - Section 0: conditional on UI, upstream logos forbidden, OKDP banner as alternative
  - Section 4: OKDP deployment context note + upstream docs link now required
  - Section 5: "Tested with" subsection added (exact validated versions)
  - Section 12: upgraded to Mandatory for Helm/Image+Chart/Sandbox, top 3 errors required
  - Section 14: renamed "Cleanup" → "Uninstall / Teardown", expanded scope, expected results added
-->

<!-- ═══════════════════════════════════════════════════════════
     SECTION 0 — Visual Header [CONDITIONAL]
     ONLY for repos with a web UI (Superset, JupyterHub, Airflow, …).
     Use a screenshot of the running application, stored in docs/assets/.

     ⚠️  Do NOT use upstream project logos (Apache Hive, Trino, Spark…).
         These are trademarked assets. Using them implies endorsement and
         may violate the upstream project's trademark policy.

     If the repo has NO web UI (Helm chart, Docker image, backend service):
       Option A — Omit this section entirely.
       Option B — Use a simple OKDP-branded text banner (see below).
     ═══════════════════════════════════════════════════════════ -->

<!-- Option A (repos WITH a UI): screenshot -->
<p align="center">
  <img src="docs/assets/screenshot.png" alt="[Project Name] — screenshot" width="700"/>
</p>

<!-- Option B (repos WITHOUT a UI): OKDP-branded text banner — delete Option A if using this -->
<!--
<p align="center">
  <strong>OKDP — [Project Name]</strong><br/>
  <em>[One-line description]</em>
</p>
-->

<!-- ═══════════════════════════════════════════════════════════
     SECTION 1 — Badges
     At minimum: CI status, Latest release, License, OKDP logo.
     Add upstream version badge if wrapping a well-known tool.
     ═══════════════════════════════════════════════════════════ -->
[![CI](https://github.com/OKDP/<repo>/actions/workflows/ci.yml/badge.svg)](https://github.com/OKDP/<repo>/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/OKDP/<repo>)](https://github.com/OKDP/<repo>/releases/latest)
[![License Apache2](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
<a href="https://okdp.io"><img src="https://okdp.io/logos/okdp-notext.svg" height="20px"/></a>

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 2 — Project Name + Short Description
     One or two sentences: what is it, what problem does it solve,
     who is it for. No jargon without explanation.
     ═══════════════════════════════════════════════════════════ -->
# Project Name

> Short description: what is it, what problem does it solve, who is it for.
>
> Example: *"OKDP-flavored Helm chart and Docker image for Apache Superset —
> adds OIDC/OAuth2 and externalized secrets on top of the official chart."*

> **Status**: `alpha` | `beta` | `stable`

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 3 — What does the project provide?
     List all delivered artifacts (image, chart, SDK, examples).
     Highlight what OKDP adds on top of the upstream project.
     ═══════════════════════════════════════════════════════════ -->
## What does this project provide?

This repository delivers:

- **Docker image** `quay.io/okdp/<image>` — built on top of `<upstream>` with:
  - OKDP addition 1
  - OKDP addition 2
- **Helm chart** — wraps `<upstream-chart>` and adds:
  - OKDP-specific configuration A
  - OKDP-specific configuration B

<!-- [OPTIONAL] Alternatives sub-section -->
### Alternatives

| Alternative | Notes |
|-------------|-------|
| [Upstream official image](https://...) | No OKDP-specific extensions |
| [Another tool](https://...) | Different trade-offs: ... |

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 4 — Architecture
     Include a diagram. Preferred formats:
     - Mermaid (renders natively in GitHub — recommended)
     - draw.io SVG (commit the .svg, store in docs/assets/)
     - Excalidraw SVG

     IMPORTANT: The diagram must show the OKDP deployment scenario,
     not just the generic upstream architecture.
     - Identify which dependencies are OKDP's specific choices
       (e.g. PostgreSQL chosen because CloudNativePG is already in the stack).
     - Clarify that other options exist to avoid misleading users.
     - Always link to the upstream architecture or design documentation.
     ═══════════════════════════════════════════════════════════ -->
## Architecture

> **OKDP deployment context:** This diagram reflects how [Project Name] is deployed within OKDP.
> [Dependency X] (e.g. PostgreSQL) was chosen because [reason — e.g. it is already provisioned by the CloudNativePG operator in the OKDP sandbox].
> Other options (e.g. MySQL) are supported by the upstream project and may also work — this is not an OKDP restriction.
> See the [upstream architecture documentation](https://link-to-upstream-docs) for the full picture.

<p align="center">
  <img src="docs/assets/architecture.drawio.svg" alt="Architecture diagram"/>
</p>

<!--
  Or with Mermaid:

```mermaid
graph TD
    A[Component A] --> B[Component B]
    B --> C[Component C]
```
-->

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 5 — Prerequisites
     Be explicit. Do NOT assume the reader knows what is implicit.
     List: tool versions, Kubernetes version, credentials, access rights.

     Two sub-tables are required:
     1. Supported versions (ranges) — what the project claims to support.
     2. Tested with — exact versions validated by maintainers.
        This avoids the situation where a user installs a version within
        the supported range that has never actually been tested.
     ═══════════════════════════════════════════════════════════ -->
## Prerequisites

| Requirement | Supported versions | Notes |
|-------------|-------------------|-------|
| Kubernetes | 1.19+ | |
| Helm | v3+ | |
| [Tool X](https://...) | vX.Y+ | Required for ... |

**Access / Credentials required:**
- Access to `quay.io/okdp` registry (public, no authentication required)
- A running PostgreSQL instance with an empty database *(if applicable)*
- OAuth2/OIDC provider credentials *(if applicable)*

### Tested with

The following versions have been validated by the maintainers. Other versions within the supported range may work but are untested.

| Tool | Version tested |
|------|---------------|
| Kubernetes (Kind) | `x.y.z` |
| Kind | `x.y.z` |
| Helm CLI | `x.y.z` |
| kubectl | `x.y.z` |
| Docker | `x.y.z` |

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 6 — Quick Start [CONDITIONAL]
     Applies to: Helm charts, Image+Chart, Sandbox repos.
     The shortest path to a working result — ideally one command.
     ALWAYS include an expected result.
     ═══════════════════════════════════════════════════════════ -->
## Quick Start

```sh
helm upgrade --install my-release oci://quay.io/okdp/charts/<chart> \
  --version <version> \
  --set key=value
```

**Expected result:**

```
NAME: my-release
LAST DEPLOYED: Mon Jun  1 10:00:00 2026
STATUS: deployed
REVISION: 1
```

> Replace `<version>` with the latest from [Releases](https://github.com/OKDP/<repo>/releases).

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 7 — Installation (full)
     Step-by-step. Every step must have:
     1. A command block
     2. An expected result block
     so the reader knows when a step has succeeded.
     ═══════════════════════════════════════════════════════════ -->
## Installation

### Step 1 — Clone the repository

```sh
git clone https://github.com/OKDP/<repo>.git
cd <repo>
```

**Expected result:**
```
Cloning into '<repo>'...
done.
```

### Step 2 — ...

```sh
command here
```

**Expected result:**
```
output here
```

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 8 — Configuration [CONDITIONAL]
     Applies to: Helm charts, Image+Chart, SDK repos.
     IMPORTANT: Cover only parameters the USER sets manually.
     Do NOT copy-paste auto-generated Helm values here
     (those belong in helm/<chart>/README.md).
     ═══════════════════════════════════════════════════════════ -->
## Configuration

### Key parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|:--------:|
| `PARAM_A` | What it controls | `default-value` | Yes |
| `PARAM_B` | What it controls | — | No |

### Environment variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY` | Application secret key for session signing | `openssl rand -base64 42` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host/db` |

> For the full Helm chart values reference, see [helm/chart/README.md](helm/chart/README.md).

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 9 — Usage Examples [CONDITIONAL]
     Applies to: SDK, API, Examples repos.
     Show realistic, runnable use cases with expected output.
     ═══════════════════════════════════════════════════════════ -->
## Usage Examples

```python
# Example: submitting a Spark job with the OKDP client
from okdp import SomeClient

client = SomeClient(...)
result = client.run(...)
print(result)
```

**Expected result:**
```
Job submitted: job-abc123
Status: RUNNING
```

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 10 — Images / Components [CONDITIONAL]
     Applies to: Image-only and Image+Chart repos.
     Title:
     - "Images" if this repo only produces Docker images
     - "Components" if it produces both images and Helm charts
     ═══════════════════════════════════════════════════════════ -->
## Images

Images are published to [`quay.io/okdp`](https://quay.io/organization/okdp).

| Image | Tag format | Example |
|-------|-----------|---------|
| `quay.io/okdp/<image>` | `<upstream-version>-<release>` | `quay.io/okdp/superset:6.0.0-1.0.0` |

> See [Releases](https://github.com/OKDP/<repo>/releases) for the full changelog and all available tags.

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 11 — OKDP Integration
     Mandatory for all repos.
     Explain how this component fits into the broader OKDP platform.
     Always link to the sandbox if this component is included there.
     ═══════════════════════════════════════════════════════════ -->
## OKDP Integration

This component is part of the [OKDP Data Platform](https://okdp.io) — a cloud-native, open-source data platform for Kubernetes.

It is pre-integrated in the [OKDP Sandbox](https://github.com/OKDP/okdp-sandbox), a full local data platform you can explore with a single command:

```sh
git clone https://github.com/OKDP/okdp-sandbox.git
```

> In the sandbox, this component is available at: `https://<service>.okdp.sandbox`

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 12 — Troubleshooting [MANDATORY for Helm, Image+Chart, Sandbox]
     Document the top 3 most common errors a new user will encounter.
     Format: symptom → likely cause → fix command + expected result.
     Do not leave this section empty or with placeholder text.
     ═══════════════════════════════════════════════════════════ -->
## Troubleshooting

### Error 1 — `Error: INSTALLATION FAILED: ...`

**Symptom:** `helm install` exits with an error.
**Cause:** ...
**Fix:**
```sh
fix command here
```

### Error 2 — Pod stuck in `Pending` state

**Symptom:** `kubectl get pods -n <namespace>` shows `Pending` after several minutes.
**Cause:** Insufficient cluster resources, missing PersistentVolumeClaim, or missing Secret.
**Fix:**
```sh
kubectl describe pod <pod-name> -n <namespace>
```
Look for `Events:` at the bottom of the output to identify the root cause.

### Error 3 — `ImagePullBackOff` on `quay.io/okdp/...`

**Symptom:** Pod stays in `ImagePullBackOff` or `ErrImagePull`.
**Cause:** The image tag does not exist (typo) or the cluster cannot reach `quay.io`.
**Fix:** Verify the tag exists at [quay.io/okdp](https://quay.io/organization/okdp) and that the cluster has outbound internet access:
```sh
kubectl run test --image=quay.io/okdp/<image>:<tag> --restart=Never -n <namespace>
kubectl describe pod test -n <namespace>
kubectl delete pod test -n <namespace>
```

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 13 — Contributing / Development [OPTIONAL]
     Include only if the repo accepts external contributions
     or if the build/test process is non-trivial.
     Each sub-section must include an expected result.
     ═══════════════════════════════════════════════════════════ -->
## Contributing / Development

See [CONTRIBUTING.md](https://github.com/OKDP/.github/blob/main/CONTRIBUTING.md) for the full contribution guide and code standards.

### Development setup

```sh
git clone https://github.com/OKDP/<repo>.git
cd <repo>
# Install dependencies
make setup
```

**Expected result:** Local environment ready for development.

### Build

```sh
make build
# or
docker build -t quay.io/okdp/<image>:<tag> .
```

**Expected result:**
```
Successfully built <image-id>
Successfully tagged quay.io/okdp/<image>:<tag>
```

### Test

```sh
make test
```

**Expected result:**
```
All tests passed. (X tests, 0 failures)
```

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 14 — Uninstall / Teardown [MANDATORY for Helm, Image+Chart, Sandbox]
     Provide a complete teardown procedure.
     For Helm repos: include both release uninstall and namespace deletion.
     For Sandbox repos: include full cluster teardown.
     Each step must have an expected result.
     ═══════════════════════════════════════════════════════════ -->
## Uninstall / Teardown

### Remove the Helm release

```sh
helm uninstall <release-name> -n <namespace>
```

**Expected result:**
```
release "<release-name>" uninstalled
```

### Remove the namespace

If the namespace was created solely for this installation:

```sh
kubectl delete namespace <namespace>
```

**Expected result:**
```
namespace "<namespace>" deleted
```

<!-- For sandbox environments, add full cluster teardown: -->
<!--
### Destroy the local cluster

```sh
kind delete cluster --name okdp-sandbox
```

**Expected result:**
```
Deleting cluster "okdp-sandbox" ...
```
-->

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 15 — Contributing & License
     Mandatory. Always link to the central CONTRIBUTING.md.
     ═══════════════════════════════════════════════════════════ -->
## Contributing & License

Contributions are welcome! Please read the [contribution guidelines](https://github.com/OKDP/.github/blob/main/CONTRIBUTING.md).

This project is licensed under the [Apache License 2.0](LICENSE).

---

<!-- ═══════════════════════════════════════════════════════════
     SECTION 16 — Footer
     MANDATORY. Do not remove or modify.
     ═══════════════════════════════════════════════════════════ -->

**Built for the OKDP Community**
<a href="https://okdp.io"><img src="https://okdp.io/logos/okdp-notext.svg" height="20px"/></a>
```

---

## Workshop Discussion Points

Things to decide together as a team:

1. **Language** — All README content in English? Or bilingual (FR/EN)? Currently inconsistent across repos.

2. **Screenshot storage convention** — `docs/assets/` vs `docs/images/`? Both are currently used. Pick one.

3. **Auto-generated Helm docs** — Some repos use `helm-docs` to auto-generate `helm/chart/README.md`. Should the template reference this tool explicitly?

4. **Minimum viable README** — For very small repos (e.g. `trino-opal-example-policy`, `meeting-notes`), which sections can be dropped? Should there be a "lite" variant of this template?

5. **Audit format** — Should colleagues submit their audit findings as a GitHub Issue (using a checklist based on the table above), or directly as a PR editing the README?

6. **Versioning this template** — If the template evolves, how do we propagate changes to repos that already used v1.0?
