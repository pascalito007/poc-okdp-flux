# Spark History Server

## Overview

Spark History Server provides a web UI for viewing completed and running Apache Spark applications.
It reads event logs from S3 storage and displays execution metrics, job timelines, and performance data.

In OKDP, Spark History Server is paired with the Spark Web Proxy to provide real-time monitoring
of running Spark applications alongside historical job data.

## Upstream Project

- **Project**: [Apache Spark](https://spark.apache.org/)
- **Helm Chart**: [OKDP/spark-history-server](https://github.com/OKDP/spark-history-server)
- **Chart Version**: 1.0.0
- **App Version**: 3.5.6 (custom OKDP image: `quay.io/okdp/spark`)

## What This Module Provides in OKDP

- Web UI for completed Spark job history
- S3-based event log reading (from SeaweedFS `spark-events` bucket)
- OIDC authentication via Keycloak (using okdp-spark-auth-filter)
- Group-based access control (admins see all jobs)
- Spark Web Proxy for real-time monitoring of running applications
- Ingress with TLS

## Key Configuration Areas

- **Event logs**: S3 endpoint, bucket, credentials for reading Spark event logs
- **OIDC auth**: Keycloak issuer URI, client credentials, redirect URI
- **Web Proxy**: optional companion for real-time Spark UI monitoring
- **Ingress**: TLS-enabled web UI access
