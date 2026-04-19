# Installing OKDP Infrastructure Prerequisites

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed

## Step 1: Build chart dependencies

```bash
cd modules/infrastructure/okdp-prerequisites
helm dependency build
```

## Step 2: Install the umbrella chart

```bash
helm install okdp-prerequisites . \
  --namespace okdp-system \
  --create-namespace \
  -f values/sandbox.yaml \
  --wait --timeout 15m
```

This installs cert-manager, ingress-nginx, CloudNativePG, Keycloak, and SeaweedFS.

## Step 3: Post-install — Create ClusterIssuers and CA

Wait for cert-manager to be ready, then create the self-signed CA:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager \
  -n okdp-system --timeout=300s

kubectl apply -f manifests/cert-manager-issuers.yaml
```

## Step 4: Post-install — Create PostgreSQL cluster

Wait for the CNPG operator to be ready, then create the PostgreSQL instance:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cloudnative-pg \
  -n okdp-system --timeout=300s

kubectl apply -f manifests/cnpg-cluster.yaml
```

Wait for PostgreSQL to be ready:

```bash
sleep 30
kubectl wait --for=condition=ready pod -l cnpg.io/cluster=postgresql-instance \
  -n cnpg-system --timeout=300s
```

## Step 5: Post-install — Create credential secrets

```bash
kubectl apply -f manifests/secrets.yaml
```

## Verify

```bash
# cert-manager
kubectl get clusterissuers
# Expected: default-issuer READY=True

# ingress-nginx
kubectl get ingressclass
# Expected: nginx

# CloudNativePG + PostgreSQL
kubectl get clusters -n cnpg-system
# Expected: postgresql-instance healthy

# Keycloak
kubectl get pods -n okdp-system -l app.kubernetes.io/name=keycloakx
# Expected: Running

# SeaweedFS
kubectl get pods -l app.kubernetes.io/name=seaweedfs
# Expected: master, volume, filer Running

# Secrets
kubectl get secrets | grep creds-
# Expected: all credential secrets present
```

## Step 6: Post-install — Configure Keycloak realm

See [keycloak/INSTALL.md](../keycloak/INSTALL.md) for realm configuration
(users, groups, roles, OIDC clients).

## Uninstall

```bash
kubectl delete cluster postgresql-instance -n cnpg-system 2>/dev/null || true
kubectl delete clusterissuer default-issuer selfsigned-bootstrap 2>/dev/null || true
kubectl delete certificate okdp-ca -n okdp-system 2>/dev/null || true
helm uninstall okdp-prerequisites -n okdp-system
```
