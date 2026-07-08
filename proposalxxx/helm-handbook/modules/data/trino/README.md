# Trino — OKDP Integration

## What's OKDP-specific in the values

The [sandbox.yaml](values/sandbox.yaml) configures Trino for OKDP:

- **Hive connector**: connects to Hive Metastore at `thrift://hive-metastore.default.svc.cluster.local:9083`
- **S3 access**: reads/writes data via SeaweedFS using `creds-trino-s3`
- **OIDC auth**: Keycloak OAuth2 for web UI and API via `creds-oidc`
- **TLS**: HTTPS with init container for PEM generation, CA trust bundle from `certs-bundle`
- **Catalogs**: `lakehouse` (Hive/S3), `tpch`, `tpcds` (benchmarks)

## Prerequisites (from OKDP infrastructure)

- Hive Metastore running
- SeaweedFS accessible
- Keycloak with OIDC clients
- Secrets: `creds-trino-s3`, `creds-oidc`, `certs-bundle`

## Service endpoint

```
https://trino-default.okdp.sandbox
```

Used by: Superset (datasource), OKDP Examples (SQL queries)

## Official docs

- [Trino](https://trino.io/docs/current/)
- [Trino Helm chart](https://trinodb.github.io/charts/)
