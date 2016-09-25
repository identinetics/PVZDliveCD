#!/bin/bash

# docker data like images, container and volumes need to reside in a writeable filesystem.
# This script searches for a device having a mark in the path of the mount point. If found
# (or passed via cl arg) it changes the docker daemon's and app' start options accordingly.
# If not found it exits with return code 1.

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


function set_http_proxy_config {
  if [ ! -e '/$dockerdata_dir/set_httpproxy.sh' ]; then
    logger -p local0.info "predocker.sh: copying default http proxy config"
    cp -n /usr/local/bin/set_httpproxy.sh $data_dir/
    chmod +x /$data_dir/set_httpproxy.sh
  fi
  logger -p local0.info "predocker.sh: setting http proxy config"
  source /$data_dir/set_httpproxy.sh
}

function patch_dockerd_config {
  systemctl stop docker
  dockerdata_dir=$1/docker
  mkdir -p $dockerdata_dir
  logger -p local0.info "predocker.sh: Docker data dir is $dockerdata_dir; now patching dockerd options"
 sed -i "s/ExecStart=\/usr\/bin\/dockerd/ExecStart=\/usr\/bin\/dockerd -g $dockerdata_dir/" /usr/lib/systemd/system/docker.service
 systemctl daemon-reload
 systemctl start docker
 # /usr/bin/dockerd -g $dockerdata_dir
  logger -p local0.info -s "Dockerd patched and restarted"
}

function create_exportenv_script {
  data_dir=$1
  logger -p local0.info "setting up export env script"
  echo '#!/bin/bash' > /tmp/set_data_dir.sh
  echo "export DATADIR=$data_dir" >> /tmp/set_data_dir.sh
}

function conf_startapp_script {
  # docker script is started from UseMe4DockerData dir
  # (easy to change script without touching the boot image)
  data_dir=$1
  cp -n /usr/local/bin/startapp.sh $data_dir/   #copy default script
}

function setup_all {
  logger -p local0.info -s "predocker.sh: Data dir = $data_dir"
  set_http_proxy_config
  patch_dockerd_config $data_dir
  create_exportenv_script $data_dir
  conf_startapp_script $data_dir
}

function find_data_dir_by_filelist {
  dir_list=`cat $1`
  for dir in $dir_list; do
    # echo "Checking: $dir"
    if [ -e "$dir/$mark_filename" ]; then
    # echo "Dir was found: $dir"
      lmark_dir=$dir
      echo $lmark_dir
      return 0
    fi
  done
  logger -p local0.info -s "No directory found in file list"
  return 1
}

function  get_mounted_disks {
  df | awk '{print $6}' |sort|uniq > /tmp/mounted_dirs1
}

function  mount_not_yet_mounted_disks {
  logger -p local0.info -s "predocker.sh: mount not mounted drives (see /tmp: mounted_disks, all_disks, notmounted_disks)"
  mount | cut -d\  -f 1|sort|uniq > /tmp/mounted_disks
  lsblk -lp|grep part|cut -d\  -f 1|sort > /tmp/all_disks
  comm -13 /tmp/mounted_disks /tmp/all_disks > /tmp/notmounted_disks    #get needed
  flist=`cat /tmp/notmounted_disks`

  echo -n > /tmp/mounted_dirs2
  #mount found disks and prepare file list
  for disk in $flist; do
    mkdir /mnt/${disk:5}
    mount $disk /mnt/${disk:5}
    echo /mnt/${disk:5} >> /tmp/mounted_dirs2
  done
}

# --- main ---

if [ -z "$mark_dir" ]; then
  logger -p local0.info -s "predocker.sh: Data dir was not set, now searching mounted devices (see /tmp/mounted_dirs1)"
  get_mounted_disks
  data_dir=$(find_data_dir_by_filelist "/tmp/mounted_dirs1")
  ret_val=$?
  if [ "$ret_val" -eq "0" ]; then
    setup_all
    exit 0
  fi

  logger -p local0.info "predocker.sh: trying to mount not yet mounted devices (see /tmp/mounted_dirs2)"
  mount_not_yet_mounted_disks
  data_dir=$(find_data_dir_by_filelist "/tmp/mounted_dirs2")
  ret_val=$?
  if [ "$ret_val" -eq "0" ]; then
    setup_all
    exit 0
  fi

  logger -p local0.info -s "Data dir not found. Mount device and set it as parameter: /usr/local/bin/predocker.sh -d docker_data_directory"
  exit 1
fi
