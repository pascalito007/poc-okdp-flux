# ingress-nginx

## Overview

ingress-nginx is the Kubernetes NGINX Ingress Controller. It provides HTTP and HTTPS routing
to services within the cluster based on Ingress resources.

In OKDP, ingress-nginx is the single entry point for all platform services, routing traffic
to Keycloak, Superset, JupyterHub, Airflow, Spark History Server, SeaweedFS, and other components.

## Upstream Project

- **Project**: [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx)
- **CNCF Status**: Part of the Kubernetes project
- **Helm Chart**: [ingress-nginx/ingress-nginx](https://kubernetes.github.io/ingress-nginx)
- **Chart Version**: 4.12.1
- **App Version**: 1.12.1

## What This Module Provides in OKDP

- Single ingress controller for all OKDP services
- TLS termination with cert-manager integration
- NodePort exposure for Kind/local clusters (ports 30080/30443)
- Proxy settings for large file uploads (SeaweedFS, Airflow DAGs)

## Key Configuration Areas

- **Service type**: NodePort for local/Kind, LoadBalancer for cloud
- **Port mappings**: HTTP (30080→80) and HTTPS (30443→443) for Kind
- **Proxy settings**: body size limits, timeouts for data-heavy services
- **IngressClass**: `nginx` (referenced by all OKDP services)
