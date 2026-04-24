# Installing ingress-nginx

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [cert-manager](../cert-manager/INSTALL.md) installed (for TLS)

## Add Helm Repository

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

## Install

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --version 4.12.1 \
  -f values/sandbox.yaml
```

## Verify

```bash
# Check pods
kubectl get pods -n ingress-nginx
# Expected: ingress-nginx-controller Running

# Check service
kubectl get svc -n ingress-nginx
# Expected: ingress-nginx-controller with NodePort or LoadBalancer

# Check IngressClass
kubectl get ingressclass
# Expected: nginx with controller kubernetes.io/ingress-nginx

# Test connectivity (Kind cluster)
curl -k https://localhost:443 2>/dev/null | head -5
# Expected: 404 (no default backend, but proves ingress is reachable)
```

## Uninstall

```bash
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```
