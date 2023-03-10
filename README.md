<a name="readme-top"></a>

<div align="center">
  <h3 align="center">Intel® Graphics SR-IOV Enablement Toolkit</h3>

  <p align="center">
    This project contains the software components and ingredients to enable Intel's graphics virtualization technology (Graphics SR-IOV) on cloud/edge-native infrastructure. The aim is to deliver GPU-accelerated workloads capability to virtual machines running on Kubernetes cluster
    <br />
    <a href="https://github.com/intel/kubevirt-gfx-sriov"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/intel/kubevirt-gfx-sriov">View Demo</a>
    ·
    <a href="https://github.com/intel/kubevirt-gfx-sriov/issues">Report Bug</a>
    ·
    <a href="https://github.com/intel/kubevirt-gfx-sriov/issues">Request Feature</a>
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
    <li><a href="#troubleshooting">Troubleshooting</a></li>
    <li><a href="#resources">Resources</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

**Intel Graphics SR-IOV Technology**

Graphics SR-IOV is Intel's latest Virtualization Technology for Graphics. Single Root I/O Virtualization (SR-IOV) defines a standard method for sharing a physical device function by partitioning the device into multiple virtual functions. Each virtual function is directly assigned to a virtual machine, thereby achieving near native performance for the virtual machine

The key benefits of Intel Graphics SR-IOV are:
  * A standard method of sharing physical GPU with virtual machines, thus allowing efficient use of GPU resource in a virtual system
  * Improved **video transcode**, **media AI analytics** and **Virtual Desktop Infrastructure (VDI)** workloads performance in virtual machine
  * Support up to 4 independent display output and 7 virtualized functions (12th Generation Intel Core embedded processors)
  * Support multiple guest operating system

**Cloud/Edge Native Technology**

Application containerization and Kubernetes orchestrator have revolutionarized the way software is developed and deployed. The containerization era has led to the development of microservices that typically run as containers and have the advantage of being lightweight, require less memory, fast startup time and operate at native performance. But there are scenarios where your application still need to run as full-fledge virtual manchines and cannot be run as containers due to legacy software support or integration complexity.

In order to achieve the best of both worlds, we can leverage **Kubernetes and KuberVirt**, a Kubernetes extension, that allows running traditional virtual machine workloads natively side by side with container workloads. With this solution, you can have the advantage of a single infrastructure for both containerized and virtualized workloads. You can also benefit from the power and features of Kubernetes

<img src=./docs/media/overview.png width="30%">

**Intel Graphics SR-IOV Enablement Toolkit**

This repository contains scripts, manifests and documentation, collectively known as the *Intel Graphics SR-IOV Enablement Tookit* to help software developer enable **Graphics SR-IOV** for cloud/edge native application development

![Product Name Screen Shot][product-screenshot]

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

Access to appropriate hardware and drivers is required for the setup. Graphics SR-IOV technology is supported on the following Intel products:
* 12th Generation Intel Core ***embedded*** processors (Alder Lake)+

### Prerequisites

* A working [Ubuntu 22.04 LTS](https://releases.ubuntu.com/22.04/) host
* Configuration to enable Graphics SR-IOV on host:
   * [12th Generation Intel Core **embedded** processors](https://cdrdv2.intel.com/v1/dl/getContent/680834)

     *Note: Save the kernel debian package files built by completing section "3.0: Host OS Kernel Build Steps" of the [Alder-Lake-MultiOS-With-GFX-SR-IOV-Virtualization-On-Ubuntu-User-Guide.pdf](https://cdrdv2.intel.com/v1/dl/getContent/680834) into a folder and proceed to create an archive file. We will use this archive file in prepration for setting up Ubuntu VM at <a href="#usage">Usage > Deploy Ubuntu Virtual Machine </a>. See below on steps to create an archive file:*
     ```sh
     mkdir kernel

     cp *.deb kernel/

     tar -czvf kernel.tgz kernel/
     ```

### Installation
  * Quick Install (easy)
  * [Manual Install][manual-install]

### Quick Install
1. Clone the repo and install toolkit. When prompted, answer 'y' to proceed with the installation.

   ***Note: If operating behind corporate firewall, setup the proxy settings before continue. `easy_install.sh` should only be run on newly setup system to prevent overwriting existing installed software and configuration. For more customized installation, please see [Manual Install][manual-install]***

   ```sh
   git clone https://github.com/intel/kubevirt-gfx-sriov.git gfx-sriov
   
   cd gfx-sriov

   ./scripts/easy_install.sh
   ```

2. After reboot, check for the presence of `intel.com/sriov-gpudevices` resource

    *Note: Please wait for all pods' *STATUS*=***Running*** by checking with the following command: `kubectl get pods -n kubevirt`*
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

3. After completing the installation of ***Intel® Graphics SR-IOV Enablement Toolkit***, proceed to the **Usage** section below to setup Virtual Machines

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

Follow the links below for instructions on how to setup and deploy virtual machines using this toolkit

[Deploy Windows Virtual Machine][deploy-windows-vm]

[Deploy Ubuntu Virtual Machine][deploy-ubuntu-vm]

_For more examples, please refer to the [Documentation][documentation-folder]_

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Architecture Design

Refer to the link below for information on the architecture and design of the overall solution

[Architecture and Design][architecture-design]

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Troubleshooting

Refer to the link below for common problems people encounter

[Troubleshooting][troubleshooting]


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

Distributed under the Apache License, Version 2.0. See *LICENSE* for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[overview]: docs/media/overview.png
[product-screenshot]: docs/media/hl-block-diagram.png
[documentation-folder]: docs/
[deploy-windows-vm]: docs/deploy-windows-vm.md#microsoft-windows-10-vm
[deploy-ubuntu-vm]: docs/deploy-ubuntu-vm.md#ubuntu-2204-lts-vm
[architecture-design]: docs/architecture-design.md#revision-history
[manual-install]: docs/manual-install.md#manual-install
[troubleshooting]: docs/troubleshooting.md#troubleshooting