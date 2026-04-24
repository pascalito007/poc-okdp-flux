# Apache Superset — OKDP Integration

## What's OKDP-specific in the values

The [sandbox.yaml](values/sandbox.yaml) configures Superset for OKDP:

- **PostgreSQL**: connects to CNPG instance for metadata via `creds-superset-db`
- **OIDC auth**: Keycloak OAuth2 login via `creds-oidc`, role mapping (admins → Admin)
- **Trino datasource**: pre-configured connection to `trino-default.okdp.sandbox`
- **Examples**: loads example dashboards from `superset-examples` database
- **Redis**: built-in Redis cache (no external dependency)

## Prerequisites (from OKDP infrastructure)

- PostgreSQL databases `superset` and `superset-examples`
- Keycloak with OIDC clients
- Trino running (for datasource)
- Secrets: `creds-superset-db`, `creds-superset-secret-key`, `creds-superset-examples-db`, `creds-redis`, `creds-oidc`

## Service endpoint

```
https://superset-default.okdp.sandbox
```

## Official docs

- [OKDP Superset chart](https://github.com/OKDP/okdp-superset)
- [Apache Superset](https://superset.apache.org/)
