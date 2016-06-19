#!/usr/bin/env bash

DOCKER_IMAGE='rhoerbe/pvzd-client-app'
CONTAINERNAME='pvzd-client'
mkdir -p $DOCKERDATA_DIR/home/liveuser/
chown -R liveuser:liveuser $DOCKERDATA_DIR/home/liveuser/

logger -p local0.info "pulling docker image $DOCKER_IMAGE"
docker pull $DOCKER_IMAGE
logger -p local0.info "starting docker image $DOCKER_IMAGE"
docker run -it --rm \
    --hostname=$CONTAINERNAME --name=$CONTAINERNAME \
    --privileged -v /dev/bus/usb:/dev/bus/usb \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix \
    -v $DOCKERDATA_DIR/home/liveuser/:/home/liveuser:Z
    $DOCKER_IMAGE
