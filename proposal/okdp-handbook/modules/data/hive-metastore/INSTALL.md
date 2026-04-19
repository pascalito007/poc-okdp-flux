# Installing Hive Metastore

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed
- [ ] [CloudNativePG](../../infrastructure/cloudnative-pg/INSTALL.md) installed with `hms` database created
- [ ] [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) installed with `hive` bucket created
- [ ] Database credentials secret `creds-hms-db` created in target namespace
- [ ] S3 credentials secret `creds-hms-s3` created in target namespace

## Add Helm Repository

The OKDP Hive Metastore chart is published as an OCI artifact:

```bash
# No helm repo add needed — install directly from OCI
```

## Install

```bash
helm install hive-metastore oci://quay.io/okdp/charts/hive-metastore \
  --namespace default \
  --version 1.4.0 \
  -f values/sandbox.yaml
```

## Verify

```bash
# Check pods
kubectl get pods -l app.kubernetes.io/name=hive-metastore
# Expected: hive-metastore-0, hive-metastore-1 Running (after init job completes)

# Check init job
kubectl get jobs -l app.kubernetes.io/name=hive-metastore
# Expected: Completed

# Check service
kubectl get svc hive-metastore
# Expected: ClusterIP on port 9083

# Test Thrift connectivity from within the cluster
kubectl run hms-test --rm -it --image=busybox --restart=Never -- \
  sh -c "nc -zv hive-metastore.default.svc.cluster.local 9083"
# Expected: open
```

## Uninstall

```bash
helm uninstall hive-metastore
```
