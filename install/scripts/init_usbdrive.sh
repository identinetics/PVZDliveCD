#!/bin/bash

# initialize usb drive with 2 partitions (1 vfat: transfer, 1 ext4: DockerData)
# requires that exactly 1 FAT-formatted drive is mounted

main() {
    set_trace
    set_terminal_colors
    init_sudo
    find_FAT_formatted_blockdevice
    partition_device
    make_filesystems
    mark_UseMe4DockerData_partition
    show_results
}


set_trace() {
    PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    mkdir -p /tmp/xtrace
    exec 4>/tmp/xtrace/$(basename $0.log)
    BASH_XTRACEFD=4
    set -x
}


set_terminal_colors() {
    /usr/bin/setterm term linux -foreground yellow -background black
}


init_sudo() {
    if [ $(id -u) -ne 0 ]; then
        sudo='sudo'
    fi
}


find_FAT_formatted_blockdevice() {
    # find a device that is FAT-formatted (there must be exactly 1 device with these properties)
    df -T | egrep '(vfat|exfat)'| awk '{print $1}' > /tmp/fatdevs
    FATDEVCOUNT=$(wc -l < /tmp/fatdevs)
    if [[ $FATDEVCOUNT == 0 ]]; then
       echo "No storage device with FAT file system mounted"
       read -p "Press Enter to exit" choice
       exit 1
    elif [[ $FATDEVCOUNT > 1 ]]; then
       echo "Only 1 storage device with FAT file system may be mounted for this tool"
       read -p "Press Enter to exit" choice
       exit 2
    else
       FATDEV=$(cat /tmp/fatdevs)
       TMP=${FATDEV/[0-9]*//}
       FATROOTDEV=${TMP%/}
       DEVATTR=$(lsblk --scsi -o 'NAME,FSTYPE,LABEL,VENDOR,MODEL,HOTPLUG,MOUNTPOINT' $FATROOTDEV)
       echo -e "Found storage device with FAT partition:\n$DEVATTR"
       lsblk | head -1
       lsblk | grep $(basename $FATROOTDEV)
       echo
       echo "======================================================================================="
       echo "Selecting storage device ${FATROOTDEV} for formatting, deleting any existing data on it"
       echo "======================================================================================="
       while true; do
           read -p "Continue (YESSS/n)?" choice
           case "$choice" in
               YESSS ) break;;
               yesss|yes|YES ) echo "make sure to type uppercase 'YESSS' woth 3 x 'S'";;
               n|N ) exit;;
               * ) echo "Invalid choice";;
           esac
       done

    fi
}


partition_device() {
    # unmount all partitions of the device
    lsblk --list --path $FATROOTDEV | grep 'part' | awk '{print "umount " $1}' > /tmp/umount_vfat.sh
    logger -p local0.info -t "local0" -s "unmounting vfat device(s) (/tmp/umount_vfat.sh)"
    $sudo bash /tmp/umount_vfat.sh

    # wipe storage drive
    logger -p local0.info -t "local0" -s "writing 2 partitions to $FATROOTDEV"
    echo "=== zeroing out parition table on ${FATROOTDEV}2 ===" 1>&2
    $sudo dd if=/dev/zero of=$FATROOTDEV bs=512  count=1

    echo "=== partition ${FATROOTDEV}2 with 1 100MB + a second partition filling the rest ===" 1>&2
    # partition with 1 100MB + a second partition filling the rest:
    # n=new, p=primary, partition=1, start=default, size=100MB
    # n=new, p=primary, partition=2, start=default, size=default
    # print, write/quit
    echo "
n
p
1

+100M
n
p
2


p
w
" | \
    $sudo fdisk $FATROOTDEV
    echo "=== fdisk completed ===" 1>&2
    $sudo partprobe
    echo "=== partprobe completed ===" 1>&2
}


make_filesystems() {
    mnt=/run/media/liveuser
    logger -p local0.info -t "local0" -s "initializing ${FATROOTDEV}1 (vfat)"
    echo "=== starting mkfs.vfat ===" 1>&2
    $sudo mkfs.vfat -n TRANSFER "${FATROOTDEV}1"
    $sudo mkdir -p ${mnt}/transfer
    echo "mounting ${FATROOTDEV}2 at ${mnt}/transfer, marking partition with 'UseMe4Transfer'"
    $sudo mount "${FATROOTDEV}1" ${mnt}/transfer
    $sudo touch ${mnt}/transfer/UseMe4Transfer

    # format and mark docker data partition
    logger -p local0.info -t "local0" -s "initializing ${FATROOTDEV}2 (ext4)"
    $sudo mkfs.ext4 -L DockerData "${FATROOTDEV}2"
}


mark_UseMe4DockerData_partition() {
    $sudo mkdir -p ${mnt}/dockerdata
    echo "=== mounting ${FATROOTDEV}2 at ${mnt}/dockerdata, marking partition with 'UseMe4DockerData' ===" 1>&2
    $sudo mount "${FATROOTDEV}2" ${mnt}/dockerdata
    $sudo touch ${mnt}/dockerdata/UseMe4DockerData
}


show_results() {
    if [[ -e ${mnt}/dockerdata/UseMe4DockerData ]]; then
        echo "Success: Docker data partition initialized and marked; mounted at ${mnt}/dockerdata"  
    else
        echo "Failure: Mark file of docker data partition not found - please check log"  
    fi

    if [[ -e ${mnt}/transfer/UseMe4Transfer ]]; then
        echo "Success: transfer partition initialized and marked; mounted at ${mnt}/transfer"  
    else
        echo "Failure: Mark file of docker data partition not found - please check log"  
    fi
    read -p "Press Enter to exit" choice
}


main