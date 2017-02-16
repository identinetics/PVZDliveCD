#!/bin/bash

# execute predocker.sh a few times hoping to find a data volume; if successful run startapp.sh

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

notify-send "Waiting for auto-mounting of block devices to complete" -t 6000
logger -p local0.info -t "local0" "waiting for auto-mounting of block devices to complete"
sleep 6

for i in {4..0}; do
  sudo /usr/local/bin/predocker.sh >> /tmp/predocker.log 2>&1
  retval=$?
  if [ $retval -eq 0 ]; then
    break
  else
    zenity --error --text "If you have an initialized medium, please insert it, wait approximately 3 seconds and press OK.

        Otherwise, follow these steps:
        a) Initialize a USB flash drive with a single FAT32 partition (on another system, can be Windows, Mac, etc.)
        b) Plug in USB medium
        c) Start 'Init USB-Drive' with the desktop icon (or /usr/local/bin/init_usbdrive.sh)
        d) press OK when done" --title "Data medium with 'UseMe4DockerData' not found ($i tries left)"
  fi
done

if [ $retval -eq 0 ]; then
  notify-send  "Data medium found"  -t 3000
  source /tmp/set_data_dir.sh > /tmp/startapp.log 2>&1
  source /$DATADIR/set_httpproxy.sh >> /tmp/startapp.log 2>&1
  /usr/local/bin/startapp.sh -t >> /tmp/startapp.log 2>&1   # nested shell must not assign own tty! (search for docker exec -it returns “cannot enable tty mode on non tty input”
else
  notify-send "Data medium not found. Connect a medium (see doc) and run 'sudo /usr/local/bin/start.sh -d /dev/<my-data-drive>'" --timeout 3000
fi

