# OKDP Handbook

Documentation, installation guides, and Helm values for all OKDP platform components.

## Structure

```
okdp-handbook/
├── modules/
│   ├── infrastructure/                # Infrastructure prerequisites
│   │   ├── okdp-prerequisites/        # Umbrella chart: deploy all infra in one shot
│   │   │   ├── Chart.yaml             # Helm umbrella (cert-manager + ingress-nginx + CNPG)
│   │   │   ├── manifests/             # Post-install: ClusterIssuers, PostgreSQL, secrets
│   │   │   ├── values/sandbox.yaml
│   │   │   ├── INSTALL.md
│   │   │   └── README.md
│   │   ├── cert-manager/              # Individual module docs + values
│   │   ├── ingress-nginx/
│   │   ├── cloudnative-pg/
│   │   ├── keycloak/
│   │   └── seaweedfs/
│   └── data/                          # Data platform components
│       ├── spark-operator/
│       ├── spark-history-server/
│       ├── hive-metastore/
│       ├── trino/
│       ├── superset/
│       ├── jupyterhub/
│       ├── airflow/
│       └── okdp-examples/
├── CONTRIBUTING.md
└── README.md
```

## Two Ways to Install

### Option A: All infrastructure at once (umbrella chart)

```bash
cd modules/infrastructure/okdp-prerequisites
helm dependency build
helm install okdp-prerequisites . -n okdp-system --create-namespace -f values/sandbox.yaml
# Then apply post-install manifests (see INSTALL.md)
```

### Option B: Module by module

Follow each module's `INSTALL.md` individually, in dependency order.

## Module Inventory

### Infrastructure

| Module                                                           | Chart          | Version | Description                   |
| ---------------------------------------------------------------- | -------------- | ------- | ----------------------------- |
| [okdp-prerequisites](modules/infrastructure/okdp-prerequisites/) | umbrella       | 1.0.0   | All infra in one shot         |
| [cert-manager](modules/infrastructure/cert-manager/)             | cert-manager   | v1.17.1 | TLS certificate management    |
| [ingress-nginx](modules/infrastructure/ingress-nginx/)           | ingress-nginx  | 4.12.1  | HTTP/HTTPS ingress controller |
| [cloudnative-pg](modules/infrastructure/cloudnative-pg/)         | cloudnative-pg | 0.23.0  | PostgreSQL operator           |
| [keycloak](modules/infrastructure/keycloak/)                     | keycloakx      | 2.5.1   | Identity & access management  |
| [seaweedfs](modules/infrastructure/seaweedfs/)                   | seaweedfs      | 4.0.407 | S3-compatible object storage  |

### Data Platform

| Module                                                     | Chart                | Version | Description                  |
| ---------------------------------------------------------- | -------------------- | ------- | ---------------------------- |
| [spark-operator](modules/data/spark-operator/)             | spark-operator       | 2.4.0   | Spark application lifecycle  |
| [spark-history-server](modules/data/spark-history-server/) | spark-history-server | 1.0.0   | Spark job monitoring UI      |
| [hive-metastore](modules/data/hive-metastore/)             | hive-metastore       | 1.4.0   | Centralized metadata catalog |
| [trino](modules/data/trino/)                               | trino                | v1.39.1 | Distributed SQL query engine |
| [superset](modules/data/superset/)                         | superset             | 0.15.0  | Data visualization & BI      |
| [jupyterhub](modules/data/jupyterhub/)                     | jupyterhub           | 4.3.1   | Interactive notebooks        |
| [airflow](modules/data/airflow/)                           | airflow              | 1.17.0  | Workflow orchestration       |
| [okdp-examples](modules/data/okdp-examples/)               | okdp-examples        | 1.1.0   | Hands-on examples            |

## Installation Order

```
Phase 1 — Infrastructure (or use okdp-prerequisites umbrella chart)
  1. cert-manager  →  2. ingress-nginx  →  3. cloudnative-pg + PostgreSQL
  4. keycloak  →  5. seaweedfs

Phase 2 — Data Platform (install individually per need)
  6. spark-operator  →  7. spark-history-server  →  8. hive-metastore
  9. trino  →  10. superset  →  11. jupyterhub  →  12. airflow
  13. okdp-examples (optional)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
