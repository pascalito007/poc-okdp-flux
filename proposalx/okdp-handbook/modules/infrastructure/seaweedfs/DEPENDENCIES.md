# SeaweedFS Dependencies

## Required Before Installation

- [cert-manager](../cert-manager/INSTALL.md) — TLS certificates for ingress
- [ingress-nginx](../ingress-nginx/INSTALL.md) — HTTP routing for S3 and filer endpoints

## Secrets Required

| Secret Name              | Namespace | Keys                  | Purpose                       |
| ------------------------ | --------- | --------------------- | ----------------------------- |
| `creds-seaweedfs-secret` | default   | `seaweedfs_s3_config` | S3 identity/permission config |
| `auth-user-secret`       | default   | `auth`                | Basic auth for filer console  |

## Secrets Produced

| Secret Name              | Namespace | Keys                                | Used By              |
| ------------------------ | --------- | ----------------------------------- | -------------------- |
| `creds-hms-s3`           | default   | `accessKey`, `secretKey`            | Hive Metastore       |
| `creds-spark-history-s3` | default   | `accessKey`, `secretKey`            | Spark History Server |
| `creds-trino-s3`         | default   | `S3_ACCESS_KEY`, `S3_SECRET_ACCESS` | Trino                |
| `creds-jupyter-s3`       | default   | `S3_ACCESS_KEY`, `S3_SECRET_KEY`    | JupyterHub           |
| `creds-airflow-s3`       | default   | `accessKey`, `secretKey`            | Airflow              |
| `creds-examples-s3`      | default   | `S3_ACCESS_KEY`, `S3_SECRET_KEY`    | OKDP Examples        |

## Required By (Downstream Dependents)

- [hive-metastore](../../data/hive-metastore/) — S3 warehouse storage
- [spark-history-server](../../data/spark-history-server/) — Spark event logs
- [trino](../../data/trino/) — S3 data access via Hive connector
- [jupyterhub](../../data/jupyterhub/) — S3 file browser
- [airflow](../../data/airflow/) — DAG log storage (optional)
- [okdp-examples](../../data/okdp-examples/) — dataset upload

## Service Endpoints

```
S3 API: https://seaweedfs-seaweedfs-default.<ingress-suffix>
Filer Console: https://seaweedfs-seaweedfs-console-default.<ingress-suffix>
```
