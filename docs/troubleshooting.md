<a name="troubleshooting-top"></a>

# Troubleshooting

Learn how to resolve the most common issues users encounter while setting up host or VM.

A list of resolutions is detailed below:

1. **intel.com/sriov-gpudevice** resource not found when executing command `kubectl describe node`

   On the host, find the GPU device
   ```sh
   sudo lspci -vnnk
   ```  
   Output:
   ```sh
   00:02.0 VGA compatible controller [0300]: Intel Corporation AlderLake-S GT1 [8086:4680] (rev 0c) (prog-if 00 [VGA controller])
        DeviceName: To Be Filled by O.E.M.
        Subsystem: Intel Corporation AlderLake-S GT1 [8086:2212]
        ...
        Capabilities: [320] Single Root I/O Virtualization (SR-IOV)
        Kernel driver in use: i915
        Kernel modules: i915

   00:02.1 VGA compatible controller [0300]: Intel Corporation AlderLake-S GT1 [8086:4680] (rev 0c) (prog-if 00 [VGA controller])
        Subsystem: Intel Corporation AlderLake-S GT1 [8086:2212]
        ...
        Kernel driver in use: vfio-pci
        Kernel modules: i915
   ```
   In this example, the virtual function (VF) with the address: 00:02.1 is enabled and the Vendor ID and Device ID of the VF is **8086:4680**. Make sure the *manifests/kubevirt-cr-gfx-sriov.yaml* file contains the Vendor ID and Device ID information. Run command `kubectl apply -f manifests/kubevirt-cr-gfx-sriov.yaml` after you entered the information to the yaml file. You might need to reboot the host afterward
   ```sh
   pciHostDevices:
      - pciVendorSelector: "8086:4680"
        resourceName: "intel.com/sriov-gpudevice"
        externalResourceProvider: false
   ```


<p align="right">(<a href="#manual-install-top">back to top</a>)</p>