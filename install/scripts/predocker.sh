#!/usr/bin/env bash
# Docker data like images, container and volumes need to reside in a writeable and persistent filesystem.
# Therefore, /var/lib/docker needs to be stored on a writeable persistent volume.
# This script searches for a device having a mark file in the path of the mount point. If found
# it changes the docker daemon's start options accordingly.
# If not found it exits with return code 1.
# The script also searches for an transfer medium (to provide a vfat mount readable on Win/Mac systems)
# Again, if not found it exits with return code 1.


main() {
    set_trace
    check_if_already_done
    mark_datadir="UseMe4DockerData"
    mark_xferdir="UseMe4Transfer"

    data_dir=$(search_for_filesystem_with_markfile $mark_datadir)
    xfer_dir=$(search_for_filesystem_with_markfile $mark_xferdir)
    create_exportenv_script $data_dir $xfer_dir
    
    set_http_proxy_config
    patch_dockerd_config $data_dir
    set_docker_image_script $data_dir
    set_predocker_ok
    checkcontainerup_script $data_dir
}


set_trace() {
    PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    mkdir -p /tmp/xtrace
    exec 4>/tmp/xtrace/$(basename $0.log)
    BASH_XTRACEFD=4
    set -x
}


check_if_already_done() {
    if [[ -e '/tmp/predocker/OK' ]]; then
        logger -p local0.info -t "local0" -s "predocker.sh: skipping (already done)"
        exit 0
    fi
}


search_for_filesystem_with_markfile() {
    markfile=$1
    logger -p local0.info -t "local0" -s "predocker.sh: Searching $markfile in mounted devices (see /tmp/predocker/mounted_filesystems)"
    get_mounted_filesystems
    marked_filesystem=''
    mkdir -p '/tmp/predocker'
    marked_filesystem=$(find_data_dir_by_filelist "/tmp/predocker/mounted_filesystems" $markfile)
    if (( $? != 0 )); then
        mount_offline_filesystems
        get_mounted_filesystems
        marked_filesystem=$(find_data_dir_by_filelist "/tmp/predocker/mounted_filesystems" $markfile)
        if (( $? != 0 )); then
            logger -p local0.error -t "local0" -s "No separate file system marked with ${mark_xferdir} found."
            zenity --error --text "No separate file system marked with ${mark_xferdir} found. Container not started"
            exit 1
        fi
    fi
    echo $marked_filesystem
    return $?
}


set_http_proxy_config() {
    if [[ ! -e '/$dockerdata_dir/set_httpproxy.sh' ]]; then
        logger -p local0.info -t "local0"  "predocker.sh: copying default http proxy config"
        cp -n /usr/local/bin/set_httpproxy.sh $data_dir/
        chmod +x /$data_dir/set_httpproxy.sh
    fi
    logger -p local0.info -t "local0"  "predocker.sh: setting http proxy config"
    source /$data_dir/set_httpproxy.sh
}


patch_dockerd_config() {
    systemctl stop docker
    dockerdata_dir=$1/docker
    mkdir -p $dockerdata_dir
    mount -o bind $dockerdata_dir /mnt/docker
    logger -p local0.info -t "local0"  "predocker.sh: Docker data dir mounted to $dockerdata_dir; now restarting dockerd"
    notify-send "predocker.sh: Docker data dir mounted to $dockerdata_dir; now restarting dockerd"
    systemctl daemon-reload
    systemctl start docker
    logger -p local0.info -t "local0" "Dockerd restarted"
    notify-send "Dockerd restarted"
}


create_exportenv_script() {
    data_dir=$1
    xfer_dir=$2
    xfer_dir=${xfer_dir:=$data_dir/transfer}
    logger -p local0.info -t "local0" "setting up export env script"
    echo '#!/bin/bash' > /tmp/set_data_dir.sh
    echo "export DATADIR=$data_dir" >> /tmp/set_data_dir.sh
    echo "export XFERDIR=$xfer_dir" >> /tmp/set_data_dir.sh
}


set_docker_image_script() {
    # docker image is set in UseMe4DockerData dir
    # (easy to change script without touching the boot image)
    data_dir=$1
    cp -n /usr/local/bin/set_docker_image.sh $data_dir/   #copy default script
}


set_predocker_ok() {
    touch '/tmp/predocker/OK'
}


checkcontainerup_script() {
    # docker script is started from UseMe4DockerData dir
    # (easy to change script without touching the boot image)
    data_dir=$1
    cp -n /usr/local/bin/checkcontainerup.sh $data_dir/   #copy default script
}


find_data_dir_by_filelist() {
    dir_list=`cat $1`
    markfile=$2
    for dir in $dir_list; do
        if [ -e "$dir/$markfile" ]; then
            echo $dir
            return 0
        fi
    done
    logger -p local0.info -t "local0" -s "No file system marked with ${markfile} found"
    return 1
}


#remount_filesystem() {
#    fs_old_path=$1
#    fs_new_path=$2
#    fs_device=$(mount | grep $fs_old_path | awk '{print $1}')
#    #mount -o bind and mount -o remount do not work reliably -> unmount/mount
#    umount $fs_device
#    mount -o uid=1000,gid=1000 $fs_device $fs_new_path
#    logger -p local0.info -t "local0" -s "Filesystem $fs_old_path remounted at $fsnew_path"
#    return 0
#}


get_mounted_filesystems() {
    df | tail -n +2 | grep -v ^tmpfs | awk '{print $6}' | sort | uniq > /tmp/predocker/mounted_filesystems
}


mount_offline_filesystems() {
    logger -p local0.info -t "local0" -s "predocker.sh: mount not mounted drives (see /tmp/predocker)"
    mount | cut -d\  -f 1 | sort | uniq > /tmp/predocker/mounted_disks
    lsblk -lp | grep part | cut -d\  -f 1 | sort > /tmp/predocker/all_disks
    comm -13 /tmp/predocker/mounted_disks /tmp/predocker/all_disks > /tmp/predocker/notmounted_disks
    flist=$(cat /tmp/predocker/notmounted_disks)

    echo -n > /tmp/predocker/disks_tried_to_mount
    # mount found disks
    for disk in $flist; do
        mkdir -p /mnt/${disk:5}
        mount $disk /mnt/${disk:5}
        echo /mnt/${disk:5} >> /tmp/predocker/disks_tried_to_mount
    done
}


main $@