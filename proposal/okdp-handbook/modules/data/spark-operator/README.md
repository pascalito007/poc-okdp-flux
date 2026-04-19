# Spark Operator

## Overview

The Kubeflow Spark Operator is a Kubernetes operator for managing Apache Spark applications.
It uses Custom Resource Definitions (SparkApplication, ScheduledSparkApplication) to declaratively
define, submit, and monitor Spark jobs on Kubernetes.

In OKDP, the Spark Operator manages all Spark workloads submitted from JupyterHub notebooks,
Airflow DAGs, or direct kubectl submissions.

## Upstream Project

- **Project**: [kubeflow/spark-operator](https://github.com/kubeflow/spark-operator)
- **CNCF Status**: Part of Kubeflow (CNCF Incubating)
- **Helm Chart**: [kubeflow/spark-operator](https://kubeflow.github.io/spark-operator)
- **Chart Version**: 2.4.0
- **App Version**: 2.4.0

## What This Module Provides in OKDP

- SparkApplication CRD for declarative Spark job management
- Webhook for validation and mutation of Spark applications
- Prometheus metrics for Spark job monitoring
- Multi-namespace support for job execution

## Key Configuration Areas

- **Job namespaces**: which namespaces can run Spark jobs
- **Webhook**: validation/mutation of SparkApplication resources
- **Metrics**: Prometheus integration
- **RBAC**: controller and spark application service accounts
