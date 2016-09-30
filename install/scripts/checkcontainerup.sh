#!/usr/bin/env bash

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

CONTAINERNAME='x11-app'
CONTAINER_IS_UP=$sudo docker inspect -f {{.State.Running}} $CONTAINERNAME
counter = 0



while [ $CONTAINER_IS_UP ! "true" ] && [ counter -gt 40 ]; do
    sleep=3
    CONTAINER_IS_UP=$sudo docker inspect -f {{.State.Running}} $CONTAINERNAME
    counter+=1
    logger -p local0.info -t "local0" "$counter. Try to start Docker Container Terminal"
done

notify-send "Starting Docker Container Terminal"
logger -p local0.info -t "local0" "Starting Docker Container Terminal"
$sudo /bin/lxterminal -T Docker-Container-Terminal -e /usr/local/bin/dockerterminal.sh
