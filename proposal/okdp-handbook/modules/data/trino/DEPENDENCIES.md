# Trino Dependencies

## Required Before Installation

- [cert-manager](../../infrastructure/cert-manager/INSTALL.md) — TLS + trust bundle
- [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) — HTTP routing
- [Hive Metastore](../hive-metastore/INSTALL.md) — table metadata catalog
- [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) — S3 data storage
- [Keycloak](../../infrastructure/keycloak/INSTALL.md) — OIDC authentication

## Secrets Required

| Secret Name      | Namespace | Keys                                | Purpose                 |
| ---------------- | --------- | ----------------------------------- | ----------------------- |
| `creds-trino-s3` | default   | `S3_ACCESS_KEY`, `S3_SECRET_ACCESS` | S3 credentials          |
| `creds-oidc`     | default   | `client_id`, `client_secret`        | OIDC client credentials |
| `certs-bundle`   | default   | `bundle.p12`                        | CA trust bundle         |

## Required By (Downstream Dependents)

- [superset](../superset/) — queries Trino for dashboard data
- [okdp-examples](../okdp-examples/) — uses Trino for SQL examples

## Service Endpoint

```
https://trino-<namespace>.<ingress-suffix>
```
