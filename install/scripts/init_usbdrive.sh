#!/bin/bash -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# initialize usb drive with 2 partitions (1 ext4: DockerData, 1 exFAT: transfer)
# requires exactly 1 FAT-formatted drive to be mounted

main() {
    set_terminal_colors
    init_sudo
    find_FAT_formatted_blockdevice
    partition_device
    make_filesystems
    mark_UseMe4DockerData_partition
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
       exit 1
    elif [[ $FATDEVCOUNT > 1 ]]; then
       echo "Only 1 storage device with FAT file system may be mounted for this tool"
       exit 2
    else
       FATDEV=$(cat /tmp/fatdevs)
       TMP=${FATDEV/[0-9]*//}
       FATROOTDEV=${TMP%/}
       DEVATTR=$(lsblk --scsi -o 'NAME,FSTYPE,LABEL,VENDOR,MODEL,HOTPLUG,MOUNTPOINT' $FATROOTDEV)
       echo "Found storage device:\n$DEVATTR"
       echo "Selected storage device ${FATROOTDEV} for formatting, deleting any existing data on it"
       while true; do
           read -p "Continue (YESSS/n)?" choice
           case "$choice" in
               YESSS ) break;;
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
    $sudo dd if=/dev/zero of=$FATROOTDEV bs=512  count=1

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
    $sudo partprobe
}


make_filesystems() {
    logger -p local0.info -t "local0" -s "initializing ${FATROOTDEV}1 (vfat)"
    $sudo mkfs.vfat -n TRANSFER "${FATROOTDEV}1"
    $sudo mkdir -p /mnt/transfer
    $sudo mount "${FATROOTDEV}1" /mnt/transfer
    $sudo touch /mnt/transfer/UseMe4Transfer

    # format and mark docker data partition
    logger -p local0.info -t "local0" -s "initializing ${FATROOTDEV}2 (ext4)"
    $sudo mkfs.ext4 -L DockerData "${FATROOTDEV}2"
}


mark_UseMe4DockerData_partition() {
    $sudo mkdir -p /mnt/dockerdata
    $sudo mount "${FATROOTDEV}2" /mnt/dockerdata
    $sudo touch /mnt/dockerdata/UseMe4DockerData
}


main