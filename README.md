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
    <li><a href="#license">License</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

[![Product Name Screen Shot][product-screenshot]]

This repository contains the collection of scripts, manifests and documentation to enable `Graphics SR-IOV` for cloud/edge-native application. [KubeVirt](https://github.com/kubevirt/kubevirt) is the main open source project that we leverages to manage Virtual Machines (VMs) and the Graphics SR-IOV resources on the host.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

Graphics SR-IOV technology is supported on the following Intel products:
* 12th generation Intel Core `embedded` processors (Alder Lake)
* Data Center GPU Flex series (Artic Sound)

### Prerequisites

The following is required:
* [Ubuntu 22.04 LTS](https://releases.ubuntu.com/22.04/)


### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/intel-sandbox/applications.virtualization.kubevirt-gfx-sriov.git
   ```
2. Install NPM packages
   ```sh
   npm install
   ```
3. Enter your API in `config.js`
   ```js
   const API_KEY = 'ENTER YOUR API';
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

Use this space to show useful examples of how a project can be used. Additional screenshots, code examples and demos work well in this space. You may also link to more resources.

_For more examples, please refer to the [Documentation](https://example.com)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the Apache License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[product-screenshot]: assets/images/screenshot.png
