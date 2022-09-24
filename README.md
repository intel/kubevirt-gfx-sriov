<a name="readme-top"></a>

<div align="center">
  <h3 align="center">Intel® Graphics SR-IOV Enablement Toolkit</h3>

  <p align="center">
    This project contains the software components and ingredients to enable Intel's graphics virtualization technology (Graphics SR-IOV) on cloud/edge-native infrastructure. The aim is to deliver GPU-accelerated workloads capability to virtual machines running on Kubernetes cluster.
    <br />
    <a href="https://github.com/intel-sandbox/applications.virtualization.kubevirt-gfx-sriov"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/intel-sandbox/applications.virtualization.kubevirt-gfx-sriov">View Demo</a>
    ·
    <a href="https://github.com/intel-sandbox/applications.virtualization.kubevirt-gfx-sriov/issues">Report Bug</a>
    ·
    <a href="https://github.com/intel-sandbox/applications.virtualization.kubevirt-gfx-sriov/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#architecture-design">Architecture Design</a></li>
    <li><a href="#resources">Resources</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

![Product Name Screen Shot][product-screenshot]

This repository contains the collection of scripts, manifests and documentation to enable **Graphics SR-IOV** for cloud/edge-native application development. [KubeVirt](https://github.com/kubevirt/kubevirt) is the main component used to manage Virtual Machines (VMs) and the Graphics SR-IOV resources on the host.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

Access to appropriate hardware and drivers is required for the setup. Graphics SR-IOV technology is supported on the following Intel products:
* 12th Generation Intel Core ***embedded*** processors (Alder Lake)+

### Prerequisites

The following is required:
* A working [Ubuntu 22.04 LTS](https://releases.ubuntu.com/22.04/) host
* Configuration to enable Graphics SR-IOV on host:
   * [12th Generation Intel Core **embedded** processors](https://cdrdv2.intel.com/v1/dl/getContent/680834)

     *Note: Save the kernel debian package files built by completing section "3.0: Host OS Kernel Build Steps" of the [Alder-Lake-MultiOS-With-GFX-SR-IOV-Virtualization-On-Ubuntu-User-Guide.pdf](https://cdrdv2.intel.com/v1/dl/getContent/680834) into a folder and proceed to create an archive file. We will use this archive file in the prepration stage for setting up Ubuntu VM at <a href="#usage">Usage > Deploy Ubuntu Virtual Machine </a> later. See below on steps to create an archive file:*
     ```sh
     mkdir kernel

     cp *.deb kernel/

     tar -czvf kernel.tgz kernel/
     ```

### Installation

1. Clone the repo

   ***Note: If operating behind corporate firewall, setup the proxy settings before continue***

   ```sh
   git clone https://github.com/intel-sandbox/applications.virtualization.kubevirt-gfx-sriov.git
   
   cd applications.virtualization.kubevirt-gfx-sriov
   ```

2. Add additional access to AppArmor libvirtd profile. This step is only required if the host OS (eg: Ubuntu) comes with AppArmor profile that is preventing KubeVirt operation. See [issue](https://github.com/kubevirt/kubevirt/issues/7473) for more detail
   ```sh   
   sudo cp apparmor/usr.sbin.libvirtd /etc/apparmor.d/local/
   
   sudo systemctl reload apparmor.service
   ```

3. Install software dependency
   ```sh
   sudo apt install curl -y
   ```

4. Install **K3s**. This step will setup a single node cluster where the host function as both the server/control plane and the worker node. This step is only required if you don't already have a Kubernetes cluster setup that you can use

   *Note: K3s is a lightweight Kubernetes distribution suitable for Edge and IoT use cases.
   ```sh
   ./scripts/setuptools.sh -ik
   ```

5. Install **KubeVirt** and **CDI**
   ```sh
   ./scripts/setuptools.sh -iv
   ```

6. Install **Krew** and **virt-plugin**

   *Note: Get help on `setuptools.sh` by running `setupstool.sh -h`*
   ```sh
   ./scripts/setuptools.sh -iw
   ```

7. After installation is completed, log out and log back in. Check K3s and KubeVirt have been successfully setup and deployed

   *Note: It might takes a few minutes for KubeVirt deployment to complete*
   ```sh
   kubectl get nodes

   kubectl get kubevirt -n kubevirt
   ```
   Output:
   ```sh
   NAME          STATUS   ROLES                  AGE    VERSION
   ubuntu-host   Ready    control-plane,master   12m   v1.24.4+k3s1

   NAME       AGE    PHASE
   kubevirt   12m   Deployed
   ```

8. Add systemd service unit file to enable graphics VFs on boot
   ```sh
   sudo mkdir -p /var/vm/scripts

   sudo cp scripts/configvfs.sh /var/vm/scripts/

   sudo chmod +x /var/vm/scripts/configvfs.sh

   sudo cp systemd/gfx-virtual-func.service /etc/systemd/system/

   sudo systemctl daemon-reload

   sudo systemctl start gfx-virtual-func.service

   sudo systemctl enable gfx-virtual-func.service

   sudo reboot
   ```  

9. Check the `configvfs.sh` log and `gfx-virtual-func.service` daemon status for any error
   ```sh
   systemctl status gfx-virtual-func.service
   ```
   Output:
   ```sh
   gfx-virtual-func.service - Intel Graphics SR-IOV Virtual Function Manager
     Loaded: loaded (/etc/systemd/system/gfx-virtual-func.service; enabled; vendor preset: enabled)
     Active: active (exited)
    Process: 930 ExecStart=/bin/bash /var/vm/scripts/configvfs.sh -e (code=exited, status=0/SUCCESS)
   Main PID: 930 (code=exited, status=0/SUCCESS)
        CPU: 138ms

   ubuntu-host systemd[1]: Starting Intel Graphics SR-IOV Virtual Function Manager...
   ```

10. Update KubeVirt custom resource configuration to enable virt-handler to discover graphics VFs on the host. All discovered VFs will be published as *allocatable* resource
    ```sh
    cd applications.virtualization.kubevirt-gfx-sriov

    kubectl apply -f manifests/kubevirt-cr-gfx-sriov.yaml
    ```

11. Check for resource presence: `intel.com/sriov-gpudevices`

    *Note: Please wait for all virt-handler pods to complete restarts using the following command: `kubectl get pods -n kubevirt`*
    ```sh
    kubectl describe nodes
    ```
    Output:
    ```sh
    Capacity:
      intel.com/sriov-gpudevice:     7
    Allocatable:
      intel.com/sriov-gpudevice:     7
    Allocated resources:
      Resource                       Requests     Limits
      --------                       --------     ------
      intel.com/sriov-gpudevice      0            0
    ```
    *Note: The value of **Request** and **Limits** will increase upon successful resource allocation to running pods/VMs*

### Uninstall

1. To uninstall all components you can run command below or you can specify which component to uninstall. 

   *Note: Get help on `setuptools.sh` by running `setupstool.sh -h`*
   ```sh
   ./scripts/setuptools.sh -u kvw
   ``` 

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

Follow the links below for instructions on how to setup and deploy virtual machines using KubeVirt

[Deploy Windows Virtual Machine][deploy-windows-vm]

[Deploy Ubuntu Virtual Machine][deploy-ubuntu-vm]

_For more examples, please refer to the [Documentation][documentation-folder]_

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Architecture Design

Refer to the link below for information on the architecture and design of the solution

[Architecture and Design][architecture-design]



<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- RESOURCES -->
## Resources

* [Kubernetes](https://kubernetes.io/)
* [K3s](https://k3s.io/)
* [KubeVirt](https://kubevirt.io/)
* [AppArmor](https://apparmor.net/)
* [Krew](https://krew.sigs.k8s.io/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the Apache License, Version 2.0. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[product-screenshot]: docs/media/winubuntu.png
[documentation-folder]: docs/
[deploy-windows-vm]: docs/deploy-windows-vm.md#microsoft-windows-10-vm
[deploy-ubuntu-vm]: docs/deploy-ubuntu-vm.md#ubuntu-2204-lts-vm
[architecture-design]: docs/architecture-design.md