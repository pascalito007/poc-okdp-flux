# Installing CloudNativePG

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed

## Add Helm Repository

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update
```

## Install the Operator

```bash
helm install cloudnative-pg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace \
  --version 0.23.0 \
  -f values/sandbox.yaml
```

## Create the PostgreSQL Cluster

After the operator is running, create the shared PostgreSQL instance:

```bash
kubectl apply -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgresql-instance
  namespace: cnpg-system
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:17.4

  storage:
    size: 5Gi
    storageClass: standard

  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"

  bootstrap:
    initdb:
      database: postgres
      owner: postgres
      postInitSQL:
        # Create databases for all OKDP services
        - CREATE DATABASE hms;
        - CREATE DATABASE superset;
        - CREATE DATABASE keycloak;
        - "CREATE DATABASE \"seaweedfs-default\";"
        - CREATE DATABASE airflow;
        - CREATE DATABASE "superset-examples";
        # Create users
        - CREATE USER hms WITH PASSWORD 'hms123';
        - CREATE USER superset WITH PASSWORD 'superset123';
        - CREATE USER keycloak WITH PASSWORD 'keycloak123';
        - CREATE USER seaweedfs WITH PASSWORD 'seaweedfs123';
        - CREATE USER airflow WITH PASSWORD 'airflow123';
        - CREATE USER examples WITH PASSWORD 'examples123';
        # Grant ownership
        - GRANT ALL PRIVILEGES ON DATABASE hms TO hms;
        - GRANT ALL PRIVILEGES ON DATABASE superset TO superset;
        - GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
        - "GRANT ALL PRIVILEGES ON DATABASE \"seaweedfs-default\" TO seaweedfs;"
        - GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;
        - "GRANT ALL PRIVILEGES ON DATABASE \"superset-examples\" TO examples;"
        # Create schema for superset-examples
        - "\\c \"superset-examples\""
        - CREATE SCHEMA IF NOT EXISTS main;
        - GRANT ALL ON SCHEMA main TO examples;
EOF
```

## Create Database Credential Secrets

These secrets are referenced by downstream OKDP services:

```bash
# Hive Metastore
kubectl create secret generic creds-hms-db \
  --namespace default \
  --from-literal=username=hms \
  --from-literal=password=hms123

# Superset
kubectl create secret generic creds-superset-db \
  --namespace default \
  --from-literal=username=superset \
  --from-literal=password=superset123

# Keycloak
kubectl create secret generic creds-keycloak-db \
  --namespace keycloak \
  --from-literal=username=keycloak \
  --from-literal=password=keycloak123

# SeaweedFS
kubectl create secret generic creds-seaweedfs-db \
  --namespace default \
  --from-literal=username=seaweedfs \
  --from-literal=password=seaweedfs123

# Airflow
kubectl create secret generic creds-airflow-db \
  --namespace default \
  --from-literal=username=airflow \
  --from-literal=password=airflow123

# Superset Examples
kubectl create secret generic creds-superset-examples-db \
  --namespace default \
  --from-literal=username=examples \
  --from-literal=password=examples123
```

## Verify

```bash
# Check operator
kubectl get pods -n cnpg-system
# Expected: cloudnative-pg-* Running

# Check PostgreSQL cluster
kubectl get clusters -n cnpg-system
# Expected: postgresql-instance with STATUS=Cluster in healthy state

# Check PostgreSQL pods
kubectl get pods -n cnpg-system -l cnpg.io/cluster=postgresql-instance
# Expected: postgresql-instance-1 Running

# Test connectivity
kubectl exec -it postgresql-instance-1 -n cnpg-system -- psql -U postgres -c "\\l"
# Expected: list of databases including hms, superset, keycloak, etc.
```

## Uninstall

```bash
kubectl delete cluster postgresql-instance -n cnpg-system
helm uninstall cloudnative-pg -n cnpg-system
kubectl delete namespace cnpg-system
```
