#!/bin/bash -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# wait until container named in $CONTAINERNAME is ready (return 0), or return 1 after timeout

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

source /tmp/set_containername.sh

CONTAINER_IS_UP=$($sudo docker inspect -f {{.State.Running}} $CONTAINERNAME 2>/dev/null)
counter=0



while [ $counter -le 12 ]; do
    sleep 5
    if [ "$CONTAINER_IS_UP" == "true" ]; then
      notify-send "Starting Docker Container Terminal"
      logger -p local0.info -t "local0" "Starting Docker Container Terminal"
      exit 0
    else
      CONTAINER_IS_UP=$($sudo docker inspect -f {{.State.Running}} $CONTAINERNAME 2>/dev/null)
      counter=$[ counter +1 ]
      logger -p local0.info -t "local0" "$counter. Waiting for Docker app to start before opening terminal session"
    fi
done

exit 1


