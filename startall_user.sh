#!/bin/sh

logger "Start sudo predocker" 
sudo /usr/bin/predocker.sh >> /tmp/pre.log 2>&1

#RET_VAR=$?
if [ $? -eq 0 ]
then 
  zenity --notification --text "Docker disk was found, starting docker image" --timeout 1
  /usr/bin/start_app.sh
else
  zenity --notification --text "Docker disk was not found. Connect medium and run 'sudo /usr/bin/predocker.sh -d /dev/<my-docker-drive>'" --timeout 1
fi

