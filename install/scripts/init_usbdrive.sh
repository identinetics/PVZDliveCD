#!/usr/bin/env bash

# initialize usb drive by device path

if [ $(id -u) -ne 0 ]; then
    sudo='sudo'
fi


# find a single device that is FAT-formatted
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

# === initialize removable storage drive (USB) ===

# unmount all partitions of the device
lsblk --list --path $FATROOTDEV | grep 'part' | awk '{print "umount " $1}' > /tmp/umount_vfat.sh
logger -p local0.info -t "local0" -s "unmounting vfat device (/tmp/umount_vfat.sh)"
$sudo bash /tmp/umount_vfat.sh

# wipe storage drive
logger -p local0.info -t "local0" -s "writing 2 partitions to $FATROOTDEV"
$sudo dd if=/dev/zero of=$FATROOTDEV bs=512  count=1

# partition with 1 100MB + a second partition filling the rest
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
s" | $sudo fdisk $FATROOTDEV

# format + mark transfer partition
logger -p local0.info -t "local0" -s "initializing ${FATROOTDEV}1 (vfat)"
$sudo mkfs.vfat "${FATROOTDEV}1"
$sudo mkdir /run/media/transfer
$sudo mount "${FATROOTDEV}1" /run/media/transfer
$sudo touch /run/media/transfer/UseMe4Transfer

# format and mark docker data partition
logger -p local0.info -t "local0" -s "initializing ${FATROOTDEV}2 (ext4)"
$sudo mkfs.ext4 "${FATROOTDEV}2"
$sudo mkdir /run/media/dockerdata
$sudo mount "$[FATROOTDEV}2" /run/media/dockerdata
$sudo touch /run/media/dockerdata/UseMe4DockerData


