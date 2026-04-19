# Superset Dependencies

## Required Before Installation

- [cert-manager](../../infrastructure/cert-manager/INSTALL.md) — TLS certificates
- [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) — HTTP routing
- [CloudNativePG](../../infrastructure/cloudnative-pg/INSTALL.md) — PostgreSQL databases `superset` and `superset-examples`
- [Keycloak](../../infrastructure/keycloak/INSTALL.md) — OIDC authentication
- [Trino](../trino/INSTALL.md) — SQL query engine (for datasource)

## Secrets Required

| Secret Name                  | Namespace | Keys                         | Purpose                 |
| ---------------------------- | --------- | ---------------------------- | ----------------------- |
| `creds-superset-db`          | default   | `username`, `password`       | PostgreSQL credentials  |
| `creds-superset-secret-key`  | default   | `superset_secret_key`        | Flask secret key        |
| `creds-superset-examples-db` | default   | `username`, `password`       | Examples DB credentials |
| `creds-redis`                | default   | `username`, `password`       | Redis credentials       |
| `creds-oidc`                 | default   | `client_id`, `client_secret` | OIDC client credentials |

## Service Endpoint

```
https://superset-<namespace>.<ingress-suffix>
```
