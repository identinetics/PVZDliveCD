#!/usr/bin/env bash

docker run -i --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix rhoerbe/pvzd-client-app