#!/usr/bin/env bash

main() {
    set_trace
    get_opts "$@"
    init_sudo
    get_container_config
    get_userdefined_settings
    pull_or_update_image_if_online
    verify_docker_image
    remove_existing_container
    run_docker_container
}


set_trace() {
    PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    mkdir -p /tmp/xtrace
    exec 4>/tmp/xtrace/$(basename $0.log)
    BASH_XTRACEFD=4
    set -x
}


get_opts() {
    runopt='-it'
    while getopts ":hptV" opt; do
      case $opt in
        t) runopt='-i';;
        p) print="True";;
        V) noverify='True';;
        *) echo "usage: $0 [-h] [-p] [-t]
               -h  print this help text
               -t  do not attach tty (used to call from nested shells, e.g. gnome autostart)
               -p  print docker run command on stdout
               -V  do not verify docker image"
          exit 0;;
      esac
    done
    shift $((OPTIND-1))
}


init_sudo() {
    if [ $(id -u) -ne 0 ]; then
        sudo="sudo"
    fi
}


get_container_config() {
    SCRIPTDIR=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
    source $SCRIPTDIR/conf.sh
}


get_userdefined_settings() {
    $sudo touch $DATADIR/localdockersettings.sh 2>/dev/null
    $sudo chown liveuser $DATADIR/localdockersettings.sh
    source $DATADIR/localdockersettings.sh
}


pull_or_update_image_if_online() {
    check_free_space
    IMAGE=$($sudo docker images | perl -pe 's/\s+/:/' | grep $DOCKER_IMAGE | awk '{print $1}')
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


update_image_if_online() {
    wget -q --tries=10 --timeout=20 --spider http://www.google.com/
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


get_latest_docker() {
    notify-send "Pulling docker image $DOCKER_IMAGE; please wait, update may have several 100 MB"
    logger -p local0.info -t "local0" "pulling docker image $DOCKER_IMAGE"
    $sudo /usr/bin/lxterminal -T DockerImagePullstatus -e docker pull $DOCKER_IMAGE
    logger -p local0.info -t "local0" "Docker image $DOCKER_IMAGE is up to date"
    notify-send "Docker image $DOCKER_IMAGE is up to date" -t 3000
}


pull_image() {
    for i in {4..0}; do
        wget -q --tries=10 --timeout=20 --spider http://www.google.com/
        if [[ $? -eq 0 ]]; then
            get_latest_docker
            return 0
        else
            zenity --error --text "Please connect (WiFi, LAN) or set http_proxy in $DATADIR/set_httpproxy.sh to download docker image" --title "No Internet connection detected! ($i tries left)"
            notify-send "No Internet connection detected (testing google.com! ($i tries left)- please connect to download docker image" -t 3000
            logger -p local0.info -t "local0" -s "No Internet connection detected! ($i tries left)- please connect"
        fi
    done
    return 1
}


verify_docker_image() {
    if [[ $noverify == 'True' ]]; then
        return 0
    fi
    $SCRIPTDIR/setup_gpg_trust.sh
    $SCRIPTDIR/dscripts/verify.sh -V
    if (($? > 0)); then
        zenity --info --text "Verification of signature for docker image failed. Cannot proceed with start"  --title "Image verification failed"
        notify-send "Verification of signature for docker image failed" -t 3000
        logger -p local0.info -t "local0" "Verification of signature for docker image failed."
        exit 1
    else
        logger -p local0.info -t "local0" "Docker image verified."
    fi
}


remove_existing_container() {
    if $sudo docker ps -a | grep $CONTAINERNAME > /dev/null; then
        logger -p local0.info -t "local0" "deleting dangling container $CONTAINERNAME"
        $sudo docker rm $CONTAINERNAME
    fi
}


run_docker_container() {
    notify-send "starting docker image $DOCKER_IMAGE" -t 3000
    logger -p local0.info -t "local0" "starting docker image $DOCKER_IMAGE"

    $sudo docker rm -f $CONTAINERNAME 2>/dev/null || true
    # $DATADIR/checkcontainerup.sh &  # use this to spawn a terminal session during startup

    runopt2="--rm --hostname=$CONTAINERNAME --name=$CONTAINERNAME $ENVSETTINGS $LOGSETTINGS $VOLMAPPING $DOCKER_IMAGE"
    runopt2=$(echo $runopt2 | tr -d '\n') # remove all newlines
    no_tty=$(docker inspect --format='{{.Config.Labels.no_tty}}' $IMAGENAME)
    if [[ "$no_tty" == 'True' ]]; then
        $sudo docker run $runopt $runopt2
    else
        $sudo /usr/bin/xfce4-terminal -T $CONTAINERNAME --hide-menubar -e "docker run -it $runopt2"
    fi
}


check_free_space() {
    free_kbytes=$(df -k $DATADIR | awk '{print $4}' | tail -1)
    if (( $free_kbytes < 2048000 )); then
        logger -p local0.info -t "local0" "free space on $DATADIR below 1GB - docker pull may fail"
        zenity --info --text "free space on $DATADIR below 2GB - docker pull may fail. Delete data or replace with larger device."  --title "Cannot pull docker image"
    fi
}


main $@