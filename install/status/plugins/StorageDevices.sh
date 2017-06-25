#!/usr/bin/env bash

echo '<pre>'
lsblk -I 8 -io NAME,TYPE,SIZE,MOUNTPOINT,FSTYPE,MODEL
echo '</pre>'
