<a name="win10-vm-top"></a>

# Microsoft Windows 10 VM

This document details steps to install Windows 10 virtual machine (VM) using **ISO** file and how to configure the VM to support GPU-accelerated workloads (eg: media transcoding, 3D rendering, AI inferencing) using Intel Graphics SR-IOV technology


## Prerequisites

* Appropriate [hardware][readme-getting-started]
* A fully [configured host][readme-getting-started] (with Graphics SR-IOV)
* A working Kubernetes cluster
* Windows 10 ISO. In this example we are using Windows 10 Enterprise version 21H2
* [Windows 10 Cumulative Update](https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/updt/2022/04/windows10.0-kb5011831-x64_8439b4066bdee925aa5352f9ed286ecfa94ce545.msu) version 21H2 (windows10.0-kb5011831-x64*.msu)
* [Intel Graphics Driver](https://cdrdv2.intel.com/v1/dl/getContent/736997/737084?filename=win64.zip) version MR2 101.3111 (win64.zip)


## Preparation

Before installing Windows 10 VM, create two *container disk images* (cdisk) to simplify the installation process. The cdisk images will contain:
1. Windows 10 ISO file

2. Intel Graphics Driver and Windows 10 update files

See steps below for the cdisk preparation:

1. Download Windows 10 ISO, Windows 10 update and Intel Graphics Driver installer files

2. Create and push ***win10-iso-cdisk*** image to public or private repository of your choice

   *Note: Specifying the `buildcdisk.sh -p` option will instruct **docker** to push cdisk image to the repository. Make sure to login to your repository by running `docker login <repository>` prior to running command below. Docker can be installed by running `sudo apt install docker.io && sudo usermod -aG docker $USER && newgrp docker`. Get help on `buildcdisk.sh` by running `buildcdisk.sh -h`*

   *Note: [Docker Hub](https://hub.docker.com/) is an example public container repository or registry you can sign up if you don't have a private repository setup*

   ```sh
   cd kubevirt-gfx-sriov

   ./scripts/buildcdisk.sh -p -i <win10-iso-filepath> -t <repository>/win10-iso-cdisk

   docker images
   ```
   Output:
   ```sh
   REPOSITORY                      TAG       IMAGE ID       CREATED          SIZE
   <repository>/win10-iso-cdisk    latest    c28c1bc0e119   19 minutes ago   4.85GB

   ```
3. Create and push ***win-softwaredrv-iso-cdisk*** image to the repository. Create a temporary folder and copy Windows 10 update and Intel Graphics Driver installer files into the folder
   ```sh
   tempdir=$(mktemp -d)

   cp windows10.0-kb5011831-x64*.msu $tempdir

   cp win64.zip $tempdir

   ./scripts/buildcdisk.sh -p -d $tempdir -t <repository>/win-softwaredrv-iso-cdisk

   rm -rf $tempdir

   docker images
   ```
   Output:
   ```sh
   REPOSITORY                                TAG       IMAGE ID       CREATED          SIZE
   <repository>/win-softwaredrv-iso-cdisk    latest    39529553d359   35 minutes ago   1.39GB

   ```

   *Note: We only use docker to create and upload cdisk images to the repository. However, for deployment, we use **crictl** to manage containers on the host, eg: `sudo crictl images`, `sudo crictl pull <repo/image>`*

4. [Optional] Once the cdisk images are uploaded to the repository, you can delete all docker images on the host to free up storage space
   ```sh
   docker rmi <repository>/win10-iso-cdisk:latest

   docker rmi <repository>/win-softwaredrv-iso-cdisk:latest

   docker system prune
   ```

<p align="right">(<a href="#win10-vm-top">back to top</a>)</p>

## Installation

Proceed with the VM installation steps below:

1. Before starting Windows VM installation, make sure all the **volumes > containerDisk > image** specified in [vm_disks_volumes.yaml][vmdiskvolume] are set to the correct values, eg: ***image: docker.io/myrepo/win10-iso-cdisk***. Executing commands below on the host will invoke the following actions:
     * Create an empty persistent volume on the host
     * Launch VM with Windows ISO and software driver ISO files attached as CD-ROMs
     * Enable SSH and RDP services

   *Note: To view all the composed resources without applying them, run `kubectl kustomize manifests/overlays/win10-install`*

   ```sh
   kubectl apply -k manifests/overlays/win10-install
   ```

2. Wait for *STATUS*=***Running*** and *READY*=***True***

   *Note: Please wait for the completion of the container disks download from the repository. This will take a while depending on the container disks size*

   ```sh
   kubectl get vm
   ```
   Output:
   ```sh
   NAME          AGE   STATUS    READY
   win10-vm      12h   Running   True
   ```

3. Deploy ***virtvnc*** service to allow VNC connection to the VM
   ```sh
   kubectl apply -f manifests/virtvnc.yaml

   kubectl get svc -n kubevirt
   ```
   Output:
   ```sh
   NAME            TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
   virtvnc         LoadBalancer   10.43.96.13    10.158.76.244   8001:31507/TCP   12h
   ```

4. Launch a web browser on the host or on a remote client and navigate to the url below. Press the ***VNC*** button to initiate VNC session to the VM

   *Note: Both the CLUSTER-IP and EXTERNAL-IP will work. You can also change the namespace value to reflect your VM's namespace*

   ```sh
   http://<EXTERNAL-IP>:8001/?namespace=default
   ```
   <img src=./media/virvnc.png width="80%">

5. Follow the instructions on the Windows Setup menu to begin the setup process

   <img src=./media/winsetup1.png width="80%">

6. In the event that the Windows Setup cannot find any target drive to install Windows, press ***Load driver*** and navigate to *virtio-win-x-y-z* drive -> select *viostor\w10\amd64* folder -> click *OK* to begin storage driver installation

   <img src=./media/winsetup4.png width="80%">
   <img src=./media/winsetup6.png width="80%">
   <img src=./media/winsetup7.png width="80%">

7. After Windows VM is successfully installed, launch VM's *Windows Device Manager* and proceed to install the corresponding virtio drivers for all the devices with missing drivers 
     * Etherner Controller > *E:\NetKVM\w10\amd64*
     * PCI Device > *E:\Balloon\w10\amd64*
     * PCI Simple Communication Controller > *E:\vioserial\w10\amd64*
     * SCSI Controller > *E:\vioscsi\w10\amd64*
     
   <img src=./media/winblank.png width="80%">
   <img src=./media/devicemgr.png width="80%">

   ***Note: If operating behind corporate firewall, setup the proxy settings.*** In this example, we'll show you how to enable and setup manual proxy, Click *Start* > type *change proxy settings* > turn **Off** all options under **Automatic proxy setup** > turn **On** *Use a proxy server* option under **Manual proxy setup** > enter *\<proxy-server-url>* in *Address* and *\<proxy-server-port>* in *Port* edit boxes

8. At this point, you have the option to enable remote desktop service on the VM to allow remote client to access the VM using RDP connection. To enable remote desktop service on the VM, go to *Settings -> Remote desktop settings -> turn **On** Enable Remote Desktop*

   On the host, run the command below to get the EXTERNAL-IP address of the RDP service for the VM

   ```sh
   kubectl get svc
   ```
   Output:
   ```sh
   NAME           TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
   win10-rdp      LoadBalancer   10.43.151.117   10.158.76.244   3389:31815/TCP   13h
   ```
   On the remote client, use RDP client application *Remote Desktop Connection* or *Remmina* to initiate RDP connection to the VM by connecting to \<EXTERNAL-IP> retrieve from `kubectl get svc`

9. Copy Intel Graphics Driver and Windows 10 update files from the CDROM drive to Windows desktop. Launch Windows 10 update installer and make sure Windows version is updated as shown below:

   *Note: Windows update will take about 30-40 minutes. Intel Graphics Driver installation will be carried out at [Deployment][deployment] step 2*

   <img src=./media/winver2.png width="55%">

10. [Optional] To enable OpenSSH Server on the Windows VM, launch *Apps and Features* -> *Optional features* -> *Add a feature* > type *ssh* in search window > select *OpenSSH Server* > click *Install*. After OpenSSH Server is installed, enable the service by launching *services* -> click *OpenSSH SSH Server* -> set *Startup type=Automatic* -> click *Start* & *OK*

    <img src=./media/sshsvc.png width="90%">

    On the host, run the command below to get the CLUSTER-IP of the SSH service for the VM
    ```sh
    kubectl get svc
    ```
    Output:
    ```sh
    NAME           TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
    win10-ssh      NodePort       10.43.5.35      <none>          22:31752/TCP     13h
    ```
    From the host, connect to the VM OpenSSH server
    ```sh
    ssh <vmuser>@<CLUSTER-IP>
    ```

11. Shutdown the Windows VM and run the command below to stop the *win10-vm* Virtual Machine resource before moving to **Deployment** stage

    ```sh
    kubectl virt stop win10-vm

    kubectl get vm
    ```
    Output:
    ```sh
    NAME          AGE   STATUS    READY
    win10-vm      15h   Stopped   False
    ```

<p align="right">(<a href="#win10-vm-top">back to top</a>)</p>

## Deployment

1. After completing the Windows VM setup, we can proceed to deploy the VM with an assigned graphics virtual function (VF) resource. This will enable GPU acceleration capability for the VM 

   *Note: To view all the composed resources without applying them, run `kubectl kustomize manifests/overlays/win10-deploy`*

   ```sh
   kubectl apply -k manifests/overlays/win10-deploy
   ```
2. Unzip and execute Intel Graphics Driver installer on the Windows desktop: *Desktop\win64\Installer.exe*

   *Note: Refer to the [Installation][installation] step 9 for the location of the Intel Graphics Driver installer*

   <img src=./media/gfxdrvinstall.png width="80%">

3. Make sure Intel Graphics Driver is successfully installed

   <img src=./media/gfxdrv.png width="80%">

4. Congratulation! You have completed the setup

   *Note: You can start or stop the VM anytime using the following command: `kubectl virt start win10-vm` and `kubectl virt stop win10-vm`*

   <img src=./media/youtube.png width="80%">

<p align="right">(<a href="#win10-vm-top">back to top</a>)</p>

[readme]: ../README.md
[readme-getting-started]: ../README.md#getting-started
[deployment]: #deployment
[installation]: #installation
[virtvnc]: ./media/virvnc.png
[winsetup1]: ./media/winsetup1.png
[winsetup4]: ./media/winsetup4.png
[winsetup6]: ./media/winsetup6.png
[winsetup7]: ./media/winsetup7.png
[winblank]: ./media/winblank.png
[devicemgr]: ./media/devicemgr.png
[winver2]: ./media/winver2.png
[sshsvc]: ./media/sshsvc.png
[gfxdrvinstall]: ./media/gfxdrvinstall.png
[gfxdrv]: ./media/gfxdrv.png
[youtube]: ./media/youtube.png
[vmdiskvolume]: ../manifests/overlays/win10-install/vm_disks_volumes.yaml