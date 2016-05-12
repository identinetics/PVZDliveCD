# clcdutils

Installation and creation of live medium

    sudo yum install docker livecd-tools
    cd <ppath to contain project>
    git clone identinetics/PVZDliveCD
    cd PVZDliveCD
    PROJ_HOME=$PWD
    echo $PWD > CLCDDIRvar
    sudo livecd-creator -d -v  -c sig-core-livemedia/kickstarts/centos-7-live-gnome-docker.cfg --cache=$PROJ_HOME/livecache/ --nocleanup


The resulting file is in the project root (livecd-centos-7-live-gnome-docker-*.iso). Copy it to USB drive (2GB ore more)

    dd -in livecd-centos-7-live-gnome-docker-*.iso -out /dev/<usb-drive>