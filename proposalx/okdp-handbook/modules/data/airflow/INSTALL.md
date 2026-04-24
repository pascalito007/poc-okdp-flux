# Installing Apache Airflow

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [cert-manager](../../infrastructure/cert-manager/INSTALL.md) installed
- [ ] [ingress-nginx](../../infrastructure/ingress-nginx/INSTALL.md) installed
- [ ] [CloudNativePG](../../infrastructure/cloudnative-pg/INSTALL.md) installed with `airflow` database
- [ ] [Spark Operator](../spark-operator/INSTALL.md) installed (for Spark job orchestration)
- [ ] Spark RBAC ServiceAccount `spark` created in target namespace
- [ ] Database credentials secret `creds-airflow-db` created in target namespace

## Add Helm Repository

```bash
helm repo add apache-airflow https://airflow.apache.org
helm repo update
```

## Install

```bash
helm install airflow apache-airflow/airflow \
  --namespace default \
  --version 1.17.0 \
  -f values/sandbox.yaml
```

## Verify

```bash
# Check pods
kubectl get pods -l release=airflow
# Expected: airflow-webserver, airflow-scheduler, airflow-triggerer Running

# Check ingress
kubectl get ingress -l release=airflow
# Expected: airflow ingress with host airflow-default.okdp.sandbox

# Access the UI
# URL: https://airflow-default.okdp.sandbox (or your custom domain)
# Default credentials: admin / admin

# Check DAG sync (if using gitSync)
kubectl logs -l component=scheduler -c git-sync --tail=5
# Expected: sync logs showing successful git pulls
```

## Uninstall

```bash
helm uninstall airflow
```
