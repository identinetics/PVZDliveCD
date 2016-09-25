#!/bin/bash

DOCKER_IMAGE='rhoerbe/pvzd-client-app'


wget -q --tries=10 --timeout=20 --spider http://www.identinetics.com/
if [[ $? -eq 0 ]]; then
        echo "Online"
        notify-send "Online - Preparing download"
else
        echo "Offline"
        notify-send "Offline - Please connect to internet and start this script again"
fi


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

notify-send "Pulling docker image $DOCKER_IMAGE; please wait" -t 50000
logger -p local0.info "pulling docker image $DOCKER_IMAGE"
$sudo docker pull $DOCKER_IMAGE
notify-send "Docker image $DOCKER_IMAGE up-to date; starting container"

logger -p local0.info "mapping container user's home to $DOCKERDATA_DIR"
$sudo mkdir -p $DATA_DIR/home/liveuser/
$sudo chown -R liveuser:liveuser $DATA_DIR/home/liveuser/

CONTAINERNAME='x11-app'

# remove dangling container
if $sudo docker ps -a | grep $CONTAINERNAME > /dev/null; then
    logger -p local0.info "deleting dangling container $CONTAINERNAME"
    $sudo docker rm $CONTAINERNAME
fi

ENVSETTINGS="
    -e DISPLAY=$DISPLAY
    -e http_proxy=$http_proxy
    -e https_proxy=$https_proxy
    -e HTTP_PROXY=$HTTP_PROXY
    -e HTTPS_PROXY=$HTTPS_PROXY
    -e no_proxy=$no_proxy
"
LOGSETTINGS="--log-driver=syslog --log-opt syslog-facility=local0"
VOLMAPPING="
    --privileged -v /dev/bus/usb:/dev/bus/usb
    -v /tmp/.X11-unix/:/tmp/.X11-unix:Z
    -v $DATA_DIR/home/liveuser/:/home/liveuser:Z
"

logger -p local0.info "starting docker image $DOCKER_IMAGE"
$sudo docker run $runopt --rm \
    --hostname=$CONTAINERNAME --name=$CONTAINERNAME \
    $ENVSETTINGS $LOGSETTINGS $VOLMAPPING \
    $DOCKER_IMAGE
