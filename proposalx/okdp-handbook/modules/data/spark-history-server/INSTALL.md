# Installing Spark History Server

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [cert-manager](../../infrastructure/cert-manager/INSTALL.md) installed
- [ ] [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) installed
- [ ] [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) installed with `spark-events` bucket
- [ ] [Keycloak](../../infrastructure/keycloak/INSTALL.md) installed with OIDC clients configured
- [ ] S3 credentials secret `creds-spark-history-s3` created
- [ ] OIDC credentials secret `creds-oidc` created
- [ ] trust-manager bundle `certs-bundle` available (for TLS verification)

## Install

```bash
helm install spark-history-server oci://quay.io/okdp/charts/spark-history-server \
  --namespace default \
  --version 1.0.0 \
  -f values/sandbox.yaml
```

## Verify

```bash
# Check pods
kubectl get pods -l app.kubernetes.io/name=spark-history-server
# Expected: spark-history-server-* Running

# Check ingress
kubectl get ingress -l app.kubernetes.io/name=spark-history-server
# Expected: ingress with host spark-history-default.okdp.sandbox

# Access the UI (requires Keycloak login)
# URL: https://spark-history-default.okdp.sandbox
```

## Uninstall

```bash
helm uninstall spark-history-server
```
