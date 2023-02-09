This guide will provide detailed steps on how to enable SR-IOV (Single Root I/O Virtualization) on a machine running Ubuntu 22.04. SR-IOV is a technique used in virtualization to directly assign a PCI Express (PCIe) device to a virtual machine (VM). This will allow the virtual machine to have direct access to the device's resources, such as its memory, interrupt handling and I/O, resulting in lower latency and improved performance.

Before we begin, it is important to note that this guide assumes that you have an ATS dGPU (Intel Flex series dGPU) and that you have already enabled Vt-d (Intel Virtualization Technology for Directed I/O), SR-IOV, and VMX in your BIOS.

Step 1: Install the Required Kernel

To use SR-IOV, you will need to install a specific kernel version. The version you need to install is linux-image-5.15.0-48-generic. You can install it using the following command:

```bash
sudo apt-get install linux-image-5.15.0-48-generic
```

Step 2: Setup dGPU Drivers

Next, you will need to setup the drivers for your ATS dGPU. You can follow the instructions provided in the official dGPU installation guide for Ubuntu, which can be found at the following link: https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-jammy-dc.html

Step 3: Install libvirt Tools

In order to use SR-IOV, you will need to install the libvirt tools, which are a set of tools used for virtualization:

```bash
apt install qemu-kvm ovmf libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager
```

#### Step 4: Add User to Group Render

Next, you will need to add the user that will be using SR-IOV to the group 'render':

sudo adduser [user name] render

#### Step 5: Set P-state Drivers to Performance Mode

```bash
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

#### Step 6: Modify Grub Configuration

You will need to modify the grub configuration file (/etc/default/grub) in order to specify the number of virtual functions (vgpus) that you want to use. For the ATS 170w, the maximum number of vgpus is 31, I am using 4. You will also need to add the following lines to the grub configuration file:

```bash
GRUB_CMDLINE_LINUX="i915.max_vfs=4 intel_iommu=on iommu=pt"
```

#### Step 7: Set Default Kernel 

**Note:** if your default kernel is 5.15.0-xx-generic, you could try to see if SR-IOV works without forcing 5.15.0.-48 to be the default, if not set the GRUB_DEFAULT to be this kernel.

In order to make linux-image-5.15.0-48-generic the default kernel, you will need to add the following line to the grub configuration file:

```bash
GRUB_DEFAULT="gnulinux-advanced-251d71d4-950e-4c83-89e8-1e7b4dfea317>gnulinux-5.15.0-48-generic-advanced-251d71d4-950e-4c83-89e8-1e7b4dfea317"
```

THE UUID (251d7xxxx-) for your system might be different, check your existing grub config to identify the correct UUID and set it. 

#### Step 8: Update Grub

Finally, you will need to update the grub configuration by running the following command:

```bash
update-grub
```

#### Step 9: Restart

After completing all of the above steps, you will need to restart your machine in order for the changes to take effect.

### Validation

we need to validate the host using virt-host-validate , the output should look like :

```
  QEMU: Checking for hardware virtualization                                 : PASS
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : PASS
  QEMU: Checking if device /dev/net/tun exists                               : PASS
  QEMU: Checking for cgroup 'cpu' controller support                         : PASS
  QEMU: Checking for cgroup 'cpuacct' controller support                     : PASS
  QEMU: Checking for cgroup 'cpuset' controller support                      : PASS
  QEMU: Checking for cgroup 'memory' controller support                      : PASS
  QEMU: Checking for cgroup 'devices' controller support                     : PASS
  QEMU: Checking for cgroup 'blkio' controller support                       : PASS
  QEMU: Checking for device assignment IOMMU support                         : PASS
  QEMU: Checking if IOMMU is enabled by kernel                               : PASS
  QEMU: Checking for secure guest support                                    : WARN (Unknown if this platform has Secure Guest support)
   LXC: Checking for Linux >= 2.6.26                                         : PASS
   LXC: Checking for namespace ipc                                           : PASS
   LXC: Checking for namespace mnt                                           : PASS
   LXC: Checking for namespace pid                                           : PASS
   LXC: Checking for namespace uts                                           : PASS
   LXC: Checking for namespace net                                           : PASS
   LXC: Checking for namespace user                                          : PASS
   LXC: Checking for cgroup 'cpu' controller support                         : PASS
   LXC: Checking for cgroup 'cpuacct' controller support                     : PASS
   LXC: Checking for cgroup 'cpuset' controller support                      : PASS
   LXC: Checking for cgroup 'memory' controller support                      : PASS
   LXC: Checking for cgroup 'devices' controller support                     : PASS
   LXC: Checking for cgroup 'freezer' controller support                     : FAIL (Enable 'freezer' in kernel Kconfig file or mount/enable cgroup controller in your system)
   LXC: Checking for cgroup 'blkio' controller support                       : PASS
   LXC: Checking if device /sys/fs/fuse/connections exists                   : PASS
```

Here IOMMU, kvm should not FAIL. If IOMMU is shown as `FAIL`, check the BIOS settings.

### Configure VFIO devices for SR-IOV by updating sysfs

If `virt-host-validate` command output looks good, move the configuration scripts provided [here](https://github.com/unrahul/applications.virtualization.kubevirt-gfx-sriov/tree/main/scripts) to `/var/vm/scripts`.

Move the systemd unit file for SR-IOV  `gfx-virtual-func.service` to `/etc/systemd/system`. Enable and start the service. 

```bash
sudo systemctl enable gfx-virtual-func
sudo systemctl start gfx-virtual-func
```

Check the status of the service:

```bash
udo systemctl status gfx-virtual-func.service 
● gfx-virtual-func.service - Intel Graphics SR-IOV Virtual Function Manager
     Loaded: loaded (/etc/systemd/system/gfx-virtual-func.service; enabled; vendor preset: enabled)
     Active: active (exited) since Wed 2023-02-08 11:14:14 PST; 6h ago
    Process: 1823 ExecStart=/bin/bash /var/vm/scripts/configvfs.sh -e (code=exited, status=0/SUCCESS)
   Main PID: 1823 (code=exited, status=0/SUCCESS)
        CPU: 2.050s

--- systemd[1]: Starting Intel Graphics SR-IOV Virtual Function Manager...
bash[1823]: Device: /sys/bus/pci/devices/0000:4d:00.0
bash[1823]: Total VF: 4
bash[1823]: ID: 0x8086 0x56c0
bash[1823]: VF enabled: 4
systemd[1]: Finished Intel Graphics SR-IOV Virtual Function Manager
```

As seen above,  4 SR-IOV devices (4vGPUS or Virtual Functions) have been enabled by writing into the pci sysfs for `display`, we can list out SR-IOV devices have been created by using:

```bash
lspci | grep -i display
4d:00.0 Display controller: Intel Corporation Device 56c0 (rev 08)
4d:00.1 Display controller: Intel Corporation Device 56c0 (rev 08)
4d:00.2 Display controller: Intel Corporation Device 56c0 (rev 08)
4d:00.3 Display controller: Intel Corporation Device 56c0 (rev 08)
4d:00.4 Display controller: Intel Corporation Device 56c0 (rev 08)
```

Now we have the host setup and ready. You can use libvirt tools like `virsh` or kubevirt and k8s to deploy and manage virtual machines withSR-IOV support.
