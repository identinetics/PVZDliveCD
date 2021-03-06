#!/usr/bin/env bash


main() {
    set_trace
    echo "starting $0" >> /tmp/startapp.log
    init_sudo
    start_statusd
    mount_ramdisk
    fix_gdk_pixbuf_warning
    wait_for_automount_completion
    find_docker_data_medium
    start_default_application
}


set_trace() {
    PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    mkdir -p /tmp/xtrace
    exec 4>/tmp/xtrace/$(basename $0.log)
    BASH_XTRACEFD=4
    set -x
}


init_sudo() {
    if (( $(id -u) != 0 )); then
        sudo="sudo"
    fi
}


start_statusd() {
    nohup /usr/local/bin/livecd_statusd.sh &
}


wait_for_automount_completion() {
    notify-send "Waiting for auto-mounting of block devices to complete" -t 6000
    logger -p local0.info -t "local0" "waiting for auto-mounting of block devices to complete"
    sleep 9  # 6s turned out to be not enough on some HW
}


find_docker_data_medium() {
    for i in {4..0}; do
      sudo /usr/local/bin/predocker.sh >> /tmp/predocker.log 2>&1
      retval=$?
      if (( $retval == 0 )); then
        break
      else
        zenity --error --text "If you have an initialized medium, please insert it, wait approximately 3 seconds and press OK.

            Otherwise, follow these steps:
            a) Initialize a USB flash drive with a single FAT32 partition (on another system, can be Windows, Mac, etc.)
            b) Plug in USB medium
            c) Start 'Init USB-Drive' with the desktop icon (or /usr/local/bin/init_usbdrive.sh)
            d) press OK when done" --title "Data medium with 'UseMe4DockerData' not found ($i tries left)"
      fi
    done
}


start_default_application() {
    if (( $retval == 0 )); then
      notify-send  "Data medium found"  -t 3000
      source /tmp/set_data_dir.sh > /tmp/startapp.log 2>&1
      source $DATADIR/set_httpproxy.sh >> /tmp/startapp.log 2>&1
      /usr/local/bin/startapp.sh -t -V >> /tmp/startapp.log 2>&1   # nested shell must not assign own tty! (search for docker exec -it returns “cannot enable tty mode on non tty input”
    else
      notify-send "Data medium not found. Connect a medium (see doc) and run 'sudo /usr/local/bin/start.sh -d /dev/<my-data-drive>'" --timeout 3000
    fi
}


fix_gdk_pixbuf_warning() {
    # see https://ubuntuforums.org/showthread.php?t=2094298  etc.
    $sudo su - -c "gdk-pixbuf-query-loaders-64  > /usr/lib64/gdk-pixbuf-2.0/2.10.0/loaders.cache"
}


mount_ramdisk() {
    RAMDISKPATH="/ramdisk"
    df -Th | tail -n +2 | egrep "tmpfs|ramfs" | awk '{print $7}'| grep ${RAMDISKPATH} >/dev/null
    if (( $? != 0 )); then # ramfs not mounted at $RAMDISKPATH
        $sudo mkdir -p ${RAMDISKPATH}/ramdisk
        $sudo mount -t tmpfs -o size=1M tmpfs ${RAMDISKPATH}
        cd ${RAMDISKPATH}
        [[ $PWD != "$RAMDISKPATH" ]] && zenity --error --text "could not make or mount ${RAMDISKPATH}" && exit 1
        echo "Created ramdisk at ${RAMDISKPATH}"
    fi
}


main $@