# Installing Trino

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [cert-manager](../../infrastructure/cert-manager/INSTALL.md) installed with trust-manager bundle
- [ ] [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) installed
- [ ] [Hive Metastore](../hive-metastore/INSTALL.md) installed
- [ ] [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) installed
- [ ] [Keycloak](../../infrastructure/keycloak/INSTALL.md) installed with OIDC clients
- [ ] S3 credentials secret `creds-trino-s3` created (keys: `S3_ACCESS_KEY`, `S3_SECRET_ACCESS`)
- [ ] OIDC credentials secret `creds-oidc` created
- [ ] trust-manager bundle `certs-bundle` available

## Add Helm Repository

```bash
helm repo add trinodb https://trinodb.github.io/charts/
helm repo update
```

## Install

```bash
helm install trinodb trinodb/trino \
  --namespace default \
  --version v1.39.1 \
  -f values/sandbox.yaml
```

## Verify

```bash
# Check pods
kubectl get pods -l app.kubernetes.io/name=trino
# Expected: trino-coordinator-* and trino-worker-* Running

# Check ingress
kubectl get ingress -l app.kubernetes.io/name=trino
# Expected: ingress with host trino-default.okdp.sandbox

# Test Trino CLI (from within cluster)
kubectl run trino-test --rm -it --image=trinodb/trino:475 --restart=Never -- \
  trino --server https://trino-default.okdp.sandbox:443 \
  --insecure --execute "SELECT 1"
# Expected: 1

# Access the UI (requires Keycloak login)
# URL: https://trino-default.okdp.sandbox
```

## Uninstall

```bash
helm uninstall trinodb
```
