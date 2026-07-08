# Phase 2 — Besoin 2 Issues

---

## Issue 2.0

**Title**: [Besoin 2] Create helm-handbook repository with structure and templates

**Labels**: `besoin-2`, `documentation`

**Body**:

### Description

Create the `helm-handbook` GitHub repository under the OKDP org with the folder structure,
standard open-source files, and documentation templates.

### Deliverables

- [ ] Repository created with `modules/infrastructure/` and `modules/data/` structure
- [ ] `README.md` with module inventory and installation order
- [ ] `CONTRIBUTING.md` with documentation standards, templates, and review process
- [ ] `LICENSE` (Apache 2.0)
- [ ] `MAINTAINERS`
- [ ] `.gitignore`

### Acceptance Criteria

- [ ] Repository is accessible to all contributors
- [ ] Templates are clear and complete
- [ ] CONTRIBUTING.md explains the 2-validator review process

**Effort**: 1 day

---

## Issue 2.1

**Title**: [Besoin 2] Create infrastructure umbrella chart (okdp-prerequisites)

**Labels**: `besoin-2`, `infrastructure`, `umbrella-chart`

**Body**:

### Description

Create the Helm umbrella chart that deploys ALL infrastructure prerequisites in one shot:
cert-manager, ingress-nginx, CloudNativePG, Keycloak, and SeaweedFS.

### Deliverables

- [ ] `modules/prerequisites/Chart.yaml` with all 5 dependencies
- [ ] `modules/prerequisites/values/sandbox.yaml`
- [ ] `modules/prerequisites/manifests/cert-manager-issuers.yaml`
- [ ] `modules/prerequisites/manifests/cnpg-cluster.yaml`
- [ ] `modules/prerequisites/manifests/secrets.yaml`
- [ ] `modules/prerequisites/README.md`

### Acceptance Criteria

- [ ] `helm dependency build` succeeds
- [ ] `helm install okdp-prerequisites` deploys all 5 infra components
- [ ] Post-install manifests create ClusterIssuers, PostgreSQL cluster, and secrets
- [ ] Full install verified on clean Kind cluster

**Effort**: 3 days

---

## Issue 2.2

**Title**: [Besoin 2] Write full-stack deployment guide

**Labels**: `besoin-2`, `documentation`

**Body**:

### Description

Write the end-to-end deployment guide (`README.md`) covering all modules in order,
with OKDP-specific integration details for each component (endpoints, credentials, values).

### Deliverables

- [ ] `README.md` with prerequisites phase and all data modules in installation order
- [ ] OKDP-specific values for each module under `modules/data/<module>/values/sandbox.yaml`

### Acceptance Criteria

- [ ] `helm install` commands work on a clean Kind cluster following only `README.md`
- [ ] All OKDP-specific integration details (auth, storage, networking, metadata) documented
- [ ] Values files contain real, working values — no placeholders
- [ ] Uninstall procedure is clean

**Effort**: 5 days

---

## Issue 2.3

**Title**: [Besoin 2] End-to-end validation of helm-handbook

**Labels**: `besoin-2`, `e2e-testing`

**Body**:

### Description

Install all modules from scratch on a clean Kind cluster following ONLY the documentation.
Must be done by someone who did NOT write any of the documentation.

### Acceptance Criteria

- [ ] Infrastructure umbrella chart installs successfully
- [ ] All data modules install following the full-stack guide (README.md)
- [ ] All web UIs accessible (Keycloak, Superset, JupyterHub, Airflow, Spark History, Trino)
- [ ] Spark job submission works
- [ ] Trino queries work against Hive Metastore
- [ ] Superset can query Trino
- [ ] JupyterHub PySpark notebooks work

**Effort**: 2 days
