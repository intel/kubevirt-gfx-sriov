# KubeVirt Graphics SR-IOV Design and Architecture

## Revision 0.1

<details>
  <summary> Table of Contents</summary>
  1. [Introduction](#introduction)
    1.1 [Scope](#scope)
    1.2 [Purpose](#purpose)
    1.3 [Acronyms](#acronyms)
  2. KubeVirt Graphics SR-IOV Architecture
    2.1 Architecture design(#architecture)
 </details>
 
 ## Introduction
 KubeVirt Graphics SR-IOV software package provides simple steps for cloud native graphics SR-IOV enablement. 
 
 ### Scope
 This document captures architectural detail on graphics SR-IOV edge cloud ecosystem enablement for cloud native application. 
 
 ### Purpose
 This document intends to bring additional clarity to the development teams to understand the overall architecture and components involved.
 
 ### Acronyms
 | K8s           |  Kubernetes                                    |
 | K3s           |  Lightweight K8s distribution                  |
 | Gfx           |  Graphics                                      |
 | SR-IOV        |  Single Root I/O Virtualization                |
 | VF            |  SR-IOV Virtual Function                       |
 | PF            |  SR-IOV Physical Funciotn                      |
 
 ## KubeVirt Graphics SR-IOV Architecture
 KubeVirt Graphics SR-IOV (Kubevirt-Gfx-SRIOV) leverage Kubernetes orchestrator and KubeVirt to deploy and manage VM resources. Ready to use images are encapsulated by container in dedicated repository, will be deployed by KubeVirt with a simple command line.
 
 ### Architecture design
 The purpose of this software package is to enable Graphics SR-IOV for cloud native application.  The software package consist of YAML files and bash script files. The YAML files that are needed to configure the virtual environment running on Kubernetes cluster. The bash script files provided are for graphic SR-IOV enablement and Kubernetes cluster setup. 
 <img src="media/KubeVirt Graphics SR-IOV/image1.png" alt="P1189#yIS1" style="width:5.39583in;height:3.97917in" />
 
 The diagram below is the design for this software package. It consist of YAML files bash script files. The bash script files automate the installation of virtual machine environment and graphic SR-IOV enablement. The YAML files consist of configuration for virtual environment and graphic SR-IOV configuration.
<img src="media/KubeVirt Graphics SR-IOV/image2.png" alt="P1189#yIS1" style="width:5.39583in;height:3.97917in" />

 The following diagram shows the inter-op of each components
 <img src="media/KubeVirt Graphics SR-IOV/image3.png" alt="P1189#yIS1" style="width:5.39583in;height:3.97917in" />
 
