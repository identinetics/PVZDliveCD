#!/usr/bin/env bash

rm livecd-centos-7-live-gnome-docker*.iso

sudo livecd-creator -d -v  -c sig-core-livemedia/centos-7-live-gnome-docker.cfg \
    --cache=$PROJ_HOME/livecache/ --nocleanup | tee > build.log
