# Revision History

| Revision Number | Description      | Revision Date | Edited By    |
|-----------------|------------------|---------------|--------------|
| 0.1             | Initial Creation | 4/7/2022      | Ng Chooi Lan |
|                 |                  |               |              |
|                 |                  |               |              |

# Contents 

1   [Introduction](#introduction)

   1.1 [Scope](#scope)
   
   1.2 [Purpose](#purpose)
   
   1.3 [Acronyms](#acronyms)

2 [KubeVirt Graphics SR-IOV Architecture](#kubevirt-graphics-sr-iov-architecture)

   2.1 [Architecture design](#architecture-design)

3 [References](#references)

##  Section

**Table of Figures**

[*Figure 1 Kubevirt-Gfx-SRIOV Flow*](#_Toc109894013)

[*Figure 2 Kubevirt-Gfx-SRIOV Design*](#_Toc109894014)

[*Figure 3 Kubevirt-Gfx-SRIOV Inter-operation](#_Toc109894015)


## Introduction

KubeVirt Graphics SR-IOV software package provides simple steps for
cloud native graphics SR-IOV enablement.

## Scope

This document captures architectural detail on graphics SR-IOV edge
cloud ecosystem enablement for cloud native application.

## Purpose

This document intends to bring additional clarity to the development
teams to understand the overall architecture and components involved.

## Acronyms

| K8s    | Kubernetes                     |
|--------|--------------------------------|
| Gfx    | Graphics                       |
| K3s    | Lightweight K8s distribution   |
| VF     | SR-IOV Virtual Function        |
| PF     | SR-IOV Physical Function       |
| SR-IOV | Single Root I/O Virtualization |
|        |                                |

# KubeVirt Graphics SR-IOV Architecture

KubeVirt Graphics SR-IOV (Kubevirt-Gfx-SRIOV) leverage Kubernetes
orchestrator and KubeVirt to deploy and manage VM resources. Ready to
use images are encapsulated by container in dedicated repository, will
be deployed by KubeVirt with a simple command line.

## Architecture design

The purpose of this software package is to enable Graphics SR-IOV for
cloud native application. The software package consists of YAML files
and bash script files. The YAML files that are needed to configure the
virtual environment running on Kubernetes cluster. The bash script files
provided are for graphic SR-IOV enablement and Kubernetes cluster setup.

<img src="media/KubeVirt Graphics SR-IOV/media/image2.PNG"
style="width:5.97285in;height:2.04in" />

<span id="_Toc109894013" class="anchor"></span>*Figure 1
Kubevirt-Gfx-SRIOV Flow*

The diagram below is the design for this software package. It consists
of YAML files bash script files. The bash script files automate the
installation of virtual machine environment and graphic SR-IOV
enablement. The YAML files consist of configuration for virtual
environment and graphic SR-IOV configuration.

<img src="media/KubeVirt Graphics SR-IOV/media/image3.PNG"
style="width:6.40527in;height:2.248in"
alt="Diagram Description automatically generated" />

<span id="_Toc109894014" class="anchor"></span>*Figure 2
Kubevirt-Gfx-SRIOV Design*

The following diagram shows the inter-op of each component:

<img src="media/KubeVirt Graphics SR-IOV/media/image4.PNG"
style="width:6.39514in;height:2.54236in"
alt="Diagram Description automatically generated" />

<span id="_Toc109894015" class="anchor"></span>Figure 3
Kubevirt-Gfx-SRIOV Inter-operation

# References

| Document | Document Location |
|----------|-------------------|
|          |                   |
|          |                   |
|          |                   |
|          |                   |
|          |                   |
