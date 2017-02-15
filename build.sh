#!/usr/bin/env bash

rm -f PVZDliveCD*.iso

PROJ_HOME=$PWD
echo $PWD > PROJHOMEvar
mkdir -p livecache

sudo livecd-creator -d -v  -c fedora-kickstarts/Fedora-lxde-remix.ks \
    --cache=$PROJ_HOME/livecache/ \
    --releasever=25 \
    --nocleanup | tee > build.log

#livemedia-creator --make-iso \
#     --ks fedora-kickstarts/Fedora-lxde-remix.ks \
#     --logfile build.log \
#     --iso PVZDliveCD-build.iso \
#     --releasever 25


mv livecd-Fedora-lxde-remix-*.iso PVZDliveCD-build$(cat BUILD).iso

echo "build PVZDliveCD-build$(cat BUILD).iso"
echo -n $(($(cat BUILD)+1))  > BUILD  # increment build number
