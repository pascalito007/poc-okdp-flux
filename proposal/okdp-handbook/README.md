# OKDP Handbook

Complete installation guide for the OKDP (Open Kubernetes Data Platform).

This handbook documents how to deploy a fully integrated OKDP stack — from infrastructure
prerequisites to data platform modules — with all components configured to work together.

> This is NOT a collection of individual Helm chart installation guides.
> Each module's official documentation covers that. This handbook documents the **OKDP-specific
> integration**: how to configure each component so it connects to the others (auth, storage,
> networking, metadata).

## Prerequisites

- Kubernetes cluster 1.28+
- Helm 3.x
- kubectl

## Full Installation Guide

### Phase 1: Infrastructure Prerequisites

Deploy all infrastructure in one shot using the umbrella chart:

```bash
cd modules/prerequisites
helm dependency build
helm install okdp-prerequisites . \
  --namespace okdp-system --create-namespace \
  -f values/sandbox.yaml \
  --wait --timeout 15m
```

This installs:

- **cert-manager** — TLS certificate management
- **ingress-nginx** — HTTP/HTTPS routing (NodePort 30080/30443 for Kind)
- **CloudNativePG** — PostgreSQL operator
- **Keycloak** — Identity provider (OIDC)
- **SeaweedFS** — S3-compatible object storage

#### Post-install: Create ClusterIssuers and CA

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager \
  -n okdp-system --timeout=300s
kubectl apply -f modules/prerequisites/manifests/cert-manager-issuers.yaml
```

#### Post-install: Create PostgreSQL cluster and databases

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cloudnative-pg \
  -n okdp-system --timeout=300s
kubectl apply -f modules/prerequisites/manifests/cnpg-cluster.yaml
sleep 30
kubectl wait --for=condition=ready pod -l cnpg.io/cluster=postgresql-instance \
  -n cnpg-system --timeout=300s
```

#### Post-install: Create credential secrets

```bash
kubectl apply -f modules/prerequisites/manifests/secrets.yaml
```

#### Post-install: Configure Keycloak realm

Access Keycloak at `https://keycloak.okdp.sandbox` (admin/admin) and configure:

- OIDC clients: `public-oidc-client` (public) and `confidential-oidc-client` (secret: `secret1`)
- Groups scope with role-to-groups protocol mapper
- Test users: usera/usera (teama), userb/userb (teamb), adm/adm (admins)

See [modules/prerequisites/](modules/prerequisites/) for detailed realm configuration.

#### Verify infrastructure

```bash
kubectl get clusterissuers                    # default-issuer READY=True
kubectl get ingressclass                      # nginx
kubectl get clusters -n cnpg-system           # postgresql-instance healthy
kubectl get pods -l app.kubernetes.io/name=keycloakx  # Running
kubectl get pods -l app.kubernetes.io/name=seaweedfs  # master, volume, filer Running
```

---

### Phase 2: Data Platform Modules

Install each data module using its OKDP-specific values. These values configure the module
to integrate with the infrastructure deployed in Phase 1 (database, S3, OIDC, ingress, TLS).

#### Spark Operator

```bash
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator --create-namespace \
  --version 2.4.0 \
  -f modules/data/spark-operator/values/sandbox.yaml

# Create Spark RBAC
kubectl apply -f modules/data/spark-operator/manifests/spark-rbac.yaml
```

#### Hive Metastore

```bash
helm install hive-metastore oci://quay.io/okdp/charts/hive-metastore \
  --version 1.4.0 \
  -f modules/data/hive-metastore/values/sandbox.yaml
```

#### Spark History Server

```bash
helm install spark-history-server oci://quay.io/okdp/charts/spark-history-server \
  --version 1.0.0 \
  -f modules/data/spark-history-server/values/sandbox.yaml
```

#### Trino

```bash
helm repo add trinodb https://trinodb.github.io/charts/
helm install trinodb trinodb/trino \
  --version v1.39.1 \
  -f modules/data/trino/values/sandbox.yaml
```

#### Apache Superset

```bash
helm install superset oci://quay.io/okdp/charts/superset \
  --version 0.15.0 \
  -f modules/data/superset/values/sandbox.yaml
```

#### JupyterHub

```bash
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm install jupyterhub jupyterhub/jupyterhub \
  --version 4.3.1 \
  -f modules/data/jupyterhub/values/sandbox.yaml
```

#### Apache Airflow

```bash
helm repo add apache-airflow https://airflow.apache.org
helm install airflow apache-airflow/airflow \
  --version 1.17.0 \
  -f modules/data/airflow/values/sandbox.yaml
```

#### OKDP Examples (optional)

```bash
helm install okdp-examples oci://quay.io/okdp/charts/okdp-examples \
  --version 1.1.0 \
  -f modules/data/okdp-examples/values/sandbox.yaml
```

---

### Phase 3: Verify the Platform

```bash
# All pods running
kubectl get pods --all-namespaces | grep -v Running | grep -v Completed

# Access services
# Keycloak:       https://keycloak.okdp.sandbox          (admin/admin)
# Airflow:        https://airflow-default.okdp.sandbox    (admin/admin)
# Superset:       https://superset-default.okdp.sandbox   (via Keycloak: adm/adm)
# JupyterHub:     https://jupyter-default.okdp.sandbox    (via Keycloak: adm/adm)
# Spark History:  https://spark-history-default.okdp.sandbox (via Keycloak)
# Trino:          https://trino-default.okdp.sandbox      (via Keycloak)
# SeaweedFS:      https://seaweedfs-seaweedfs-default.okdp.sandbox (admin/admin123)
```

---

## Module Values Reference

Each module folder contains the OKDP-specific Helm values that configure the module
for integration with the rest of the platform. These are NOT generic values — they contain
the specific endpoints, credentials, and settings that make the module work within OKDP.

| Module                                                     | Values                                                                | What's OKDP-specific                                        |
| ---------------------------------------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------- |
| [prerequisites](modules/prerequisites/)                    | [sandbox.yaml](modules/prerequisites/values/sandbox.yaml)             | All infra: cert-manager, ingress, CNPG, Keycloak, SeaweedFS |
| [spark-operator](modules/data/spark-operator/)             | [sandbox.yaml](modules/data/spark-operator/values/sandbox.yaml)       | Webhook, namespaces, RBAC                                   |
| [spark-history-server](modules/data/spark-history-server/) | [sandbox.yaml](modules/data/spark-history-server/values/sandbox.yaml) | S3 event logs, OIDC auth, ingress                           |
| [hive-metastore](modules/data/hive-metastore/)             | [sandbox.yaml](modules/data/hive-metastore/values/sandbox.yaml)       | PostgreSQL + S3 connection                                  |
| [trino](modules/data/trino/)                               | [sandbox.yaml](modules/data/trino/values/sandbox.yaml)                | Hive connector, S3, OIDC, TLS                               |
| [superset](modules/data/superset/)                         | [sandbox.yaml](modules/data/superset/values/sandbox.yaml)             | PostgreSQL, OIDC, Trino datasource                          |
| [jupyterhub](modules/data/jupyterhub/)                     | [sandbox.yaml](modules/data/jupyterhub/values/sandbox.yaml)           | OIDC, S3 browser, Spark profiles                            |
| [airflow](modules/data/airflow/)                           | [sandbox.yaml](modules/data/airflow/values/sandbox.yaml)              | PostgreSQL, DAG sync, ingress                               |
| [okdp-examples](modules/data/okdp-examples/)               | [sandbox.yaml](modules/data/okdp-examples/values/sandbox.yaml)        | S3 endpoint, Trino endpoint                                 |

## Uninstall

```bash
# Data platform (reverse order)
helm uninstall okdp-examples airflow jupyterhub superset trinodb \
  spark-history-server hive-metastore spark-operator 2>/dev/null

# Infrastructure
kubectl delete cluster postgresql-instance -n cnpg-system 2>/dev/null
kubectl delete clusterissuer default-issuer selfsigned-bootstrap 2>/dev/null
helm uninstall okdp-prerequisites -n okdp-system
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
