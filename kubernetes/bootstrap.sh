#!/usr/bin/env bash
# Installs what a fresh Talos cluster needs before Argo CD can take over: the Gateway API CRDs and Cilium
# (pinned in the cilium submodule), the spread of CoreDNS across nodes, the sealed-secrets key when given,
# and Argo CD (argocd.yaml).
# Every step is skipped when its result already exists, so it can be rerun after a failure.
#
# Usage: kubernetes/bootstrap.sh <env> [sealed-secrets-key.yaml]
#   KUBECONFIG defaults to ansible/artifacts/<env>.kubeconfig (task k8s:config)
set -euo pipefail

env=${1:?usage: $0 <env> [sealed-secrets-key.yaml]}
sealed_key=${2:-}
root=$(cd "$(dirname "$0")/.." && pwd)
cilium=$root/cilium
export KUBECONFIG=${KUBECONFIG:-$root/ansible/artifacts/$env.kubeconfig}

echo "cluster: $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"

if [ "$(yq '.gatewayAPI.enabled' "$cilium/values.yaml")" = "true" ]; then
  gw_repo=$(yq '.repo' "$cilium/gateway-api.yaml")
  gw_version=$(yq '.version' "$cilium/gateway-api.yaml")
  kubectl apply --server-side -f "$gw_repo/releases/download/$gw_version/standard-install.yaml"
fi

if helm status cilium -n kube-system >/dev/null 2>&1; then
  echo "cilium: already installed"
else
  helm install cilium "$(yq '.chart' "$cilium/version.yaml")" \
    --repo "$(yq '.repo' "$cilium/version.yaml")" --version "$(yq '.version' "$cilium/version.yaml")" \
    --namespace kube-system --values "$cilium/values.yaml"
fi
kubectl -n kube-system rollout status daemonset/cilium --timeout=600s
kubectl wait --for=condition=Ready node --all --timeout=600s

# Talos' CoreDNS only prefers other nodes, so both replicas land on the first node that becomes Ready.
# Talos only creates its manifests and never owns this field, so the spread survives Talos' reconciliation
kubectl apply --server-side --field-manager=lab-bootstrap -f "$root/kubernetes/coredns-spread.yaml"
kubectl -n kube-system rollout status deployment/coredns --timeout=300s

# Must exist before the sealed-secrets controller starts, or it generates a key of its own
if [ -n "$sealed_key" ]; then
  kubectl apply -f "$sealed_key"
fi

if helm status argocd -n argocd >/dev/null 2>&1; then
  echo "argocd: already installed"
else
  helm install argocd "$(yq '.chart' "$root/kubernetes/argocd.yaml")" \
    --repo "$(yq '.repo' "$root/kubernetes/argocd.yaml")" --version "$(yq '.version' "$root/kubernetes/argocd.yaml")" \
    --namespace argocd --create-namespace --values <(yq '.values' "$root/kubernetes/argocd.yaml")
fi
for workload in deployment/argocd-server statefulset/argocd-application-controller deployment/argocd-repo-server; do
  kubectl -n argocd rollout status "$workload" --timeout=600s
done

echo "Argo CD is up. Hand over to lab-argo with: (cd ../lab-argo && task bootstrap)"
