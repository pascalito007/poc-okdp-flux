# Installing cert-manager

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] `kubectl` configured to target the cluster

## Add Helm Repository

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

## Install cert-manager

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.1 \
  -f values/sandbox.yaml
```

## Create the Self-Signed CA ClusterIssuer

After cert-manager is running, create the self-signed CA used by all OKDP services:

```bash
# Step 1: Create a self-signed issuer to bootstrap the CA
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-bootstrap
spec:
  selfSigned: {}
EOF

# Step 2: Create the CA certificate
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: okdp-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: "OKDP Sandbox Self-Signed CA"
  subject:
    organizations:
      - OKDP
    countries:
      - FR
  duration: 8760h  # 1 year
  privateKey:
    algorithm: ECDSA
    size: 256
  secretName: default-issuer
  issuerRef:
    name: selfsigned-bootstrap
    kind: ClusterIssuer
    group: cert-manager.io
EOF

# Step 3: Create the CA ClusterIssuer that all services will reference
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: default-issuer
spec:
  ca:
    secretName: default-issuer
EOF
```

## Install trust-manager (optional, recommended)

trust-manager distributes the CA bundle to all namespaces so services can validate each other's certificates:

```bash
helm install trust-manager jetstack/trust-manager \
  --namespace cert-manager \
  --version v0.14.0 \
  --set app.trust.namespace=cert-manager
```

Create the trust bundle:

```bash
kubectl apply -f - <<EOF
apiVersion: trust.cert-manager.io/v1alpha1
kind: Bundle
metadata:
  name: certs-bundle
spec:
  sources:
    - useDefaultCAs: true
    - secret:
        name: default-issuer
        key: ca.crt
  target:
    configMap:
      key: root-certs.pem
    secret:
      key: root-certs.pem
    namespaceSelector:
      matchLabels: {}
EOF
```

## Verify

```bash
# Check cert-manager pods
kubectl get pods -n cert-manager
# Expected: cert-manager, cert-manager-cainjector, cert-manager-webhook all Running

# Check ClusterIssuers
kubectl get clusterissuers
# Expected: default-issuer with READY=True

# Check CA certificate
kubectl get certificates -n cert-manager
# Expected: okdp-ca with READY=True

# Export CA certificate (for browser trust)
kubectl get secret default-issuer -n cert-manager \
  -o jsonpath='{.data.ca\.crt}' | base64 -d > okdp-ca.crt
```

## Uninstall

```bash
kubectl delete bundle certs-bundle 2>/dev/null || true
kubectl delete clusterissuer default-issuer selfsigned-bootstrap 2>/dev/null || true
kubectl delete certificate okdp-ca -n cert-manager 2>/dev/null || true
helm uninstall trust-manager -n cert-manager 2>/dev/null || true
helm uninstall cert-manager -n cert-manager
kubectl delete namespace cert-manager
```
