#!/bin/bash

IGPU_PCIDEV_PATH="/sys/bus/pci/devices/0000:00:02.0"

enable_vfs()
{
    if [ ! -f $IGPU_PCIDEV_PATH/sriov_totalvfs ]; then
        echo "System doesn't support Graphics SR-IOV"
        exit 101
    fi

    totalvfs=$(cat $IGPU_PCIDEV_PATH/sriov_totalvfs)
    if [ $totalvfs -eq 0 ]; then 
        echo "Total number of VF is 0. Nothing to do"
        exit 102
    fi

    numvfs=$(cat $IGPU_PCIDEV_PATH/sriov_numvfs)
    if [ $numvfs -ne 0 ]; then 
        echo "VF already enabled: $numvfs. Nothing to do"
        exit 103
    fi

    echo "Total VF: $totalvfs"

    modprobe i2c-algo-bit
    modprobe video
    modprobe vfio-pci

    echo '0' > $IGPU_PCIDEV_PATH/sriov_drivers_autoprobe
    echo $totalvfs > /sys/class/drm/card0/device/sriov_numvfs
    echo '1' > $IGPU_PCIDEV_PATH/sriov_drivers_autoprobe

    vendor=$(cat $IGPU_PCIDEV_PATH/vendor)
    device=$(cat $IGPU_PCIDEV_PATH/device)

    echo "ID: $vendor $device"
    echo "$vendor $device" > /sys/bus/pci/drivers/vfio-pci/new_id

    numvfs=$(cat $IGPU_PCIDEV_PATH/sriov_numvfs)
    echo "VF enabled: $numvfs"
}

disable_vfs()
{
    numvfs=$(cat $IGPU_PCIDEV_PATH/sriov_numvfs)

    if [ $numvfs -eq 0 ]; then 
        echo "Number of VF enabled is 0. Nothing to do"
        exit 104
    fi

    for (( index = 1; index <= $numvfs; index++ )); do
        echo 0000\:00\:02.$index > /sys/bus/pci/drivers/vfio-pci/unbind
    done

    vendor=$(cat $IGPU_PCIDEV_PATH/vendor)
    device=$(cat $IGPU_PCIDEV_PATH/device)
    echo "$vendor $device" > /sys/bus/pci/drivers/vfio-pci/remove_id

    echo '0' > /sys/bus/pci/devices/0000\:00\:02.0/sriov_drivers_autoprobe
    echo '0' > /sys/class/drm/card0/device/sriov_numvfs
    echo '1' > /sys/bus/pci/devices/0000\:00\:02.0/sriov_drivers_autoprobe
    echo "VF disabled: $numvfs"
}

usage() 
{
    echo "Usage: $0 <option>"
    echo "options:"
    echo "   -e     : enable VFs"
    echo "   -d     : disable VFs"
}

while getopts "ed" opt; do
    case "${opt}" in
        e) enable_vfs
           exit 0
           ;;
        d) disable_vfs
           exit 0 
           ;;
    esac
done

usage
exit 0