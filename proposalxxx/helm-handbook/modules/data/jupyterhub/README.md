# JupyterHub — OKDP Integration

## What's OKDP-specific in the values

The [sandbox.yaml](values/sandbox.yaml) configures JupyterHub for OKDP:

- **OIDC auth**: Keycloak GenericOAuthenticator via `creds-oidc`
- **S3 browser**: jupyter-fs connected to SeaweedFS via `creds-jupyter-s3`
- **PySpark**: Spark-on-K8s client mode with ServiceAccount `spark`
- **Notebook profiles**: Minimal Python, Scientific, Data Science, PySpark (3.4.4 and 3.5.6)
- **Welcome notebook**: links to okdp-examples

## Prerequisites (from OKDP infrastructure)

- Keycloak with OIDC clients
- SeaweedFS accessible
- Spark Operator + Spark RBAC
- Secrets: `creds-oidc`, `creds-jupyter-s3`, `creds-examples-s3`

## Service endpoint

```
https://jupyter-default.okdp.sandbox
```

## Official docs

- [JupyterHub Helm chart](https://z2jh.jupyter.org/)
- [OKDP JupyterLab images](https://github.com/OKDP/jupyterlab-docker)
