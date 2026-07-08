# OKDP Prerequisites

Umbrella Helm chart that deploys all OKDP infrastructure in one shot.

## What gets installed

| Component     | Purpose             | OKDP-specific config                                                                      |
| ------------- | ------------------- | ----------------------------------------------------------------------------------------- |
| cert-manager  | TLS certificates    | Self-signed CA ClusterIssuer `default-issuer`                                             |
| ingress-nginx | HTTP/HTTPS routing  | NodePort 30080/30443 (Kind), proxy settings                                               |
| CloudNativePG | PostgreSQL operator | Cluster with 6 databases (hms, superset, keycloak, seaweedfs, airflow, superset-examples) |
| Keycloak      | Identity provider   | OIDC clients, users, groups, realm config                                                 |
| SeaweedFS     | S3 object storage   | Buckets (hive, spark-events), per-service S3 credentials                                  |

## Post-install manifests

These must be applied after the umbrella chart because they create CRDs that require
the operators to be running first:

| Manifest                              | What it creates                                 |
| ------------------------------------- | ----------------------------------------------- |
| `manifests/cert-manager-issuers.yaml` | Self-signed CA + ClusterIssuer `default-issuer` |
| `manifests/cnpg-cluster.yaml`         | PostgreSQL instance with all databases          |
| `manifests/secrets.yaml`              | Credential secrets for all services             |

## Keycloak realm configuration

After installation, Keycloak requires manual realm configuration:

- OIDC clients: `public-oidc-client` (public) and `confidential-oidc-client` (secret: `secret1`)
- Groups scope with `roles_map_to_groups` protocol mapper
- Users: usera (teama), userb (teamb), adm (admins)
- Roles/Groups: teama, teamb, admins

## SeaweedFS S3 credentials

Per-service S3 credentials are defined in `manifests/secrets.yaml`:

| Secret                   | Used by              | Permissions                       |
| ------------------------ | -------------------- | --------------------------------- |
| `creds-hms-s3`           | Hive Metastore       | Read/Write/List on `hive`         |
| `creds-spark-history-s3` | Spark History Server | Read/Write/List on `spark-events` |
| `creds-trino-s3`         | Trino                | Read/Write/List (all)             |
| `creds-jupyter-s3`       | JupyterHub           | Read/Write/List (all)             |
| `creds-airflow-s3`       | Airflow              | Read/Write/List on `airflow-logs` |
| `creds-examples-s3`      | OKDP Examples        | Admin (all)                       |
