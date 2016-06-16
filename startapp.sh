#!/usr/bin/env bash

docker_image='rhoerbe/pvzd-client-app'

logger -p local0.info "pulling docker image $docker_image"
docker pull $docker_image
logger -p local0.info "starting docker image $docker_image"
docker run -i --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix $docker_image