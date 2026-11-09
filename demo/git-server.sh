#!/bin/sh
# In-cluster Git server for the Argo CD demo: publishes <out-dir>/argocd as git://okdp-git.okdp-git.svc/okdp-gitops.
# Without <out-dir>, the repository holds only a README (Argo CD installed, nothing published yet).
# Usage: CONTEXT=<kube-context> demo/git-server.sh [<out-dir>]
set -eu
K="kubectl --context ${CONTEXT:-kind-okdp-poc}"
src=${1:-}
$K create ns okdp-git --dry-run=client -o yaml | $K apply -f - >/dev/null
if [ -n "$src" ]; then
  args=""; for f in $(cd "$src" && find argocd -type f | sort); do args="$args --from-file=$(echo "$f" | sed 's#/#__#g')=$src/$f"; done
else
  args="--from-literal=README.md=nothing-published-yet"
fi
$K -n okdp-git create configmap gitops-files $args --dry-run=client -o yaml | $K apply -f - >/dev/null
cat <<'YAML' | $K apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: { name: okdp-git, namespace: okdp-git }
spec:
  replicas: 1
  selector: { matchLabels: { app: okdp-git } }
  template:
    metadata: { labels: { app: okdp-git } }
    spec:
      volumes: [ { name: files, configMap: { name: gitops-files } } ]
      containers:
        - name: git
          image: alpine:3.20
          command: ["/bin/sh", "-ec"]
          args:
            - |
              apk add --no-cache git git-daemon >/dev/null
              mkdir -p /work && cd /work
              for f in /files/*; do p=$(basename "$f" | sed 's#__#/#g'); mkdir -p "$(dirname "$p")"; cp "$f" "$p"; done
              git init -q -b main . && git add . && git -c user.name=okdp -c user.email=poc@okdp.local commit -qm "generated artefacts"
              git clone -q --bare /work /srv/okdp-gitops && touch /srv/okdp-gitops/git-daemon-export-ok
              exec git daemon --reuseaddr --base-path=/srv --export-all /srv
          ports: [ { containerPort: 9418 } ]
          volumeMounts: [ { name: files, mountPath: /files } ]
---
apiVersion: v1
kind: Service
metadata: { name: okdp-git, namespace: okdp-git }
spec: { selector: { app: okdp-git }, ports: [ { port: 9418, targetPort: 9418 } ] }
YAML
$K -n okdp-git rollout restart deploy/okdp-git >/dev/null
$K -n okdp-git rollout status deploy/okdp-git --timeout=300s
