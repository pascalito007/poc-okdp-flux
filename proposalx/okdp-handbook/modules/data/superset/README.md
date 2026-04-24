# Apache Superset

## Overview

Apache Superset is a modern data visualization and exploration platform. It provides interactive
dashboards, SQL Lab for ad-hoc queries, and a rich set of visualization types.

In OKDP, Superset connects to Trino for querying data stored in the Hive/S3 data lake,
providing business intelligence capabilities to platform users.

## Upstream Project

- **Project**: [superset.apache.org](https://superset.apache.org/)
- **Helm Chart**: [OKDP/okdp-superset](https://github.com/OKDP/okdp-superset) (wrapper)
- **Chart Version**: 0.15.0
- **App Version**: 4.1.2

## What This Module Provides in OKDP

- Interactive dashboards and data visualization
- SQL Lab for ad-hoc Trino queries
- OAuth2/OIDC authentication via Keycloak
- Pre-configured Trino datasource
- Example dashboards (optional, loaded from superset-examples DB)
- PostgreSQL-backed metadata (via CNPG)
- Built-in Redis cache

## Key Configuration Areas

- **Database**: PostgreSQL connection for Superset metadata
- **OIDC auth**: Keycloak OAuth2 configuration
- **Datasources**: Trino connection for SQL queries
- **Redis**: cache backend (built-in or external)
- **Examples**: optional example dashboards loading
- **Ingress**: TLS-enabled web UI
