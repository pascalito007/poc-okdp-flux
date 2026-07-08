# Hive Metastore Dependencies

## Required Before Installation

- [CloudNativePG](../../infrastructure/cloudnative-pg/INSTALL.md) — PostgreSQL database `hms`
- [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) — S3 storage with `hive` bucket

## Secrets Required

| Secret Name    | Namespace        | Keys                     | Purpose                  |
| -------------- | ---------------- | ------------------------ | ------------------------ |
| `creds-hms-db` | target namespace | `username`, `password`   | PostgreSQL credentials   |
| `creds-hms-s3` | target namespace | `accessKey`, `secretKey` | SeaweedFS S3 credentials |

## Required By (Downstream Dependents)

- [trino](../trino/) — connects to Hive Metastore for table metadata
- [spark-history-server](../spark-history-server/) — reads table metadata for Spark SQL

## Service Endpoint

```
thrift://hive-metastore.<namespace>.svc.cluster.local:9083
```
