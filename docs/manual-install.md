<a name="manual-install-top"></a>

# Manual Installation

## Installation

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

## Uninstall

1. To uninstall all components you can run command below or you can specify which component to uninstall. 

   *Note: Get help on `setuptools.sh` by running `setupstool.sh -h`*
   ```sh
   ./scripts/setuptools.sh -u kvw
   ``` 

<p align="right">(<a href="#manual-install-top">back to top</a>)</p>
