#!/usr/bin/bash

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

/usr/bin/setterm term linux -foreground green -background black
$sudo journalctl --follow -t "local0"