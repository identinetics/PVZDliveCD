#!/bin/bash

# format debug output if using bash -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

notify-send "Looking for Data medium" -t 3000
logger -p local0.info -t  "local0"  "Looking for Docker data medium"
sleep 3
notify-send "waiting for auto-mounting of block devices to complete" -t 3000
logger -p local0.info -t "local0" "waiting for auto-mounting of block devices to complete"
sleep 3
for i in {4..0}; do
  sudo /usr/local/bin/predocker.sh >> /tmp/predocker.log 2>&1
  retval=$?
  if [ $retval -eq 0 ]; then

    break
  else
    zenity --error --text "If you have an initialized medium, please insert it, wait approximately 3 seconds and press OK.

        If you do not have a an initialized medium, follow these steps:
        a) Unplug your medium (USB Flash drive) if it is connected
        b) Open a terminal (from the menu or the 3rd icon from left on the bottom task bar)
        c) Plug in medium
        d) Identify the device number of the medium
           dmesg|tail -15|egrep '(Product|Manufact|logical blocks)'
        e) Identify the <device path>
           lsblk --scsi --path
        f) initialize it:
           umount </device/path>
           mkfs.ext4 </device/path>
           mount </device/path> /mnt
           touch /mnt/UseMe4DockerData
        g) press OK" --title "Data medium not found ($i tries left)"
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

