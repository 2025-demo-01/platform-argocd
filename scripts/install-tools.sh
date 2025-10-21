#!/usr/bin/env bash
set -euo pipefail

# kustomize
curl -sSL https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash
sudo mv kustomize /usr/local/bin/

# kubeconform
curl -L -o kubeconform.tar.gz https://github.com/yannh/kubeconform/releases/download/v0.6.7/kubeconform-linux-amd64.tar.gz
tar -xzf kubeconform.tar.gz kubeconform && sudo mv kubeconform /usr/local/bin/

# yq
sudo wget -q -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

echo "kustomize $(kustomize version)"
echo "kubeconform $(kubeconform -v)"
echo "yq v$(yq --version | awk '{print $NF}')"
