#!/usr/bin/env bash


main() {
    check_lock
    do_forever
}


check_lock() {
    myName="`echo $0 | awk '{print $NF}' FS='/'`"
    lockDir="/run/lock/"
    lockFile=$lockDir$myName.pid
    currentPID=$$
    oldPID="`cat $lockFile`"
    oldderExist=` kill -0 $oldPID 2>/dev/null ; echo $? `

    if (( "$oldderExist" == 0 )); then
        echo "Another instance is running. PID: $oldPID" ;
        exit
    else
        echo $currentPID > $lockFile
    fi
}


do_forever() {
    cd /usr/local/status
    while [[ 1 ]]; do
        ./gen_status_page.py
        sleep 1
    done
}


main "$@"