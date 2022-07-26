#!/bin/bash

YELLOW='\033[1;33m'
KV_VERSION="v0.53.0"
CDI_VERSION="v1.48.1"
KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
KREW_PATH="/home/${USER}/.krew/bin"

# helper function
warn()
{
  echo -e "${YELLOW} $@ ${NC}" >&2
}

check_sw_installed()
{
  clear
  if command_exists docker; then
    warn "Docker appears to be installed on the system."
    warn "Please uninstall Docker before continuing installation."
    echo ""
  fi

  if command_exists kubectl; then
    warn "Kubernetes software appears to be installed on the system."
    warn "Please uninstall Kubernetes software before continuing installation."
    echo ""
  fi
}

install_docker()
{
  echo "Installing docker"
  sudo apt-get update
  sudo apt-get install ca-certificates curl gnupg lsb-release -y

  sudo rm /usr/share/keyrings/docker-archive-keyring.gpg
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y
}

uninstall_docker()
{
  echo "Uninstalling docker"
  sudo apt-get purge docker-ce docker-ce-cli containerd.io -y
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd
}

conf_usergroup()
{
  echo "Configure usergroup"
  sudo usermod -aG docker ${USER}
}

install_k3s()
{
  echo "Installing K3s"
  curl -sfL https://get.k3s.io | sh -s - --docker --disable=traefik --write-kubeconfig-mode=644
}

uninstall_k3s()
{
  echo "Uninstalling K3s"
  if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
    /usr/local/bin/k3s-uninstall.sh
  fi

  if [[ -f /usr/local/bin/k3s-agent-uninstall.sh ]]; then
    /usr/local/bin/k3s-agent-uninstall.sh
  fi
}

conf_k3s()
{
  echo "Configure K3s and kubectl"

  found=$(grep -x "source <(kubectl completion bash)" ~/.bashrc 2> /dev/null | wc -l)
  if [[ $found -eq 0 ]]; then
    echo "source <(kubectl completion bash)" >> ~/.bashrc
  fi

  found=$(grep -x "alias k=kubectl" ~/.bashrc 2> /dev/null | wc -l)
  if [[ $found -eq 0 ]]; then
    echo "alias k=kubectl" >> ~/.bashrc
  fi

  found=$(grep -x "complete -F __start_kubectl k" ~/.bashrc 2> /dev/null | wc -l)
  if [[ $found -eq 0 ]]; then
    echo "complete -F __start_kubectl k" >> ~/.bashrc
  fi

  found=$(grep -x "export KUBECONFIG=${KUBECONFIG_PATH}" ~/.bashrc 2> /dev/null | wc -l)
  if [[ $found -eq 0 ]]; then
    echo "export KUBECONFIG=${KUBECONFIG_PATH}" >> ~/.bashrc
  fi

  alias k=kubectl
  export KUBECONFIG="${KUBECONFIG_PATH}"
}

install_kubevirt()
{
  echo "Uninstalling KubeVirt"
  # deploy kubevirt operator
  kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KV_VERSION}/kubevirt-operator.yaml

  # deploy kubevirt CRD
  kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KV_VERSION}/kubevirt-cr.yaml

  # kubectl -n kubevirt wait kv/kubevirt --for condition=available --timeout 120s
}

uninstall_kubevirt()
{
  echo "Uninstalling KubeVirt"
  kubectl delete -n kubevirt kubevirt kubevirt --wait=true
  kubectl delete apiservices v1alpha3.subresources.kubevirt.io
  kubectl delete mutatingwebhookconfigurations virt-api-mutator
  kubectl delete validatingwebhookconfigurations virt-api-validator
  kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${KV_VERSION}/kubevirt-operator.yaml --wait=false
}

install_cdi()
{
  kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml

  kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-cr.yaml

  # kubectl -n cdi wait cdi/cdi --for condition=available --timeout 120s
}

uninstall_cdi()
{
  kubectl delete -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-cr.yaml

  kubectl delete -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml
}


# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
install_krew()
{
  echo "Installing krew"
  sudo apt-get install git

  cd "$(mktemp -d)" && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    KREW="krew-${OS}_${ARCH}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf "${KREW}.tar.gz" && \
    ./"${KREW}" install krew
}

uninstall_krew()
{
  echo "Uninstalling krew"
  rm -rf -- ~/.krew
}

config_krew()
{
  echo "Configure krew"

  found=$(grep -w "${KREW_PATH}" ~/.bashrc 2> /dev/null | wc -l)
  if [[ $found -eq 0 ]]; then
    echo "export PATH=\"${PATH}:${KREW_PATH}\"" >> ~/.bashrc
  fi

  export PATH="${PATH}:${KREW_PATH}"
}

install_virt_plugin()
{
  kubectl krew install virt
}

uninstall_virt_plugin()
{
  kubectl krew uninstall virt
}

undo_conf()
{
  temp=$(mktemp)
  cat ~/.bashrc | grep -v "source <(kubectl completion bash)" | grep -v "alias k=kubectl" | grep -v "complete -F __start_kubectl k" | grep -v "${KREW_PATH}" | grep -v "export KUBECONFIG=${KUBECONFIG_PATH}" > ${temp} && cp ${temp} ~/.bashrc
}

install_apps()
{
  check_sw_installed

  install_docker
  conf_usergroup

  install_k3s
  conf_k3s

  install_kubevirt
  install_cdi

  install_krew
  conf_krew
  install_virt_plugin

  echo ""
  warn "Please reboot system.."
}

uninstall_apps()
{
  uninstall_virt_plugin
  uninstall_krew
  uninstall_kubevirt
  uninstall_k3s
  uninstall_docker
  undo_conf

  echo ""
  warn "Please reboot system.."
}

command_exists()
{
  command -v "$@" > /dev/null 2>&1
}

usage() 
{
  echo ""
  echo "Usage: $0 <option>"
  echo "options:"
  echo "   -i  : Install Docker, K3s, KubeVirt, CDI, Krew, virt-plugin"
  echo "   -u  : Uninstall Docker, K3s, KubeVirt, CDI, Krew, virt-plugin"
  echo ""
}

clear
while getopts "iu" opt; do
    case "${opt}" in
        i) install_apps
           exit 0
           ;;
        u) uninstall_apps
           exit 0 
           ;;
    esac
done

usage
exit 0

# if [[ $1 = "install" ]]; then
#   install_apps
# elif [[ $1 = "uninstall" ]]; then
#   uninstall_apps
# elif [[ -z $1 ]]; then
#   usage
# else
#   usage
# fi