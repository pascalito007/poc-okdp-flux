#!/bin/sh
# Removes everything a platform deployed with demo/full-argocd.sh, so the journey can be run again on a
# clean cluster. Reads only Argo CD (no out/ folder needed):
#   1. deletes the root Application (it has no finalizer: its children stay, and are not recreated);
#   2. deletes the child Applications in reverse wave order (each one has a finalizer: Argo CD deletes
#      what it installed). Operators go last, so CNPG / External Secrets objects are not left stuck;
#   3. deletes the namespaces the Applications deployed to (volumes and leftovers go with them).
# Argo CD itself, the okdp-git server, the repository Secrets and the operators' CRDs are kept.
# Usage: demo/cleanup-argocd.sh <kube-context> <platform name>     e.g. demo/cleanup-argocd.sh kind-okdp-b trino-tenant
set -eu
[ $# -eq 2 ] || { echo "usage: $0 <kube-context> <platform name>   (e.g. $0 kind-okdp-b trino-tenant)" >&2; exit 2; }
CTX=$1; P=$2
k() { kubectl --context "$CTX" "$@"; }
TAB=$(printf '\t')

echo "== 1. root Application $P-root"
k -n argocd delete application "$P-root" --ignore-not-found --wait=true

# child Applications of this platform: "<wave><TAB><name><TAB><namespace>", last wave first
apps=$(k -n argocd get applications -o json | jq -r --arg p "$P-" '
  .items[] | select(.metadata.name | startswith($p))
  | [(.metadata.annotations["argocd.argoproj.io/sync-wave"] // "0" | tonumber), .metadata.name, .spec.destination.namespace]
  | @tsv' | sort -rn)

echo "== 2. child Applications, last wave first"
if [ -z "$apps" ]; then echo "   none"; fi
echo "$apps" | while IFS="$TAB" read -r wave name ns; do
  [ -n "$name" ] || continue
  echo "   wave $wave  $name"
  k -n argocd delete application "$name" --wait=true --timeout=600s
done

echo "== 3. namespaces"
for ns in $(echo "$apps" | cut -f3 | sort -u); do
  case "$ns" in
    ""|argocd|okdp-git|default|kube-system|kube-public|kube-node-lease|local-path-storage)
      echo "   kept $ns" ;;
    *)
      echo "   deleting $ns"
      k delete namespace "$ns" --ignore-not-found --wait=true --timeout=600s ;;
  esac
done

left=$(k -n argocd get applications -o name | grep "/$P-" || true)
if [ -n "$left" ]; then echo "STILL PRESENT:"; echo "$left"; exit 1; fi
echo "CLEAN: no Application of $P is left"
