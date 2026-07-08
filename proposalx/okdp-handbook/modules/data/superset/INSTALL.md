# Installing Apache Superset

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [cert-manager](../../infrastructure/cert-manager/INSTALL.md) installed
- [ ] [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) installed
- [ ] [CloudNativePG](../../infrastructure/cloudnative-pg/INSTALL.md) installed with `superset` and `superset-examples` databases
- [ ] [Keycloak](../../infrastructure/keycloak/INSTALL.md) installed with OIDC clients
- [ ] [Trino](../trino/INSTALL.md) installed (for datasource connectivity)
- [ ] Secrets created: `creds-superset-db`, `creds-superset-secret-key`, `creds-superset-examples-db`, `creds-redis`, `creds-oidc`

## Install

The OKDP Superset chart is published as an OCI artifact:

```bash
helm install superset oci://quay.io/okdp/charts/superset \
  --namespace default \
  --version 0.15.0 \
  -f values/sandbox.yaml
```

## Verify

```bash
# Check pods
kubectl get pods -l app.kubernetes.io/name=superset
# Expected: superset-* pods Running

# Check ingress
kubectl get ingress -l app.kubernetes.io/name=superset
# Expected: ingress with host superset-default.okdp.sandbox

# Access the UI (redirects to Keycloak login)
# URL: https://superset-default.okdp.sandbox
# Login via Keycloak: adm / adm
```

## Uninstall

```bash
helm uninstall superset
```
