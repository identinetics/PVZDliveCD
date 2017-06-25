#!/bin/bash
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

source /tmp/set_containername.sh

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

clear
source /tmp/set_data_dir.sh
$DATADIR/checkcontainerup.sh

$sudo docker exec -it $CONTAINERNAME /exec_pmp.sh