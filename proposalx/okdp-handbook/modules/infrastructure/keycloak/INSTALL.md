# Installing Keycloak

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [cert-manager](../cert-manager/INSTALL.md) installed with `default-issuer` ClusterIssuer
- [ ] [ingress-nginx](../ingress-nginx/INSTALL.md) installed
- [ ] [CloudNativePG](../cloudnative-pg/INSTALL.md) installed with `keycloak` database created
- [ ] Database credentials secret `creds-keycloak-db` created in `keycloak` namespace

## Add Helm Repository

```bash
helm repo add codecentric https://codecentric.github.io/helm-charts
helm repo update
```

## Create Namespace and Secrets

```bash
kubectl create namespace keycloak

kubectl create secret generic creds-keycloak-db \
  --namespace keycloak \
  --from-literal=username=keycloak \
  --from-literal=password=keycloak123
```

## Install

```bash
helm install keycloak codecentric/keycloakx \
  --namespace keycloak \
  --version 2.5.1 \
  -f values/sandbox.yaml
```

## Post-Installation: Configure Realm

After Keycloak is running, configure the realm via the admin UI or Keycloak REST API.

The sandbox requires the following configuration:

### 1. Create OIDC Clients

```bash
# Access Keycloak admin: https://keycloak.okdp.sandbox
# Login: admin / admin

# Create public-oidc-client
# - Client ID: public-oidc-client
# - Client authentication: OFF (public client)
# - Valid redirect URIs: https://okdp-server.okdp.sandbox/*, https://okdp-ui.okdp.sandbox/*
# - Web origins: https://okdp-server.okdp.sandbox, https://okdp-ui.okdp.sandbox

# Create confidential-oidc-client
# - Client ID: confidential-oidc-client
# - Client authentication: ON
# - Client secret: secret1
# - Valid redirect URIs: https://*
# - Web origins: https://*
# - Default client scopes: web-origins, acr, roles, profile, groups, basic, email
```

### 2. Create Groups Scope

```bash
# In Keycloak admin → Client scopes → Create
# - Name: groups
# - Protocol: openid-connect
# - Include in token scope: OFF
# - Display on consent screen: ON
#
# Add protocol mapper:
# - Name: roles_map_to_groups
# - Mapper type: User Realm Role
# - Token claim name: groups
# - Add to ID token: ON
# - Add to access token: ON
# - Add to userinfo: ON
# - Multivalued: ON
```

### 3. Create Test Users

| Username | Email         | Password | Roles  |
| -------- | ------------- | -------- | ------ |
| usera    | usera@okdp.io | usera    | teama  |
| userb    | userb@okdp.io | userb    | teamb  |
| adm      | adm@okdp.io   | adm      | admins |

### 4. Create Roles and Groups

- Roles: `teama`, `teamb`, `admins`
- Groups: `teama`, `teamb`, `admins`
- Assign users to their respective roles

### 5. Create OIDC Credentials Secret

This secret is shared by all OKDP services that need OIDC authentication:

```bash
kubectl create secret generic creds-oidc \
  --namespace default \
  --from-literal=client_id=confidential-oidc-client \
  --from-literal=client_secret=secret1
```

## Verify

```bash
# Check pods
kubectl get pods -n keycloak
# Expected: keycloak-0 Running

# Check ingress
kubectl get ingress -n keycloak
# Expected: keycloak ingress with host keycloak.okdp.sandbox

# Test admin access
curl -sk https://keycloak.okdp.sandbox/realms/master/.well-known/openid-configuration | head -5
# Expected: JSON with issuer, authorization_endpoint, token_endpoint

# Test OIDC discovery
curl -sk https://keycloak.okdp.sandbox/realms/master/.well-known/openid-configuration | python3 -m json.tool | grep issuer
# Expected: "issuer": "https://keycloak.okdp.sandbox/realms/master"
```

## Uninstall

```bash
helm uninstall keycloak -n keycloak
kubectl delete namespace keycloak
```
