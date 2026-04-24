# Spark Operator — OKDP Integration

## What's OKDP-specific in the values

The [sandbox.yaml](values/sandbox.yaml) configures the Spark Operator for OKDP:

- **Job namespaces**: all namespaces allowed (empty string)
- **RBAC**: disabled in chart — created separately via `manifests/spark-rbac.yaml`
  to allow flexibility across namespaces
- **Webhook**: enabled for SparkApplication validation/mutation

## Manifests

- `manifests/spark-rbac.yaml` — ServiceAccount `spark`, Role, RoleBinding in default namespace

## Official docs

- [Kubeflow Spark Operator](https://github.com/kubeflow/spark-operator)
