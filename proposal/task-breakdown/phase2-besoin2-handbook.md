# Phase 2 — Besoin 2: Module Documentation & Install Guides (okdp-handbook)

## Objective

Create the `okdp-handbook` repository with standardized documentation, install guides,
and Helm values for each OKDP module. This includes the infrastructure umbrella chart
(meta chart) for deploying all prerequisites in one shot.

## Tasks

### Task 2.0: Create okdp-handbook repository

**What**: Create the repo with folder structure, CONTRIBUTING.md, README.md.

**Deliverables**:

- Repository with `modules/infrastructure/` and `modules/data/` structure
- CONTRIBUTING.md with documentation standards and review process
- README.md with module inventory and installation order

**Estimated effort**: 1 day

---

### Task 2.1: Create infrastructure umbrella chart (okdp-prerequisites)

**What**: Create the Helm umbrella chart that deploys cert-manager + ingress-nginx + CloudNativePG
in one shot, plus post-install manifests for ClusterIssuers, PostgreSQL cluster, and secrets.

**Deliverables**:

- `modules/infrastructure/okdp-prerequisites/Chart.yaml`
- `modules/infrastructure/okdp-prerequisites/values/sandbox.yaml`
- `modules/infrastructure/okdp-prerequisites/manifests/cert-manager-issuers.yaml`
- `modules/infrastructure/okdp-prerequisites/manifests/cnpg-cluster.yaml`
- `modules/infrastructure/okdp-prerequisites/manifests/secrets.yaml`
- `modules/infrastructure/okdp-prerequisites/README.md`
- `modules/infrastructure/okdp-prerequisites/INSTALL.md`

**Acceptance Criteria**:

- `helm dependency build` succeeds
- `helm install okdp-prerequisites` deploys all 3 infra components
- Post-install manifests create ClusterIssuers, PostgreSQL, and secrets
- Full install verified on clean Kind cluster

**Estimated effort**: 3 days

---

### Infrastructure Module Tasks

### Task 2.2: Document cert-manager

**Estimated effort**: 2 days

### Task 2.3: Document ingress-nginx

**Estimated effort**: 1 day

### Task 2.4: Document CloudNativePG

**Estimated effort**: 2 days

### Task 2.5: Document Keycloak

**Estimated effort**: 3 days

### Task 2.6: Document SeaweedFS

**Estimated effort**: 3 days

---

### Data Platform Module Tasks

### Task 2.7: Document Spark Operator

**Estimated effort**: 1 day

### Task 2.8: Document Spark History Server

**Estimated effort**: 2 days

### Task 2.9: Document Hive Metastore

**Estimated effort**: 2 days

### Task 2.10: Document Trino

**Estimated effort**: 2 days

### Task 2.11: Document Superset

**Estimated effort**: 3 days

### Task 2.12: Document JupyterHub

**Estimated effort**: 3 days

### Task 2.13: Document Airflow

**Estimated effort**: 2 days

### Task 2.14: Document OKDP Examples

**Estimated effort**: 1 day

---

### Task 2.15: End-to-end validation

**What**: Install all modules from scratch on a clean Kind cluster following only the documentation.

**Acceptance Criteria**:

- Infrastructure umbrella chart installs successfully
- All data modules install following INSTALL.md
- All web UIs accessible
- Spark, Trino, Superset, JupyterHub functional

**Assignee**: Someone who did NOT write any documentation
**Estimated effort**: 2 days

---

## Summary

| Task      | Module               | Effort              |
| --------- | -------------------- | ------------------- |
| 2.0       | Repository setup     | 1 day               |
| 2.1       | Umbrella chart       | 3 days              |
| 2.2       | cert-manager         | 2 days              |
| 2.3       | ingress-nginx        | 1 day               |
| 2.4       | CloudNativePG        | 2 days              |
| 2.5       | Keycloak             | 3 days              |
| 2.6       | SeaweedFS            | 3 days              |
| 2.7       | Spark Operator       | 1 day               |
| 2.8       | Spark History Server | 2 days              |
| 2.9       | Hive Metastore       | 2 days              |
| 2.10      | Trino                | 2 days              |
| 2.11      | Superset             | 3 days              |
| 2.12      | JupyterHub           | 3 days              |
| 2.13      | Airflow              | 2 days              |
| 2.14      | OKDP Examples        | 1 day               |
| 2.15      | E2E validation       | 2 days              |
| **Total** |                      | **~33 person-days** |
