# Installing JupyterHub

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [cert-manager](../../infrastructure/cert-manager/INSTALL.md) installed
- [ ] [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) installed
- [ ] [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) installed
- [ ] [Keycloak](../../infrastructure/keycloak/INSTALL.md) installed with OIDC clients
- [ ] [Spark Operator](../spark-operator/INSTALL.md) installed with Spark RBAC
- [ ] Secrets created: `creds-oidc`, `creds-jupyter-s3`, `creds-examples-s3`

## Add Helm Repository

```bash
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update
```

## Install

```bash
helm install jupyterhub jupyterhub/jupyterhub \
  --namespace default \
  --version 4.3.1 \
  -f values/sandbox.yaml
```

## Verify

```bash
# Check pods
kubectl get pods -l app.kubernetes.io/name=jupyterhub
# Expected: hub-* and proxy-* pods Running

# Check ingress
kubectl get ingress -l app.kubernetes.io/name=jupyterhub
# Expected: ingress with host jupyter-default.okdp.sandbox

# Access the UI (redirects to Keycloak login)
# URL: https://jupyter-default.okdp.sandbox
# Login via Keycloak: adm / adm
# Select a notebook profile and start a server
```

## Uninstall

```bash
helm uninstall jupyterhub
```
