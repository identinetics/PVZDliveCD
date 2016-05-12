# PVZD Live CD

## Purpose
Boot a CentOS 7 live medium into a GNOME desktop running inside a docker container with the PVZD client application.

## Installation and creation of live medium

    sudo yum install docker livecd-tools
    cd <path to contain project>
    git clone identinetics/PVZDliveCD
    cd PVZDliveCD
    PROJ_HOME=$PWD
    echo $PWD > CLCDDIRvar
    mkdir livecache
    sudo livecd-creator -d -v  -c sig-core-livemedia/kickstarts/centos-7-live-gnome-docker.cfg --cache=$PROJ_HOME/livecache/ --nocleanup


The resulting file is in the project root (livecd-centos-7-live-gnome-docker-*.iso). Copy it to USB drive (2GB ore more)

    dd if=livecd-centos-7-live-gnome-docker-<timestamp>.iso of=/dev/<usb-drive>