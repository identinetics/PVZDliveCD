#!/usr/bin/env bash

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

CONTAINERNAME='x11-app'
CONTAINER_IS_UP=$($sudo docker inspect -f {{.State.Running}} $CONTAINERNAME 2>/dev/null)
counter=0



while [ $counter -lt 40 ]; do
    sleep 3
    if [ "$CONTAINER_IS_UP" == "true" ]; then
      notify-send "Starting Docker Container Terminal"
      logger -p local0.info -t "local0" "Starting Docker Container Terminal"
      $sudo /bin/lxterminal -T PVZDclient-Terminal --geometry=120x30 -e /usr/local/bin/dockerterminal.sh
      exit 0
    else
      CONTAINER_IS_UP=$($sudo docker inspect -f {{.State.Running}} $CONTAINERNAME 2>/dev/null)
      counter=$[ counter +1 ]
      logger -p local0.info -t "local0" "$counter. Try to start Docker Container Terminal"
    fi
done


