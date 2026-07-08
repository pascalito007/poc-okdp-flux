# SeaweedFS `auth-config` ConfigMap mount failure — reproduction

Reproduces the OKDP `seaweedfs` bug where the S3 pod is stuck in
`ContainerCreating` with:

```
MountVolume.SetUp failed for volume "auth-config" :
  configmap "seaweedfs-<suffix>-auth-config" not found
```

## Root cause (short)

- The `seaweedfs` package (`packages/services/seaweedfs/seaweedfs.yaml`, tag `4.17.0-p2`)
  mounts the IAM auth ConfigMap by the hardcoded name
  `{{ .Release.metadata.name }}-auth-config`.
- The `seaweedfs-auth-config` Helm chart names that ConfigMap with the standard
  Helm `fullname` helper, which only collapses to `<release>-auth-config` when
  Helm's fullname **dedup** triggers (i.e. the release name literally contains
  the chart name `seaweedfs-auth-config`).
- For console / per-project releases the name has a random suffix
  (e.g. `seaweedfs-ij1yin`). Dedup does **not** trigger, so the real ConfigMap
  is `seaweedfs-ij1yin-auth-config-seaweedfs-auth-config`, while the pod mounts
  `seaweedfs-ij1yin-auth-config`. Mismatch -> `FailedMount` -> `ContainerCreating`.

> This reproduces the exact kubelet `FailedMount` mechanism in an isolated
> namespace, without the full OKDP platform. The only substitution is `busybox`
> in place of the real seaweedfs S3 image: the mount failure happens before the
> container starts, so the image is irrelevant to the bug.

## Prerequisites

- A running Kubernetes cluster (any Kind cluster is fine) and `kubectl` context set
- `helm` and `git`

## Setup — clone the chart, create an isolated namespace

```bash
cd /tmp
rm -rf hcu-repro
git clone --depth 1 https://github.com/OKDP/helm-charts-utilities.git hcu-repro
kubectl create namespace seaweedfs-repro
```

## Step 1 — install auth-config as the KuboCD-style suffixed release

The release name `seaweedfs-ij1yin-auth-config` mimics what KuboCD names the
module sub-release for an OKDP release called `seaweedfs-ij1yin`.

```bash
helm install seaweedfs-ij1yin-auth-config /tmp/hcu-repro/charts/seaweedfs-auth-config \
  -n seaweedfs-repro
```

## Step 2 — show the real ConfigMap name the chart generates

```bash
kubectl -n seaweedfs-repro get cm | grep -v kube-root-ca
# => seaweedfs-ij1yin-auth-config-seaweedfs-auth-config
```

## Step 3 — create the S3 pod exactly as the `-p2` main module mounts it

The pod references `seaweedfs-ij1yin-auth-config` (the hardcoded `-p2` name),
which does not exist.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: seaweedfs-ij1yin-s3
  namespace: seaweedfs-repro
  labels:
    app.kubernetes.io/component: s3
spec:
  containers:
  - name: seaweedfs-s3
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
    volumeMounts:
    - name: auth-config
      mountPath: /etc/seaweed/iam
      readOnly: true
  volumes:
  - name: auth-config
    configMap:
      name: seaweedfs-ij1yin-auth-config    # the -p2 hardcoded reference
EOF
```

## Step 4 — observe the failure

```bash
sleep 15
kubectl -n seaweedfs-repro get pod seaweedfs-ij1yin-s3
# => STATUS: ContainerCreating

kubectl -n seaweedfs-repro describe pod seaweedfs-ij1yin-s3 | grep -A3 -i events:
# => Warning  FailedMount  MountVolume.SetUp failed for volume "auth-config" :
#              configmap "seaweedfs-ij1yin-auth-config" not found
```

That is the reproduction of the reported error.

## (Optional) Confirm the fix

The fix adds `fullnameOverride: {{ $release }}-auth-config` to the `auth-config`
module in `packages/services/seaweedfs/seaweedfs.yaml`. Simulate it with `--set`:

```bash
helm upgrade seaweedfs-ij1yin-auth-config /tmp/hcu-repro/charts/seaweedfs-auth-config \
  -n seaweedfs-repro --set fullnameOverride=seaweedfs-ij1yin-auth-config

kubectl -n seaweedfs-repro get cm | grep -v kube-root-ca
# => seaweedfs-ij1yin-auth-config   (now matches what the pod mounts)

# kubelet retries the mount automatically (exponential backoff, up to ~2 min)
kubectl -n seaweedfs-repro get pod seaweedfs-ij1yin-s3 -w
# => eventually READY 1/1, Running
```

## Cleanup (restores the cluster to its prior state)

```bash
helm -n seaweedfs-repro uninstall seaweedfs-ij1yin-auth-config
kubectl delete namespace seaweedfs-repro
rm -rf /tmp/hcu-repro
```
