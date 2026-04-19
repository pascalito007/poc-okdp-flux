# CloudNativePG

## Overview

CloudNativePG (CNPG) is a Kubernetes operator that manages the full lifecycle of PostgreSQL clusters.
It handles provisioning, high availability, backups, and failover natively within Kubernetes.

In OKDP, CNPG provides the shared PostgreSQL instance used by Hive Metastore, Superset, Keycloak,
SeaweedFS, and Airflow for their metadata storage.

## Upstream Project

- **Project**: [cloudnative-pg.io](https://cloudnative-pg.io/)
- **CNCF Status**: Sandbox
- **Helm Chart**: [cloudnative-pg/charts](https://cloudnative-pg.github.io/charts)
- **Chart Version**: 0.23.0
- **App Version**: 1.25.0

## What This Module Provides in OKDP

- PostgreSQL operator for automated cluster management
- Single PostgreSQL instance shared by all OKDP services
- Automatic database and user provisioning via CNPG Cluster CR
- Built-in backup and recovery capabilities

## Key Configuration Areas

- **Cluster size**: single instance for sandbox, 3 replicas for production
- **Storage**: PVC size and storage class
- **Databases**: hms, superset, keycloak, seaweedfs, airflow, superset-examples
- **Credentials**: managed via Kubernetes Secrets
