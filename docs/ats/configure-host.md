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

Step 9: Restart

After completing all of the above steps, you will need to restart your machine in order for the changes to take effect.
