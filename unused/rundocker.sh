#!/bin/bash
cd /home/liveuser
cp /home/Dockerfile .

# do not build locally, fetch from dockerhub
# docker build --rm -t rhoerbe/PVZDclient -f Dockerfile .
docker run -i --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix --name PVZDclient rhoerbe/pvzd-client-app
