# JupyterHub Dependencies

## Required Before Installation

- [cert-manager](../../infrastructure/cert-manager/INSTALL.md) — TLS certificates
- [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) — HTTP routing
- [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) — S3 file browser
- [Keycloak](../../infrastructure/keycloak/INSTALL.md) — OIDC authentication
- [Spark Operator](../spark-operator/INSTALL.md) — for PySpark notebooks

## Secrets Required

| Secret Name         | Namespace | Keys                             | Purpose                     |
| ------------------- | --------- | -------------------------------- | --------------------------- |
| `creds-oidc`        | default   | `client_id`, `client_secret`     | OIDC client credentials     |
| `creds-jupyter-s3`  | default   | `S3_ACCESS_KEY`, `S3_SECRET_KEY` | S3 file browser credentials |
| `creds-examples-s3` | default   | `S3_ACCESS_KEY`, `S3_SECRET_KEY` | Examples S3 access          |

## Service Endpoint

```
https://jupyter-<namespace>.<ingress-suffix>
```
