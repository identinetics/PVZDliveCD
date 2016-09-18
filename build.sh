#!/usr/bin/env bash

rm -f livecd-PVZDliveCD*.iso

PROJ_HOME=$PWD
echo $PWD > CLCDDIRvar
mkdir livecache

sudo livecd-creator -d -v  -c fedora-kickstarts/PVZDliveCD-Fedora24-lxde-Remix.ks \
    --cache=$PROJ_HOME/livecache/ \
    --nocleanup | tee > build.log
