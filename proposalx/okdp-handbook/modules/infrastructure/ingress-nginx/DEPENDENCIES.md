# ingress-nginx Dependencies

## Required Before Installation

- [cert-manager](../cert-manager/INSTALL.md) — for automatic TLS certificate provisioning

## Required By (Downstream Dependents)

All OKDP modules that expose a web UI or API:

- [keycloak](../keycloak/) — identity provider UI
- [seaweedfs](../seaweedfs/) — S3 and filer console
- [spark-history-server](../../data/spark-history-server/) — Spark monitoring UI
- [superset](../../data/superset/) — BI dashboard
- [jupyterhub](../../data/jupyterhub/) — notebook environment
- [airflow](../../data/airflow/) — workflow UI

## IngressClass Reference

All downstream modules reference the IngressClass name in their ingress configuration:

```yaml
ingressClassName: nginx
```
