#!/usr/bin/env bash

# configuration for dscripts/verify.sh

main() {
    set_trace
    echo "starting $0" >> /tmp/startapp.log
    get_mount_points
    set_image_and_container_name
    set_image_signature_args
    init_sudo
    set_run_args
    set_vol_mapping
}


set_trace() {
    PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    mkdir -p /tmp/xtrace
    exec 4>/tmp/xtrace/$(basename $0.log)
    BASH_XTRACEFD=4
    set -x
}


get_mount_points() {
    source /tmp/set_data_dir.sh >> /tmp/startapp.log 2>&1
}


set_image_and_container_name() {
    source $DATADIR/set_docker_image.sh >> /tmp/startapp.log 2>&1
    export IMAGENAME=$DOCKER_IMAGE
    export CONTAINERNAME=$(echo $DOCKER_IMAGE | sed -e 's/^.*\///; s/:.*$//')   # remove repo/ and :tag
    logger -p local0.info -t "local0" "setting up /tmp/set_containername.sh"
    echo '#!/bin/bash' > /tmp/set_containername.sh
    echo "export CONTAINERNAME=$CONTAINERNAME" >> /tmp/set_containername.sh
}


set_image_signature_args() {
    export DIDI_SIGNER='rh@identinetics.com'  # PGP uid  - no verification if empty
    export GPG_SIGN_OPTIONS='--default-key 904F1906'
}


init_sudo() {
    if [ $(id -u) -ne 0 ]; then
        sudo="sudo"
    fi
}


set_run_args() {
    source $DATADIR/set_httpproxy.sh >> /tmp/startapp.log 2>&1
    export ENVSETTINGS="
        --net=host
        -e DISPLAY=$DISPLAY
        -e http_proxy=$http_proxy
        -e https_proxy=$https_proxy
        -e HTTP_PROXY=$HTTP_PROXY
        -e HTTPS_PROXY=$HTTPS_PROXY
        -e no_proxy=$no_proxy
        -e LIVECD_BUILD=$(cat /opt/BUILD 2>/dev/null)
    "
    export LOGSETTINGS='--log-driver=journald --log-opt tag="local0" '
}


set_vol_mapping() {
    export VOLMAPPING="
        --privileged -v /dev/bus/usb:/dev/bus/usb
        -v /tmp/.X11-unix/:/tmp/.X11-unix:Z
        -v $DATADIR/home/liveuser:/home/liveuser:Z
        -v $XFERDIR:/transfer:Z
        -v /ramdisk:/ramdisk
     "
    $sudo mkdir -p $DATADIR/home/liveuser/
    $sudo chown -R liveuser:liveuser $DATADIR/home/liveuser/
    $sudo mkdir -p $XFERDIR
}


main $@
