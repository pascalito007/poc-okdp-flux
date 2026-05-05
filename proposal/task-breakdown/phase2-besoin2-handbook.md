# Phase 2 — Besoin 2: Module Documentation & Install Guides (helm-handbook)

## Objective

Create the `helm-handbook` repository with two deployment guides and the OKDP-specific
Helm values for each module:

- **Full-stack deployment guide** (`README.md`): end-to-end installation covering all modules in order
- **Prerequisites guide** (`modules/prerequisites/README.md`): infrastructure umbrella chart and post-install steps

## Tasks

### Task 2.0: Create helm-handbook repository

**What**: Create the repo with folder structure, CONTRIBUTING.md, README.md.

**Deliverables**:

- Repository with `modules/infrastructure/` and `modules/data/` structure
- CONTRIBUTING.md with documentation standards and review process
- README.md with module inventory and installation order

**Estimated effort**: 1 day

---

### Task 2.1: Create infrastructure umbrella chart (okdp-prerequisites)

**What**: Create the Helm umbrella chart that deploys all infrastructure prerequisites in one shot
(cert-manager, ingress-nginx, CloudNativePG, Keycloak, SeaweedFS), plus post-install manifests
for ClusterIssuers, PostgreSQL cluster, and secrets.

**Deliverables**:

- `modules/prerequisites/Chart.yaml`
- `modules/prerequisites/values/sandbox.yaml`
- `modules/prerequisites/manifests/cert-manager-issuers.yaml`
- `modules/prerequisites/manifests/cnpg-cluster.yaml`
- `modules/prerequisites/manifests/secrets.yaml`
- `modules/prerequisites/README.md`

**Acceptance Criteria**:

- `helm dependency build` succeeds
- `helm install okdp-prerequisites` deploys all infrastructure components
- Post-install manifests create ClusterIssuers, PostgreSQL, and secrets
- Full install verified on clean Kind cluster

**Estimated effort**: 3 days

---

### Task 2.2: Write full-stack deployment guide

**What**: Write `README.md` covering end-to-end installation of all modules in order,
with OKDP-specific integration details for each component.

**Deliverables**:

- `README.md` with prerequisites phase and all data modules
- OKDP-specific values for each module under `modules/data/<module>/values/sandbox.yaml`

**Estimated effort**: 5 days

---

### Task 2.3: End-to-end validation

**What**: Install all modules from scratch on a clean Kind cluster following only the documentation.

**Acceptance Criteria**:

- Infrastructure umbrella chart installs successfully
- All data modules install following the full-stack guide (README.md)
- All web UIs accessible
- Spark, Trino, Superset, JupyterHub functional

**Assignee**: Someone who did NOT write any documentation
**Estimated effort**: 2 days

---

## Summary

| Task      | Description              | Effort             |
| --------- | ------------------------ | ------------------ |
| 2.0       | Repository setup         | 1 day              |
| 2.1       | Prerequisites guide      | 3 days             |
| 2.2       | Full-stack guide + values | 5 days             |
| 2.3       | E2E validation           | 2 days             |
| **Total** |                          | **~11 person-days** |
