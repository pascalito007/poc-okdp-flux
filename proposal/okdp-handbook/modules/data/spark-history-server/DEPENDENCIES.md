# Spark History Server Dependencies

## Required Before Installation

- [cert-manager](../../infrastructure/cert-manager/INSTALL.md) — TLS certificates
- [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) — HTTP routing
- [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) — S3 storage for event logs
- [Keycloak](../../infrastructure/keycloak/INSTALL.md) — OIDC authentication

## Secrets Required

| Secret Name              | Namespace | Keys                         | Purpose                              |
| ------------------------ | --------- | ---------------------------- | ------------------------------------ |
| `creds-spark-history-s3` | default   | `accessKey`, `secretKey`     | S3 credentials for event logs        |
| `creds-oidc`             | default   | `client_id`, `client_secret` | OIDC client credentials              |
| `certs-bundle`           | default   | `bundle.p12`                 | CA trust bundle (from trust-manager) |

## Service Endpoint

```
https://spark-history-<namespace>.<ingress-suffix>
https://spark-web-proxy-<namespace>.<ingress-suffix>  (if web proxy enabled)
```
