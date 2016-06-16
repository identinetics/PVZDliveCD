#!/bin/bash

# docker data like images, container and volumes need to reside in a writeable filesystem.
# This script searches for a device having a mark in the path of the mount point and 
# changes the docker daemon' start options accordingly.

# format debug output if using bash -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

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


function patch_dockerd_config {
  dockerdata_dir=$1
  logger -p local0.info "predocker.sh: Docker data dir is $dockerdata_dir; now patching docker daemon options"
  sed -i "s~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/ -g $dockerdata_dir~" /usr/lib/systemd/system/docker.service
  systemctl daemon-reload
  systemctl start docker
  logger -p local0.info -s "Docker daemon patched and restarted"
}


function conf_startapp_script {
  # docker script is started from UseMe4DockerData dir
  # (easy to change script without touching the bood image)
  dockerdata_dir=$1
  logger -p local0.info "setting up startapp script"
  echo '#!/bin/bash' > /tmp/startapp_inv.sh
  echo "$dockerdata_dir/startapp.sh" >> /tmp/startapp_inv.sh
  chmod +x /tmp/startapp_inv.sh
}


function find_docker_dir_by_filelist {
# find docker dir, argument is a dir list
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
  logger -p local0.info -s "No directory found in file list"
  return 1
}


logger -p local0.info "predocker.sh - waiting for auto-mounting of block devices to complete"
sleep 5


if [[ -z "$mark_dir" ]]
then
  logger -p local0.info -s "predocker.sh: Docker dir was not set, now searching mounted devices (see /tmp/mounted_dirs1)"
  df | awk '{print $6}' |sort|uniq > /tmp/mounted_dirs1
  dockerdata_dir=$(find_docker_dir_by_filelist "/tmp/mounted_dirs1")
  ret_val=$?
  logger -p local0.info -s "predocker.sh: Docker dir = $dockerdata_dir"
  if [ "$ret_val" -eq "0" ]
  then
    patch_dockerd_config $dockerdata_dir
    conf_startapp_script $dockerdata_dir
   exit 0
  fi

  logger -p local0.info -s "predocker.sh: mount not mounted drives (see /tmp: mounted_disks, all_disks, notmounted_disks)"
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
    mkdir /mnt/${disk:5}
    mount $disk /mnt/${disk:5}
    echo /mnt/${disk:5} >> /tmp/mounted_dirs2
  done

  logger -p local0.info "predocker.sh: Search in actually mounted devices (see /tmp/mounted_dirs2)"
  dockerdata_dir=$(find_docker_dir_by_filelist "/tmp/mounted_dirs2")
  ret_val=$?
  logger -p local0.info "UseMe4DockerData = $dockerdata_dir"
  echo $dockerdata_dir > /tmp/DockerDataDir

  if [ "$ret_val" -eq "0" ]
  then
    patch_dockerd_config $dockerdata_dir
    conf_startapp_script $dockerdata_dir
    exit 0
  fi

  logger -p local0.info -s "Docker dir not found. Mount device and set it as parameter: /usr/bin/predocker.sh -d docker_data_directory"
  exit 1
fi
