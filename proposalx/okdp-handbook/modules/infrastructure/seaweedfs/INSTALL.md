# Installing SeaweedFS

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [cert-manager](../cert-manager/INSTALL.md) installed with `default-issuer` ClusterIssuer
- [ ] [ingress-nginx](../ingress-nginx/INSTALL.md) installed

## Add Helm Repository

```bash
helm repo add seaweedfs https://seaweedfs.github.io/seaweedfs/helm
helm repo update
```

## Create S3 Credentials

SeaweedFS requires an S3 config secret that defines per-service access credentials.
Create the credentials secrets first, then the S3 config:

```bash
# Per-service S3 credential secrets
kubectl create secret generic creds-hms-s3 \
  --from-literal=accessKey=hms_access \
  --from-literal=secretKey=hms_secret

kubectl create secret generic creds-spark-history-s3 \
  --from-literal=accessKey=spark_access \
  --from-literal=secretKey=spark_secret

kubectl create secret generic creds-trino-s3 \
  --from-literal=S3_ACCESS_KEY=trino_access \
  --from-literal=S3_SECRET_ACCESS=trino_secret

kubectl create secret generic creds-jupyter-s3 \
  --from-literal=S3_ACCESS_KEY=jupyter_access \
  --from-literal=S3_SECRET_KEY=jupyter_secret

kubectl create secret generic creds-airflow-s3 \
  --from-literal=accessKey=airflow_access \
  --from-literal=secretKey=airflow_secret

kubectl create secret generic creds-examples-s3 \
  --from-literal=S3_ACCESS_KEY=examples_access \
  --from-literal=S3_SECRET_KEY=examples_secret

kubectl create secret generic creds-seaweedfs-s3 \
  --from-literal=accessKey=admin_access \
  --from-literal=secretKey=admin_secret

# SeaweedFS S3 config secret (defines all identities and their permissions)
# This JSON maps access keys to identities with specific bucket permissions
kubectl create secret generic creds-seaweedfs-secret \
  --from-literal=seaweedfs_s3_config='{
    "identities": [
      {
        "name": "admin",
        "credentials": [{"accessKey": "admin_access", "secretKey": "admin_secret"}],
        "actions": ["Admin"]
      },
      {
        "name": "hms",
        "credentials": [{"accessKey": "hms_access", "secretKey": "hms_secret"}],
        "actions": ["Read:hive", "Write:hive", "List:hive"]
      },
      {
        "name": "spark",
        "credentials": [{"accessKey": "spark_access", "secretKey": "spark_secret"}],
        "actions": ["Read:spark-events", "Write:spark-events", "List:spark-events"]
      },
      {
        "name": "trino",
        "credentials": [{"accessKey": "trino_access", "secretKey": "trino_secret"}],
        "actions": ["Read", "Write", "List"]
      },
      {
        "name": "jupyter",
        "credentials": [{"accessKey": "jupyter_access", "secretKey": "jupyter_secret"}],
        "actions": ["Read", "Write", "List"]
      },
      {
        "name": "airflow",
        "credentials": [{"accessKey": "airflow_access", "secretKey": "airflow_secret"}],
        "actions": ["Read:airflow-logs", "Write:airflow-logs", "List:airflow-logs"]
      },
      {
        "name": "examples",
        "credentials": [{"accessKey": "examples_access", "secretKey": "examples_secret"}],
        "actions": ["Admin"]
      }
    ]
  }'

# Basic auth secret for filer console
kubectl create secret generic auth-user-secret \
  --from-literal=auth="$(echo -n 'admin' | htpasswd -i -n admin)"
```

## Install

```bash
helm install seaweedfs seaweedfs/seaweedfs \
  --namespace default \
  --version 4.0.407 \
  -f values/sandbox.yaml
```

## Verify

```bash
# Check pods
kubectl get pods -l app.kubernetes.io/name=seaweedfs
# Expected: master, volume, filer pods Running

# Check S3 endpoint
curl -sk https://seaweedfs-seaweedfs-default.okdp.sandbox
# Expected: response from S3 API

# Test S3 with aws-cli
aws --endpoint-url https://seaweedfs-seaweedfs-default.okdp.sandbox \
  --no-verify-ssl \
  s3 ls \
  --region us-east-1
# Expected: list of buckets (hive, spark-events)

# Check filer console
curl -sk -u admin:admin https://seaweedfs-seaweedfs-console-default.okdp.sandbox
# Expected: filer HTML page
```

## Uninstall

```bash
helm uninstall seaweedfs
kubectl delete secret creds-seaweedfs-secret auth-user-secret \
  creds-hms-s3 creds-spark-history-s3 creds-trino-s3 \
  creds-jupyter-s3 creds-airflow-s3 creds-examples-s3 creds-seaweedfs-s3
```
