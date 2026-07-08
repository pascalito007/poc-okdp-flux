# Spark History Server — OKDP Integration

## What's OKDP-specific in the values

The [sandbox.yaml](values/sandbox.yaml) configures Spark History Server for OKDP:

- **S3 event logs**: reads from SeaweedFS `spark-events` bucket via `creds-spark-history-s3`
- **OIDC auth**: Keycloak-based authentication via okdp-spark-auth-filter
- **TLS**: CA trust bundle from cert-manager trust-manager (`certs-bundle`)
- **Admin groups**: `admins` group has access to all jobs

## Prerequisites (from OKDP infrastructure)

- SeaweedFS with `spark-events` bucket
- Keycloak with OIDC clients configured
- Secrets: `creds-spark-history-s3`, `creds-oidc`, `certs-bundle`

## Service endpoint

```
https://spark-history-default.okdp.sandbox
```

## Official docs

- [OKDP Spark History Server chart](https://github.com/OKDP/spark-history-server)
- [Apache Spark Monitoring](https://spark.apache.org/docs/latest/monitoring.html)
