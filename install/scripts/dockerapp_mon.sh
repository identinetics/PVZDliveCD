#!/usr/bin/bash

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi


$sudo journalctl --follow -t "local0"