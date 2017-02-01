#!/usr/bin/env bash

rm -f PVZDliveCD*.iso

PROJ_HOME=$PWD
echo $PWD > PROJHOMEvar
mkdir livecache

sudo livecd-creator -d -v  -c fedora-kickstarts/Fedora24-lxde-remix.ks \
    --cache=$PROJ_HOME/livecache/ \
    --releasever=24\
    --nocleanup | tee > build.log

mv livecd-Fedora24-lxde-remix-*.iso PVZDliveCD-build$(cat BUILD).iso

echo -n $(($(cat BUILD)+1))  > BUILD  # increment build number
