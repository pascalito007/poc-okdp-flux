# Phase 2 — Besoin 2 Issues

---

## Issue 2.0

**Title**: [Besoin 2] Create okdp-handbook repository with structure and templates

**Labels**: `besoin-2`, `documentation`

**Body**:

### Description

Create the `okdp-handbook` GitHub repository under the OKDP org with the folder structure,
standard open-source files, and documentation templates.

### Deliverables

- [ ] Repository created with `modules/infrastructure/` and `modules/data/` structure
- [ ] `README.md` with module inventory and installation order
- [ ] `CONTRIBUTING.md` with documentation standards, templates, and review process
- [ ] `LICENSE` (Apache 2.0)
- [ ] `MAINTAINERS`
- [ ] `.gitignore`
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` with module-specific checklist

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

- [ ] `modules/infrastructure/okdp-prerequisites/Chart.yaml` with all 5 dependencies
- [ ] `modules/infrastructure/okdp-prerequisites/values/sandbox.yaml`
- [ ] `modules/infrastructure/okdp-prerequisites/manifests/cert-manager-issuers.yaml`
- [ ] `modules/infrastructure/okdp-prerequisites/manifests/cnpg-cluster.yaml`
- [ ] `modules/infrastructure/okdp-prerequisites/manifests/secrets.yaml`
- [ ] `modules/infrastructure/okdp-prerequisites/README.md`
- [ ] `modules/infrastructure/okdp-prerequisites/INSTALL.md`

### Acceptance Criteria

- [ ] `helm dependency build` succeeds
- [ ] `helm install okdp-prerequisites` deploys all 5 infra components
- [ ] Post-install manifests create ClusterIssuers, PostgreSQL cluster, and secrets
- [ ] Full install verified on clean Kind cluster

**Effort**: 3 days

---

## Issue 2.2

**Title**: [Besoin 2] Document cert-manager module

**Labels**: `besoin-2`, `infrastructure`, `documentation`

**Body**:

### Description

Create complete documentation for cert-manager including self-signed CA setup,
trust-manager integration, and ClusterIssuer creation.

### Deliverables

- [ ] `modules/infrastructure/cert-manager/README.md`
- [ ] `modules/infrastructure/cert-manager/INSTALL.md`
- [ ] `modules/infrastructure/cert-manager/DEPENDENCIES.md`
- [ ] `modules/infrastructure/cert-manager/values/sandbox.yaml`

### Acceptance Criteria

- [ ] `helm install` commands work on a clean Kind cluster
- [ ] ClusterIssuer `default-issuer` is created and READY
- [ ] CA certificate can be exported
- [ ] Uninstall is clean (no orphaned resources)

**Effort**: 2 days

---

## Issue 2.3

**Title**: [Besoin 2] Document ingress-nginx module

**Labels**: `besoin-2`, `infrastructure`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/infrastructure/ingress-nginx/README.md`
- [ ] `modules/infrastructure/ingress-nginx/INSTALL.md`
- [ ] `modules/infrastructure/ingress-nginx/DEPENDENCIES.md`
- [ ] `modules/infrastructure/ingress-nginx/values/sandbox.yaml`

### Acceptance Criteria

- [ ] Ingress controller reachable on localhost:443 (Kind)
- [ ] IngressClass `nginx` created
- [ ] Uninstall is clean

**Effort**: 1 day

---

## Issue 2.4

**Title**: [Besoin 2] Document CloudNativePG module

**Labels**: `besoin-2`, `infrastructure`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/infrastructure/cloudnative-pg/README.md`
- [ ] `modules/infrastructure/cloudnative-pg/INSTALL.md`
- [ ] `modules/infrastructure/cloudnative-pg/DEPENDENCIES.md`
- [ ] `modules/infrastructure/cloudnative-pg/values/sandbox.yaml`

### Acceptance Criteria

- [ ] CNPG operator running
- [ ] PostgreSQL cluster healthy with all 6 databases created
- [ ] All credential secrets exist
- [ ] `psql` connectivity test passes

**Effort**: 2 days

---

## Issue 2.5

**Title**: [Besoin 2] Document Keycloak module

**Labels**: `besoin-2`, `infrastructure`, `documentation`

**Body**:

### Description

Most complex infrastructure module. Requires documenting realm configuration,
users, groups, roles, and OIDC client setup.

### Deliverables

- [ ] `modules/infrastructure/keycloak/README.md`
- [ ] `modules/infrastructure/keycloak/INSTALL.md`
- [ ] `modules/infrastructure/keycloak/DEPENDENCIES.md`
- [ ] `modules/infrastructure/keycloak/values/sandbox.yaml`

### Acceptance Criteria

- [ ] Keycloak accessible at `https://keycloak.<domain>`
- [ ] Admin login works (admin/admin)
- [ ] Test users (usera, userb, adm) can authenticate
- [ ] OIDC clients configured (public-oidc-client, confidential-oidc-client)
- [ ] Groups scope with role-to-groups mapper configured

**Effort**: 3 days

---

## Issue 2.6

**Title**: [Besoin 2] Document SeaweedFS module

**Labels**: `besoin-2`, `infrastructure`, `documentation`

**Body**:

### Description

Complex secret management. Requires documenting S3 authentication setup,
per-service credentials, and bucket creation.

### Deliverables

- [ ] `modules/infrastructure/seaweedfs/README.md`
- [ ] `modules/infrastructure/seaweedfs/INSTALL.md`
- [ ] `modules/infrastructure/seaweedfs/DEPENDENCIES.md`
- [ ] `modules/infrastructure/seaweedfs/values/sandbox.yaml`

### Acceptance Criteria

- [ ] SeaweedFS accessible at `https://seaweedfs-*.<domain>`
- [ ] S3 API functional (test with aws-cli)
- [ ] Buckets created (hive, spark-events)
- [ ] Per-service credentials work

**Effort**: 3 days

---

## Issue 2.7

**Title**: [Besoin 2] Document Spark Operator module

**Labels**: `besoin-2`, `data-platform`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/data/spark-operator/README.md`
- [ ] `modules/data/spark-operator/INSTALL.md`
- [ ] `modules/data/spark-operator/DEPENDENCIES.md`
- [ ] `modules/data/spark-operator/values/sandbox.yaml`

### Acceptance Criteria

- [ ] Operator running with webhook enabled
- [ ] SparkPi test job completes successfully
- [ ] Spark RBAC (ServiceAccount, Role, RoleBinding) documented

**Effort**: 1 day

---

## Issue 2.8

**Title**: [Besoin 2] Document Spark History Server module

**Labels**: `besoin-2`, `data-platform`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/data/spark-history-server/README.md`
- [ ] `modules/data/spark-history-server/INSTALL.md`
- [ ] `modules/data/spark-history-server/DEPENDENCIES.md`
- [ ] `modules/data/spark-history-server/values/sandbox.yaml`

### Acceptance Criteria

- [ ] History Server UI accessible with OIDC login
- [ ] S3 event log reading works
- [ ] Spark Web Proxy documented

**Effort**: 2 days

---

## Issue 2.9

**Title**: [Besoin 2] Document Hive Metastore module

**Labels**: `besoin-2`, `data-platform`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/data/hive-metastore/README.md`
- [ ] `modules/data/hive-metastore/INSTALL.md`
- [ ] `modules/data/hive-metastore/DEPENDENCIES.md`
- [ ] `modules/data/hive-metastore/values/sandbox.yaml`

### Acceptance Criteria

- [ ] Hive Metastore running with Thrift service on port 9083
- [ ] PostgreSQL connection working
- [ ] S3 warehouse configured

**Effort**: 2 days

---

## Issue 2.10

**Title**: [Besoin 2] Document Trino module

**Labels**: `besoin-2`, `data-platform`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/data/trino/README.md`
- [ ] `modules/data/trino/INSTALL.md`
- [ ] `modules/data/trino/DEPENDENCIES.md`
- [ ] `modules/data/trino/values/sandbox.yaml`

### Acceptance Criteria

- [ ] Trino UI accessible with OIDC login
- [ ] Hive connector configured (queries against Hive Metastore work)
- [ ] S3 data access via lakehouse catalog works
- [ ] TLS with init container for PEM generation documented

**Effort**: 2 days

---

## Issue 2.11

**Title**: [Besoin 2] Document Superset module

**Labels**: `besoin-2`, `data-platform`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/data/superset/README.md`
- [ ] `modules/data/superset/INSTALL.md`
- [ ] `modules/data/superset/DEPENDENCIES.md`
- [ ] `modules/data/superset/values/sandbox.yaml`

### Acceptance Criteria

- [ ] Superset UI accessible with OIDC login
- [ ] Trino datasource pre-configured
- [ ] Example dashboards loaded (optional)
- [ ] Redis cache working

**Effort**: 3 days

---

## Issue 2.12

**Title**: [Besoin 2] Document JupyterHub module

**Labels**: `besoin-2`, `data-platform`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/data/jupyterhub/README.md`
- [ ] `modules/data/jupyterhub/INSTALL.md`
- [ ] `modules/data/jupyterhub/DEPENDENCIES.md`
- [ ] `modules/data/jupyterhub/values/sandbox.yaml`

### Acceptance Criteria

- [ ] JupyterHub accessible with OIDC login
- [ ] PySpark notebook profile works (Spark-on-K8s client mode)
- [ ] S3 file browser configured
- [ ] Multiple notebook profiles documented

**Effort**: 3 days

---

## Issue 2.13

**Title**: [Besoin 2] Document Airflow module

**Labels**: `besoin-2`, `data-platform`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/data/airflow/README.md`
- [ ] `modules/data/airflow/INSTALL.md`
- [ ] `modules/data/airflow/DEPENDENCIES.md`
- [ ] `modules/data/airflow/values/sandbox.yaml`

### Acceptance Criteria

- [ ] Airflow UI accessible
- [ ] DAG gitSync working
- [ ] PostgreSQL metadata connection working
- [ ] Spark integration documented (SparkKubernetesOperator)

**Effort**: 2 days

---

## Issue 2.14

**Title**: [Besoin 2] Document OKDP Examples module

**Labels**: `besoin-2`, `data-platform`, `documentation`

**Body**:

### Deliverables

- [ ] `modules/data/okdp-examples/README.md`
- [ ] `modules/data/okdp-examples/INSTALL.md`
- [ ] `modules/data/okdp-examples/DEPENDENCIES.md`
- [ ] `modules/data/okdp-examples/values/sandbox.yaml`

### Acceptance Criteria

- [ ] Examples pod running
- [ ] Dataset download and S3 upload working
- [ ] Trino integration documented

**Effort**: 1 day

---

## Issue 2.15

**Title**: [Besoin 2] End-to-end validation of okdp-handbook

**Labels**: `besoin-2`, `e2e-testing`

**Body**:

### Description

Install all modules from scratch on a clean Kind cluster following ONLY the documentation.
Must be done by someone who did NOT write any of the documentation.

### Acceptance Criteria

- [ ] Infrastructure umbrella chart installs successfully
- [ ] All data modules install following INSTALL.md
- [ ] All web UIs accessible (Keycloak, Superset, JupyterHub, Airflow, Spark History, Trino)
- [ ] Spark job submission works
- [ ] Trino queries work against Hive Metastore
- [ ] Superset can query Trino
- [ ] JupyterHub PySpark notebooks work

**Effort**: 2 days
