#!/usr/bin/env bash

rm -f livecd-centos-7-gnome-docker*.iso

sudo livecd-creator -d -v  -c sig-core-livemedia/centos-7-gnome-docker.cfg \
    --cache=$PROJ_HOME/livecache/ \
    --nocleanup | tee > build.log
