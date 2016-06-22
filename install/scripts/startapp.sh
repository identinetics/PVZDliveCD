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

notify-send "Pulling docker image $DOCKER_IMAGE; please wait"  -t 50000
logger -p local0.info "pulling docker image $DOCKER_IMAGE"
docker pull $DOCKER_IMAGE
notify-send "Docker image $DOCKER_IMAGE up-to date; starting container"

DOCKERDATA_DIR=$(cat /tmp/dockerdata_dir)
logger -p local0.info "mapping container user's home to $DOCKERDATA_DIR"
mkdir -p $DOCKERDATA_DIR/home/liveuser/
chown -R liveuser:liveuser $DOCKERDATA_DIR/home/liveuser/

CONTAINERNAME='x11-app'

# remove dangling container
if [ "$(docker ps -a | grep $CONTAINERNAME)" == "$CONTAINERNAME" ]; then
    docker rm $(docker ps -a -q)
fi

logger -p local0.info "starting docker image $DOCKER_IMAGE"
docker run $runopt --rm \
    --hostname=$CONTAINERNAME --name=$CONTAINERNAME \
    --log-driver=syslog --log-opt syslog-facility=local0 \
    --privileged -v /dev/bus/usb:/dev/bus/usb \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix \
    -v $DOCKERDATA_DIR/home/liveuser/:/home/liveuser:Z \
    $DOCKER_IMAGE
