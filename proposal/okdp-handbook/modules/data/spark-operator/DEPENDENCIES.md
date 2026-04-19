# Spark Operator Dependencies

## Required Before Installation

None — Spark Operator is independent of other OKDP modules.

## Required By (Downstream Dependents)

- [spark-history-server](../spark-history-server/) — monitors Spark applications managed by the operator
- [jupyterhub](../jupyterhub/) — submits Spark jobs from notebooks via the operator
- [airflow](../airflow/) — orchestrates Spark jobs via SparkKubernetesOperator
