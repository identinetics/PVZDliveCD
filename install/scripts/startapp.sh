#!/bin/bash

DOCKER_IMAGE='rhoerbe/pvzd-client-app'

runopt='-it'
while getopts ":hpt" opt; do
  case $opt in
    t)
      runopt='-i'
      ;;
    p)
      print="True"
      ;;
    *)
      echo "usage: $0 [-h] [-p] [-t]
   -h  print this help text
   -t  do not attach tty (used to call from nested shells, e.g. gnome autostart)
   -p  print docker run command on stdout"
      exit 0
      ;;
  esac
done
shift $((OPTIND-1))

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

notify-send "Pulling docker image $DOCKER_IMAGE; please wait"  -t 50000
logger -p local0.info "pulling docker image $DOCKER_IMAGE"
$sudo docker pull $DOCKER_IMAGE
notify-send "Docker image $DOCKER_IMAGE up-to date; starting container"

DOCKERDATA_DIR=$(cat /tmp/dockerdata_dir)
logger -p local0.info "mapping container user's home to $DOCKERDATA_DIR"
$sudo mkdir -p $DOCKERDATA_DIR/home/liveuser/
$sudo chown -R liveuser:liveuser $DOCKERDATA_DIR/home/liveuser/

CONTAINERNAME='x11-app'

# remove dangling container
if $sudo docker ps -a | grep $CONTAINERNAME > /dev/null; then
    logger -p local0.info "deleting dangling container $CONTAINERNAME"
    $sudo docker rm $CONTAINERNAME
fi

export ENVSETTINGS="
    -e DISPLAY=$DISPLAY
"
if [ -e $http_proxy ]
export VOLMAPPING="
    --privileged -v /dev/bus/usb:/dev/bus/usb
    -v /tmp/.X11-unix/:/tmp/.X11-unix:Z
    -v $DOCKERDATA_DIR/home/liveuser/:/home/liveuser:Z
"

logger -p local0.info "starting docker image $DOCKER_IMAGE"
$sudo docker run $runopt --rm \
    --hostname=$CONTAINERNAME --name=$CONTAINERNAME \
    --log-driver=syslog --log-opt syslog-facility=local0 \
    $ENVSETTINGS $VOLMAPPING \
    $DOCKER_IMAGE
