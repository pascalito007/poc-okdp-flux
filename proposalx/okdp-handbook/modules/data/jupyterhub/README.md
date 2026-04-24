# JupyterHub

## Overview

JupyterHub is a multi-user server for Jupyter notebooks. It spawns individual notebook servers
for each user with configurable resource limits and pre-installed kernels.

In OKDP, JupyterHub provides interactive data science workspaces with PySpark integration,
S3 file browsing, and OIDC authentication via Keycloak.

## Upstream Project

- **Project**: [jupyter.org/hub](https://jupyter.org/hub)
- **Helm Chart**: [jupyterhub/helm-chart](https://hub.jupyter.org/helm-chart/)
- **Chart Version**: 4.3.1
- **App Version**: 5.2.1

## What This Module Provides in OKDP

- Multi-user Jupyter notebook environment
- PySpark kernel with Spark-on-K8s integration (client mode)
- Multiple notebook profiles (Minimal Python, Scientific, Data Science, PySpark)
- S3 file browser via jupyter-fs (connected to SeaweedFS)
- OIDC authentication via Keycloak (GenericOAuthenticator)
- Welcome notebook with OKDP examples link
- Per-user persistent storage

## Key Configuration Areas

- **Authentication**: Keycloak OIDC (GenericOAuthenticator)
- **Notebook profiles**: image selection, resource limits
- **Spark integration**: ServiceAccount, executor images, event log config
- **S3 browser**: SeaweedFS endpoint, credentials
- **Storage**: PVC per user, storage class
- **Ingress**: TLS-enabled hub access
