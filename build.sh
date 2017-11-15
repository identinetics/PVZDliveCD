#!/usr/bin/env bash

rm -f PVZDliveCD*.iso

show_repo_status.sh

PROJ_HOME=$PWD
echo $PWD > PROJHOMEvar
mkdir -p livecache

sudo livecd-creator -d -v  -c fedora-kickstarts/Fedora-lxde-remix.ks \
    --cache=$PROJ_HOME/livecache/ --cacheonly \
    --releasever=25 \
    --nocleanup  | tee > build.log 2>&1

#livemedia-creator --make-iso \
#     --ks fedora-kickstarts/Fedora-lxde-remix.ks \
#     --logfile build.log \
#     --iso PVZDliveCD-build.iso \
#     --releasever 25


mv livecd-Fedora-lxde-remix-*.iso PVZDliveCD-build$(cat BUILD).iso

echo "build PVZDliveCD-build$(cat BUILD).iso"
[[ "$1" == '--samebuild' ]] || echo -n $(($(cat BUILD)+1))  > BUILD  # increment build number
