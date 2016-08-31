#!/usr/bin/env bash

CONTAINERNAME='x11-app'

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

$sudo docker exec -it $CONTAINERNAME bash