# Trino

## Overview

Trino is a distributed SQL query engine designed for fast, interactive analytics on large datasets.
It can query data across multiple sources (S3, PostgreSQL, Hive Metastore) in a single query.

In OKDP, Trino provides the SQL query layer over data stored in SeaweedFS via the Hive Metastore catalog.
It's the primary query engine used by Superset for dashboards and by JupyterHub for interactive analysis.

## Upstream Project

- **Project**: [trino.io](https://trino.io/)
- **Helm Chart**: [trinodb/charts](https://trinodb.github.io/charts)
- **Chart Version**: v1.39.1
- **App Version**: 475

## What This Module Provides in OKDP

- Distributed SQL query engine with Hive connector for S3 data
- OIDC authentication via Keycloak for web UI and API
- HTTPS with TLS termination and SSL passthrough
- Pre-configured catalogs: `lakehouse` (Hive/S3), `tpch`, `tpcds` (benchmarks)
- CA trust bundle integration for self-signed certificates

## Key Configuration Areas

- **Catalogs**: Hive connector (metastore URI, S3 endpoint, credentials)
- **OIDC auth**: Keycloak issuer, client credentials, OAuth2 scopes
- **TLS**: HTTPS enabled with init container for PEM generation
- **Workers**: replica count, CPU/memory resources
- **Ingress**: SSL passthrough for end-to-end TLS
