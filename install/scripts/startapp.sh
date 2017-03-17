#!/bin/bash


function main {
    get_opts $@
    init_sudo
    source /tmp/set_data_dir.sh > /tmp/startapp.log 2>&1
    source $DATADIR/set_docker_image.sh >> /tmp/startapp.log 2>&1
    set_container_name
    pull_or_update_image_if_online
    run_docker_container
}


function init_sudo {
    if [ $(id -u) -ne 0 ]; then
        sudo="sudo"
    fi
}


function set_container_name {
    CONTAINERNAME=$(echo $DOCKER_IMAGE | sed -e 's/^.*\///; s/:.*$//')   # remove repo/ and :tag
    logger -p local0.info -t "local0" "setting up /tmp/set_containername.sh"
    echo '#!/bin/bash' > /tmp/set_containername.sh
    echo "export CONTAINERNAME=$CONTAINERNAME" >> /tmp/set_containername.sh
}


function pull_or_update_image_if_online {
    IMAGE=$($sudo docker images | grep $DOCKER_IMAGE |  awk '{print $3}')
    if [[ -z $IMAGE ]]; then
        pull_image
        if [ "$?" -ne 0 ]; then
            logger -p local0.info -t "local0" "Docker image $DOCKER_IMAGE could not be downloaded"
            exit 1
        fi
    else
       logger -p local0.info -t "local0" "Local Docker image $DOCKER_IMAGE found"
       update_image_if_online
    fi
}


function get_opts {
    runopt='-it'
    while getopts ":hpt" opt; do
      case $opt in
        t) runopt='-i';;
        p) print="True";;
        *) echo "usage: $0 [-h] [-p] [-t]
               -h  print this help text
               -t  do not attach tty (used to call from nested shells, e.g. gnome autostart)
               -p  print docker run command on stdout"
          exit 0;;
      esac
    done
    shift $((OPTIND-1))
}


function get_latest_docker {
    notify-send "Pulling docker image $DOCKER_IMAGE; please wait, update may have several 100 MB"
    logger -p local0.info -t "local0" "pulling docker image $DOCKER_IMAGE"
    $sudo /usr/bin/lxterminal -T DockerImagePullstatus -e docker pull $DOCKER_IMAGE
    logger -p local0.info -t "local0" "Docker image $DOCKER_IMAGE is up to date"
    notify-send "Docker image $DOCKER_IMAGE is up to date" -t 3000
}


function pull_image {
    for i in {4..0}; do
        wget -q --tries=10 --timeout=20 --spider http://www.identinetics.com/
        if [[ $? -eq 0 ]]; then
            get_latest_docker
            return 0
        else
            zenity --error --text "Please connect (WiFi, LAN) or set http_proxy in $DATADIR/set_httpproxy.sh to download docker image" --title "No Internet connection detected! ($i tries left)"
            notify-send "No Internet connection detected! ($i tries left)- please connect to download docker image" -t 3000
            logger -p local0.info -t "local0" -s "No Internet connection detected! ($i tries left)- please connect"
        fi
    done
    return 1
}


function update_image_if_online {
    wget -q --tries=10 --timeout=20 --spider http://www.identinetics.com/
    if [[ $? -eq 0 ]]; then
        notify-send "Online - Preparing download" -t 3000
        logger -p local0.info -t "local0" "Online preparing download"
        #Checking if Docker image is up to date
        #DOCKER_LATEST="'wget -qO- http://$REGISTRY/v1/repositories/$DOCKER_IMAGE/tags'"
        #echo $DOCKER_LATEST
        #DOCKER_LATEST='echo $DOCKER_LATEST | sed "s/{//g" | sed "s/}//g" | sed "s/\"//g" | cut -d ' ' -f2'
        #DOCKER_RUNNING='$sudo docker inspect "$REGISTRY/$DOCKER_IMAGE" | grep Id | sed "s/\"//g" | sed "s/,//g" |  tr -s ' ' | cut -d ' ' -f3'
        #if [ "$DOCKER_RUNNING" == "$DOCKER_LATEST" ];then
         #   run_docker_container
        #else
            get_latest_docker
        #fi

    else
        zenity --info --text "Not checking for docker image update"  --title "OFFLINE - No Internet Connection"
        notify-send "Not checking for  docker image update - OFFLINE" -t 3000
        logger -p local0.info -t "local0" "Not checking for docker image update - OFFLINE"
    fi
}


function run_docker_container {
    notify-send "Docker image $DOCKER_IMAGE found; starting container" -t 3000
    logger -p local0.info -t "local0" "mapping container user's home to $DATADIR"
    source /tmp/set_data_dir.sh > /tmp/startapp.log 2>&1
    source $DATADIR/set_httpproxy.sh >> /tmp/startapp.log 2>&1
    $sudo mkdir -p $DATADIR/home/liveuser/
    $sudo chown -R liveuser:liveuser $DATADIR/home/liveuser/

    # remove dangling container
    if $sudo docker ps -a | grep $CONTAINERNAME > /dev/null; then
        logger -p local0.info -t "local0" "deleting dangling container $CONTAINERNAME"
        $sudo docker rm $CONTAINERNAME
    fi

    # $DATADIR/checkcontainerup.sh &  # use this to spawn a terminal session during startup

    ENVSETTINGS="
        -e DISPLAY=$DISPLAY
        -e http_proxy=$http_proxy
        -e https_proxy=$https_proxy
        -e HTTP_PROXY=$HTTP_PROXY
        -e HTTPS_PROXY=$HTTPS_PROXY
        -e no_proxy=$no_proxy
        -e LIVECD_BUILD=$(cat /opt/BUILD 2>/dev/null)
    "
    LOGSETTINGS='--log-driver=journald --log-opt tag="local0" '
    mkdir -p $XFERDIR
    VOLMAPPING="
        --privileged -v /dev/bus/usb:/dev/bus/usb
        -v /tmp/.X11-unix/:/tmp/.X11-unix:Z
        -v $DATADIR/home/liveuser:/home/liveuser:Z
        -v $XFERDIR:/transfer:Z
     "

    touch $DATADIR/localdockersettings.sh 2>/dev/null
    source $DATADIR/localdockersettings.sh

    logger -p local0.info -t "local0" "starting docker image $DOCKER_IMAGE"
    notify-send "starting docker image $DOCKER_IMAGE" -t 3000
    $sudo docker run $runopt --rm \
        --hostname=$CONTAINERNAME --name=$CONTAINERNAME \
        $ENVSETTINGS $LOGSETTINGS $VOLMAPPING \
        $DOCKER_IMAGE
}


main $@