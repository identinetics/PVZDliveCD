#!/usr/bin/bash

source /tmp/set_containername.sh

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

clear
$sudo docker exec -it $CONTAINERNAME /exec_patool.sh