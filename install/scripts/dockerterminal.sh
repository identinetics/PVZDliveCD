#!/usr/bin/bash

source /tmp/set_containername.sh

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

#/usr/bin/setterm term linux -foreground black -background white
clear
$sudo docker exec -it $CONTAINERNAME /exec_app.sh