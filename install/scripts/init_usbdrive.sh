#!/usr/bin/env bash

# initialize usb drive by device path


/usr/bin/setterm term linux -foreground yellow -background black

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

# === initialize removable storage drive (USB) ===

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
" | $sudo fdisk $FATROOTDEV

# format + mark transfer partition
logger -p local0.info -t "local0" -s "initializing ${FATROOTDEV}1 (vfat)"
$sudo mkfs.vfat -n transfer "${FATROOTDEV}1"
$sudo mkdir -p /mnt/transfer
$sudo mount "${FATROOTDEV}1" /mnt/transfer
$sudo touch /mnt/transfer/UseMe4Transfer

# format and mark docker data partition
logger -p local0.info -t "local0" -s "initializing ${FATROOTDEV}2 (ext4)"
$sudo mkfs.ext4 -L UseMe4DockerData "${FATROOTDEV}2"
$sudo mkdir -p /mnt/dockerdata
$sudo mount "${FATROOTDEV}2" /mnt/dockerdata
$sudo touch /mnt/dockerdata/UseMe4DockerData


