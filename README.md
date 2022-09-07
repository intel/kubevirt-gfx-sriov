<a name="readme-top"></a>

<div align="center">
  <h3 align="center">KubeVirt Graphics SR-IOV</h3>

  <p align="center">
    This project contains the software components and ingredients to enable Intel's graphics virtualization technology (Graphics SR-IOV) on cloud/edge-native infrastructure. The aim is deliver GPU-accelerated workloads capability to virtual machines running on Kubernetes cluster. 
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
    <li><a href="#resources">Resources</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

[![Product Name Screen Shot][product-screenshot]]

This repository contains the collection of scripts, manifests and documentation to enable `Graphics SR-IOV` for cloud/edge-native application development. [KubeVirt](https://github.com/kubevirt/kubevirt) is the main component used to manage Virtual Machines (VMs) and the Graphics SR-IOV resources on the host.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

Access to appropriate hardware and drivers is required for the setup. Graphics SR-IOV technology is supported on the following Intel products:
* 12th Generation Intel Core `embedded` processors (Alder Lake)
* Data Center GPU Flex series (Artic Sound)

### Prerequisites

The following is required:
* A fully configured [Ubuntu 22.04 LTS](https://releases.ubuntu.com/22.04/) host with Graphics SR-IOV support

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/intel-sandbox/applications.virtualization.kubevirt-gfx-sriov.git
   
   cd applications.virtualization.kubevirt-gfx-sriov
   ```
2. Add additional access to AppArmor libvirtd profile. This step is only required if the host OS comes with AppArmor profile that is preventing KubeVirt operation. See [issue](https://github.com/kubevirt/kubevirt/issues/7473) for more detail.
   ```sh   
   sudo cp apparmor/usr.sbin.libvirtd /etc/apparmor.d/local/
   
   sudo systemctl reload apparmor.service
   ```
3. Install `K3s`. This step is only required if you don't already have a Kubernetes cluster setup. 

   *Note: K3s is being used here because it's lightweight and quick to setup up* 
   ```sh
   ./scripts/setuptools.sh -ik
   ```
4. Install `KubeVirt` and `CDI`
   ```sh
   ./scripts/setuptools.sh -iv
   ```
5. Install `Krew` and `virt-plugin`

   *Note: Get help on `setuptools.sh` by running `setupstool.sh -h`*
   ```sh
   ./scripts/setuptools.sh -iw
   ```
6. After installation is completed, log out and log back in. Check K3s and KubeVirt have been  successfully setup and deployed 

   *Note: It might takes a few minutes*
   ```sh
   kubectl get nodes

   kubectl get kubevirt -n kubevirt
   ``` 

### Uninstallation

1. To uninstall all components you can run command below or you can specify which component to uninstall. Get help on `setuptools.sh` by running `setupstool.sh -h`
   ```sh
   ./scripts/setuptools.sh -u kvw
   ``` 

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

Use this space to show useful examples of how a project can be used. Additional screenshots, code examples and demos work well in this space. You may also link to more resources.

_For more examples, please refer to the [Documentation](https://example.com)_

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

Distributed under the Apache License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[product-screenshot]: assets/images/screenshot.png
