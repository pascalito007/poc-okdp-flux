#!/bin/sh
# Step 1 of the Argo CD demo, run once before presenting: installs Argo CD, an in-cluster git server holding an
# EMPTY repository, and the repository Secrets of the OKDP chart registry and of that git server.
# Afterwards Argo CD runs with no Application at all. Step 2 (after compose + emit): demo/argocd-publish.sh.
# Usage: demo/argocd-install.sh <kube-context>     e.g. demo/argocd-install.sh kind-okdp-b
set -eu
[ $# -eq 1 ] || { echo "usage: $0 <kube-context>   (e.g. $0 kind-okdp-b)" >&2; exit 2; }
cd "$(dirname "$0")/.."
CTX=$1; K="kubectl --context $CTX"
ARGO_VERSION=${ARGO_VERSION:-v3.4.12}
echo "== Argo CD $ARGO_VERSION"
$K create ns argocd --dry-run=client -o yaml | $K apply -f - >/dev/null
$K apply -n argocd --server-side --force-conflicts -f "https://raw.githubusercontent.com/argoproj/argo-cd/$ARGO_VERSION/manifests/install.yaml" >/dev/null
# components the demo does not use (memory of the 7.7 GB kind VM)
$K -n argocd scale deploy argocd-dex-server argocd-notifications-controller argocd-applicationset-controller --replicas=0 >/dev/null
$K -n argocd rollout status statefulset/argocd-application-controller --timeout=600s
$K -n argocd rollout status deploy/argocd-repo-server --timeout=600s
echo "== in-cluster git server (empty repository)"
CONTEXT=$CTX demo/git-server.sh
echo "== repositories: OKDP chart registry and git server"
$K apply -f demo/argocd-setup.yaml
echo "ARGO CD READY: $($K -n argocd get applications --no-headers 2>/dev/null | wc -l | tr -d ' ') Application(s)"
