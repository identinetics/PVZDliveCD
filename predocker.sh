#!/bin/bash

# docker data like images, container and volumes need to reside in a writeable filesystem.
# This script searches for a device having a mark in the path of the mount point and 
# changes the docker daemon' start options accordingly.

mark_dir=
mark_filename="UseMe4DockerData"

while getopts ":d:" opt
do
  case $opt in
    d)
      echo "-d was set, using $OPTARG dir" >&2
      mark_dir=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      exit 1
      ;;
   esac
done


function patch_config {
  logger "predocker.sh: new docker dir is $1"
  new_dock_dir=$1
  #enable docker settings
  #sed "s~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/ -g $new_dock_dir~" /tmp/docker.service
  sed -i "s~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/ -g $new_dock_dir~" /usr/lib/systemd/system/docker.service
  systemctl daemon-reload
  systemctl start docker
}


function find_docker_dir_by_filelist {
# find docker dir, argument is a dir list
# echo $1
  dir_list=`cat $1`

  for dir in $dir_list
  do
    # echo "Checking: $dir"
    if [ -e "$dir/$mark_filename" ]
    then
    # echo "Dir was found: $dir"
      lmark_dir=$dir
      echo $lmark_dir
      return 0
    fi
  done
  echo "No directory found in file list"
  return 1
}


logger "predocker.sh - waiting for auto-mounting of block devices to complete"
sleep 10


if [[ -z "$mark_dir" ]]
then
  logger "predocker.sh: Docker dir was not set, now searching mounted devices (see /tmp/mounted_dirs1)"
  echo "Docker dir was not set, searching mounted devices"
  df | awk '{print $6}' |sort|uniq > /tmp/mounted_dirs1
  found_place=$(find_docker_dir_by_filelist "/tmp/mounted_dirs1")
  ret_val=$?
  logger "predocker.sh: Docker dir = $found_place"
  echo "Docker dir = $found_place"
  if [ "$ret_val" -eq "0" ]
  then
    logger "predocker.sh: Docker dir is $found_place; now patching docker daemon options"
    patch_config $found_place
    echo "Docker dir is $found_place; patched docker daemon options"
   exit 0
  fi
  
  

  logger "predocker.sh: mount not mounted drives (see /tmp: mounted_disks, all_disks, notmounted_disks)"
  echo "mount not mounted drives"
  #get mounted
  mount | cut -d\  -f 1|sort|uniq > /tmp/mounted_disks

  #get all disks
  lsblk -lp|grep part|cut -d\  -f 1|sort > /tmp/all_disks

  #get needed
  comm -13 /tmp/mounted_disks /tmp/all_disks > /tmp/notmounted_disks

  flist=`cat /tmp/notmounted_disks`
  

  echo -n > /tmp/mounted_dirs2
  #mount found disks and prepare file list
  for disk in $flist
  do
    #echo mkdir /mnt/${disk:5}
    #echo mount $disk /mnt/${disk:5}
    mkdir /mnt/${disk:5}
    mount $disk /mnt/${disk:5}
    echo /mnt/${disk:5} >> /tmp/mounted_dirs2
  done

  logger "predocker.sh: Search in actually mounted devices (see /tmp/mounted_dirs2)"
  found_place=$(find_docker_dir_by_filelist "/tmp/mounted_dirs2")
  ret_val=$?
  echo "found_place = $found_place"

  if [ "$ret_val" -eq "0" ]
  then
    logger "predocker.sh: Docker dir is $found_place; now patching docker daemon options"
    patch_config $found_place
    echo "Docker dir is $found_place; patched docker daemon options"
    exit 0
  fi

  echo "Docker dir not found. Mount device and set it as parameter: /usr/bin/predocker.sh -d docker_data_directory"
  exit 1
fi


