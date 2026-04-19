# cert-manager Dependencies

## Required Before Installation

None — cert-manager is the first module to install.

## Required By (Downstream Dependents)

All OKDP modules that expose an ingress endpoint depend on cert-manager for TLS:

- [ingress-nginx](../ingress-nginx/) — uses cert-manager annotations for automatic TLS
- [keycloak](../keycloak/) — TLS for identity provider endpoints
- [seaweedfs](../seaweedfs/) — TLS for S3 and filer endpoints
- [spark-history-server](../../data/spark-history-server/) — TLS for Spark UI
- [superset](../../data/superset/) — TLS for BI dashboard
- [jupyterhub](../../data/jupyterhub/) — TLS for notebook environment
- [airflow](../../data/airflow/) — TLS for workflow UI

## ClusterIssuer Reference

All downstream modules reference the ClusterIssuer by name in their ingress annotations:

```yaml
annotations:
  cert-manager.io/cluster-issuer: default-issuer
```

If you change the ClusterIssuer name, update all downstream module values accordingly.
