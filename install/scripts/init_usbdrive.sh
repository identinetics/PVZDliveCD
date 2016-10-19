#!/usr/bin/env bash

# initialize usb drive by device path

if [ $(id -u) -ne 0 ]; then
    sudo='sudo'
fi

$sudo umount $DEV
$sudo mkfs.ext4 $DEV
$sudo mount $DEV /mnt
$sudo touch /mnt/UseMe4DockerData


