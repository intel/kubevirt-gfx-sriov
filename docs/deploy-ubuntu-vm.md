# Ubuntu 22.04 LTS  VM

In this document, we are going to explain how to install Ubuntu 22.04 virtual machine (VM) using **ISO** file and how to configure the VM to support GPU-accelerated workloads (eg: media transcoding, 3D rendering, AI inferencing) using Intel Graphics SR-IOV technology


## Prerequisites

* Appropriate [hardware][readme-getting-started]
* A fully [configured host][readme-getting-started] (with Graphics SR-IOV)
* A working Kubernetes cluster
* [Ubuntu 22.04 desktop ISO.](https://releases.ubuntu.com/22.04/) In this example we are using Ubuntu 22.04 desktop
* [MR2 release package](https://cdrdv2.intel.com/v1/dl/getContent/738824/738826?filename=ADL-S_KVM_MultiOS_MR2.zip) (ADL-S_KVM_MultiOS_MR2.zip )
* [Linux kernel archive][readme-prerequisites] (kernel.tgz)


## Preparation

Prior to installing Ubuntu 22.04 VM, we'll create two *container disk images* (cdisk) to simplify the installation process. The cdisk images will contain:
1. Ubuntu 22.04 ISO file

2. Linux kernel archive and MR2 release package files

See steps below for the cdisk preparation:

1. Download Ubuntu 22.04 ISO and MR2 release package files

2. Create and push ***ubuntu22-iso-cdisk*** image to public or private repository of your choice

   *Note: Specifying the `buildcdisk.sh -p` option will instruct **docker** to push cdisk image to the repository. Make sure to login to your repository by running `docker login <repository>` prior to running command below. Docker can be installed by running `sudo apt install docker.io`. Get help on `buildcdisk.sh` by running `buildcdisk.sh -h`*

   *Note: [Docker Hub](https://hub.docker.com/) is an example public container repository or registry you can sign up if you don't have a private repository setup*

   ```sh
   cd applications.virtualization.kubevirt-gfx-sriov

   ./scripts/buildcdisk.sh -p -i <ubuntu22-iso-filepath> -t <repository>/ubuntu22-iso-cdisk

   docker images
   ```
   Output:
   ```sh
   REPOSITORY                        TAG       IMAGE ID       CREATED          SIZE
   <repository>/ubuntu22-iso-cdisk   latest    d72a9dde0409   16 minutes ago   3.65GB
   ```

3. Create and push ***linux-softwaredrv-iso-cdisk*** image to the repository. Create a temporary folder and move Linux kernel archive and MR2 release package files to the folder
   ```sh
   tempdir=$(mktemp -d)

   mv <files> $tempdir

   ./scripts/buildcdisk.sh -p -d $tempdir -t <repository>/linux-softwaredrv-iso-cdisk

   docker images
   ```
   Output:
   ```sh
   REPOSITORY                                 TAG       IMAGE ID       CREATED          SIZE
   <repository>/linux-softwaredrv-iso-cdisk   latest    15d23d3934d8   25 minutes ago   1.18GB
   ```

   *Note: We only use docker to create and upload cdisk images to the repository. However, for deployment, we use **crictl** to manage containers on the host, eg: `sudo crictl images`, `sudo crictl pull <repo/image>`*

5. [Optional] Once cdisk images have been upload to the repository, you can delete all docker images on the host to free up storage space
   ```sh
   docker rmi <repository>/ubuntu22-iso-cdisk:latest

   docker rmi <repository>/linux-softwaredrv-iso-cdisk:latest

   docker system prune
   ```


## Installation

Proceed with the VM installation steps below:

1. Before starting Ubuntu VM installation, make sure all the **volumes > containerDisk > image** specified in [vm_disks_volumes.yaml][vmdiskvolume] are set to the correct values, eg: ***image: docker.io/myrepo/ubuntu22-iso-cdisk***. Executing commands below on the host will invoke the following actions:
     * Create an empty persistent volume on the host
     * Launch VM with Ubuntu ISO and software driver ISO files attached as CD-ROMs
     * Enable SSH service

   ```sh
   kubectl apply -k manifests/overlays/ubuntu22-install
   ```

2. Wait for *STATUS*=***Running*** and *READY*=***True***

   *Note: Please wait for the completion of the container disks download from the repository. This will take a while depending on the container disks size*

   ```sh
   kubectl get vm
   ```
   Output:
   ```sh
   NAME             AGE   STATUS    READY
   ubuntu22-vm      13h   Running   True
   ```

3. Deploy ***virtvnc*** service to allow VNC connection to the VM
   ```sh
   kubectl apply -f manifests/virtvnc.yaml

   kubectl get svc -n kubevirt
   ```
   Output:
   ```sh
   NAME            TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
   virtvnc         LoadBalancer   10.43.96.13    10.158.76.244   8001:31507/TCP   13h
   ```

4. Launch a web browser on the host and navigate to the url below. Press the ***VNC*** button to initiate VNC session to the VM

   *Note: Both the CLUSTER-IP and EXTERNAL-IP will work. You can also change the namespace value to reflect your VM's namespace*

   ```sh
   http://<EXTERNAL-IP>:8001/?namespace=default
   ```
   <img src=./media/virtvnc2.png width="80%">

5. Follow the instructions on the Ubuntu Install menu to begin the setup process

   <img src=./media/ubuntusetup.png width="80%">

   <img src=./media/ubuntublank.png width="80%">

6. After Ubuntu VM is successfully installed, run commands below in the VM to update and upgrade all software packages and install OpenSSH Server

   Ubuntu VM:
   ```sh
   sudo apt update && sudo apt upgrade -y

   sudo apt install openssh-server
   ```
   Host:
   ```sh
   kubectl get svc
   ```
   Output:
   ```sh
   NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
   ubuntu22-ssh   NodePort    10.43.135.205   <none>        22:32128/TCP   15h
   ```

7. From the host, remote into the VM using SSH client and copy Linux kernel archive and MR2 release package files to $HOME folder on VM

   Host:
   ```sh
   ssh <vmuser>@<CLUSTER-IP>

   lsblk
   ```
   Output:
   ```sh
   sr0     11:0    1   3.4G  0 rom  /media/vmuser/Ubuntu 22.04 LTS amd64
   sr1     11:1    1   1.1G  0 rom  /media/vmuser/CDROM
   vda    252:0    0    50G  0 disk
   ├─vda1 252:1    0   512M  0 part /boot/efi
   └─vda2 252:2    0  49.5G  0 part /

   ```
   In this example, the *linux-softwaredrv-iso-cdisk* is mounted at /media/vmuser/CDROM on the VM
   ```sh
   mkdir $HOME/build

   sudo cp /media/vmuser/CDROM/* $HOME/build
   ```
8. Extract all the required files to prepare for software and kernel installation
   ```sh
   cd $HOME/build

   tar -xzvf kernel.tgz --strip-components=1

   unzip mr2_rele.zip

   unzip MR2_release/sriov_patches.zip -d $HOME/build

   unzip -jo MR2_release/ubuntu_kvm_multios_scripts.zip -d $HOME/build

   chmod +x *.sh
   ```

9. Download and install i915 firmware files, install Linux kernel and update grub settings

   ```sh
   cd $HOME/build

   sudo ./sriov_setup_kernel.sh
   ```

   Press 'y' to reboot the VM. After reboot, remote into VM from the host and check the version of the installed kernel
   ```sh
   ssh <vmuser>@<CLUSTER-IP>

   uname -r
   ```
   Output:
   ```sh
   5.15.44-lts2021-iotg
   ```

10. Run commands below to install userspace libraries and tools. If prompted, answer 'y' to proceed with the installation
    ```sh
    cd $HOME/build

    sed -i 's/reboot_required=0/reboot_required=0\nGUEST_SETUP=1/' sriov_setup_ubuntu.sh

    sudo ./sriov_setup_ubuntu.sh
    ```

11. Shutdown the Ubuntu VM and run the following command to stop the *ubuntu22-vm* Virtual Machine resource before moving to **Deployment** stage

    ```sh
    kubectl virt stop ubuntu22-vm

    kubectl get vm
    ```
    Output:
    ```sh
    NAME             AGE   STATUS    READY
    ubuntu22-vm      17h   Stopped   False
    ```

## Deployment

1. After completing the Ubuntu VM setup, we can proceed to deploy the VM with an assigned graphics virtual function (VF) resource. This will enable GPU acceleration capability for the VM

   *Note: To view all the composed resources without applying them, run `kubectl kustomize manifests/overlays/ubuntu22-deploy`*

   ```sh
   kubectl apply -k manifests/overlays/ubuntu22-deploy
   ```

2. Make sure GPU acceleration is enabled
   ```sh
   ```

3. Congratulation! You have completed the setup

   *Note: You can start or stop the VM anytime using the following command: `kubectl virt start ubuntu22-vm` and `kubectl virt stop ubuntu22-vm`*

[readme]: ../README.md
[readme-getting-started]: ../README.md#getting-started
[readme-prerequisites]: ../README.md#prerequisites
[virtvnc2]: ./media/virtvnc2.png
[ubuntusetup]: ./media/ubuntusetup.png
[ubuntublank]: ./media/ubuntublank.png
[vmdiskvolume]: ../manifests/overlays/ubuntu22-install/vm_disks_volumes.yaml