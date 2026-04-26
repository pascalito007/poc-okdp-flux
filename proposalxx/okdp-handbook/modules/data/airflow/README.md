# Apache Airflow — OKDP Integration

## What's OKDP-specific in the values

The [sandbox.yaml](values/sandbox.yaml) configures Airflow for OKDP:

- **PostgreSQL**: connects to CNPG instance for metadata (airflow/airflow123)
- **DAG sync**: gitSync from `OKDP/okdp-sandbox` repo (`examples/airflow/dags`)
- **Executor**: LocalExecutor (sandbox), no Redis/Celery
- **Ingress**: TLS via cert-manager `default-issuer`
- **Disabled**: workers, dagProcessor, flower, pgbouncer, statsd (sandbox simplicity)

## Prerequisites (from OKDP infrastructure)

- PostgreSQL database `airflow`
- cert-manager ClusterIssuer
- ingress-nginx
- Spark Operator + Spark RBAC (for SparkKubernetesOperator DAGs)

## Service endpoint

```
https://airflow-default.okdp.sandbox  (admin/admin)
```

## Official docs

- [Apache Airflow Helm chart](https://airflow.apache.org/docs/helm-chart/stable/index.html)
