# Cilium on Kind — Lab Cheat Sheet

> Lab context : cluster Kind local, CNI Cilium, kube-proxy replacement, Ingress & Gateway API  
> Demo app : **podinfo** (frontend + backend + redis)  
> Stack : Kind · Cilium 1.16+ · Helm · kubectl

-----

## 1. Kind cluster configuration (without CNI)

```yaml
# k8s-without-cni.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: my-k8s-cluster
networking:
  disableDefaultCNI: true      # mandatory — let Cilium be the CNI
  kubeProxyMode: "none"        # mandatory — let Cilium replace kube-proxy
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80      # Docker bridge: laptop:80 → node:80
        hostPort: 80
      - containerPort: 443
        hostPort: 443
  - role: worker
  - role: worker
```

```bash
kind create cluster --config k8s-without-cni.yaml
```

> **Why `kubeProxyMode: none`?**  
> Without it, kube-proxy DaemonSet is deployed alongside Cilium’s kube-proxy replacement → conflicts on service routing.

-----

## 2. Cilium installation via Helm

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update
helm search repo cilium          # check available versions
helm show values cilium/cilium   # inspect all default values
```

### Install

```bash
helm install cilium cilium/cilium \
  --namespace kube-system \
  -f cilium-values.yaml
```

### Upgrade after config change

```bash
helm upgrade cilium cilium/cilium -n kube-system -f cilium-values.yaml
kubectl rollout restart deployment cilium-operator -n kube-system
kubectl rollout restart daemonset cilium -n kube-system
kubectl rollout restart daemonset cilium-envoy -n kube-system
```

-----

## 3. Demo app — podinfo

podinfo is a microservices demo app used for Kubernetes training.  
It exposes a web UI (frontend) backed by an API (backend) with optional Redis.

### Ports

|Component       |Service port|Protocol|
|----------------|------------|--------|
|frontend-podinfo|9898        |HTTP    |
|frontend-podinfo|9999        |gRPC    |
|backend-podinfo |9898        |HTTP    |
|backend-podinfo |9999        |gRPC    |

### Install via Helm

```bash
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update

# Deploy backend
helm install backend podinfo/podinfo \
  --namespace test \
  --create-namespace \
  --set redis.enabled=true

# Deploy frontend pointing to backend
helm install frontend podinfo/podinfo \
  --namespace test \
  --set backend=http://backend-podinfo:9898/echo
```

### Verify

```bash
kubectl get po -n test
kubectl get svc -n test
# Expected services: backend-podinfo, backend-podinfo-redis, frontend-podinfo
```

-----

## 4. kube-proxy management

```bash
# Verify kube-proxy replacement is active
kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep KubeProxyReplacement

# Delete kube-proxy if cluster was NOT created with kubeProxyMode: none
kubectl -n kube-system delete ds kube-proxy
kubectl -n kube-system delete cm kube-proxy

# List ConfigMaps in kube-system
kubectl get cm -n kube-system
```

-----

## 5. Useful commands

```bash
# All pods
kubectl get po -A
kubectl get po -A -w            # watch mode

# All services
kubectl get svc -A

# All daemonsets
kubectl get daemonset -A

# Helm values currently deployed
helm get values cilium -n kube-system

# Check Cilium status
cilium status
```

-----

## 6. Ingress Controller (Cilium hostNetwork mode)

### Why hostNetwork?

On Kind there is no cloud provider → LoadBalancer stays `<pending>`.  
`hostNetwork: true` makes Envoy listen **directly on the node port**, bypassing any LoadBalancer/NodePort.

> ⚠️ Cilium CNI + pod `hostPort` are incompatible. Always use `hostNetwork` on the Envoy listener instead.

### cilium-values.yaml — Ingress mode

```yaml
kubeProxyReplacement: "true"
k8sServiceHost: "my-k8s-cluster-control-plane"
k8sServicePort: "6443"

ingressController:
  enabled: true
  default: true
  loadbalancerMode: shared
  hostNetwork:
    enabled: true
    sharedListenerPort: 80     # correct key — NOT sharedListener

envoy:
  securityContext:
    capabilities:
      keepCapNetBindService: true
      envoy:
        - NET_ADMIN
        - SYS_ADMIN
        - NET_BIND_SERVICE     # required for port ≤ 1023
```

### Ingress manifest

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: podinfo-ingress
  namespace: test
spec:
  ingressClassName: cilium
  rules:
    - host: localhost
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-podinfo
                port:
                  number: 9898
```

```bash
kubectl apply -f ingress.yaml
kubectl get ingress -n test
curl http://localhost
```

### Traffic flow

```
Browser localhost:80
    ↓  extraPortMappings (Docker)
Kind node :80
    ↓  hostNetwork
Envoy (Cilium Ingress — binds directly on :80)
    ↓  Ingress rule (ingressClassName: cilium)
frontend-podinfo :9898
    ↓  eBPF (no kube-proxy)
Pod podinfo
```

-----

## 7. Gateway API (Cilium hostNetwork mode)

### Install Gateway API CRDs (prerequisite)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.4.1/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.4.1/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.4.1/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.4.1/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.4.1/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
```

### cilium-values.yaml — Gateway API mode

> ⚠️ `ingressController.hostNetwork` and `gatewayAPI.hostNetwork` are **independent** Helm values.  
> Disabling ingressController does NOT carry over its hostNetwork to gatewayAPI.

```yaml
kubeProxyReplacement: "true"
k8sServiceHost: "my-k8s-cluster-control-plane"
k8sServicePort: "6443"

ingressController:
  enabled: false

gatewayAPI:
  enabled: true
  hostNetwork:
    enabled: true              # disables LoadBalancer service — correct on Kind

envoy:
  securityContext:
    capabilities:
      keepCapNetBindService: true
      envoy:
        - NET_ADMIN
        - SYS_ADMIN
        - NET_BIND_SERVICE
```

### Gateway manifest

```yaml
# gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
  namespace: test
spec:
  gatewayClassName: cilium
  listeners:
    - name: http
      protocol: HTTP
      port: 80                 # binds directly on node with hostNetwork
    - name: http-alt
      protocol: HTTP
      port: 8080               # second listener (no privileged port issue)
```

### HTTPRoute manifest

```yaml
# http_route.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: frontend-route
  namespace: test
spec:
  parentRefs:
    - name: my-gateway
      namespace: test
      sectionName: http        # target the specific listener
  hostnames:
    - localhost
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: frontend-podinfo
          port: 9898           # actual podinfo service port
```

```bash
kubectl apply -f gateway.yaml
kubectl apply -f http_route.yaml

# Verify — PROGRAMMED must be True
kubectl get gateway -n test
kubectl get httproute -n test

curl http://localhost
```

### Traffic flow

```
Browser localhost:80
    ↓  extraPortMappings (Docker)
Kind node :80
    ↓  hostNetwork
Envoy (Cilium Gateway — binds directly on :80)
    ↓  HTTPRoute rule → frontend-podinfo:9898
    ↓  eBPF (no kube-proxy)
Pod frontend-podinfo :9898
```

-----

## 8. Troubleshooting Gateway API

```bash
# Is Gateway programmed? (PROGRAMMED must be True)
kubectl get gateway -n test
kubectl describe gateway my-gateway -n test

# Is HTTPRoute accepted and refs resolved?
kubectl describe httproute frontend-route -n test

# Cilium operator logs — gateway errors
kubectl -n kube-system logs deployment/cilium-operator | grep -i gateway | tail -20

# Was a service created? (ClusterIP expected with hostNetwork, none without)
kubectl get svc -A | grep gateway

# Is Envoy listening on the right port?
docker exec my-k8s-cluster-control-plane ss -tlnp | grep -E ':80|:8080'
```

-----

## 9. Key gotchas

|Issue                               |Root cause                                                |Fix                                                          |
|------------------------------------|----------------------------------------------------------|-------------------------------------------------------------|
|LoadBalancer `<pending>`            |No cloud provider on Kind                                 |Use `hostNetwork: true` (Cilium 1.16+)                       |
|`Connection refused` on hostPort    |Cilium CNI incompatible with pod hostPort                 |Use `hostNetwork: true` on Envoy listener                    |
|`Connection reset`                  |Nothing listening on node port                            |Check hostNetwork is enabled and port is correct             |
|`no healthy upstream`               |Wrong backend port in HTTPRoute                           |Match `port` to actual service port (e.g. `9898` for podinfo)|
|`sharedListener: 80` ignored        |Wrong Helm key                                            |Correct key is `sharedListenerPort: 80`                      |
|Port 80 bind fails                  |Privileged port requires capability                       |Add `NET_BIND_SERVICE` + `keepCapNetBindService: true`       |
|Gateway API not processing          |`gatewayAPI.enabled` not set                              |Add to cilium-values.yaml and upgrade Helm                   |
|curl fails after enabling gatewayAPI|`gatewayAPI.hostNetwork` ≠ `ingressController.hostNetwork`|Set `gatewayAPI.hostNetwork.enabled: true` explicitly        |
|kube-proxy pods still running       |Cluster created without `kubeProxyMode: none`             |Recreate cluster with correct Kind config                    |
|`no healthy upstream` on podinfo    |HTTPRoute port `8080` but service is `9898`               |Use correct service port in `backendRefs`                    |

-----

## 10. Full cilium-values.yaml reference

### Mode A — Ingress Controller

```yaml
kubeProxyReplacement: "true"
k8sServiceHost: "my-k8s-cluster-control-plane"
k8sServicePort: "6443"

ingressController:
  enabled: true
  default: true
  loadbalancerMode: shared
  hostNetwork:
    enabled: true
    sharedListenerPort: 80

envoy:
  securityContext:
    capabilities:
      keepCapNetBindService: true
      envoy:
        - NET_ADMIN
        - SYS_ADMIN
        - NET_BIND_SERVICE
```

### Mode B — Gateway API

```yaml
kubeProxyReplacement: "true"
k8sServiceHost: "my-k8s-cluster-control-plane"
k8sServicePort: "6443"

ingressController:
  enabled: false

gatewayAPI:
  enabled: true
  hostNetwork:
    enabled: true

envoy:
  securityContext:
    capabilities:
      keepCapNetBindService: true
      envoy:
        - NET_ADMIN
        - SYS_ADMIN
        - NET_BIND_SERVICE
```