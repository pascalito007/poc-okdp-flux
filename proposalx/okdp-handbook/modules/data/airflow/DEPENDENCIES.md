# Airflow Dependencies

## Required Before Installation

- [cert-manager](../../infrastructure/cert-manager/INSTALL.md) — TLS certificates
- [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) — HTTP routing
- [CloudNativePG](../../infrastructure/cloudnative-pg/INSTALL.md) — PostgreSQL database `airflow`
- [Spark Operator](../spark-operator/INSTALL.md) — for SparkKubernetesOperator DAGs

## Secrets Required

| Secret Name        | Namespace        | Keys                   | Purpose                |
| ------------------ | ---------------- | ---------------------- | ---------------------- |
| `creds-airflow-db` | target namespace | `username`, `password` | PostgreSQL credentials |

## Optional Dependencies

- [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) — for S3-based DAG sync and log storage
- S3 credentials secret `creds-airflow-s3` with keys `accessKey`, `secretKey`

## Service Endpoint

```
https://airflow-<namespace>.<ingress-suffix>
```
