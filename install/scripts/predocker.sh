#!/bin/bash -x

# docker data like images, container and volumes need to reside in a writeable and persistent filesystem.
# Therefore, /var/lib/docker needs to be replaces on a liveCD.
# This script searches for a device having a mark file in the path of the mount point. If found
# (or passed via cl arg) it changes the docker daemon's and app' start options accordingly.
# If not found it exits with return code 1.
# The script also searches for an optional transfer medium (to provide a vfat mount instead of ext4)

# format debug output if using bash -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'


main() {
    mark_datadir="UseMe4DockerData"
    mark_xferdir="UseMe4Transfer"

    data_dir=$(search_for_filesystem_with_markfile $mark_datadir)
    xfer_dir=$(search_for_filesystem_with_markfile $mark_xferdir)
    if (( $? != 0 )); then
        logger -p local0.info -t "local0" -s "No separate file system for transfer dir found. Setting it to $data_dir/transfer"
        xfer_dir="$data_dir/transfer"
        mkdir -p $xfer_dir
    else
        mkdir -p /mnt/xfer
        remount_filesystem $xfer_dir /mnt/xfer
    fi
    create_exportenv_script $data_dir $xfer_dir
    
    set_http_proxy_config
    patch_dockerd_config $data_dir
    set_docker_image_script $data_dir
    checkcontainerup_script $data_dir
}


search_for_filesystem_with_markfile() {
    markfile=$1
    logger -p local0.info -t "local0" -s "predocker.sh: Searching $markfile in mounted devices (see /tmp/mounted_filesystems)"
    get_mounted_filesystems
    marked_filesystem=''
    marked_filesystem=$(find_data_dir_by_filelist "mounted_filesystems" $markfile)
    if (( $? != 0 )); then
        mount_offline_filesystems
        get_mounted_filesystems
        marked_filesystem=$(find_data_dir_by_filelist "mounted_filesystems" $markfile)
        if (( $? == 0 )); then
            setup_with_datadir
        else
            logger -p local0.info -t "local0" -s "Datadir dir not found. Mount device and set it as parameter: /usr/local/bin/predocker.sh -d docker_data_directory"
            exit 2
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
    logger -p local0.info -t "local0"  "predocker.sh: Docker data dir is $dockerdata_dir; now patching dockerd options"
    notify-send "predocker.sh: Docker data dir is $dockerdata_dir; now patching dockerd options"
    mount -o bind $dockerdata_dir /mnt/docker
    systemctl daemon-reload
    systemctl start docker
    logger -p local0.info -t "local0" "Dockerd patched and restarted"
    notify-send "Dockerd patched and restarted"
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
    logger -p local0.info -t "local0" -s "No docker data directory found in file list"
    return 1
}


remount_filesystem() {
    fs_old_path=$1
    fs_new_path=$2
    fs_device=$(mount | grep $fs_old_path | awk '{print $1}')
    #mount -o bind and mount -o remount do not work reliably -> unmount/mount
    umount $fs_device
    mount -o uid=1000,gid=1000 $fs_device $fs_new_path
    logger -p local0.info -t "local0" -s "Filesystem $fs_old_path remounted at $fsnew_path"
    return 0
}


get_mounted_filesystems() {
    df | awk '{print $6}' | sort | uniq > mounted_filesystems
}


mount_offline_filesystems() {
    logger -p local0.info -t "local0" -s "predocker.sh: mount not mounted drives (see /tmp: mounted_disks, all_disks, notmounted_disks)"
    mount | cut -d\  -f 1 | sort | uniq > /tmp/mounted_disks
    lsblk -lp | grep part | cut -d\  -f 1 | sort > /tmp/all_disks
    comm -13 /tmp/mounted_disks /tmp/all_disks > /tmp/notmounted_disks
    flist=$(cat /tmp/notmounted_disks)

    echo -n > /tmp/disks_tried_to_mount
    # mount found disks
    for disk in $flist; do
        mkdir -p /mnt/${disk:5}
        mount $disk /mnt/${disk:5}
        echo /mnt/${disk:5} >> /tmp/disks_tried_to_mount
    done
}


main $@