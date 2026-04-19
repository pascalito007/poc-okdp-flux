# Apache Airflow

## Overview

Apache Airflow is a platform to programmatically author, schedule, and monitor workflows.
It uses directed acyclic graphs (DAGs) to define complex data pipelines.

In OKDP, Airflow orchestrates data workflows including Spark jobs (via SparkKubernetesOperator),
ETL pipelines, and data quality checks across the platform.

## Upstream Project

- **Project**: [Apache Airflow](https://airflow.apache.org/)
- **Helm Chart**: [apache/airflow](https://airflow.apache.org/docs/helm-chart/stable/index.html)
- **Chart Version**: 1.17.0
- **App Version**: 2.9.3

## What This Module Provides in OKDP

- Workflow orchestration with DAG-based pipeline definitions
- Spark job submission via SparkKubernetesOperator
- Git-sync for DAG deployment from Git repositories
- S3-based DAG sync alternative for air-gapped environments
- PostgreSQL-backed metadata storage (via CNPG)
- Ingress with TLS for the Airflow web UI

## Key Configuration Areas

- **Executor**: LocalExecutor (sandbox), CeleryExecutor (production)
- **DAG source**: git (gitSync), s3 (sidecar sync), or local
- **Database**: PostgreSQL connection for metadata
- **Ingress**: TLS-enabled web UI access
- **Spark integration**: ServiceAccount for SparkKubernetesOperator
