# Installing Spark Operator

## Prerequisites

- [ ] Kubernetes cluster 1.28+
- [ ] Helm 3.x installed

## Add Helm Repository

```bash
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update
```

## Install

```bash
helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator \
  --create-namespace \
  --version 2.4.0 \
  -f values/sandbox.yaml
```

## Create Spark RBAC (ServiceAccount + Role + RoleBinding)

Spark applications need a ServiceAccount with appropriate permissions in the namespace where they run:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spark
  namespace: default
automountServiceAccountToken: true
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: spark-role
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log", "services", "configmaps", "persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "create", "delete", "patch", "update"]
  - apiGroups: ["sparkoperator.k8s.io"]
    resources: ["sparkapplications", "sparkapplications/status", "scheduledsparkapplications"]
    verbs: ["get", "list", "watch", "create", "delete", "patch", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: spark-role-binding
  namespace: default
subjects:
  - kind: ServiceAccount
    name: spark
    namespace: default
roleRef:
  kind: Role
  name: spark-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

## Verify

```bash
# Check operator pods
kubectl get pods -n spark-operator
# Expected: spark-operator-controller-* and spark-operator-webhook-* Running

# Check CRDs
kubectl get crd sparkapplications.sparkoperator.k8s.io
# Expected: CRD exists

# Test with SparkPi example
kubectl apply -f - <<EOF
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: spark-pi-test
  namespace: default
spec:
  type: Scala
  mode: cluster
  image: "quay.io/okdp/spark-py:spark-3.5.6-python-3.11-scala-2.12-java-17"
  mainClass: org.apache.spark.examples.SparkPi
  mainApplicationFile: "local:///opt/spark/examples/jars/spark-examples_2.12-3.5.6.jar"
  sparkVersion: "3.5.6"
  restartPolicy:
    type: Never
  driver:
    cores: 1
    memory: "512m"
    serviceAccount: spark
  executor:
    cores: 1
    instances: 1
    memory: "512m"
EOF

# Watch the application
kubectl get sparkapplication spark-pi-test -w
# Expected: SUBMITTED → RUNNING → COMPLETED

# Cleanup test
kubectl delete sparkapplication spark-pi-test
```

## Uninstall

```bash
helm uninstall spark-operator -n spark-operator
kubectl delete namespace spark-operator
```
