#!/bin/sh
# Step 2 of the Argo CD demo, run after compose + emit: publishes the emitted argocd/ folder in the in-cluster
# git server, declares the OCI chart registries its Applications use, applies the emitted Application health
# rule, then applies the root Application. Argo CD then creates the child Applications, wave by wave.
# Needs demo/argocd-install.sh first, and only the argocd/ folder written by emit.
# Usage: demo/argocd-publish.sh <kube-context> <platform | artefact-dir>   e.g. demo/argocd-publish.sh kind-okdp-b trino-tenant
set -eu
[ $# -eq 2 ] || { echo "usage: $0 <kube-context> <platform | artefact-dir>   (e.g. $0 kind-okdp-b trino-tenant)" >&2; exit 2; }
cd "$(dirname "$0")/.."
CTX=$1; s=$2; K="kubectl --context $CTX"
# the second argument is a platform name (out/<platform>) or an artefact directory
if [ -d "$s" ]; then d=$(cd "$s" && pwd); s=$(basename "$d"); else d="$PWD/out/$s"; fi
[ -d "$d/argocd/apps" ] || { echo "$d/argocd not found: run compose then emit first" >&2; exit 1; }
$K -n argocd get deploy argocd-server >/dev/null 2>&1 || { echo "Argo CD not found in $CTX: run demo/argocd-install.sh first" >&2; exit 1; }

echo "== publish $d/argocd in the git server"
CONTEXT=$CTX demo/git-server.sh "$d"

# OCI chart registries used by the generated Applications (a repoURL without "scheme://"), except the ones
# already declared (the OKDP registry, by demo/argocd-setup.yaml): Argo CD needs a repository with enableOCI.
echo "== OCI chart registries"
declared=$($K -n argocd get secrets -l argocd.argoproj.io/secret-type=repository -o jsonpath='{range .items[*]}{.data.url}{"\n"}{end}' \
  | while read -r u; do [ -n "$u" ] && echo "$u" | base64 -d && echo; done)
for r in $(sed -n 's/^ *repoURL: *//p' "$d"/argocd/apps/*.yaml | tr -d "\"'" | grep -v '://' | sort -u); do
  if echo "$declared" | grep -qxF "$r"; then continue; fi
  n=$(echo "$r" | sed -E 's#[^a-z0-9]+#-#g')
  echo "   $r"
  $K -n argocd create secret generic "repo-$n" --from-literal=type=helm --from-literal=name="$n" --from-literal=url="$r" --from-literal=enableOCI=true --dry-run=client -o yaml \
    | $K label --local -f - argocd.argoproj.io/secret-type=repository -o yaml | $K apply -f - >/dev/null
done

echo "== Application health rule (waves wait for the previous one)"
$K apply --server-side --field-manager=okdp-emitter -f "$d/argocd/argocd-cm-application-health.yaml"
$K -n argocd rollout restart statefulset/argocd-application-controller >/dev/null
$K -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

echo "== root Application"
sed 's#REPLACE_WITH_GIT_REPO#git://okdp-git.okdp-git.svc/okdp-gitops#' "$d/argocd/root-application.yaml" > "demo/root-application.$s.yaml"
date -u +%FT%TZ > "demo/argocd-start.$s.txt"
$K apply -f "demo/root-application.$s.yaml"
# re-read the repository now (a re-publish would otherwise wait for Argo CD's next poll, ~3 min)
root=$(sed -n 's/^  name: *//p' "$d/argocd/root-application.yaml" | head -1)
$K -n argocd annotate application "$root" argocd.argoproj.io/refresh=hard --overwrite >/dev/null
echo "PUBLISHED: watch with  kubectl --context $CTX -n argocd get applications -w"
