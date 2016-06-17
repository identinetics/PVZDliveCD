#!/usr/bin/env bash

DOCKER_IMAGE='rhoerbe/pvzd-client-app'
CONTAINERNAME='pvzd-client'

logger -p local0.info "pulling docker image $DOCKER_IMAGE"
docker pull $DOCKER_IMAGE
logger -p local0.info "starting docker image $DOCKER_IMAGE"
docker run -it --rm \
    --hostname=$CONTAINERNAME --name=$CONTAINERNAME \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix \
    $DOCKER_IMAGE
