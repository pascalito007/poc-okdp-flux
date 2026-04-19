# SeaweedFS

## Overview

SeaweedFS is a distributed file system with an S3-compatible API. It provides high-performance
object storage with support for buckets, access control, and filer-based file browsing.

In OKDP, SeaweedFS is the shared S3-compatible object storage used by Hive Metastore (data warehouse),
Spark (event logs), JupyterHub (notebooks), Airflow (DAG logs), and Trino (query data).

## Upstream Project

- **Project**: [seaweedfs.com](https://seaweedfs.com/)
- **Helm Chart**: [seaweedfs/helm](https://seaweedfs.github.io/seaweedfs/helm)
- **Chart Version**: 4.0.407
- **App Version**: 4.0.407

## What This Module Provides in OKDP

- S3-compatible API for all OKDP services
- Pre-created buckets: `hive` (data warehouse), `spark-events` (Spark event logs)
- Per-service S3 credentials with fine-grained access control
- Filer console with basic auth for web-based file browsing
- Ingress with TLS for both S3 API and filer console

## Key Configuration Areas

- **Master**: metadata server (replicas, storage)
- **Volume**: data storage (replicas, PVC size)
- **Filer**: file browsing and S3 gateway (replicas, storage, ingress)
- **S3 Auth**: per-service credentials via S3 config secret
- **Buckets**: auto-created buckets for OKDP services
