# Keycloak Dependencies

## Required Before Installation

- [cert-manager](../cert-manager/INSTALL.md) — TLS certificates for ingress
- [ingress-nginx](../ingress-nginx/INSTALL.md) — HTTP routing
- [CloudNativePG](../cloudnative-pg/INSTALL.md) — PostgreSQL database `keycloak`

## Secrets Required

| Secret Name         | Namespace | Keys                   | Purpose                |
| ------------------- | --------- | ---------------------- | ---------------------- |
| `creds-keycloak-db` | keycloak  | `username`, `password` | PostgreSQL credentials |

## Secrets Produced

| Secret Name  | Namespace | Keys                         | Used By                   |
| ------------ | --------- | ---------------------------- | ------------------------- |
| `creds-oidc` | default   | `client_id`, `client_secret` | All OIDC-enabled services |

## Required By (Downstream Dependents)

All OKDP services that use OIDC authentication:

- [trino](../../data/trino/) — OIDC for web UI and API
- [superset](../../data/superset/) — OAuth2 login
- [jupyterhub](../../data/jupyterhub/) — GenericOAuthenticator
- [spark-history-server](../../data/spark-history-server/) — OIDC auth filter

## Service Endpoints

```
Admin UI: https://keycloak.<ingress-suffix>
OIDC Discovery: https://keycloak.<ingress-suffix>/realms/master/.well-known/openid-configuration
Auth URL: https://keycloak.<ingress-suffix>/realms/master/protocol/openid-connect
```
