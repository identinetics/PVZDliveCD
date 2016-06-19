#!/usr/bin/env bash

DOCKER_IMAGE='rhoerbe/pvzd-client-app'
logger -p local0.info "pulling docker image $DOCKER_IMAGE"
docker pull $DOCKER_IMAGE


CONTAINERNAME='pvzd-client'
DOCKERDATA_DIR=$(cat /tmp/dockerdata_dir)
logger -p local0.info "mapping container user's home to $DOCKERDATA_DIR"
mkdir -p $DOCKERDATA_DIR/home/liveuser/
chown -R liveuser:liveuser $DOCKERDATA_DIR/home/liveuser/

logger -p local0.info "starting docker image $DOCKER_IMAGE"
docker run -it --rm \
    --hostname=$CONTAINERNAME --name=$CONTAINERNAME \
    --log-driver=syslog --log-opt syslog-facility=local0 \
    --privileged -v /dev/bus/usb:/dev/bus/usb \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix \
    -v $DOCKERDATA_DIR/home/liveuser/:/home/liveuser:Z
    $DOCKER_IMAGE
