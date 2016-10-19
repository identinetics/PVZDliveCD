#!/usr/bin/env bash

# initialize usb drive by device path

if [ $(id -u) -ne 0 ]; then
    sudo='sudo'
fi


# find a single device that is FAT-formatted
df -T | egrep ’(vfat|exfat)’| grep -v ' EFI'  | awk '{print $1}' > /tmp/fatdevs
FATDEVNO=$(wc -l < /tmp/fatdevs)
if [[ $FATDEVNO == 0 ]]; then
   echo "No storage device with FAT file system mounted"
   exit 1
elif [[ $FATDEVNO > 1 ]]; then
   echo "Only 1 storage device with FAT file system may be mounted for this tool"
   exit 2
else
   FATROOTDEV=${FATDEVNO/[0-9]*//}
   DEVATTR=$(lsblk --scsi -o 'NAME,FSTYPE,LABEL,VENDOR,MODELHOTPLUG,MOUNTPOINT' $FATROOTDEV)
   echo "Selected this storage device ${DEVATTR} for formatting, deleting any existing data on it"
   while true; do
       read -p "Continue (y/n)?" choice
       case "$choice" in
           y|Y ) break;;
           n|N ) exit;;
           * ) echo "Invalid choice";;
       esac
   done

fi

# initialize removable storage drive (USB)
$sudo umount $FATROOTDEV

# wipe storage drive
$sudo dd if=/dev/zero of=$FATROOTDEV bs=512  count=1

# partition with 1 100MB + a second partition filling the rest
echo "n
p
1

+100M
p
2


w" | $sudo fdisk $FATROOTDEV

# format + mark transfer partition
$sudo mkfs.vfat "$[FATROOTDEV}1"
$sudo mkdir /run/media/transfer
$sudo mount "${FATROOTDEV}1" /run/media/transfer
$sudo touch /run/media/transfer/UseMe4Transfer

# format and mark docker data partition
$sudo mkfs.ext4 "${FATROOTDEV}2"
$sudo mkdir /run/media/dockerdata
$sudo mount "$[FATROOTDEV}2" /run/media/dockerdata
$sudo touch /run/media/dockerdata/UseMe4DockerData


