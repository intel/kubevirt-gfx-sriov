# Microsoft Windows 10 VM

In this document, we are going explain how to install Windows 10 virtual machine (VM) using **ISO** file and how to configure the VM to support GPU-accelerated workloads (eg: media transcoding, 3D rendering, AI inferencing) using Intel Graphics SR-IOV technology


## Prerequisites

* Appropriate [hardware][readme]
* A fully [configured host][readme] (with Graphics SR-IOV)
* A working Kubernetes cluster
* Windows 10 ISO. In this example we are using Windows 10 Enterprise version 21H2
* [Windows 10 Cumulative Update](https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/updt/2022/04/windows10.0-kb5011831-x64_8439b4066bdee925aa5352f9ed286ecfa94ce545.msu) (version 21H2)
* [Intel Graphics Driver](https://cdrdv2.intel.com/v1/dl/getContent/736997/737084?filename=win64.zip) (version MR2 101.3111)


## Preparation

Prior to installing Windows 10 VM, we'll create two *container disks* to simplify the installation process. The *container disks* will contain:
1. Windows 10 ISO file

2. Intel Graphics Driver and Windows 10 update files

See steps below for the *container disks* preparation:

1. Download Windows 10 ISO, Windows 10 update and Intel Graphics Driver installer files

2. Create *win10-iso-cdisk* 
   ```sh
   cd applications.virtualization.kubevirt-gfx-sriov
   ```

3. Create *win-software-drv-iso-cdisk*
   ```sh
   ...
   ```

4. Check container images 
   ```sh
   sudo crictl images
   ```
   Output:
   ```sh
   IMAGE                             TAG                 IMAGE ID            SIZE
   ../win10-iso-cdisk                latest              2ba64909efd0d       5.23GB
   ../win-software-drv-iso-cdisk     latest              6d315a9294be1       2.01GB
   ```

5. Push the *container disks* to private or public registry of your choice
   ```sh
   ...
   ```


## Installation

Proceed with the VM installation steps below:

1. Starting Windows VM installation. Executing commands below on the host will invoke the following actions:
     * Create an empty persistent volume on the host
     * Launch VM with Windows ISO and software driver ISO files attached as CD-ROMs
     * Enable SSH and RDP services     

   *Note: To view all the composed resources without applying them, run `kubectl kustomize manifests/overlays/win10-install`*

   ```sh
   kubectl apply -k manifests/overlays/win10-install
   ```
2. Wait for  *STATUS*=***Running*** and *READY*=***True***

   *Note: Please wait for the completion of the container disks download from the registry. This will take a while depending on the container disks size*

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

4. Launch a web browser on the host and navigate to the url below. Press the ***VNC*** button to initiate VNC session to the VM

   *Note: Both the CLUSTER-IP and EXTERNAL-IP will work*

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

8. At this point, you have the option to enable remote desktop service on the VM to allow remote client to access the VM using RDP connection. To enable remote desktop service on the VM, go to *Settings -> Remote desktop settings -> Enable Remote Desktop*

   On the host, run command below to get the EXTERNAL-IP address of the RDP service for the VM

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

   *Note: Windows update will take about 30-40 minutes. Intel Graphics Driver installation will be carried out at later **Deployment** stage* 

   <img src=./media/winver2.png width="55%">

10. [Optional] To enable OpenSSH Server on the Windows VM, launch *Apps and Features* -> *Optional features* -> *Add a feature* > type *ssh* in search window > select *OpenSSH Server* > click *Install*. After OpenSSH Server is installed, enable the service by launching *services* -> click *OpenSSH SSH Server* -> set *Startup type=Automatic* -> click *Start* & *OK*

    <img src=./media/sshsvc.png width="90%">

    On the host, run command below to get the CLUSTER-IP of the SSH service for the VM
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
    ssh <user>@<CLISTER-IP>
    ```

11. Shutdown the Windows VM and run the following command to stop the *win10-vm* Virtual Machine resource to prepare for the **Deployment** stage

    ```sh
    kubectl virt stop win10-vm

    kubectl get vm
    ```
    Output:
    ```sh
    NAME          AGE   STATUS    READY
    win10-vm      15h   Stopped   False
    ```


## Deployment

1. After completing the Windows VM setup, we can proceed to deploy the VM with an assigned graphics virtual function (VF) resource. This will enable GPU acceleration capability for the VM 

   *Note: To view all the composed resources without applying them, run `kubectl kustomize manifests/overlays/win10-deploy`*

   ```sh
   kubectl apply -k manifests/overlays/win10-deploy
   ```
2. Unzip and execute Intel Graphics Driver installer on the Windows desktop: *Desktop\win64\Installer.exe*

   *Note: The installation will take a while to complete*

   <img src=./media/gfxdrvinstall.png width="80%">

3. Make sure Intel Graphics Driver is successfully installed

   <img src=./media/gfxdrv.png width="80%">

4. Congratulation, you have completed the setup. The Window VM is now ready to support GPU hardware-accelerated workloads leveraging Intel Graphics SR-IOV technology.  

   *Note: You can start or stop the VM anytime using the following command: `kubectl virt start win10-vm` and `kubectl virt stop win10-vm`*


[readme]: ../README.md
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