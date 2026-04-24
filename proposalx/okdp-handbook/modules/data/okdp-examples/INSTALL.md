# Installing OKDP Examples

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) installed
- [ ] [Trino](../trino/INSTALL.md) installed
- [ ] S3 credentials secret `creds-examples-s3` created

## Install

```bash
helm install okdp-examples oci://quay.io/okdp/charts/okdp-examples \
  --namespace default \
  --version 1.1.0 \
  -f values/sandbox.yaml
```

## Verify

```bash
# Check pods
kubectl get pods -l app.kubernetes.io/name=okdp-examples
# Expected: okdp-examples-* Running

# Check logs for dataset download progress
kubectl logs -l app.kubernetes.io/name=okdp-examples --tail=20
```

## Uninstall

```bash
helm uninstall okdp-examples
```
