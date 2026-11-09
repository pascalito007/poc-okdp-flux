#!/bin/sh
# Argo CD live run of a platform in one command: demo/argocd-install.sh (Argo CD, empty git server, repositories)
# then demo/argocd-publish.sh (the emitted argocd/ folder, OCI registries, health rule, root Application).
# For a demo, run the two steps separately: install before presenting, publish after compose + emit.
# Usage: demo/full-argocd.sh <kube-context> <platform | artefact-dir>   e.g. demo/full-argocd.sh kind-okdp-b trino-tenant
set -eu
[ $# -eq 2 ] || { echo "usage: $0 <kube-context> <platform | artefact-dir>   (e.g. $0 kind-okdp-b trino-tenant)" >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd)
"$here/argocd-install.sh" "$1"
"$here/argocd-publish.sh" "$1" "$2"
