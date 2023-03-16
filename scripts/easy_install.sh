#!/bin/bash

set -e

trap 'rm -rf "$WORK_DIR"' EXIT

command_exists()
{
  command -v "$@" > /dev/null 2>&1
}

clear
echo ""
read -p "This installer will overwrite existing software packages, do you want to continue? [y/n]: " res
if [[ $res != y ]]; then
  echo "Abort installation"
  exit 0
fi

# check dependency
if ! command_exists git; then
  sudo apt install git -y
fi

WORK_DIR=$(mktemp -d)
pushd $WORK_DIR

REPO=gfx-sriov

# clone repo
git clone https://github.com/intel/kubevirt-gfx-sriov.git $REPO

if [[ ! -d $WORK_DIR/$REPO ]]; then
  echo "Fail to clone repository"
fi

# Add access to AppArmor libvirtd profile
sudo cp $WORK_DIR/$REPO/apparmor/usr.sbin.libvirtd /etc/apparmor.d/local/ && \
sudo systemctl reload apparmor.service

# install k3s, kubevirt, CDI, Krew, virt-plugin
$WORK_DIR/$REPO/scripts/setuptools.sh -ikvw

kubectl apply -f $WORK_DIR/$REPO/manifests/kubevirt-cr-gfx-sriov.yaml

# install systemd unit
sudo mkdir -p /var/vm/scripts

sudo cp $WORK_DIR/$REPO/scripts/configvfs.sh /var/vm/scripts/

sudo chmod +x /var/vm/scripts/configvfs.sh

sudo cp $WORK_DIR/$REPO/systemd/gfx-virtual-func.service /etc/systemd/system/

sudo systemctl daemon-reload

sudo systemctl start gfx-virtual-func.service

sudo systemctl enable gfx-virtual-func.service

echo ""
read -p "Reboot is required, do you want to reboot NOW? [y/N]" res
if [[ $res = y ]]; then
  sudo reboot
else
  echo "Please reboot the system for change to take effect"
fi

popd
rm -rf $WORK_DIR