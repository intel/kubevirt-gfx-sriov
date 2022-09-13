#!/bin/bash

KV_VERSION="v0.53.0"
CDI_VERSION="v1.48.1"
KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
KREW_PATH="/home/$USER/.krew/bin"

# helper functions
info()
{
  echo '[INFO] ' "$@"
}
warn()
{
  echo '[WARN] ' "$@" >&2
}
fatal()
{
  echo '[ERROR] ' "$@" >&2
  exit 1
}

install_k3s()
{
  info "Installing K3s"
  curl -sfL https://get.k3s.io | sh -s - --disable=traefik --write-kubeconfig-mode=644
}

uninstall_k3s()
{
  info "Uninstalling K3s"
  if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
    /usr/local/bin/k3s-uninstall.sh
  fi

  if [[ -f /usr/local/bin/k3s-agent-uninstall.sh ]]; then
    /usr/local/bin/k3s-agent-uninstall.sh
  fi
}

conf_k3s()
{
  info "Configuring K3s and kubectl"

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
}

unconf_k3s()
{
  info "Undo K3s and kubectl configuration"
  temp=$(mktemp)
  cat ~/.bashrc | grep -v "source <(kubectl completion bash)" | grep -v "alias k=kubectl" | grep -v "complete -F __start_kubectl k" | grep -v "export KUBECONFIG=${KUBECONFIG_PATH}" > $temp && cp $temp ~/.bashrc
}

install_kubevirt()
{
  info "Installing KubeVirt"
  # deploy kubevirt operator
  kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KV_VERSION}/kubevirt-operator.yaml

  # deploy kubevirt CRD
  kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KV_VERSION}/kubevirt-cr.yaml
}

uninstall_kubevirt()
{
  info "Uninstalling KubeVirt"
  kubectl delete -n kubevirt kubevirt kubevirt --wait=true
  kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${KV_VERSION}/kubevirt-operator.yaml --wait=false
}

install_cdi()
{
  info "Installing CDI"
  kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml
  kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-cr.yaml
}

uninstall_cdi()
{
  info "Uninstalling CDI"
  kubectl delete -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-cr.yaml
  kubectl delete -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml
}

# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
install_krew()
{
  info "Installing krew"

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
  info "Uninstalling krew"
  rm -rf -- ~/.krew
}

conf_krew()
{
  info "Configuring krew"

  found=$(grep -x "export PATH=\$PATH:$KREW_PATH" ~/.bashrc 2> /dev/null | wc -l)
  if [[ $found -eq 0 ]]; then
    echo "export PATH=\$PATH:$KREW_PATH" >> ~/.bashrc
  fi
}

unconf_krew()
{
  info "Undo krew configuration"
  temp=$(mktemp)
  cat ~/.bashrc | grep -v "export PATH=\$PATH:$KREW_PATH" > $temp && cp $temp ~/.bashrc
}

install_virt_plugin()
{
  info "Installing virt plugin"
  $KREW_PATH/kubectl-krew install virt
}

uninstall_virt_plugin()
{
  info "Uninstalling virt plugin"
  $KREW_PATH/kubectl-krew uninstall virt
}

command_exists()
{
  command -v "$@" > /dev/null 2>&1
}

become_superuser()
{
  SUDO=sudo
  if [ $(id -u) -eq 0 ]; then
    SUDO=
  fi
}

usage() 
{
  echo ""
  echo "Usage: $0 option [arguments]"
  echo "option:"
  echo "    -i  : Install [args]"
  echo "    -u  : Uninstall [args]"
  echo "    -h  : Help"
  echo "argument:"
  echo "     k  : K3s"
  echo "     v  : KubeVirt, CDI"
  echo "     w  : Krew, virt-plugin"
  echo "Example:"
  echo "  # Install K3s, KubeVirt, CDI, Krew, virt-plugin"
  echo "    $0 -ikvw"
  echo "  # Install Krew, virt-plugin"
  echo "    $0 -i w"
  echo "  # Uninstall KubeVirt, CDI"
  echo "    $0 -uv"
  echo ""
}

clear
[ $# -eq 0 ] && usage

# determine option entered
while getopts "i:u:hf" opt; do
  case "$opt" in
    i)
      OPT_INSTALL=true
      OPT_ARG=$OPTARG
      ;;
    u)
      OPT_UNINSTALL=true
      OPT_ARG=$OPTARG
      ;;
    h | *)
      usage
      exit 0
      ;;
  esac
done

# only one option allowed at a time
if [[ $OPT_INSTALL = true && $OPT_UNINSTALL = true ]]; then
  echo "$0: illegal to specify more than one option"
  usage
  exit 1
fi

# determine option arguments entered
index=0
while [[ $index -lt ${#OPT_ARG} ]]; do
  case "${OPT_ARG:$index:1}" in
    k)
      OPT_ARG_K3S=true
      ;;
    v)
      OPT_ARG_KUBEVIRT=true
      ;;
    w)
      OPT_ARG_KREW=true
      ;;
    *)
      echo "$0: invalid argument -- ${OPT_ARG:$index:1}"
      usage
      exit 1
      ;;
  esac
  index=$(( $index + 1 ))
done

# Option: install
if [[ $OPT_INSTALL = true && $OPT_ARG_K3S = true ]]; then
  if command_exists k3s; then
    warn 'The "k3s" command appears to already exist on this system'
    warn 'Skip "k3s" installation'
  else
    become_superuser
    install_k3s
    conf_k3s
  fi
fi

if [[ $OPT_INSTALL = true && $OPT_ARG_KUBEVIRT = true ]]; then
  if command_exists kubectl; then
    install_kubevirt
    install_cdi
  else
    fatal 'Can not find "kubectl" on this system. Abort "KubeVirt" installation'
  fi
fi

if [[ $OPT_INSTALL = true && $OPT_ARG_KREW = true ]]; then
  if command_exists kubectl; then
    install_krew
    conf_krew
    install_virt_plugin
  else
    fatal 'Can not find "kubectl" on this system. Abort "krew" installation'
  fi
fi

# Option: uninstall
if [[ $OPT_UNINSTALL = true && $OPT_ARG_KREW = true ]]; then
  if command_exists kubectl; then
    uninstall_virt_plugin
    uninstall_krew
    unconf_krew
  else
    warn 'The "kubectl" command does not exist on this system'
    warn 'Skip "krew" uninstallation'
  fi
fi

if [[ $OPT_UNINSTALL = true && $OPT_ARG_KUBEVIRT = true ]]; then
  if command_exists kubectl; then
    uninstall_cdi
    uninstall_kubevirt
  else
    warn 'The "kubectl" command does not exist on this system'
    warn 'Skip "KubeVirt" uninstallation'
  fi
fi

if [[ $OPT_UNINSTALL = true && $OPT_ARG_K3S = true ]]; then
  if command_exists k3s; then
    become_superuser
    uninstall_k3s
    unconf_k3s
  else
    warn 'The "k3s" command does not exist on this system'
    warn 'Skip "k3s" uninstallation'
  fi
fi