kubectl --context kind-okdp-full run apk-ip2 --restart=Never --image=alpine:3.20 --env=http_proxy=http://10.154.61.6:3128 --env=https_proxy=http://10.154.61.6:3128 --env=HTTP_PROXY=http://10.154.61.6:3128 --env=HTTPS_PROXY=http://10.154.61.6:3128 -- sh -c 'getent hosts proxy.infra.dgfip; echo "getent exit=$?"; wget -S -O /dev/null https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/APKINDEX.tar.gz; echo "wget exit=$?"; apk add --no-cache git git-daemon; echo "apk exit=$?"'


export P=http://10.154.61.6:3128

export NP=argocd-repo-server,argocd-redis,argocd-server,argocd-application-controller,kind-registry,kubernetes.default.svc,.svc,.cluster.local,10.96.0.0/16,10.244.0.0/16,172.18.0.0/16,127.0.0.1,localhost


kubectl --context kind-okdp-full -n okdp-git set env deploy/okdp-git http_proxy=$P https_proxy=$P HTTP_PROXY=$P HTTPS_PROXY=$P

kubectl --context kind-okdp-full -n argocd set env deploy/argocd-repo-server HTTP_PROXY=$P HTTPS_PROXY=$P NO_PROXY=$NP

kubectl --context kind-okdp-full -n okdp-git rollout status deploy/okdp-git --timeout=180s

kubectl --context kind-okdp-full -n argocd rollout status deploy/argocd-repo-server --timeout=180s


kubectl --context kind-okdp-full -n argocd annotate application b-tenant-root argocd.argoproj.io/refresh=hard --overwrite

kubectl --context kind-okdp-full -n argocd get applications -w

kubectl --context kind-okdp-full -n argocd get applications -o json | jq -r '.items[] | [.metadata.name, .status.sync.status, .status.health.status, (.status.conditions[0].message // "-")] | @tsv'

kubectl --context kind-okdp-full delete pod apk-test apk-proxy apk-ip apk-ip2 dns-test --ignore-not-found


sed 's#REPLACE_WITH_GIT_REPO#git://okdp-git.okdp-git.svc/okdp-gitops#' out/int-hub/argocd/root-application.yaml | kubectl --context kind-okdp-full apply -f -

kubectl --context kind-okdp-full -n argocd get applications -o json | jq -r '.items[] | "\(.metadata.name): \(.status.sync.status) / \(.status.health.status) \(.status.conditions[0].message // "")"'
