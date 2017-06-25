#!/usr/bin/env bash

if [[ -e "/tmp/set_data_dir.sh" ]]; then
    source /tmp/set_data_dir.sh
    echo "<table>"
    echo "<tr><td>File System</td><td>LiveCD</td><td>Container</td></tr>"
    echo "<tr><td>DATADIR</td><td>$DATADIR</td><td></td></tr>"
    echo "<tr><td></td><td>$DATADIR/home/liveuser</td><td>/home/liveuser</td></tr>"
    echo "<tr><td>XFERDIR</td><td>$XFERDIR</td><td>/transfer</td></td></tr>"
    echo "<tr><td>tmpfs</td><td>/ramdisk</td><td>/ramdisk</td></td></tr>"
    echo "</table>"
    exit 0
else
    echo "predocker.sh not yet completed"
    exit 4
fi