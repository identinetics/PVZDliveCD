#!/bin/bash -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

/usr/bin/setterm term linux -foreground green -background black
$sudo journalctl --follow -t "local0"