Diagram 1 — Repository structure + layers

graph TD
subgraph REPO["🗂 okdp-sandbox — GitHub repo"]
subgraph CLUSTER["clusters/sandbox/ ← only this changes per cluster"]
FLUX["flux/\n──────────────\nbootstrap.yaml\nroot-kustomization.yaml\n\n⚡ apply once manually\nFlux takes over after"]
CONTEXT["context/ ← replaces KuboCD Context CR\n──────────────\ncluster-vars.yaml 🌐 ingress, cert-issuer\nstorage-vars.yaml 🗄 S3 URLs,
buckets\nidentity-vars.yaml 🔐 OIDC issuer\ndatabase-vars.yaml 🐘 DB host, creds\nnamespace-default.yaml"]
ROLES_DIR["roles/ ← THE KEY: role-as-Kustomization\n──────────────\nrole-ingress.yaml → infra/ingress-nginx\nrole-external-secrets.yaml →
infra/local-secrets-provider\nrole-pg-operator.yaml → infra/cloudnative-pg\nrole-database-server.yaml → infra/cnpg-postgresql\nrole-storage.yaml →
infra/seaweedfs\nrole-identity.yaml → infra/keycloak\nrole-spark-operator.yaml → infra/spark-operator\nrole-data-catalog.yaml →
apps/hive-metastore\n\n⚙ swap path per cluster for portability"]
end

          subgraph INFRA["infra/  ← Layer 1: infrastructure  (shared, no cluster values)"]
              SOURCES["sources/\nokdp-oci-charts.yaml\ncert-manager.yaml\nseaweedfs.yaml"]
              SVC1["cert-manager/\nhelmrelease.yaml"]
              SVC2["ingress-nginx/\nhelmrelease.yaml"]
              SVC3["cloudnative-pg/\nhelmrelease.yaml"]
              SVC4["cnpg-postgresql/\nhelmrelease.yaml"]
              SVC5["keycloak/\nhelmrelease.yaml"]
              SVC6["seaweedfs/\nhelmrelease.yaml"]
              SVC7["local-secrets-provider/\nhelmrelease.yaml"]
              SVC8["spark-operator/\nhelmrelease.yaml"]
          end

          subgraph APPS["apps/  ← Layer 3: applications  (dependsOn role names only)"]
              APP1["hive-metastore/\nhelmrelease.yaml\ndependsOn: role-database-server\n          role-storage"]
              APP2["spark-history-server/\nbase/ overlays/with-proxy/\n      overlays/without-proxy/\ndependsOn: role-identity\n          role-storage\n
    role-ingress"]
              APP3["airflow/\nhelmrelease.yaml\ndependsOn: role-external-secrets\n          role-database-server\n          role-ingress"]
              APP4["trinodb/\nhelmrelease.yaml\ndependsOn: role-data-catalog\n          role-ingress"]
              APP5["jupyterhub/\nsuperset/\nokdp-examples/"]
          end

          DEPRECATED["packages/okdp-packages/\n──────────────\nKuboCD Package descriptors\n⚠ deprecated — remove gradually\nas each app migrates to apps/"]
      end

      ROLES_DIR -->|"path: ./infra/seaweedfs\nwait: true"| INFRA
      ROLES_DIR -->|"substituteFrom\nCluster ConfigMaps"| CONTEXT
      APPS -->|"dependsOn:\nrole names"| ROLES_DIR

---

Diagram 2 — Role dependency DAG (deployment ordering)

graph TD
subgraph LAYER0["Layer 0 — no dependencies"]
DNS["role-dns\n infra/dns-server"]
NGINX["role-ingress\n infra/ingress-nginx"]
CERT["role-cert-manager\n infra/cert-manager"]
SECRETS["role-external-secrets\n infra/local-secrets-provider"]
TOOLS["role-tools\n infra/tools"]
PGOP["role-pg-operator\n infra/cloudnative-pg"]
SPARKOP["role-spark-operator\n infra/spark-operator"]
end

      subgraph LAYER1["Layer 1 — depends on Layer 0"]
          DB["role-database-server\n infra/cnpg-postgresql"]
          STORAGE["role-storage\n infra/seaweedfs\n ⚙ swap → MinIO, S3..."]
      end

      subgraph LAYER2["Layer 2 — depends on Layer 1"]
          IDENTITY["role-identity\n infra/keycloak"]
          CATALOG["role-data-catalog\n apps/hive-metastore"]
      end

      subgraph LAYER3["Layer 3 — applications"]
          SHS["spark-history-server\n apps/spark-history-server"]
          TRINO["trinodb\n apps/trinodb"]
          AIRFLOW["airflow\n apps/airflow"]
          JUPYTER["jupyterhub\n apps/jupyterhub"]
          SUPERSET["superset\n apps/superset"]
      end

      PGOP --> DB
      SECRETS --> DB
      TOOLS --> DB
      NGINX --> STORAGE
      NGINX --> IDENTITY
      DB --> IDENTITY
      SECRETS --> IDENTITY
      DB --> CATALOG
      STORAGE --> CATALOG
      IDENTITY --> SHS
      STORAGE --> SHS
      NGINX --> SHS
      CATALOG --> TRINO
      NGINX --> TRINO
      SECRETS --> AIRFLOW
      DB --> AIRFLOW
      NGINX --> AIRFLOW
      NGINX --> JUPYTER
      STORAGE --> JUPYTER
      DB --> SUPERSET
      NGINX --> SUPERSET

      style STORAGE fill:#f9a,stroke:#c66
      style IDENTITY fill:#adf,stroke:#66c
      style DB fill:#afd,stroke:#6c6
      style CATALOG fill:#fda,stroke:#c96

---

Tips for Excalidraw

Once imported, I suggest:

- Color the 4 layers differently — Excalidraw lets you bulk-select by layer and change fill color
- Add a legend box mapping KuboCD concepts → Flux equivalents (role files → Kustomization CRs, Context CR → ConfigMaps)
- Highlight clusters/sandbox/roles/ with a bright border — it's the key selling point, the answer to KuboCD's main argument
- Put Diagram 1 (structure) on the left, Diagram 2 (dependency flow) on the right, connected by an arrow labeled "roles/ wires these together"
