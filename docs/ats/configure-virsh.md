## Deploying a Linux Virtual Machine with Intel vGPUs and SR-IOV

This guide outlines the steps required to set up a Linux virtual machine (VM) that leverages Intel virtual GPUs (vGPUs) with SR-IOV enabled.

### Prerequisites

Before proceeding, ensure that the following tools are installed on your system:

```bash
sudo apt-get install socat autoconf  qemu-kvm ovmf  libvirt-daemon-system libvirt-clients bridge-utils virtinst
```

### Get an OS iso file

Here, I am using Ubuntu 22.04 as an example:

```bash
wget https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso
```

### Create a vm using virt-install

```bash
virt-install --name ubvm   --video=qxl  --ram  8096 --disk pool=default,size=40,bus=virtio,format=qcow2 --vcpus 8 --cpu host-passthrough --os-type linux  --network network:default  --console pty,target_type=serial --location ubuntu-22.04.1-live-server-amd64.iso  --extra-args console=ttyS0 --force --debug
```

### Setup the VM

Once `virt-install` brings up the OS, follow through and complete the installation by logging into the VM console:

```bash
virsh console ubvm
```

After setup is complete exit out of the VM and shutdown the VM:

```bash
virsh destroy ubvm
```

### Add PCIE pass through of the VF(vGPU to the VM)

1. Get the PCIE address of the virtual function using `lspci`:

```bash
lspci | grep -i display
4d:00.0 Display controller: Intel Corporation Device 56c0 (rev 08)
4d:00.1 Display controller: Intel Corporation Device 56c0 (rev 08)
4d:00.2 Display controller: Intel Corporation Device 56c0 (rev 08)
4d:00.3 Display controller: Intel Corporation Device 56c0 (rev 08)
4d:00.4 Display controller: Intel Corporation Device 56c0 (rev 08)
```

As we have created 4 VF from the Physical GPU, we can see 5 devices listed here. The one with the address
`4d:00.0` is the Physical device, the others are the VF (Virtual Functions or vGPUS).

Attach the pcie device to the VM:

```bash
virt-xml ubvm --add-device --hostdev 4d:00.1,driver.name=vfio
```

We are using the `VFIO` driver to pass the virtualized GPU to the VM.

Once this is successful, start the vm using virsh and console into it:

```bash
virsh start ubvm
virsh console ubvm
```

Once you are inside the device, you can use `lspci` to check if the device is visible. 

```bash
rahul@ubvm2:~$ lspci | grep -i display
07:00.0 Display controller: Intel Corporation Device 56c0 (rev 08)
```

The `07:00.0` is the virtual PCIE address provided to the device by libvirt.

Now you can install the kernel modules and usermod drivers as provided in the steps [here](https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-jammy-arc.html?utm_source=pocket_mylist) to utilize the vGPU from the VM.


