#!/bin/bash


exec="docker run -i --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix rhoerbe/PVZD-client-app"
logger $exec
$exec

