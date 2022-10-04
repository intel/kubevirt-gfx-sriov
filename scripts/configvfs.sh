#!/bin/sh

ROOT_PATH="/sys/bus/pci/devices"

enable_vfs()
{
    for pcidev in $ROOT_PATH/*; do
        # Class Code: 0x03 - Display Controller
        if [ -d "$pcidev" ] && [ -f "$pcidev/class" ] &&
           [ "$(cat $pcidev/class | cut -c 3-4)" = "03" ] &&
           [ -f "$pcidev/sriov_totalvfs" ] &&
           [ -f "$pcidev/sriov_numvfs" ]; then
            enable_pcidev_vfs $pcidev
        fi
    done
}

enable_pcidev_vfs()
{
    pcidev=$1

    totalvfs=$(cat $pcidev/sriov_totalvfs)
    if [ "$totalvfs" -eq 0 ]; then
        echo "Total number of VF is 0. Nothing to do"
        return 0
    fi

    numvfs=$(cat $pcidev/sriov_numvfs)
    if [ "$numvfs" -ne 0 ]; then
        echo "VF already enabled: $numvfs. Nothing to do"
        return 0
    fi

    echo "Device: $pcidev"
    echo "Total VF: $totalvfs"

    modprobe i2c-algo-bit
    modprobe video
    modprobe vfio-pci

    echo '0' > $pcidev/sriov_drivers_autoprobe
    echo $totalvfs > $pcidev/sriov_numvfs
    echo '1' > $pcidev/sriov_drivers_autoprobe

    vendor=$(cat $pcidev/vendor)
    device=$(cat $pcidev/device)

    echo "ID: $vendor $device"
    echo "$vendor $device" > /sys/bus/pci/drivers/vfio-pci/new_id

    numvfs=$(cat $pcidev/sriov_numvfs)
    echo "VF enabled: $numvfs"
}

disable_vfs()
{
    for pcidev in $ROOT_PATH/*; do
        if [ -d "$pcidev" ] && [ -f "$pcidev/class" ] &&
           [ "$(cat $pcidev/class | cut -c 3-4)" = "03" ] &&
           [ -f "$pcidev/sriov_totalvfs" ] &&
           [ -f "$pcidev/sriov_numvfs" ]; then
            disable_pcidev_vfs $pcidev
        fi
    done
}

disable_pcidev_vfs()
{
    pcidev=$1

    numvfs=$(cat $pcidev/sriov_numvfs)
    if [ "$numvfs" -eq 0 ]; then
        echo "Number of VF enabled is 0. Nothing to do"
        return 0
    fi

    # extract DDDD:BB:DD from /sys/bus/pci/devices/DDDD:BB:DD.F
    dbd=$(printf $pcidev | awk -F'[/.]' '{print $6}')

    index=1
    while [ "$index" -le "$numvfs" ]; do
        echo "$dbd.$index" > /sys/bus/pci/drivers/vfio-pci/unbind
        index=$(( $index + 1 ))
    done

    vendor=$(cat $pcidev/vendor)
    device=$(cat $pcidev/device)
    echo "$vendor $device" > /sys/bus/pci/drivers/vfio-pci/remove_id
    echo '0' > $pcidev/sriov_numvfs

    numvfs=$(cat $pcidev/sriov_numvfs)
    echo "Device: $pcidev"
    echo "VF enabled: $numvfs"
}

usage() 
{
    echo "Usage: $0 <option>"
    echo "options:"
    echo "   -e     : enable VFs"
    echo "   -d     : disable VFs"
    echo
}

if [ "$1" = "-e" ]; then
    enable_vfs
elif [ "$1" = "-d" ]; then
    disable_vfs
else
    usage
fi