# Keycloak

## Overview

Keycloak is an open-source identity and access management solution. It provides single sign-on (SSO),
identity brokering, user federation, and fine-grained authorization services.

In OKDP, Keycloak is the central identity provider. All platform services (Superset, JupyterHub,
Trino, Spark History Server) authenticate users via OIDC against Keycloak.

## Upstream Project

- **Project**: [keycloak.org](https://www.keycloak.org/)
- **CNCF Status**: Incubating
- **Helm Chart**: [codecentric/keycloakx](https://github.com/codecentric/helm-charts)
- **Chart Version**: 2.5.1
- **App Version**: 24.4.11

## What This Module Provides in OKDP

- Central OIDC identity provider for all OKDP services
- Pre-configured realm with test users (usera, userb, adm)
- Groups and roles (teama, teamb, admins) for RBAC
- Two OIDC clients: `public-oidc-client` (for UIs) and `confidential-oidc-client` (for services)
- Groups scope with protocol mapper for role-to-groups claim mapping
- PostgreSQL-backed user store (via CNPG)

## Key Configuration Areas

- **Database**: PostgreSQL connection for Keycloak metadata
- **Realm**: master realm with users, groups, roles, clients
- **OIDC clients**: redirect URIs, web origins, client scopes
- **Ingress**: TLS-enabled admin and auth endpoints
