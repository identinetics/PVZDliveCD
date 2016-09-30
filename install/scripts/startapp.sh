#!/bin/bash

DOCKER_IMAGE='rhoerbe/pvzd-client-app'
REGISTRY="docker.io:5000"

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


function run_docker_container {
    notify-send "Docker image $DOCKER_IMAGE found; starting container"
    logger -p local0.info -t "local0" "mapping container user's home to $DATADIR"
    source /tmp/set_data_dir.sh > /tmp/startapp.log 2>&1
    source $DATADIR/set_httpproxy.sh >> /tmp/startapp.log 2>&1
    $sudo mkdir -p $DATADIR/home/liveuser/
    $sudo chown -R liveuser:liveuser $DATADIR/home/liveuser/

    CONTAINERNAME='x11-app'

    # remove dangling container
    if $sudo docker ps -a | grep $CONTAINERNAME > /dev/null; then
        logger -p local0.info -t "local0" "deleting dangling container $CONTAINERNAME"
        $sudo docker rm $CONTAINERNAME
    fi

    $datadir/checkcontainerup.sh

    ENVSETTINGS="
        -e DISPLAY=$DISPLAY
        -e http_proxy=$http_proxy
        -e https_proxy=$https_proxy
        -e HTTP_PROXY=$HTTP_PROXY
        -e HTTPS_PROXY=$HTTPS_PROXY
        -e no_proxy=$no_proxy
    "
    LOGSETTINGS='--log-driver=journald --log-opt tag="local0" --log-level=warning'
    VOLMAPPING="
        --privileged -v /dev/bus/usb:/dev/bus/usb
        -v /tmp/.X11-unix/:/tmp/.X11-unix:Z
        -v $DATADIR/home/liveuser/:/home/liveuser:Z
     "

    logger -p local0.info -t "local0" "starting docker image $DOCKER_IMAGE"
    notify-send "starting docker image $DOCKER_IMAGE"
    $sudo docker run $runopt --rm \
        --hostname=$CONTAINERNAME --name=$CONTAINERNAME \
        $ENVSETTINGS $LOGSETTINGS $VOLMAPPING \
        $DOCKER_IMAGE
}

function get_latest_docker {
    notify-send "Pulling docker image $DOCKER_IMAGE; please wait, Update has several 100MB " -t 50000
    logger -p local0.info -t "local0" "pulling docker image $DOCKER_IMAGE"
    $sudo docker pull $DOCKER_IMAGE
    notify-send "Docker image $DOCKER_IMAGE is up to date"
    run_docker_container
}

function check_online_status_no_image {
    wget -q --tries=10 --timeout=20 --spider http://www.identinetics.com/
    if [[ $? -eq 0 ]]; then
           echo "Online"
           notify-send "Online - Preparing download"
           logger -p local0.info -t "local0" "Online prepareing download"
           get_latest_docker
    else
        echo "Not pulling docker image - OFFLINE"
        notify-send "Not pulling docker image - OFFLINE"
        logger -p local0.info -t "local0" -s "Not pulling docker image - OFFLINE"
    fi
}

function check_online_status {
    wget -q --tries=10 --timeout=20 --spider http://www.identinetics.com/
    if [[ $? -eq 0 ]]; then
        notify-send "Online - Preparing download"
        logger -p local0.info -t "local0" "Online prepareing download"
        #Checking if Docker image is up to date
        DOCKER_LATEST="'wget -qO- http://$REGISTRY/v1/repositories/$DOCKER_IMAGE/tags'"
        DOCKER_LATEST='echo $LATEST | sed "s/{//g" | sed "s/}//g" | sed "s/\"//g" | cut -d ' ' -f2'
        DOCKER_RUNNING='$sudo docker inspect "$REGISTRY/$DOCKER_IMAGE" | grep Id | sed "s/\"//g" | sed "s/,//g" |  tr -s ' ' | cut -d ' ' -f3'
        if [ "$DOCKER_RUNNING" == "$DOCKER_LATEST" ];then
            run_docker_container
        else
            get_latest_docker
        fi

    else
        notify-send "Not checking for  docker image update - OFFLINE"
        logger -p local0.info -t "local0" "Not checking for  docker image update - OFFLINE"
        run_docker_container
    fi
}


#Check if docker image exists
IMAGE=$($sudo docker images | grep $DOCKER_IMAGE |  awk '{print $3}')
if [[ -z $IMAGE ]]; then
    check_online_status_no_image
    logger -p local0.info -t "local0" "No local Docker image $DOCKER_IMAGE found"
else
   logger -p local0.info -t "local0" "Local Docker image $DOCKER_IMAGE found"
   check_online_status
fi