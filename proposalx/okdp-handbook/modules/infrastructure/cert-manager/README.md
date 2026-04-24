# cert-manager

## Overview

cert-manager is a Kubernetes-native certificate management controller. It automates the creation,
renewal, and management of TLS certificates from various issuers (Let's Encrypt, self-signed, CA, Vault, etc.).

In OKDP, cert-manager provides TLS certificates for all platform services (ingress endpoints,
inter-service communication) using a self-signed CA by default.

## Upstream Project

- **Project**: [cert-manager.io](https://cert-manager.io/)
- **CNCF Status**: Graduated
- **Helm Chart**: [jetstack/cert-manager](https://artifacthub.io/packages/helm/cert-manager/cert-manager)
- **Chart Version**: v1.17.1
- **App Version**: v1.17.1

## What This Module Provides in OKDP

- Automatic TLS certificate provisioning for all ingress endpoints
- Self-signed CA ClusterIssuer (`default-issuer`) used by all OKDP services
- trust-manager integration for distributing CA bundles across namespaces
- Foundation for upgrading to Let's Encrypt or external CA in production

## Key Configuration Areas

- **ClusterIssuers**: self-signed CA configuration (name, organization, validity)
- **trust-manager**: CA bundle distribution to all namespaces
- **Certificate defaults**: algorithm (ECDSA), key size, validity period
