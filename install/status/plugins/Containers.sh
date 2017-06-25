#!/usr/bin/env bash

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

PLUGINDIR=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
PARENTDIR=$(cd $(dirname $PLUGINDIR) && pwd)

if [[ -z $(docker ps -q) ]]; then
    exit 5
fi

$sudo docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' --all | $PARENTDIR/tab2table.py

