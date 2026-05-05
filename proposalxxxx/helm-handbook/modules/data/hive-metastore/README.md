# Hive Metastore — OKDP Integration

## What's OKDP-specific in the values

The [sandbox.yaml](values/sandbox.yaml) configures Hive Metastore to integrate with the OKDP stack:

- **PostgreSQL**: connects to the CNPG-managed instance (`postgresql-instance-rw.cnpg-system.svc.cluster.local`)
  using credentials from secret `creds-hms-db`
- **S3 Storage**: connects to SeaweedFS (`seaweedfs-seaweedfs-default.okdp.sandbox`)
  using credentials from secret `creds-hms-s3`, warehouse bucket `hive`
- **Network policies**: disabled for sandbox simplicity

## Prerequisites (from OKDP infrastructure)

- PostgreSQL database `hms` (created by okdp-prerequisites manifests)
- SeaweedFS with `hive` bucket (created by okdp-prerequisites)
- Secrets: `creds-hms-db` (username/password), `creds-hms-s3` (accessKey/secretKey)

## Service endpoint

```
thrift://hive-metastore.default.svc.cluster.local:9083
```

Used by: Trino (Hive connector), Spark (metastore access)

## Official docs

- [OKDP Hive Metastore chart](https://github.com/OKDP/hive-metastore/tree/main/helm/hive-metastore)
- [Apache Hive](https://hive.apache.org/)
