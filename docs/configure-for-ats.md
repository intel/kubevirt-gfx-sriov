## Enabling SR-IOV for an ATS dGPU

The following steps will guide you through the process of enabling SR-IOV for an ATS dGPU from Intel in a Kubernetes environment.


### Prerequisites

    System specifications:
        Minimum hardware requirements: A server with Ats Flex cards installed and configured. 
        Operating system: Ubuntu 22.04
    Software dependencies:
        Docker
        K8s, kubevirt and kubectl

### Steps:

0. Clone the repository: https://github.com/unrahul/applications.virtualization.kubevirt-gfx-sriov

Change the directory to repo parent dir `gfx-sriov/`:


```bash
cd gfx-sriov/
```

#### Step 1: Apply SR-IOV Manifests

Add the device to the Kubernetes namespace:

```bash
kubectl apply -f manifests/kubevirt-cr-gfx-sriov.yaml
```

This command applies the SR-IOV manifests to the Kubernetes cluster. The SR-IOV manifests are used to configure the SR-IOV support for the GPU device.

#### Step 2: Create a CDisk

Create a bootable disk image from an Ubuntu 22.04 ISO file by running the following script:

```bash
./gfx-sriov/scripts/buildcdisk.sh -i /home/intel/ubuntu-22.04.1-live-server-amd64.iso  -t docker.io/rahulunair/ubvm22:v0.1
```

This script creates a bootable disk image using the specified Ubuntu ISO file and tags it with the specified name and version. The bootable disk image is used to launch the virtual machine.

#### Step 3: Verify Image Availability

Check if the image is available locally:

```bash
docker images
```

#### Step 4: Push to Remote Repository

Push the image to a remote repository, for example, a personal repository:

```bash
docker push rahulunair/ubvm22:v0.1
```

#### Step 5: Apply the VM Manifest

To create the virtual machine, use the following command:

```bash
kubectl apply -k manifests/overlays/ubuntu22-install
```

This command applies the VM manifest to the Kubernetes cluster. The VM manifest is used to define the configuration of the virtual machine.

Check the status of the virtual machine and wait for a few minutes until it is created:

```bash
kubectl get vm
```

#### Step 6: Deploy the VNC Service

Deploy the VNC service with the following command:

```bash
kubectl apply -f manifests/virtvnc.yaml
```

This command deploys the VNC service to the Kubernetes cluster. The VNC service provides a graphical user interface for the virtual machine.


#### Step 7: Get the Cluster IP of Kubevirt

Get the cluster IP address of the kubevirt service:

```bash
kubectl get svc -n kubevirt
```

#### Step 8: Launch the VNC Server

You can now launch the VNC server using the external IP and continue the setup process:

```bash
http://<EXTERNAL-IP>:8001/?namespace=default
```


#### Step 9: Verify vGPU Availability

After creating the virtual machine, verify the availability of the vGPU by running the following command inside the virtual machine:

```bash
lspci | grep -i display
```

Output:

```bash
rahul@ubvmkubevirt:~$ lspci | grep -i display
05:00.0 Display controller: Intel Corporation Device 56c0 (rev 08)
```

With these steps, you should now have successfully enabled SR-IOV for an ATS dGPU from Intel in a Kubernetes environment.

### Final Steps

After enabling SR-IOV, configure the virtual machine with ATS DKMS modules and userspace libraries to utilize the vGPU. Setup instructions for this can be found [here](https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-jammy-dc.html).


Additionally, you can install Intel oneAPI toolkits by following the instructions [here](https://www.intel.com/content/www/us/en/develop/documentation/installation-guide-for-intel-oneapi-toolkits-linux/top/installation/install-using-package-managers/apt.html). To install PTI-gpu tools, clone the [repo](https://github.com/intel/pti-gpu) and follow the instructions in the Readme.




