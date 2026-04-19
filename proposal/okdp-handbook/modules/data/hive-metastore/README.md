# Hive Metastore

## Overview

Apache Hive Metastore is a centralized metadata repository for data lakes. It stores table schemas,
partition information, and data locations, enabling engines like Spark, Trino, and Presto to access
structured data on object storage (S3, GCS, HDFS).

In OKDP, Hive Metastore is the shared metadata catalog that connects Trino, Spark, and Superset
to data stored in SeaweedFS (S3-compatible storage).

## Upstream Project

- **Project**: [Apache Hive](https://hive.apache.org/)
- **Helm Chart**: [OKDP/hive-metastore](https://github.com/OKDP/hive-metastore)
- **Chart Version**: 1.4.0
- **App Version**: 4.0.1 (custom OKDP image: `quay.io/okdp/hive-metastore:4.0.1`)

## What This Module Provides in OKDP

- Thrift-based metadata service accessible by Trino and Spark
- PostgreSQL-backed metadata storage (via CNPG)
- S3 warehouse integration with SeaweedFS
- Automatic schema initialization via init job

## Key Configuration Areas

- **Database**: PostgreSQL connection (host, port, database name, credentials)
- **S3 Storage**: SeaweedFS endpoint, bucket name, access credentials
- **Service**: Thrift port (9083), replica count
- **Network Policies**: restrict access to allowed namespaces
