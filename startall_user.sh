#!/bin/sh

zenity --notification --text "Looking for Docker data medium" --timeout 3
logger -p local0.info "Looking for Docker data medium"
for i in {1..10}; do
    sudo /usr/bin/predocker.sh >> /tmp/predocker.log 2>&1
    sleep 3
    [ $? -eq 0 ] && break
done

#RET_VAR=$?
if [ $? -eq 0 ]
then 
  zenity --notification --text "Docker data medium found, starting docker image" --timeout 3
  /tmp/startapp_inv.sh
else
  zenity --notification --text "Docker data medium not found. Connect medium and run 'sudo /usr/bin/predocker.sh -d /dev/<my-docker-drive>'" --timeout 3
fi

