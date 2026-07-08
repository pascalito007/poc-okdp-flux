# Phase 3 — Besoin 3 Issues

---

## Issue 3.0

**Title**: [Besoin 3] Create feature/fluxcd-native branch on okdp-sandbox

**Labels**: `besoin-3`

**Body**:

### Description

Create the `feature/fluxcd-native` branch on `okdp-sandbox` for the FluxCD-native refactor.

### Acceptance Criteria

- [ ] Branch created from `main`

**Effort**: 0.5 day

---

## Issue 3.1

**Title**: [Besoin 3] Create FluxCD bootstrap and chart sources

**Labels**: `besoin-3`, `infrastructure`

**Body**:

### Deliverables

- [ ] `clusters/sandbox/flux/bootstrap.yaml` (GitRepository + root Kustomizations)
- [ ] `clusters/sandbox/infra/sources/helm-repos.yaml` (8 HelmRepositories)
- [ ] `clusters/sandbox/infra/sources/okdp-oci-charts.yaml` (4 OCIRepositories)

### Acceptance Criteria

- [ ] `flux get sources helm` shows all repos ready
- [ ] `flux get sources oci` shows all OCI repos ready
- [ ] `flux get sources git` shows okdp-sandbox repo ready

**Effort**: 1 day

---

## Issue 3.2

**Title**: [Besoin 3] Create split context ConfigMaps (replace KuboCD Context)

**Labels**: `besoin-3`, `infrastructure`

**Body**:

### Description

Convert the KuboCD `Context` CR into split ConfigMaps using `postBuild.substituteFrom`.

### Deliverables

- [ ] `clusters/sandbox/context/cluster-vars.yaml` (ingress, storage class, DB host, proxy)
- [ ] `clusters/sandbox/context/storage-vars.yaml` (S3 endpoints, buckets, credential refs)
- [ ] `clusters/sandbox/context/identity-vars.yaml` (Keycloak endpoints, OIDC config)
- [ ] `clusters/sandbox/context/namespace-default.yaml` (namespace-scoped variables)

### Acceptance Criteria

- [ ] All ConfigMaps created in flux-system namespace
- [ ] Variable naming is consistent and documented
- [ ] No KuboCD Go template syntax remains

**Effort**: 2 days

---

## Issue 3.3

**Title**: [Besoin 3] Create role Kustomizations (replace KuboCD roles)

**Labels**: `besoin-3`, `infrastructure`

**Body**:

### Deliverables

- [ ] `clusters/sandbox/roles/role-certificates.yaml`
- [ ] `clusters/sandbox/roles/role-ingress.yaml` (dependsOn: role-certificates)
- [ ] `clusters/sandbox/roles/role-pg-operator.yaml`
- [ ] `clusters/sandbox/roles/role-storage.yaml` (dependsOn: role-ingress)
- [ ] `clusters/sandbox/roles/role-identity.yaml` (dependsOn: role-pg-operator, role-ingress)

### Acceptance Criteria

- [ ] `flux get kustomizations` shows all roles reconciled
- [ ] Dependency ordering correct
- [ ] Variables properly substituted in child resources

**Effort**: 1 day

---

## Issue 3.4

**Title**: [Besoin 3] Convert infrastructure to FluxCD HelmReleases

**Labels**: `besoin-3`, `infrastructure`

**Body**:

### Deliverables

- [ ] `clusters/sandbox/infra/cert-manager/helmrelease.yaml` + `cluster-issuer.yaml`
- [ ] `clusters/sandbox/infra/ingress-nginx/helmrelease.yaml`
- [ ] `clusters/sandbox/infra/cloudnative-pg/helmrelease.yaml` + `cluster.yaml`
- [ ] `clusters/sandbox/infra/keycloak/helmrelease.yaml`
- [ ] `clusters/sandbox/infra/seaweedfs/helmrelease.yaml`

### Acceptance Criteria

- [ ] All infrastructure HelmReleases reconcile successfully
- [ ] cert-manager ClusterIssuer ready
- [ ] PostgreSQL cluster healthy
- [ ] SeaweedFS S3 API functional
- [ ] Keycloak accessible

**Effort**: 3 days

---

## Issue 3.5

**Title**: [Besoin 3] Convert data platform apps to FluxCD HelmReleases with role-based deps

**Labels**: `besoin-3`, `data-platform`

**Body**:

### Description

Most complex task. Convert all data platform apps with role-based `dependsOn`.
Resolve KuboCD Go templates to `${VARIABLE}` syntax.

### Deliverables

- [ ] `clusters/sandbox/apps/kustomizations.yaml` (all app Kustomizations)
- [ ] `clusters/sandbox/apps/spark-operator/helmrelease.yaml` + `rbac.yaml`
- [ ] `clusters/sandbox/apps/hive-metastore/helmrelease.yaml`
- [ ] `clusters/sandbox/apps/spark-history-server/base/` + `overlays/`
- [ ] `clusters/sandbox/apps/trinodb/helmrelease.yaml`
- [ ] `clusters/sandbox/apps/superset/helmrelease.yaml`
- [ ] `clusters/sandbox/apps/jupyterhub/helmrelease.yaml`
- [ ] `clusters/sandbox/apps/airflow/helmrelease.yaml`

### Acceptance Criteria

- [ ] All app HelmReleases reconcile
- [ ] All web UIs accessible
- [ ] Spark job submission works
- [ ] Trino queries work
- [ ] Superset dashboards work
- [ ] JupyterHub notebooks work
- [ ] Airflow DAGs sync and execute

**Effort**: 5 days

---

## Issue 3.6

**Title**: [Besoin 3] Handle auxiliary components and remove KuboCD

**Labels**: `besoin-3`, `infrastructure`

**Body**:

### Deliverables

- [ ] Kustomization for local-secrets-provider
- [ ] Kustomization for tools (reloader, replicator)
- [ ] Remove `clusters/sandbox/flux/kubocd.yaml`
- [ ] Remove `clusters/sandbox/default-context.yaml`
- [ ] Remove `clusters/sandbox/releases/` directory

### Acceptance Criteria

- [ ] No KuboCD CRDs or controller remain
- [ ] All auxiliary functions preserved via native K8s/FluxCD resources

**Effort**: 2 days

---

## Issue 3.7

**Title**: [Besoin 3] Create prod environment skeleton

**Labels**: `besoin-3`

**Body**:

### Deliverables

- [ ] `clusters/prod/context/cluster-vars.yaml`
- [ ] `clusters/prod/context/storage-vars.yaml`
- [ ] `clusters/prod/context/identity-vars.yaml`
- [ ] Documentation on how to add a new environment

**Effort**: 1 day

---

## Issue 3.8

**Title**: [Besoin 3] Update sandbox README (remove KuboCD references)

**Labels**: `besoin-3`, `documentation`

**Body**:

### Acceptance Criteria

- [ ] README documents FluxCD-native installation
- [ ] All KuboCD references removed
- [ ] Installation steps updated

**Effort**: 1 day

---

## Issue 3.9

**Title**: [Besoin 3] End-to-end testing of FluxCD-native sandbox

**Labels**: `besoin-3`, `e2e-testing`

**Body**:

### Acceptance Criteria

- [ ] Full sandbox deploys without KuboCD
- [ ] `flux get kustomizations` shows all roles and apps reconciled
- [ ] `flux get helmreleases -A` shows all releases ready
- [ ] All services accessible and functional
- [ ] Changing a context variable propagates to affected apps

**Effort**: 3 days
