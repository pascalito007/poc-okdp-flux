# OKDP Sandbox — FluxCD Native

Refactored OKDP Sandbox using native FluxCD resources. No KuboCD dependency.

## Architecture

```
okdp-sandbox/
├── clusters/
│   ├── sandbox/                         # Sandbox environment
│   │   ├── flux/                        # FluxCD bootstrap
│   │   │   └── bootstrap.yaml           # GitRepository CR pointing to this repo
│   │   │
│   │   ├── context/                     # Shared variables (replaces KuboCD Context CR)
│   │   │   ├── cluster-vars.yaml        # Ingress suffix, storage class, cluster info
│   │   │   ├── storage-vars.yaml        # S3 endpoints, buckets, credentials refs
│   │   │   ├── identity-vars.yaml       # Keycloak endpoints, OIDC config, client refs
│   │   │   └── namespace-default.yaml   # Default namespace ConfigMap
│   │   │
│   │   ├── roles/                       # Role-based dependency layer (replaces KuboCD roles)
│   │   │   ├── role-ingress.yaml        # Kustomization: deploys ingress-nginx
│   │   │   ├── role-pg-operator.yaml    # Kustomization: deploys CNPG + PostgreSQL
│   │   │   ├── role-storage.yaml        # Kustomization: deploys SeaweedFS
│   │   │   ├── role-identity.yaml       # Kustomization: deploys Keycloak
│   │   │   └── role-certificates.yaml   # Kustomization: deploys cert-manager + issuers
│   │   │
│   │   ├── infra/                       # Infrastructure HelmReleases
│   │   │   ├── sources/                 # HelmRepository / OCIRepository / GitRepository
│   │   │   │   ├── okdp-oci-charts.yaml # oci://quay.io/okdp/charts (shared)
│   │   │   │   ├── helm-repos.yaml      # External Helm repos (jetstack, ingress-nginx, etc.)
│   │   │   │   └── git-repos.yaml       # Git sources if needed
│   │   │   ├── cert-manager/
│   │   │   │   ├── helmrelease.yaml
│   │   │   │   └── cluster-issuer.yaml
│   │   │   ├── ingress-nginx/
│   │   │   │   └── helmrelease.yaml
│   │   │   ├── cloudnative-pg/
│   │   │   │   ├── helmrelease.yaml
│   │   │   │   └── cluster.yaml         # CNPG Cluster CR (PostgreSQL instance)
│   │   │   ├── keycloak/
│   │   │   │   └── helmrelease.yaml
│   │   │   └── seaweedfs/
│   │   │       └── helmrelease.yaml
│   │   │
│   │   └── apps/                        # Data platform HelmReleases
│   │       ├── spark-operator/
│   │       │   ├── helmrelease.yaml
│   │       │   └── rbac.yaml            # ServiceAccount, Role, RoleBinding
│   │       ├── hive-metastore/
│   │       │   └── helmrelease.yaml
│   │       ├── spark-history-server/
│   │       │   ├── base/
│   │       │   │   ├── helmrelease-main.yaml
│   │       │   │   └── helmrelease-proxy.yaml
│   │       │   └── overlays/
│   │       │       ├── with-proxy/
│   │       │       └── without-proxy/
│   │       ├── trinodb/
│   │       │   └── helmrelease.yaml
│   │       ├── superset/
│   │       │   └── helmrelease.yaml
│   │       ├── jupyterhub/
│   │       │   └── helmrelease.yaml
│   │       └── airflow/
│   │           └── helmrelease.yaml
│   │
│   └── prod/                            # Production environment (skeleton)
│       └── ...                          # Same structure, different context values
│
├── packages/
│   └── okdp-packages/                   # Kept for reference / backward compat
├── examples/                            # Unchanged
└── docs/                                # Unchanged
```

## Key Design Decisions

### Context via `postBuild.substituteFrom`

The KuboCD `Context` CR is replaced by ConfigMaps and Secrets in `context/`.
Each role Kustomization uses `postBuild.substituteFrom` to inject these variables
into the HelmReleases it manages. This is the native FluxCD way to share configuration.

### Role-based Dependencies via Kustomizations

KuboCD's role concept (apps depend on roles like `storage`, `ingress`, not on specific releases)
is replicated using FluxCD `Kustomization` CRDs. Each role:

- Points to a path containing the actual HelmReleases (`./infra/cert-manager`, `./infra/seaweedfs`)
- Injects context variables via `postBuild.substituteFrom`
- Apps `dependsOn` roles, not specific components

### Base/Overlays for Environment Variants

Apps that need environment-specific configuration (e.g., proxy settings) use the
Kustomize base/overlays pattern. The `base/` contains the common HelmRelease,
and `overlays/` contain patches for specific environments.

## Installation

```bash
# 1. Create Kind cluster
kind create cluster --config /tmp/okdp-sandbox-config.yaml

# 2. Install Flux
flux install

# 3. Bootstrap — apply the GitRepository and root Kustomization
kubectl apply -f clusters/sandbox/flux/bootstrap.yaml

# 4. Flux takes over — reconciles everything automatically
# Monitor progress:
flux get kustomizations -w
flux get helmreleases -A -w
```

## What Changed vs KuboCD

| Aspect           | KuboCD                               | FluxCD Native                               |
| ---------------- | ------------------------------------ | ------------------------------------------- |
| Release API      | `kubocd.kubotal.io/v1alpha1 Release` | `helm.toolkit.fluxcd.io/v2 HelmRelease`     |
| Shared config    | `Context` CR with Go templates       | ConfigMap + `postBuild.substituteFrom`      |
| Dependencies     | Role-based (custom controller)       | Role Kustomizations + `dependsOn`           |
| Package source   | KuboCD OCI packages                  | `HelmRepository` / `OCIRepository` (native) |
| Extra controller | KuboCD controller required           | None — uses FluxCD built-in controllers     |
| Template engine  | Go templates in KuboCD packages      | Kustomize `postBuild` variable substitution |
| Multi-env        | Context inheritance                  | `clusters/sandbox/` vs `clusters/prod/`     |
