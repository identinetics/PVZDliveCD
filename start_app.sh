#!/bin/bash


exec="docker run -i --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix rhoerbe/PVZDclient"
logger $exec
$exec

