#!/usr/bin/bash

source /tmp/set_containername.sh

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

clear
source /tmp/set_data_dir.sh
$DATADIR/checkcontainerup.sh

$sudo docker exec -it $CONTAINERNAME /exec_pmp.sh