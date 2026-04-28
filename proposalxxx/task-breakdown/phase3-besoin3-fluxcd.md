# Phase 3 — Besoin 3: FluxCD Native Sandbox (okdp-sandbox refactor)

## Objective

Refactor the existing `okdp-sandbox` repository to use native FluxCD resources instead of KuboCD.
Architecture follows the role-based Kustomization pattern with `postBuild.substituteFrom` for
shared configuration injection.

## Architecture Summary

```
clusters/sandbox/
├── flux/bootstrap.yaml          # GitRepository + root Kustomizations
├── context/                     # Split ConfigMaps (replaces KuboCD Context CR)
│   ├── cluster-vars.yaml        # postBuild.substituteFrom by all roles
│   ├── storage-vars.yaml        # postBuild.substituteFrom by storage-dependent apps
│   ├── identity-vars.yaml       # postBuild.substituteFrom by auth-dependent apps
│   └── namespace-default.yaml   # Namespace-scoped variables
├── roles/                       # Kustomization CRDs (replaces KuboCD role concept)
│   ├── role-certificates.yaml   # → ./infra/cert-manager
│   ├── role-ingress.yaml        # → ./infra/ingress-nginx, dependsOn: role-certificates
│   ├── role-pg-operator.yaml    # → ./infra/cloudnative-pg
│   ├── role-storage.yaml        # → ./infra/seaweedfs, dependsOn: role-ingress
│   └── role-identity.yaml       # → ./infra/keycloak, dependsOn: role-pg-operator, role-ingress
├── infra/                       # Infrastructure HelmReleases
│   ├── sources/                 # HelmRepository / OCIRepository
│   ├── cert-manager/            # helmrelease.yaml + cluster-issuer.yaml
│   ├── ingress-nginx/           # helmrelease.yaml
│   ├── cloudnative-pg/          # helmrelease.yaml + cluster.yaml
│   ├── keycloak/                # helmrelease.yaml
│   └── seaweedfs/               # helmrelease.yaml
└── apps/                        # App Kustomizations + HelmReleases
    ├── kustomizations.yaml      # All app Kustomizations with role-based dependsOn
    ├── spark-operator/          # helmrelease.yaml + rbac.yaml
    ├── hive-metastore/          # helmrelease.yaml
    ├── spark-history-server/    # base/ + overlays/ (with-proxy, without-proxy)
    ├── trinodb/                 # helmrelease.yaml
    ├── superset/                # helmrelease.yaml
    ├── jupyterhub/              # helmrelease.yaml
    └── airflow/                 # helmrelease.yaml
```

## Tasks

### Task 3.0: Create feature branch

**What**: Create `feature/fluxcd-native` branch on `okdp-sandbox`.

**Estimated effort**: 0.5 day

---

### Task 3.1: Create flux bootstrap and sources

**What**: Create `flux/bootstrap.yaml` with GitRepository CR and root Kustomizations.
Create all HelmRepository and OCIRepository sources.

**Deliverables**:

- `clusters/sandbox/flux/bootstrap.yaml`
- `clusters/sandbox/infra/sources/helm-repos.yaml`
- `clusters/sandbox/infra/sources/okdp-oci-charts.yaml`

**Acceptance Criteria**:

- `flux get sources helm` shows all repos ready
- `flux get sources oci` shows all OCI repos ready
- `flux get sources git` shows okdp-sandbox repo ready

**Estimated effort**: 1 day

---

### Task 3.2: Create split context ConfigMaps

**What**: Convert the KuboCD `Context` CR into split ConfigMaps using `postBuild.substituteFrom`.
Each ConfigMap covers a specific domain (cluster, storage, identity, namespace).

**Deliverables**:

- `clusters/sandbox/context/cluster-vars.yaml`
- `clusters/sandbox/context/storage-vars.yaml`
- `clusters/sandbox/context/identity-vars.yaml`
- `clusters/sandbox/context/namespace-default.yaml`

**Key work**:

- Extract all variables from `default-context.yaml` (KuboCD Context)
- Resolve all Go template expressions (`.Context.ingress.suffix`, `.Release.namespace`, etc.)
  into flat `${VARIABLE}` references
- Group variables by domain for clean separation of concerns
- Document which ConfigMaps each role/app needs

**Acceptance Criteria**:

- All ConfigMaps created in flux-system namespace
- Variable naming is consistent and documented
- No KuboCD Go template syntax remains

**Estimated effort**: 2 days

---

### Task 3.3: Create role Kustomizations

**What**: Create FluxCD Kustomization CRDs that replicate KuboCD's role-based dependency system.
Each role points to an infra path and injects context variables via `postBuild.substituteFrom`.

**Deliverables**:

- `clusters/sandbox/roles/role-certificates.yaml`
- `clusters/sandbox/roles/role-ingress.yaml`
- `clusters/sandbox/roles/role-pg-operator.yaml`
- `clusters/sandbox/roles/role-storage.yaml`
- `clusters/sandbox/roles/role-identity.yaml`

**Key work**:

- Map KuboCD roles to Kustomization CRDs
- Set up correct `dependsOn` chains between roles
- Configure `postBuild.substituteFrom` with appropriate ConfigMaps per role

**Acceptance Criteria**:

- `flux get kustomizations` shows all roles reconciled
- Dependency ordering is correct (certificates → ingress → storage, etc.)
- Variables are properly substituted in child resources

**Estimated effort**: 1 day

---

### Task 3.4: Convert infrastructure HelmReleases

**What**: Convert cert-manager, ingress-nginx, CloudNativePG, Keycloak, SeaweedFS from
KuboCD Release to FluxCD HelmRelease with `${VARIABLE}` substitution syntax.

**Deliverables**:

- `clusters/sandbox/infra/cert-manager/helmrelease.yaml`
- `clusters/sandbox/infra/cert-manager/cluster-issuer.yaml`
- `clusters/sandbox/infra/ingress-nginx/helmrelease.yaml`
- `clusters/sandbox/infra/cloudnative-pg/helmrelease.yaml`
- `clusters/sandbox/infra/cloudnative-pg/cluster.yaml`
- `clusters/sandbox/infra/keycloak/helmrelease.yaml`
- `clusters/sandbox/infra/seaweedfs/helmrelease.yaml`

**Key work**:

- For each module: extract final rendered Helm values from KuboCD package
- Replace all `.Context.*` and `.Parameters.*` Go templates with `${VARIABLE}` syntax
- Ensure all `${VARIABLE}` references match the context ConfigMaps
- Add cert-manager CRDs (ClusterIssuer, Certificate) as separate manifests

**Acceptance Criteria**:

- All infrastructure HelmReleases reconcile successfully
- `flux get helmreleases -A` shows all ready
- cert-manager ClusterIssuer is ready
- PostgreSQL cluster is healthy
- SeaweedFS S3 API is functional

**Estimated effort**: 3 days

---

### Task 3.5: Convert app HelmReleases with role-based dependsOn

**What**: Convert all data platform apps to FluxCD HelmRelease + Kustomization with
role-based `dependsOn` (not direct component references).

**Deliverables**:

- `clusters/sandbox/apps/kustomizations.yaml` (all app Kustomizations)
- `clusters/sandbox/apps/spark-operator/helmrelease.yaml`
- `clusters/sandbox/apps/spark-operator/rbac.yaml`
- `clusters/sandbox/apps/hive-metastore/helmrelease.yaml`
- `clusters/sandbox/apps/spark-history-server/base/` + `overlays/`
- `clusters/sandbox/apps/trinodb/helmrelease.yaml`
- `clusters/sandbox/apps/superset/helmrelease.yaml`
- `clusters/sandbox/apps/jupyterhub/helmrelease.yaml`
- `clusters/sandbox/apps/airflow/helmrelease.yaml`

**Key work**:

- Most complex task — Superset, JupyterHub, and Airflow have deep KuboCD templating
- Resolve all Go templates to `${VARIABLE}` syntax
- Implement base/overlays for spark-history-server (with-proxy, without-proxy)
- Wire each app Kustomization to the correct roles via `dependsOn`
- Configure `postBuild.substituteFrom` with the right ConfigMaps per app

**Acceptance Criteria**:

- All app HelmReleases reconcile successfully
- All web UIs are accessible
- Spark job submission works
- Trino queries work against Hive Metastore
- Superset can query Trino
- JupyterHub notebooks can run PySpark
- Airflow DAGs sync and execute

**Estimated effort**: 5 days

---

### Task 3.6: Handle auxiliary components

**What**: Convert or replace dns-server, coredns-patch, local-secrets-provider, tools.
Remove KuboCD-specific components (webhooks, kubocd controller).

**Deliverables**:

- Kustomization for local-secrets-provider (Secret manifests)
- Kustomization for tools (reloader, replicator)
- Remove `clusters/sandbox/flux/kubocd.yaml`
- Remove `clusters/sandbox/default-context.yaml`
- Remove `clusters/sandbox/releases/` directory

**Estimated effort**: 2 days

---

### Task 3.7: Create prod skeleton

**What**: Create `clusters/prod/` with different context values to demonstrate multi-env support.

**Deliverables**:

- `clusters/prod/context/cluster-vars.yaml` (production values)
- `clusters/prod/context/storage-vars.yaml`
- `clusters/prod/context/identity-vars.yaml`
- Documentation on how to add a new environment

**Estimated effort**: 1 day

---

### Task 3.8: Update README and documentation

**What**: Rewrite the sandbox README to document the FluxCD-native installation process.
Remove all KuboCD references.

**Estimated effort**: 1 day

---

### Task 3.9: End-to-end testing

**What**: Deploy the full sandbox from scratch using only FluxCD and verify all services
work identically to the current KuboCD-based deployment.

**Acceptance Criteria**:

- Full sandbox deploys without KuboCD
- `flux get kustomizations` shows all roles and apps reconciled
- `flux get helmreleases -A` shows all releases ready
- All services accessible and functional
- Changing a context variable propagates to affected apps

**Estimated effort**: 3 days

---

## Summary

| Task      | Description                  | Effort                |
| --------- | ---------------------------- | --------------------- |
| 3.0       | Feature branch               | 0.5 day               |
| 3.1       | Flux bootstrap + sources     | 1 day                 |
| 3.2       | Split context ConfigMaps     | 2 days                |
| 3.3       | Role Kustomizations          | 1 day                 |
| 3.4       | Infrastructure HelmReleases  | 3 days                |
| 3.5       | App HelmReleases + role deps | 5 days                |
| 3.6       | Auxiliary components         | 2 days                |
| 3.7       | Prod skeleton                | 1 day                 |
| 3.8       | README update                | 1 day                 |
| 3.9       | E2E testing                  | 3 days                |
| **Total** |                              | **~19.5 person-days** |
