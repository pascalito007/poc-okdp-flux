# OKDP Infrastructure Prerequisites (Umbrella Chart)

## Overview

This is an umbrella Helm chart that deploys ALL OKDP infrastructure prerequisites in a single command.

## What Gets Installed

| Component     | Purpose                                      |
| ------------- | -------------------------------------------- |
| cert-manager  | TLS certificate management                   |
| ingress-nginx | HTTP/HTTPS ingress controller                |
| CloudNativePG | PostgreSQL operator                          |
| Keycloak      | Identity & access management (OIDC provider) |
| SeaweedFS     | S3-compatible object storage                 |

## What Needs Manual Post-Install

| Step | Resource                            | Manifest                                          |
| ---- | ----------------------------------- | ------------------------------------------------- |
| 1    | ClusterIssuers + CA certificate     | `manifests/cert-manager-issuers.yaml`             |
| 2    | PostgreSQL instance + databases     | `manifests/cnpg-cluster.yaml`                     |
| 3    | Credential secrets for all services | `manifests/secrets.yaml`                          |
| 4    | Keycloak realm configuration        | See [keycloak/INSTALL.md](../keycloak/INSTALL.md) |

## Individual Module Docs

Each component also has its own standalone documentation if you prefer to install modules individually:

- [cert-manager](../cert-manager/)
- [ingress-nginx](../ingress-nginx/)
- [cloudnative-pg](../cloudnative-pg/)
- [keycloak](../keycloak/)
- [seaweedfs](../seaweedfs/)
